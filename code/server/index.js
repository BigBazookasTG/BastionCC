const express = require('express');
const http = require('http');
const https = require('https');
const { Server } = require('socket.io');
const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const net = require('net');
const dns = require('dns');
const rateLimit = require('express-rate-limit');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { maxHttpBufferSize: 1e8 }); 

app.use(express.static(path.join(__dirname, '../public')));

// Explicit asset routes to eliminate js/serving-sensitive-directory
app.get('/node_modules/xterm/css/xterm.css', (req, res) => {
    res.sendFile(path.join(__dirname, '../node_modules/xterm/css/xterm.css'));
});
app.get('/node_modules/xterm/lib/xterm.js', (req, res) => {
    res.sendFile(path.join(__dirname, '../node_modules/xterm/lib/xterm.js'));
});
app.get('/node_modules/xterm-addon-fit/lib/xterm-addon-fit.js', (req, res) => {
    res.sendFile(path.join(__dirname, '../node_modules/xterm-addon-fit/lib/xterm-addon-fit.js'));
});

app.use(express.json());

const CONFIG_DIR = path.join(__dirname, '../data');

function isValidKeyPath(keyPath) {
    if (!keyPath || typeof keyPath !== 'string') return false;
    const resolvedPath = path.resolve(keyPath);
    if (resolvedPath.startsWith(CONFIG_DIR)) return false;
    if (!resolvedPath.includes('/.ssh/') && !resolvedPath.startsWith('/app/keys/')) return false;
    return true;
}
const AUTH_FILE = path.join(CONFIG_DIR, 'auth.json');
const DATA_FILE = path.join(CONFIG_DIR, 'servers.json');
const BANS_FILE = path.join(CONFIG_DIR, 'ban_history.json');
const PUBLIC_CHANGELOG = path.join(__dirname, '../public/changelog.json');

if (!fs.existsSync(CONFIG_DIR)) fs.mkdirSync(CONFIG_DIR, { recursive: true });
if (!fs.existsSync(BANS_FILE)) fs.writeFileSync(BANS_FILE, JSON.stringify([]));

let masterAuth = null;
if (fs.existsSync(AUTH_FILE)) {
    masterAuth = JSON.parse(fs.readFileSync(AUTH_FILE, 'utf8'));
    if (!masterAuth.jwtSecret) {
        masterAuth.jwtSecret = crypto.randomBytes(64).toString('hex');
        fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
    }
}

const authLimiter = rateLimit({ windowMs: 5 * 60 * 1000, max: 5, message: { success: false, message: 'Too many attempts, please try again after 5 minutes' } });

function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.split(' ')[1];
    if (!token || !masterAuth) return res.status(401).json({ success: false, message: 'Unauthorized' });
    jwt.verify(token, masterAuth.jwtSecret, (err) => {
        if (err) return res.status(401).json({ success: false, message: 'Invalid session' });
        next();
    });
}

app.get('/api/status', (req, res) => res.json({ needsSetup: !fs.existsSync(AUTH_FILE) }));

app.get('/api/changelog', (req, res) => {
    try {
        if (fs.existsSync(PUBLIC_CHANGELOG)) {
            const data = fs.readFileSync(PUBLIC_CHANGELOG, 'utf8');
            return res.json(JSON.parse(data));
        }
        res.json([]);
    } catch(e) {
        res.status(500).json({ error: 'Failed to read changelog' });
    }
});

app.post('/api/setup', authLimiter, (req, res) => {
    if (fs.existsSync(AUTH_FILE)) return res.status(400).json({ success: false, message: 'System is already configured.' });
    const pin = (req.body.pin || '').trim();
    if (pin.length < 4) return res.status(400).json({ success: false, message: 'PIN must be at least 4 characters.' });

    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.scryptSync(pin, salt, 64).toString('hex');
    const masterKeySalt = crypto.randomBytes(32).toString('hex');
    const jwtSecret = crypto.randomBytes(64).toString('hex'); 
    
    masterAuth = { salt, hash, masterKeySalt, jwtSecret };
    fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
    const token = jwt.sign({ auth: true }, masterAuth.jwtSecret, { expiresIn: '12h' });
    res.json({ success: true, token });
});

app.post('/api/login', authLimiter, (req, res) => {
    if (!masterAuth) return res.status(400).json({ success: false, message: 'System requires setup.' });
    const pin = (req.body.pin || '').trim();
    const verifyHash = crypto.scryptSync(pin, masterAuth.salt, 64);
    const storedHash = Buffer.from(masterAuth.hash, 'hex');
    let isValid = false;
    if (verifyHash.length === storedHash.length) isValid = crypto.timingSafeEqual(verifyHash, storedHash);
    
    if (isValid) {
        const token = jwt.sign({ auth: true }, masterAuth.jwtSecret, { expiresIn: '12h' });
        res.json({ success: true, token });
    } else res.status(401).json({ success: false, message: 'Invalid Master PIN' });
});

app.post('/api/reset-pin', requireAuth, (req, res) => {
    const { currentPin, newPin } = req.body;
    if (!currentPin || !newPin || newPin.length < 4) return res.status(400).json({success: false, message: 'Invalid input'});
    
    const verifyHash = crypto.scryptSync(currentPin, masterAuth.salt, 64);
    const storedHash = Buffer.from(masterAuth.hash, 'hex');
    if (verifyHash.length !== storedHash.length || !crypto.timingSafeEqual(verifyHash, storedHash)) return res.status(401).json({success: false, message: 'Invalid current PIN'});
    
    let servers = getServers();
    servers = servers.map(s => {
        if (s.encryptedPassphrase) s.tempPlaintext = decryptPassphrase(s.encryptedPassphrase, currentPin);
        if (s.encryptedPrivateKey) s.tempKeyPlaintext = decryptPassphrase(s.encryptedPrivateKey, currentPin);
        return s;
    });
    
    let tempAbuseKey = '';
    if (masterAuth.encryptedAbuseIpDbKey) {
        tempAbuseKey = decryptPassphrase(masterAuth.encryptedAbuseIpDbKey, currentPin);
    }

    const newSalt = crypto.randomBytes(16).toString('hex');
    const newHash = crypto.scryptSync(newPin, newSalt, 64).toString('hex');
    const newMasterKeySalt = crypto.randomBytes(32).toString('hex');
    const newJwtSecret = crypto.randomBytes(64).toString('hex'); 
    
    masterAuth = { salt: newSalt, hash: newHash, masterKeySalt: newMasterKeySalt, jwtSecret: newJwtSecret };
    if (tempAbuseKey) {
        masterAuth.encryptedAbuseIpDbKey = encryptPassphrase(tempAbuseKey, newPin);
    }
    fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
    
    servers = servers.map(s => {
        if (s.tempPlaintext) { s.encryptedPassphrase = encryptPassphrase(s.tempPlaintext, newPin); delete s.tempPlaintext; }
        if (s.tempKeyPlaintext) { s.encryptedPrivateKey = encryptPassphrase(s.tempKeyPlaintext, newPin); delete s.tempKeyPlaintext; }
        return s;
    });
    fs.writeFileSync(DATA_FILE, JSON.stringify(servers, null, 2));
    io.disconnectSockets();
    res.json({success: true});
});

app.get('/api/abuseipdb-status', requireAuth, (req, res) => {
    res.json({ hasKey: !!(masterAuth && masterAuth.encryptedAbuseIpDbKey) });
});

app.post('/api/abuseipdb-key', requireAuth, (req, res) => {
    const { apiKey, pin } = req.body;
    if (!pin) return res.status(400).json({ success: false, message: 'PIN is required to encrypt key' });
    
    const verifyHash = crypto.scryptSync(pin, masterAuth.salt, 64);
    const storedHash = Buffer.from(masterAuth.hash, 'hex');
    if (verifyHash.length !== storedHash.length || !crypto.timingSafeEqual(verifyHash, storedHash)) {
        return res.status(401).json({ success: false, message: 'Invalid Master PIN' });
    }

    if (!apiKey || !apiKey.trim()) {
        delete masterAuth.encryptedAbuseIpDbKey;
    } else {
        masterAuth.encryptedAbuseIpDbKey = encryptPassphrase(apiKey.trim(), pin);
    }
    fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
    res.json({ success: true, hasKey: !!masterAuth.encryptedAbuseIpDbKey });
});

app.delete('/api/abuseipdb-key', requireAuth, (req, res) => {
    if (masterAuth && masterAuth.encryptedAbuseIpDbKey) {
        delete masterAuth.encryptedAbuseIpDbKey;
        fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
    }
    res.json({ success: true });
});

function getMasterEncryptionKey(pin) { return masterAuth ? crypto.scryptSync(pin, masterAuth.masterKeySalt, 32) : null; }

function encryptPassphrase(passphrase, pin) {
    if (!passphrase || !masterAuth) return '';
    const key = getMasterEncryptionKey(pin);
    const iv = crypto.randomBytes(12);
    const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
    let encrypted = cipher.update(passphrase, 'utf8', 'hex'); encrypted += cipher.final('hex');
    return `${iv.toString('hex')}:${cipher.getAuthTag().toString('hex')}:${encrypted}`;
}

function decryptPassphrase(encryptedData, pin) {
    if (!encryptedData || !masterAuth) return '';
    try {
        const parts = encryptedData.split(':'); if (parts.length !== 3) return '';
        const iv = Buffer.from(parts[0], 'hex'), authTag = Buffer.from(parts[1], 'hex'), key = getMasterEncryptionKey(pin);
        const decipher = crypto.createDecipheriv('aes-256-gcm', key, iv); decipher.setAuthTag(authTag);
        let decrypted = decipher.update(parts[2], 'hex', 'utf8'); decrypted += decipher.final('utf8');
        return decrypted;
    } catch (e) { return ''; }
}

function resolvePrivateKey(serverConfig, pin) {
    if (serverConfig.encryptedPrivateKey && pin) {
        const decrypted = decryptPassphrase(serverConfig.encryptedPrivateKey, pin);
        if (decrypted) return decrypted;
    }
    if (serverConfig.privateKeyPath && isValidKeyPath(serverConfig.privateKeyPath)) {
        try { return fs.readFileSync(path.resolve(serverConfig.privateKeyPath), 'utf8'); } catch(e) { return null; }
    }
    return null;
}

if (!fs.existsSync(DATA_FILE)) fs.writeFileSync(DATA_FILE, JSON.stringify([]));

function getServers() {
    try { const content = fs.readFileSync(DATA_FILE, 'utf8'); return content.trim() ? JSON.parse(content) : []; } 
    catch (err) { return []; }
}

function getBanHistory() {
    try { const content = fs.readFileSync(BANS_FILE, 'utf8'); return content.trim() ? JSON.parse(content) : []; } 
    catch (err) { return []; }
}

function recordBanEntry(entry) {
    try {
        const bans = getBanHistory();
        bans.push({ ...entry, timestamp: Date.now() });
        fs.writeFileSync(BANS_FILE, JSON.stringify(bans, null, 2));
    } catch(e) {}
}

const COUNTRY_COORDS = {
    'US': [37.0902, -95.7129], 'CA': [56.1304, -106.3468], 'GB': [55.3781, -3.4360], 'DE': [51.1657, 10.4515],
    'FR': [46.2276, 2.2137], 'RU': [61.5240, 105.3188], 'CN': [35.8617, 104.1954], 'NL': [52.1326, 5.2913],
    'SG': [1.3521, 103.8198], 'IN': [20.5937, 78.9629], 'BR': [-14.2350, -51.9253], 'AU': [-25.2744, 133.7751],
    'JP': [36.2048, 138.2529], 'KR': [35.9078, 127.7669], 'HK': [22.3193, 114.1694], 'VN': [14.0583, 108.2772],
    'UA': [48.3794, 31.1656], 'PL': [51.9194, 19.1451], 'SE': [60.1282, 18.6435], 'CH': [46.8182, 8.2275],
    'IT': [41.8719, 12.5674], 'ES': [40.4637, -3.7492], 'RO': [45.9432, 24.9668], 'BG': [42.7339, 25.4858],
    'TR': [38.9637, 35.2433], 'IR': [32.4279, 53.6880], 'ID': [-0.7893, 113.9213], 'SC': [-4.6796, 55.4920]
};

const HEADER_DICT = {
    'strict-transport-security': { desc: 'Forces HTTPS connections.', rec: 'Ensure max-age is high and includes preload.' },
    'content-security-policy': { desc: 'Mitigates XSS & data injection.', rec: 'Implement a strict CSP restricting unsafe-inline scripts.' },
    'x-frame-options': { desc: 'Protects against clickjacking.', rec: 'Set to SAMEORIGIN or DENY.' },
    'x-content-type-options': { desc: 'Prevents MIME-sniffing.', rec: 'Set to nosniff.' },
    'referrer-policy': { desc: 'Controls referrer leaks.', rec: 'Set to strict-origin-when-cross-origin.' },
    'permissions-policy': { desc: 'Restricts browser features.', rec: 'Disable unused features (e.g., camera, microphone).' }
};

function escapeHtmlForReport(str) { return String(str).replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m])); }

function fetchHttpsJson(url, headers = {}) {
    return new Promise((resolve, reject) => {
        const req = https.get(url, { headers: { 'User-Agent': 'BastionCC/1.9', ...headers }, timeout: 4000 }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); }
                catch(e) { reject(e); }
            });
        });
        req.on('error', err => reject(err));
        req.on('timeout', function() { this.destroy(); reject(new Error('Timeout')); });
    });
}

async function resolveIpIntel(ip, pin) {
    let result = null;

    try {
        const raw = await fetchHttpsJson(`https://ipwho.is/${ip}`);
        if (raw && raw.success !== false) {
            result = {
                country: raw.country || 'Unknown',
                country_code: raw.country_code || '',
                country_flag: raw.flag?.emoji || '🌐',
                region: raw.region || '',
                city: raw.city || '',
                isp: raw.connection?.isp || raw.connection?.org || 'Unknown ISP',
                org: raw.connection?.org || raw.connection?.isp || '',
                asn: raw.connection?.asn ? `AS${raw.connection.asn}` : 'N/A',
                ip_range: raw.ip || ip
            };
        }
    } catch(e) {}

    if (!result) {
        try {
            const raw = await fetchHttpsJson(`https://ipapi.co/${ip}/json/`);
            if (raw && !raw.error) {
                result = {
                    country: raw.country_name || 'Unknown',
                    country_code: raw.country_code || '',
                    country_flag: '🌐',
                    region: raw.region || '',
                    city: raw.city || '',
                    isp: raw.org || 'Unknown ISP',
                    org: raw.org || '',
                    asn: raw.asn || 'N/A',
                    ip_range: raw.ip || ip
                };
            }
        } catch(e) {}
    }

    if (!result) {
        result = { country: 'Internet Host', country_code: 'XX', country_flag: '🌐', region: '', city: '', isp: 'Unknown Provider', org: '', asn: 'N/A', ip_range: ip };
    }

    let abuseKey = '';
    if (masterAuth && masterAuth.encryptedAbuseIpDbKey && pin) {
        abuseKey = decryptPassphrase(masterAuth.encryptedAbuseIpDbKey, pin);
    }

    if (abuseKey) {
        try {
            const abuseRaw = await fetchHttpsJson(`https://api.abuseipdb.com/api/v2/check?ipAddress=${encodeURIComponent(ip)}&maxAgeInDays=90&verbose`, {
                'Key': abuseKey,
                'Accept': 'application/json'
            });
            if (abuseRaw && abuseRaw.data) {
                const conf = abuseRaw.data.abuseConfidenceScore || 0;
                let score = 1;
                let level = 'Low Threat';
                if (conf >= 50) { score = 5; level = 'High Threat (Known Abuse)'; }
                else if (conf >= 15) { score = 3; level = 'Moderate Threat (Suspicious Activity)'; }
                else { score = 1; level = 'Low Threat (Clean)'; }

                result.threat = {
                    score,
                    level,
                    engine: 'AbuseIPDB Global Intelligence',
                    confidence: conf,
                    totalReports: abuseRaw.data.totalReports || 0,
                    lastReportedAt: abuseRaw.data.lastReportedAt || 'N/A',
                    usageType: abuseRaw.data.usageType || 'Commercial/Data Center'
                };
                return result;
            }
        } catch(e) {}
    }

    const lowerOrg = (result.org + ' ' + result.isp).toLowerCase();
    const isHostingDc = /cloud|host|data|server|digitalocean|hetzner|ovh|linode|vultr|aws|amazon|google|microsoft|azure|alibaba|tencent|oracle|choopa|m247|fastly|cloudflare/.test(lowerOrg);
    
    let score = 1;
    let level = 'Low Threat (Benign / Residential)';
    if (isHostingDc) {
        score = 3;
        level = 'Moderate Threat (Hosting / Datacenter Node)';
    }

    result.threat = {
        score,
        level,
        engine: 'BastionCC Local Heuristics',
        confidence: isHostingDc ? 45 : 10,
        totalReports: null,
        lastReportedAt: null,
        usageType: isHostingDc ? 'Data Center / Hosting Provider' : 'ISP / Residential Line'
    };

    return result;
}

const activePins = new Map();

io.use((socket, next) => {
    if (!masterAuth) return next(new Error('System requires setup'));
    const token = socket.handshake.auth.token, pin = (socket.handshake.auth.pin || '').trim();
    if (!token) return next(new Error('No token'));
    jwt.verify(token, masterAuth.jwtSecret, (err) => {
        if (err) return next(new Error('Invalid token'));
        if (pin) activePins.set(socket.id, pin);
        next();
    });
});

io.on('connection', (socket) => {
    let sshClient = null; let sftpSession = null; let activeShellStream = null; 
    let statsInterval = null; let dockerInterval = null; const activeUploads = new Map();
    let prevCpuTicks = null;

    socket.emit('servers-list', getServers());
    
    socket.on('emergency-lock', () => {
        const servers = getServers(); servers.forEach(s => { delete s.encryptedPassphrase; delete s.encryptedPrivateKey; });
        fs.writeFileSync(DATA_FILE, JSON.stringify(servers, null, 2));
        masterAuth.jwtSecret = crypto.randomBytes(64).toString('hex');
        delete masterAuth.encryptedAbuseIpDbKey;
        fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
        if (sshClient) sshClient.end();
        if (statsInterval) clearInterval(statsInterval); if (dockerInterval) clearInterval(dockerInterval);
        io.disconnectSockets();
    });

    socket.on('save-server', (serverData) => {
        const pin = activePins.get(socket.id);
        if (serverData.passphrase && pin) serverData.encryptedPassphrase = encryptPassphrase(serverData.passphrase, pin);
        delete serverData.passphrase;
        if (serverData.privateKey && pin) {
            if (serverData.privateKey === 'CLEAR_KEY') {
                delete serverData.encryptedPrivateKey;
            } else {
                serverData.encryptedPrivateKey = encryptPassphrase(serverData.privateKey.trim(), pin);
            }
        }
        delete serverData.privateKey;
        if (serverData.privateKeyPath && !isValidKeyPath(serverData.privateKeyPath)) {
            delete serverData.privateKeyPath;
        }
        const servers = getServers();
        if (serverData.id) {
            const index = servers.findIndex(s => s.id === serverData.id);
            if (index !== -1) {
                if (!serverData.encryptedPassphrase && servers[index].encryptedPassphrase) serverData.encryptedPassphrase = servers[index].encryptedPassphrase;
                if (!serverData.encryptedPrivateKey && servers[index].encryptedPrivateKey && serverData.privateKey !== 'CLEAR_KEY') serverData.encryptedPrivateKey = servers[index].encryptedPrivateKey;
                servers[index] = serverData;
            } else servers.push(serverData);
        } else { serverData.id = 'srv_' + Date.now(); servers.push(serverData); }
        fs.writeFileSync(DATA_FILE, JSON.stringify(servers, null, 2));
        io.emit('servers-list', getServers());
    });

    socket.on('delete-server', (serverId) => {
        let servers = getServers().filter(s => s.id !== serverId);
        fs.writeFileSync(DATA_FILE, JSON.stringify(servers, null, 2));
        io.emit('servers-list', getServers());
    });

    socket.on('terminal-input', (data) => { if (activeShellStream) activeShellStream.write(data); });
    socket.on('terminal-resize', ({ cols, rows }) => { if (activeShellStream) activeShellStream.setWindow(rows, cols, 0, 0); });

    socket.on('fetch-server-log', ({ type, path: logPath }) => {
        if (!sshClient || !/^[\/a-zA-Z0-9_.-]+$/.test(logPath)) return socket.emit('log-data', '\r\n\x1b[31mError: Path contains invalid characters and was blocked.\x1b[0m\r\n');
        let cmd = type === 'systemd' 
            ? (logPath === 'syslog' ? 'journalctl -n 500 --no-pager 2>/dev/null || cat /var/log/syslog 2>/dev/null || cat /var/log/messages 2>/dev/null' : `journalctl -u "${logPath}" -n 500 --no-pager 2>/dev/null || journalctl -n 500 --no-pager 2>/dev/null`) 
            : `tail -n 500 "${logPath}" 2>/dev/null || cat "${logPath}" 2>/dev/null`;
        sshClient.exec(cmd, (err, stream) => {
            if (err) return socket.emit('log-data', '\r\n\x1b[31mFailed to read log.\x1b[0m\r\n');
            stream.on('data', d => socket.emit('log-data', d.toString('utf-8')));
            stream.stderr.on('data', d => socket.emit('log-data', d.toString('utf-8')));
        });
    });

    socket.on('scan-log-folder', ({ path: folderPath, buttonId }) => {
        if (!sshClient || !/^[\/a-zA-Z0-9_.-]+$/.test(folderPath)) return;
        sshClient.exec(`find "${folderPath}" -maxdepth 1 -type f ! -name "*.gz" ! -name "*.[0-9]*" -exec basename {} \\; | sort`, (err, stream) => {
            if (err) return; let dataStr = '';
            stream.on('data', chunk => dataStr += chunk.toString('utf-8'));
            stream.on('close', () => socket.emit('log-folder-data', { folderPath, files: dataStr.split('\n').map(f => f.trim()).filter(f => f), buttonId }));
        });
    });

    socket.on('resolve-whois', async ({ ip, cellId }) => {
        if (!net.isIPv4(ip)) return socket.emit('whois-result', { ip, cellId, success: false });
        const pin = activePins.get(socket.id);
        const intel = await resolveIpIntel(ip, pin);
        socket.emit('whois-result', { ip, cellId, success: !!intel, data: intel });
    });

    socket.on('fetch-threat-map-data', () => {
        const history = getBanHistory();
        const countryMap = {};
        history.forEach(item => {
            const cc = (item.countryCode || 'XX').toUpperCase();
            if (!countryMap[cc]) {
                countryMap[cc] = {
                    total: 0,
                    countryName: item.countryName || cc,
                    coords: COUNTRY_COORDS[cc] || null,
                    breakdown: { 'High (Score 5)': 0, 'Moderate (Score 3)': 0, 'Low (Score 1)': 0 }
                };
            }
            countryMap[cc].total++;
            if (item.score >= 5) countryMap[cc].breakdown['High (Score 5)']++;
            else if (item.score >= 3) countryMap[cc].breakdown['Moderate (Score 3)']++;
            else countryMap[cc].breakdown['Low (Score 1)']++;
        });
        socket.emit('threat-map-data', countryMap);
    });

    // --- MULTI-ENGINE FIREWALL DISCOVERY & THREAT SCANNER ---
    socket.on('scan-log-threats', ({ type, path: logPath }) => {
        if (!sshClient || !/^[\/a-zA-Z0-9_.-]+$/.test(logPath)) {
            return socket.emit('log-threats-result', { error: 'Invalid log path or not connected' });
        }
        
        const logSourceCmd = type === 'systemd'
            ? (logPath === 'syslog' ? 'journalctl -n 10000 --no-pager 2>/dev/null || cat /var/log/syslog 2>/dev/null || cat /var/log/messages 2>/dev/null' : `journalctl -u "${logPath}" -n 10000 --no-pager 2>/dev/null || journalctl -n 10000 --no-pager 2>/dev/null`)
            : `cat "${logPath}" 2>/dev/null || tail -n 10000 "${logPath}" 2>/dev/null`;
        
        const pipelineCmd = `
            BANNED_REGEX=$( ( \\
                sudo -n cscli decisions list -o raw 2>/dev/null | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" ; \\
                sudo -n fail2ban-client banned 2>/dev/null | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" ; \\
                sudo -n ufw status 2>/dev/null | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" ; \\
                sudo -n firewall-cmd --list-rich-rules 2>/dev/null | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" ; \\
                sudo -n nft list ruleset 2>/dev/null | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" ; \\
                sudo -n iptables -L -n 2>/dev/null | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" \\
            ) | sort -u | paste -sd '|' - )
            
            { ${logSourceCmd} ; } \
              | grep -aEi "401|403|429|failed|invalid|unauthorized|denied|auth failure|error|found|disconnected|refused|rejected|ban|drop|status code|remote_ip" \
              | grep -aEo "([0-9]{1,3}\\.){3}[0-9]{1,3}" \
              | grep -vE "^(127\\.|10\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.|192\\.168\\.|0\\.0\\.0\\.0|255\\.255\\.255\\.255)" \
              | { if [ -n "$BANNED_REGEX" ]; then grep -vE "^($BANNED_REGEX)$"; else cat; fi; } \
              | sort \
              | uniq -c \
              | sort -nr \
              | head -n 25
        `;

        sshClient.exec(pipelineCmd, (err, stream) => {
            if (err) return socket.emit('log-threats-result', { error: err.message });
            let output = '';
            stream.on('data', d => output += d.toString('utf-8'));
            stream.stderr.on('data', () => {});
            stream.on('close', async () => {
                const lines = output.trim().split('\n');
                const threats = [];
                let resolvedHostIp = '';
                if (sshClient && sshClient._host) {
                    if (net.isIPv4(sshClient._host)) {
                        resolvedHostIp = sshClient._host;
                    } else {
                        try {
                            const dnsRes = await dns.promises.lookup(sshClient._host);
                            resolvedHostIp = dnsRes.address;
                        } catch(e) {}
                    }
                }

                lines.forEach(line => {
                    const match = line.trim().match(/^(\d+)\s+(([0-9]{1,3}\.){3}[0-9]{1,3})$/);
                    if (match && net.isIPv4(match[2])) {
                        const ipStr = match[2];
                        const isHost = !!((resolvedHostIp && ipStr === resolvedHostIp) || (sshClient && sshClient._host && ipStr === sshClient._host));
                        threats.push({ count: parseInt(match[1]), ip: ipStr, isHost });
                    }
                });
                socket.emit('log-threats-result', { logPath, threats });
            });
        });
    });

    // --- MULTI-TIER DEFENSE CASCADE WITH UNIVERSAL FIREWALL ADAPTER ---
    socket.on('block-threat', ({ ip, mode, rowIndex, countryCode, countryName, score, severity }) => {
        if (!sshClient) return socket.emit('block-threat-result', { success: false, ip, rowIndex, message: 'SSH not connected' });
        if (!net.isIPv4(ip)) return socket.emit('block-threat-result', { success: false, ip, rowIndex, message: 'Invalid IPv4 Address' });
        if (!['ip', 'subnet'].includes(mode)) return socket.emit('block-threat-result', { success: false, ip, rowIndex, message: 'Invalid block mode' });
        
        let targetBlock = ip;
        if (mode === 'subnet') {
            const octets = ip.split('.');
            targetBlock = `${octets[0]}.${octets[1]}.${octets[2]}.0/24`;
        }

        const cascadeCmd = `
            TARGET="${targetBlock}"
            MODE="${mode}"

            # 1. Try CrowdSec
            if command -v cscli >/dev/null 2>&1 && sudo -n cscli decisions list >/dev/null 2>&1; then
                if [ "$MODE" = "subnet" ]; then
                    if sudo -n cscli decisions add --range "$TARGET" --reason "BastionCC Threat Block" --duration 720h >/dev/null 2>&1; then
                        echo "SUCCESS:CrowdSec:Banned subnet $TARGET via CrowdSec (720h duration)"
                        exit 0
                    fi
                else
                    if sudo -n cscli decisions add --ip "$TARGET" --reason "BastionCC Threat Block" --duration 720h >/dev/null 2>&1; then
                        echo "SUCCESS:CrowdSec:Banned IP $TARGET via CrowdSec (720h duration)"
                        exit 0
                    fi
                fi
            fi

            # 2. Try Fail2ban
            if command -v fail2ban-client >/dev/null 2>&1 && sudo -n fail2ban-client ping >/dev/null 2>&1; then
                JAILS=$(sudo -n fail2ban-client status 2>/dev/null | grep -i "Jail list:" | sed 's/.*Jail list://g' | tr ',' ' ')
                CHOSEN_JAIL=""
                for j in $JAILS; do
                    if [ "$j" = "recidive" ]; then CHOSEN_JAIL="recidive"; break; fi
                    if [ -z "$CHOSEN_JAIL" ]; then CHOSEN_JAIL="$j"; fi
                done
                if [ -n "$CHOSEN_JAIL" ]; then
                    if sudo -n fail2ban-client set "$CHOSEN_JAIL" banip "$TARGET" >/dev/null 2>&1; then
                        echo "SUCCESS:Fail2ban:Banned $TARGET in jail [$CHOSEN_JAIL] via Fail2ban"
                        exit 0
                    fi
                fi
            fi

            # 3. Universal Multi-Engine Native Firewall Adapter
            if command -v ufw >/dev/null 2>&1 && sudo -n ufw status >/dev/null 2>&1; then
                if sudo -n ufw insert 1 deny from "$TARGET" to any comment "BastionCC Threat Block" >/dev/null 2>&1; then
                    echo "SUCCESS:UFW:Inserted Rule 1 Deny for $TARGET via UFW"
                    exit 0
                fi
            fi

            if command -v firewall-cmd >/dev/null 2>&1 && sudo -n firewall-cmd --state >/dev/null 2>&1; then
                if sudo -n firewall-cmd --add-rich-rule="rule family=ipv4 source address=\"$TARGET\" drop" --permanent >/dev/null 2>&1 && sudo -n firewall-cmd --reload >/dev/null 2>&1; then
                    echo "SUCCESS:Firewalld:Added permanent rich rule drop for $TARGET via Firewalld"
                    exit 0
                fi
            fi

            if command -v nft >/dev/null 2>&1 && sudo -n nft list ruleset >/dev/null 2>&1; then
                sudo -n nft add table inet bastioncc 2>/dev/null
                sudo -n nft 'add chain inet bastioncc input { type filter hook input priority -10; policy accept; }' 2>/dev/null
                if sudo -n nft add rule inet bastioncc input ip saddr "$TARGET" drop >/dev/null 2>&1; then
                    echo "SUCCESS:Nftables:Injected rule to drop $TARGET via Nftables"
                    exit 0
                fi
            fi

            if command -v iptables >/dev/null 2>&1; then
                if sudo -n iptables -I INPUT 1 -s "$TARGET" -j DROP >/dev/null 2>&1; then
                    echo "SUCCESS:Iptables:Inserted INPUT Rule 1 DROP for $TARGET via Iptables"
                    exit 0
                fi
            fi

            echo "FAILED:No supported defense engine succeeded or sudo NOPASSWD required"
            exit 1
        `;

        sshClient.exec(cascadeCmd, (err, stream) => {
            if (err) return socket.emit('block-threat-result', { success: false, ip, targetBlock, rowIndex, message: err.message });
            let out = '';
            stream.on('data', d => out += d.toString('utf-8'));
            stream.stderr.on('data', d => out += d.toString('utf-8'));
            stream.on('close', (code) => {
                const trimmed = out.trim();
                if (trimmed.startsWith('SUCCESS:')) {
                    const parts = trimmed.split(':');
                    const engine = parts[1];
                    const detail = parts.slice(2).join(':');
                    
                    recordBanEntry({
                        ip: targetBlock,
                        mode,
                        countryCode: countryCode || 'XX',
                        countryName: countryName || 'Unknown',
                        score: score || 3,
                        severity: severity || 'Manual Threat Ban',
                        engine
                    });

                    socket.emit('block-threat-result', { 
                        success: true, 
                        ip,
                        targetBlock, 
                        rowIndex,
                        engine, 
                        message: detail 
                    });
                } else {
                    const errorDetail = trimmed.replace(/^FAILED:/, '') || `Command exited with code ${code}`;
                    socket.emit('block-threat-result', { 
                        success: false, 
                        ip,
                        targetBlock, 
                        rowIndex,
                        message: errorDetail 
                    });
                }
            });
        });
    });

    socket.on('security-scan', ({ type, flags, origin, targetServerId, targetUrl }) => {
        socket.emit('security-data', `\r\n\x1b[36m>>> Initiating ${type.toUpperCase()} Audit...\x1b[0m\r\n`);
        
        if (type === 'nmap') {
            const cleanFlags = (flags || '').replace(/[^a-zA-Z0-9\s\-\.,]/g, '');
            const servers = getServers();
            const targetSrv = servers.find(s => s.id === targetServerId);
            if (!targetSrv) { socket.emit('security-data', '\x1b[31mError: Target server not found for scanning.\x1b[0m\r\n'); socket.emit('security-complete'); return; }
            const targetHost = targetSrv.host;

            socket.emit('security-status', `Nmap Network Audit (${targetHost})`);
            const nmapAttribution = `\x1b[90mNmap Security Scanner is (C) 1996–2026 Nmap Software LLC ("The Nmap Project") | https://nmap.org\x1b[0m\r\n\r\n`;
            socket.emit('security-data', nmapAttribution);

            if (origin === 'local') {
                exec(`nmap ${cleanFlags} ${targetHost}`, (error, stdout, stderr) => {
                    if (stdout) socket.emit('security-data', stdout); if (stderr) socket.emit('security-data', stderr);
                    socket.emit('security-complete');
                });
            } else {
                const pivotSrv = servers.find(s => s.id === origin);
                if (!pivotSrv) { socket.emit('security-data', '\x1b[31mError: Pivot origin server not found.\x1b[0m\r\n'); socket.emit('security-complete'); return; }
                
                socket.emit('security-data', `\x1b[36m[Hub-Spoke Pivot] Connecting to ${pivotSrv.name} to scan ${targetSrv.name} (${targetHost})...\x1b[0m\r\n`);
                const tempClient = new Client();
                const pin = activePins.get(socket.id);
                const decryptedPassphrase = pivotSrv.encryptedPassphrase ? decryptPassphrase(pivotSrv.encryptedPassphrase, pin) : '';
                
                let connectOpts = { host: pivotSrv.host, port: parseInt(pivotSrv.port) || 22, username: pivotSrv.username, tryKeyboard: true };
                if (pivotSrv.authMethod === 'password') connectOpts.password = decryptedPassphrase;
                else {
                    const privateKeyStr = resolvePrivateKey(pivotSrv, pin);
                    if (!privateKeyStr) { socket.emit('security-data', '\x1b[31mError: Pivot SSH private key not found or decryption failed.\x1b[0m\r\n'); socket.emit('security-complete'); return; }
                    connectOpts.privateKey = privateKeyStr;
                    if (decryptedPassphrase) connectOpts.passphrase = decryptedPassphrase;
                }

                tempClient.on('ready', () => {
                    socket.emit('security-data', `\x1b[32m[Pivot] Connected. Executing remote Nmap...\x1b[0m\r\n`);
                    const prefix = pivotSrv.username !== 'root' ? 'sudo -n ' : '';
                    const safeCmd = `command -v nmap >/dev/null 2>&1 || { echo -e "\\x1b[31m[Error] Nmap is not installed on ${pivotSrv.name}.\\x1b[0m"; exit 1; } ; ${prefix}nmap ${cleanFlags} ${targetHost}`;
                    tempClient.exec(safeCmd, (err, stream) => {
                        if (err) { socket.emit('security-data', `Error: ${err.message}`); tempClient.end(); socket.emit('security-complete'); return; }
                        stream.on('data', d => socket.emit('security-data', d.toString('utf-8')));
                        stream.stderr.on('data', d => socket.emit('security-data', d.toString('utf-8')));
                        stream.on('close', () => { tempClient.end(); socket.emit('security-complete'); });
                    });
                }).on('keyboard-interactive', (name, instructions, instructionsLang, prompts, finish) => {
                    socket.emit('ssh-keyboard-interactive', { id: pivotSrv.id, name, instructions, prompts });
                    socket.once(`ssh-keyboard-interactive-response-${pivotSrv.id}`, answers => finish(answers));
                }).on('error', err => {
                    socket.emit('security-data', `\x1b[31m[Pivot Connection Error]: ${err.message}\x1b[0m\r\n`); socket.emit('security-complete');
                }).connect(connectOpts);
            }
        } 
        else if (type === 'curl') {
            const cleanUrl = (targetUrl || '').replace(/[^a-zA-Z0-9\.\:\/\-]/g, '');
            socket.emit('security-status', `HTTP Header Matrix (${cleanUrl})`);
            exec(`curl -s -I -L -k https://${cleanUrl}`, (error, stdout, stderr) => {
                let cleanOut = (stdout || '').replace(/\r/g, '');
                let out = `\x1b[36m--- Raw cURL Output ---\x1b[0m\r\n${cleanOut}\r\n`;
                out += `\x1b[36m=== Intelligent Header Matrix ===\x1b[0m\r\nTARGET: https://${cleanUrl}\r\n\r\n`;
                if (cleanOut) {
                    const lines = cleanOut.toLowerCase().split('\n');
                    const foundHeaders = new Set();
                    out += `| \x1b[33mDETECTED HEADER\x1b[0m            | \x1b[33mWHAT IT DOES\x1b[0m                        | \x1b[33mRECOMMENDATION\x1b[0m\r\n`;
                    out += `|----------------------------|-------------------------------------|----------------------------------------------------------\r\n`;
                    lines.forEach(line => {
                        const match = line.match(/^([^:]+):\s*(.*)$/);
                        if (match) {
                            const headerName = match[1].trim();
                            if (HEADER_DICT[headerName]) {
                                foundHeaders.add(headerName);
                                out += `| \x1b[32m${headerName.padEnd(26)}\x1b[0m | ${HEADER_DICT[headerName].desc.padEnd(35)} | ${HEADER_DICT[headerName].rec}\r\n`;
                            }
                        }
                    });
                    out += `\r\n\x1b[31m=== Missing Critical Security Policies ===\x1b[0m\r\n`;
                    let missingCount = 0;
                    Object.keys(HEADER_DICT).forEach(h => {
                        if (!foundHeaders.has(h)) { missingCount++; out += `- \x1b[31m${h}\x1b[0m: ${HEADER_DICT[h].rec}\r\n`; }
                    });
                    if(missingCount === 0) out += `\x1b[32mAll critical security headers are present!\x1b[0m\r\n`;
                }
                if (stderr) out += `\r\n\x1b[31mError:\x1b[0m ${stderr}`;
                socket.emit('security-data', out); socket.emit('security-complete');
            });
        }
        else if (type === 'ssl') {
            const cleanUrl = (targetUrl || '').replace(/[^a-zA-Z0-9\.\:\/\-]/g, '');
            socket.emit('security-status', `SSL/TLS Certificate Expiry (${cleanUrl})`);
            exec(`echo | openssl s_client -servername ${cleanUrl} -connect ${cleanUrl}:443 2>/dev/null | openssl x509 -noout -issuer -subject -dates`, (error, stdout, stderr) => {
                socket.emit('security-data', `\x1b[36m=== SSL/TLS Certificate Data ===\x1b[0m\r\n\r\n${stdout ? stdout : (stderr || "Failed to fetch SSL data.")}`);
                socket.emit('security-complete');
            });
        }
        else if (type === 'firewall-check' && sshClient) {
            socket.emit('security-status', 'Universal Firewall & Docker Inspection');
            const fwProbeCmd = `
                if command -v ufw >/dev/null 2>&1 && sudo -n ufw status >/dev/null 2>&1; then
                    echo "=== DETECTED FIREWALL: UFW ==="
                    cat /etc/ufw/after.rules 2>/dev/null | grep -q "BEGIN UFW AND DOCKER" && echo -e "\x1b[32m[Secure] Found existing UFW-Docker integration blocks in /etc/ufw/after.rules.\x1b[0m\n" || echo -e "\x1b[31m[Warning] No UFW-Docker override rules detected in /etc/ufw/after.rules!\x1b[0m\nDisclaimer: This exposure affects publicly accessible VPS Docker ports.\n🔗 Guide: https://github.com/chaifeng/ufw-docker\n"
                    sudo -n ufw status verbose < /dev/null
                elif command -v firewall-cmd >/dev/null 2>&1 && sudo -n firewall-cmd --state >/dev/null 2>&1; then
                    echo "=== DETECTED FIREWALL: Firewalld ==="
                    sudo -n firewall-cmd --list-all < /dev/null
                elif command -v nft >/dev/null 2>&1 && sudo -n nft list ruleset >/dev/null 2>&1; then
                    echo "=== DETECTED FIREWALL: Nftables ==="
                    sudo -n nft list ruleset < /dev/null
                elif command -v iptables >/dev/null 2>&1; then
                    echo "=== DETECTED FIREWALL: Native Iptables ==="
                    sudo -n iptables -L -n -v --line-numbers < /dev/null
                else
                    echo -e "\x1b[31mNo active firewall subsystem found or sudo NOPASSWD required.\x1b[0m"
                fi
            `;
            sshClient.exec(fwProbeCmd, handleSecurityStream);
        }
        else if (type === 'fail2ban' && sshClient) {
            socket.emit('security-status', 'Fail2ban Jails & Active Bans');
            sshClient.exec(`sudo -n fail2ban-client status || fail2ban-client status ; echo -e "\\n\x1b[36m--- Active Banned IPs ---\x1b[0m" ; sudo -n fail2ban-client banned || fail2ban-client banned || echo -e "\x1b[31mFail2ban not found or requires password sudo.\x1b[0m"`, handleSecurityStream);
        }
        else if (type === 'crowdsec' && sshClient) {
            socket.emit('security-status', 'CrowdSec Metrics & Decision Drops');
            sshClient.exec(`sudo -n cscli metrics || cscli metrics ; echo -e "\\n\x1b[36m--- Active Decision List ---\x1b[0m" ; sudo -n cscli decision list || cscli decision list || echo -e "\x1b[31mCrowdSec (cscli) not found or requires password sudo.\x1b[0m"`, handleSecurityStream);
        }
        
        function handleSecurityStream(err, stream) {
            if (err) return socket.emit('security-data', `\x1b[31mError: ${err.message}\x1b[0m\r\n`);
            stream.on('data', d => socket.emit('security-data', d.toString('utf-8')));
            stream.stderr.on('data', d => socket.emit('security-data', d.toString('utf-8')));
            stream.on('close', () => socket.emit('security-complete'));
        }
    });

    // --- HARDENED DEEP BATCH SCAN WITH TIMEOUT PROTECTIONS & BANNED IPS TELEMETRY ---
    socket.on('run-deep-scan', async ({ domains, nmapOrigin, targetServerId }) => {
        socket.emit('security-data', `\x1b[36m>>> Initiating Full Deep Security Batch Scan...\x1b[0m\r\n`);
        
        let logoBase64 = '';
        try { const logoPath = path.join(__dirname, '../public/bastioncc.png'); if (fs.existsSync(logoPath)) logoBase64 = `data:image/png;base64,` + fs.readFileSync(logoPath, 'base64'); } catch(e) {}

        const targetSrv = getServers().find(s => s.id === targetServerId);
        const targetServerName = targetSrv ? targetSrv.name : 'Unknown Server';
        const targetHost = targetSrv ? targetSrv.host : '127.0.0.1';

        let htmlReport = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>BastionCC Security Deep Audit</title>
        <style>body { background: #0f172a; color: #f8fafc; font-family: monospace; padding: 30px; line-height: 1.5; } .header-container { text-align: center; border-bottom: 2px solid #334155; padding-bottom: 20px; margin-bottom: 30px; } .logo { max-width: 220px; height: auto; margin-bottom: 15px; } h1 { color: #f97316; margin: 0 0 5px 0; } .server-subtitle { color: #94a3b8; font-size: 15px; margin-bottom: 10px; } .timestamp { color: #64748b; font-size: 12px; } .attribution { color: #64748b; font-size: 11px; margin-top: 6px; font-style: italic; } h2 { color: #38bdf8; margin-top: 30px; border-bottom: 1px solid #334155; padding-bottom: 5px;} h3 { color: #f8fafc; } .section { background: #1e293b; padding: 20px; border-radius: 8px; border: 1px solid #334155; margin-bottom: 20px; overflow-x: auto; } pre { white-space: pre-wrap; word-wrap: break-word; font-size: 13px; } .success { color: #22c55e; } .warning { color: #eab308; } .danger { color: #ef4444; } table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; } th, td { text-align: left; padding: 8px; border-bottom: 1px solid #334155; } th { color: #f97316; }</style></head><body>
        <div class="header-container">${logoBase64 ? `<img src="${logoBase64}" class="logo" alt="BastionCC Logo">` : ''}<h1>BastionCC Deep Audit Report</h1><div class="server-subtitle">Target Server: ${escapeHtmlForReport(targetServerName)} (${escapeHtmlForReport(targetHost)})</div><div class="timestamp">Generated: ${new Date().toLocaleString()}</div></div>`;

        const execPromise = (command) => new Promise(res => exec(command, (err, out, serr) => res(out || serr || (err ? err.message : ''))));
        const sshPromiseWithTimeout = (command, timeoutMs = 4000) => new Promise(res => {
            if (!sshClient) return res('No active remote connection.');
            let hasCompleted = false;
            const timer = setTimeout(() => {
                if (!hasCompleted) {
                    hasCompleted = true;
                    res('Probe timed out or requires interactive terminal input.');
                }
            }, timeoutMs);

            sshClient.exec(command, (err, stream) => {
                if (err) {
                    if (!hasCompleted) { hasCompleted = true; clearTimeout(timer); res(`SSH Error: ${err.message}`); }
                    return;
                }
                let out = '';
                stream.on('data', d => out += d.toString());
                stream.stderr.on('data', d => out += d.toString());
                stream.on('close', () => {
                    if (!hasCompleted) { hasCompleted = true; clearTimeout(timer); res(out); }
                });
            });
        });

        socket.emit('security-status', `1/4 Full Deep Nmap (-A) Scan on ${targetHost}`);
        socket.emit('security-data', `[1/4] Running Full Deep Nmap (-A) Scan on ${targetHost}...\r\n`);
        let nmapOut = '';
        if (nmapOrigin === 'local') {
            nmapOut = await execPromise(`nmap -A ${targetHost}`);
        } else {
            const pivotSrv = getServers().find(s => s.id === nmapOrigin);
            if (!pivotSrv) nmapOut = "Error: Pivot origin server not found.";
            else {
                nmapOut = await new Promise(res => {
                    const tempClient = new Client();
                    const pin = activePins.get(socket.id);
                    const decryptedPassphrase = pivotSrv.encryptedPassphrase ? decryptPassphrase(pivotSrv.encryptedPassphrase, pin) : '';
                    let connectOpts = { host: pivotSrv.host, port: parseInt(pivotSrv.port) || 22, username: pivotSrv.username, tryKeyboard: true };
                    if (pivotSrv.authMethod === 'password') connectOpts.password = decryptedPassphrase;
                    else {
                        const privateKeyStr = resolvePrivateKey(pivotSrv, pin);
                        if (!privateKeyStr) return res("Pivot Error: SSH private key not found or decryption failed.");
                        connectOpts.privateKey = privateKeyStr;
                        if (decryptedPassphrase) connectOpts.passphrase = decryptedPassphrase;
                    }

                    tempClient.on('ready', () => {
                        const prefix = pivotSrv.username !== 'root' ? 'sudo -n ' : '';
                        const safeCmd = `command -v nmap >/dev/null 2>&1 || { echo "Nmap not installed on ${pivotSrv.name}."; exit 1; } ; ${prefix}nmap -A ${targetHost}`;
                        tempClient.exec(safeCmd, (err, stream) => {
                            if (err) return res(`Error: ${err.message}`);
                            let out = ''; stream.on('data', d => out += d.toString()); stream.stderr.on('data', d => out += d.toString());
                            stream.on('close', () => { tempClient.end(); res(out); });
                        });
                    }).on('keyboard-interactive', (name, instructions, instructionsLang, prompts, finish) => {
                        socket.emit('ssh-keyboard-interactive', { id: pivotSrv.id, name, instructions, prompts });
                        socket.once(`ssh-keyboard-interactive-response-${pivotSrv.id}`, answers => finish(answers));
                    }).on('error', err => res(`Pivot Error: ${err.message}`)).connect(connectOpts);
                });
            }
        }
        htmlReport += `<h2>1. Network Profile (Full Deep Nmap -A via ${nmapOrigin === 'local' ? 'Local' : 'Pivot Node'})</h2><div class="section"><pre>${escapeHtmlForReport(nmapOut)}</pre><div class="attribution">Nmap Security Scanner is (C) 1996–2026 Nmap Software LLC ("The Nmap Project") | https://nmap.org</div></div>`;

        if (sshClient) {
            socket.emit('security-status', '2/4 Universal Firewall Rules');
            socket.emit('security-data', `[2/4] Inspecting Host Firewall Subsystem...\r\n`);
            const fwScanCmd = `
                if command -v ufw >/dev/null 2>&1 && sudo -n ufw status >/dev/null 2>&1; then
                    echo "[Engine: UFW]"; sudo -n ufw status verbose < /dev/null
                elif command -v firewall-cmd >/dev/null 2>&1 && sudo -n firewall-cmd --state >/dev/null 2>&1; then
                    echo "[Engine: Firewalld]"; sudo -n firewall-cmd --list-all < /dev/null
                elif command -v nft >/dev/null 2>&1 && sudo -n nft list ruleset >/dev/null 2>&1; then
                    echo "[Engine: Nftables]"; sudo -n nft list ruleset < /dev/null
                elif command -v iptables >/dev/null 2>&1; then
                    echo "[Engine: Iptables]"; sudo -n iptables -L -n -v < /dev/null
                else
                    echo "No active firewall found or sudo NOPASSWD required."
                fi
            `;
            const fwResult = await sshPromiseWithTimeout(fwScanCmd, 4000);
            htmlReport += `<h2>2. Active Firewall Profile & Rules</h2><div class="section"><pre>${escapeHtmlForReport(fwResult)}</pre></div>`;
            
            socket.emit('security-status', '3/4 Intrusion Prevention & Ban Lists');
            socket.emit('security-data', `[3/4] Running Intrusion Detection & Ban Lists...\r\n`);
            const f2bOut = await sshPromiseWithTimeout(`sudo -n fail2ban-client status < /dev/null || fail2ban-client status < /dev/null ; echo "\n--- Active Banned IPs ---" ; sudo -n fail2ban-client banned < /dev/null || fail2ban-client banned < /dev/null || echo "Fail2ban not found."`, 4000);
            const crowdsecOut = await sshPromiseWithTimeout(`sudo -n cscli metrics < /dev/null || cscli metrics < /dev/null ; echo "\n--- Active Decision List ---" ; sudo -n cscli decision list < /dev/null || cscli decision list < /dev/null || echo "CrowdSec not found."`, 4000);
            htmlReport += `<h2>3. Intrusion Prevention Status</h2><div class="section"><h3>Fail2ban & Active Bans</h3>
            <pre>${escapeHtmlForReport(f2bOut)}</pre><h3>CrowdSec & Decision List</h3><pre>${escapeHtmlForReport(crowdsecOut)}</pre></div>`;
        }

        // SECTION 4: HISTORICAL BANNED IPS & ORIGIN TELEMETRY
        const bansHistory = getBanHistory();
        let bansHtml = `<table><tr><th>Target / Subnet</th><th>Origin Registry</th><th>Defense Engine</th><th>Severity / Threat Level</th><th>Timestamp</th></tr>`;
        if (bansHistory.length === 0) {
            bansHtml += `<tr><td colspan="5" class="warning" style="text-align:center; padding:12px;">No historical manual bans recorded in ledger.</td></tr>`;
        } else {
            bansHistory.forEach(b => {
                const dateStr = b.timestamp ? new Date(b.timestamp).toLocaleString() : 'N/A';
                bansHtml += `<tr>
                    <td class="danger font-bold">${escapeHtmlForReport(b.ip)}</td>
                    <td>${escapeHtmlForReport(b.countryName || 'Unknown')} (${escapeHtmlForReport(b.countryCode || 'XX')})</td>
                    <td>${escapeHtmlForReport(b.engine || 'Firewall')}</td>
                    <td>Score ${b.score || 3}/5 - ${escapeHtmlForReport(b.severity || 'Threat Block')}</td>
                    <td style="color:#94a3b8;">${escapeHtmlForReport(dateStr)}</td>
                </tr>`;
            });
        }
        bansHtml += `</table>`;
        htmlReport += `<h2>4. Historical Banned IPs & Origin Telemetry</h2><div class="section">${bansHtml}</div>`;

        if (domains && domains.length > 0) {
            socket.emit('security-status', 'Web & SSL Domain Audits');
            socket.emit('security-data', `Auditing Target Domains...\r\n`);
            htmlReport += `<h2>5. Web & SSL Domain Audits</h2>`;
            for (const d of domains) {
                if (!d.trim()) continue;
                const cleanUrl = d.replace(/[^a-zA-Z0-9\.\:\/\-]/g, '');
                const curlOutRaw = (await execPromise(`curl -s -I -L -k https://${cleanUrl}`)).replace(/\r/g, '');
                const sslOut = await execPromise(`echo | openssl s_client -servername ${cleanUrl} -connect ${cleanUrl}:443 2>/dev/null | openssl x509 -noout -issuer -subject -dates`);
                
                const lines = curlOutRaw.toLowerCase().split('\n');
                const foundHeaders = new Set();
                let matrixHtml = `<table><tr><th>Detected Header</th><th>What It Does</th><th>Recommendation</th></tr>`;
                lines.forEach(line => {
                    const match = line.match(/^([^:]+):\s*(.*)$/);
                    if (match && HEADER_DICT[match[1].trim()]) {
                        const h = match[1].trim(); foundHeaders.add(h);
                        matrixHtml += `<tr><td class="success">${h}</td><td>${HEADER_DICT[h].desc}</td><td>${HEADER_DICT[h].rec}</td></tr>`;
                    }
                }); matrixHtml += `</table>`;
                
                let missingHtml = `<ul>`;
                Object.keys(HEADER_DICT).forEach(h => { if (!foundHeaders.has(h)) missingHtml += `<li class="danger"><strong>${h}</strong>: ${HEADER_DICT[h].rec}</li>`; });
                missingHtml += `</ul>`;

                htmlReport += `<div class="section"><h3>Target: https://${escapeHtmlForReport(cleanUrl)}</h3><h4>SSL Certificate Data</h4><pre>${escapeHtmlForReport(sslOut)}</pre><h4>Raw cURL Headers</h4><pre>${escapeHtmlForReport(curlOutRaw)}</pre><h4>Security Policy Matrix</h4>${matrixHtml}<h4>Missing Critical Policies</h4>${missingHtml}</div>`;
            }
        }
        htmlReport += `
    

</body></html>`;
        socket.emit('security-data', `\x1b[32m✔ Deep Scan Complete! Preparing HTML Report...\x1b[0m\r\n`);
        socket.emit('deep-scan-complete', htmlReport);
    });

    socket.on('docker-action', ({ action, container }) => {
        if (!sshClient || !/^[a-zA-Z0-9_.-]+$/.test(container)) return;
        let cmd = action === 'start' ? `docker start ${container}` : action === 'stop' ? `docker stop ${container}` : action === 'restart' ? `docker restart ${container}` : action === 'remove' ? `docker rm -f ${container}` : '';
        if (cmd) sshClient.exec(cmd, (err, stream) => { if (stream) stream.on('data', d => socket.emit('terminal-data', `\r\n[Docker] ${d.toString()}`)); });
    });

    socket.on('docker-logs', ({ container }) => {
        if (!sshClient || !/^[a-zA-Z0-9_.-]+$/.test(container)) return;
        sshClient.exec(`docker logs --tail 200 ${container}`, (err, stream) => {
            if (err) return; stream.on('data', d => socket.emit('modal-data', d.toString('utf-8'))); stream.stderr.on('data', d => socket.emit('modal-data', d.toString('utf-8')));
        });
    });

    socket.on('docker-scan', ({ image }) => {
        if (!sshClient || !/^[a-zA-Z0-9_:./-]+$/.test(image)) return;
        socket.emit('modal-data', `\x1b[36mInitiating Grype scan for ${image}...\x1b[0m\n`);
        sshClient.exec(`grype -v ${image}`, (err, stream) => {
            if (err) return socket.emit('modal-data', '\x1b[31mError running grype. Is it installed in /usr/local/bin?\x1b[0m\n');
            stream.on('data', d => socket.emit('modal-data', d.toString('utf-8'))); stream.stderr.on('data', d => socket.emit('modal-data', d.toString('utf-8')));
        });
    });

    socket.on('connect-ssh', (config) => {
        if (sshClient) sshClient.end(); 
        if (statsInterval) clearInterval(statsInterval); if (dockerInterval) clearInterval(dockerInterval);
        activeShellStream = null; sshClient = new Client();
        prevCpuTicks = null;
        
        try {
            const pin = activePins.get(socket.id);
            const decryptedPassphrase = config.encryptedPassphrase ? decryptPassphrase(config.encryptedPassphrase, pin) : '';
            
            let connectOpts = { host: config.host, port: parseInt(config.port) || 22, username: config.username, tryKeyboard: true };
            if (config.authMethod === 'password') connectOpts.password = decryptedPassphrase;
            else {
                const privateKeyStr = resolvePrivateKey(config, pin);
                if (!privateKeyStr) return socket.emit('terminal-data', '\r\n\x1b[31mConfig Error: SSH private key not found or decryption failed.\x1b[0m\r\n');
                connectOpts.privateKey = privateKeyStr;
                if (decryptedPassphrase) connectOpts.passphrase = decryptedPassphrase;
            }

            sshClient.on('ready', () => {
                socket.emit('ssh-status', { id: config.id, status: 'Connected' }); sshClient._host = config.host; 
                sshClient.shell({ term: 'xterm-256color', cols: config.cols || 80, rows: config.rows || 24 }, (err, stream) => {
                    if (err) return socket.emit('terminal-data', '\r\nShell error.\r\n');
                    activeShellStream = stream; stream.on('data', d => socket.emit('terminal-data', d.toString('utf-8'))); stream.on('close', () => activeShellStream = null);
                });

                // Server-side instantaneous poll - raw /proc/stat read & free -m
                const statsCmd = `head -n 1 /proc/stat 2>/dev/null; echo "---MEM---"; free -m 2>/dev/null`;

                statsInterval = setInterval(() => {
                    sshClient.exec(statsCmd, (err, stream) => {
                        if (err) return;
                        let raw = '';
                        stream.on('data', chunk => raw += chunk.toString());
                        stream.on('close', () => {
                            try {
                                const parts = raw.trim().split('---MEM---');
                                const cpuLine = (parts[0] || '').trim();
                                const memOutput = (parts[1] || '').trim();
                                let cpuLoadStr = '--%';

                                if (cpuLine.startsWith('cpu')) {
                                    const tokens = cpuLine.replace(/^cpu\s+/, '').trim().split(/\s+/).map(Number);
                                    if (tokens.length >= 4) {
                                        const idle = (tokens[3] || 0) + (tokens[4] || 0); // idle + iowait
                                        const total = tokens.reduce((acc, v) => acc + (isNaN(v) ? 0 : v), 0);

                                        if (prevCpuTicks) {
                                            const deltaIdle = idle - prevCpuTicks.idle;
                                            const deltaTotal = total - prevCpuTicks.total;
                                            if (deltaTotal > 0) {
                                                const pct = Math.max(0, Math.min(100, ((deltaTotal - deltaIdle) / deltaTotal) * 100));
                                                cpuLoadStr = pct.toFixed(1) + '%';
                                            }
                                        }
                                        prevCpuTicks = { idle, total };
                                    }
                                }

                                let ramStatsStr = '';
                                const memMatch = memOutput.match(/Mem:\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+\d+\s+\d+\s+(\d+))?/);
                                if (memMatch) {
                                    const totalMB = parseInt(memMatch[1]) || 0;
                                    const usedMB = parseInt(memMatch[2]) || 0;
                                    const freeMB = parseInt(memMatch[3]) || 0;
                                    const cacheMB = parseInt(memMatch[4]) || 0;
                                    ramStatsStr = `used=${usedMB}&total=${totalMB}&free=${freeMB}&cache=${cacheMB}`;
                                }

                                socket.emit('server-stats', { cpu: cpuLoadStr, ram: ramStatsStr });
                            } catch(e) {}
                        });
                    });
                }, 5000);

                if (config.dockerEnabled !== false) {
                    dockerInterval = setInterval(() => {
                        sshClient.exec(`echo "{\\"ps\\": [$(docker ps -a --format '{{json .}}' | paste -sd, - || echo "")], \\"stats\\": [$(docker stats --no-stream --format '{{json .}}' | paste -sd, - || echo "")]}"`, (err, stream) => {
                            if (err) return; let dData = ''; stream.on('data', chunk => dData += chunk.toString());
                            stream.on('close', () => { try { socket.emit('docker-data', JSON.parse(dData)); } catch(e){} });
                        });
                    }, 5000);
                }

                sshClient.sftp((err, sftp) => {
                    if (err) return; sftpSession = sftp;
                    ['sftp-list', 'sftp-download', 'sftp-upload-start', 'sftp-upload-chunk', 'sftp-upload-end'].forEach(evt => socket.removeAllListeners(evt));
                    socket.on('sftp-list', (targetPath) => {
                        sftp.readdir(targetPath, (err, list) => {
                            if (err) return;
                            const cleanList = list.filter(i => i.filename !== '.' && i.filename !== '..').map(i => ({ name: i.filename, isDir: i.attrs.isDirectory(), size: i.attrs.size })).sort((a, b) => a.isDir === b.isDir ? a.name.localeCompare(b.name) : (a.isDir ? -1 : 1));
                            socket.emit('sftp-list-data', { path: targetPath, items: cleanList });
                        });
                    });
                    socket.on('sftp-download', (filePath) => {
                        const readStream = sftp.createReadStream(filePath);
                        readStream.on('data', chunk => socket.emit('sftp-download-chunk', { filePath, chunk }));
                        readStream.on('end', () => socket.emit('sftp-download-complete', filePath));
                    });
                    socket.on('sftp-upload-start', ({ remotePath }) => {
                        const writeStream = sftp.createWriteStream(remotePath); activeUploads.set(remotePath, writeStream);
                        writeStream.on('close', () => { socket.emit('sftp-upload-complete', remotePath); activeUploads.delete(remotePath); });
                    });
                    socket.on('sftp-upload-chunk', ({ remotePath, chunk }) => { if (activeUploads.has(remotePath)) activeUploads.get(remotePath).write(Buffer.from(chunk)); });
                    socket.on('sftp-upload-end', ({ remotePath }) => { if (activeUploads.has(remotePath)) activeUploads.get(remotePath).end(); });
                });
            }).on('keyboard-interactive', (name, instructions, instructionsLang, prompts, finish) => {
                socket.emit('ssh-keyboard-interactive', { id: config.id, name, instructions, prompts });
                socket.once(`ssh-keyboard-interactive-response-${config.id}`, answers => finish(answers));
            }).on('error', (err) => socket.emit('terminal-data', '\r\n\x1b[31mConnection Error: ' + err.message + '\x1b[0m\r\n'))
              .on('end', () => { clearInterval(statsInterval); clearInterval(dockerInterval); })
              .on('close', () => { clearInterval(statsInterval); clearInterval(dockerInterval); })
              .connect(connectOpts);
        } catch (e) { socket.emit('terminal-data', '\r\n\x1b[31mConfig Error: ' + e.message + '\x1b[0m\r\n'); }
    });

    socket.on('disconnect', () => {
        if (statsInterval) clearInterval(statsInterval); if (dockerInterval) clearInterval(dockerInterval);
        if (sshClient) sshClient.end(); activeUploads.clear(); activePins.delete(socket.id);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => console.log(`BastionCC v1.9 Ready on port ${PORT}`));
