const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const rateLimit = require('express-rate-limit');
const { exec } = require('child_process');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { maxHttpBufferSize: 1e8 }); 

app.use(express.static(path.join(__dirname, '../public')));
app.use('/node_modules/xterm', express.static(path.join(__dirname, '../node_modules/xterm')));
app.use('/node_modules/xterm-addon-fit', express.static(path.join(__dirname, '../node_modules/xterm-addon-fit')));
app.use(express.json());

const CONFIG_DIR = path.join(__dirname, '../data');
const AUTH_FILE = path.join(CONFIG_DIR, 'auth.json');
const DATA_FILE = path.join(CONFIG_DIR, 'servers.json');

if (!fs.existsSync(CONFIG_DIR)) fs.mkdirSync(CONFIG_DIR, { recursive: true });

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
    servers = servers.map(s => { if (s.encryptedPassphrase) s.tempPlaintext = decryptPassphrase(s.encryptedPassphrase, currentPin); return s; });
    
    const newSalt = crypto.randomBytes(16).toString('hex');
    const newHash = crypto.scryptSync(newPin, newSalt, 64).toString('hex');
    const newMasterKeySalt = crypto.randomBytes(32).toString('hex');
    const newJwtSecret = crypto.randomBytes(64).toString('hex'); 
    
    masterAuth = { salt: newSalt, hash: newHash, masterKeySalt: newMasterKeySalt, jwtSecret: newJwtSecret };
    fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
    
    servers = servers.map(s => { if (s.tempPlaintext) { s.encryptedPassphrase = encryptPassphrase(s.tempPlaintext, newPin); delete s.tempPlaintext; } return s; });
    fs.writeFileSync(DATA_FILE, JSON.stringify(servers, null, 2));
    io.disconnectSockets();
    res.json({success: true});
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

if (!fs.existsSync(DATA_FILE)) fs.writeFileSync(DATA_FILE, JSON.stringify([]));

function getServers() {
    try { const content = fs.readFileSync(DATA_FILE, 'utf8'); return content.trim() ? JSON.parse(content) : []; } 
    catch (err) { return []; }
}

const HEADER_DICT = {
    'strict-transport-security': { desc: 'Forces HTTPS connections.', rec: 'Ensure max-age is high and includes preload.' },
    'content-security-policy': { desc: 'Mitigates XSS & data injection.', rec: 'Implement a strict CSP restricting unsafe-inline scripts.' },
    'x-frame-options': { desc: 'Protects against clickjacking.', rec: 'Set to SAMEORIGIN or DENY.' },
    'x-content-type-options': { desc: 'Prevents MIME-sniffing.', rec: 'Set to nosniff.' },
    'referrer-policy': { desc: 'Controls referrer leaks.', rec: 'Set to strict-origin-when-cross-origin.' },
    'permissions-policy': { desc: 'Restricts browser features.', rec: 'Disable unused features (e.g., camera, microphone).' }
};

function escapeHtmlForReport(str) { return String(str).replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m])); }

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

    socket.emit('servers-list', getServers());
    
    socket.on('emergency-lock', () => {
        const servers = getServers(); servers.forEach(s => delete s.encryptedPassphrase);
        fs.writeFileSync(DATA_FILE, JSON.stringify(servers, null, 2));
        masterAuth.jwtSecret = crypto.randomBytes(64).toString('hex');
        fs.writeFileSync(AUTH_FILE, JSON.stringify(masterAuth, null, 2));
        if (sshClient) sshClient.end();
        if (statsInterval) clearInterval(statsInterval); if (dockerInterval) clearInterval(dockerInterval);
        io.disconnectSockets();
    });

    socket.on('save-server', (serverData) => {
        const pin = activePins.get(socket.id);
        if (serverData.passphrase && pin) serverData.encryptedPassphrase = encryptPassphrase(serverData.passphrase, pin);
        delete serverData.passphrase;
        const servers = getServers();
        if (serverData.id) {
            const index = servers.findIndex(s => s.id === serverData.id);
            if (index !== -1) { if (!serverData.encryptedPassphrase && servers[index].encryptedPassphrase) serverData.encryptedPassphrase = servers[index].encryptedPassphrase; servers[index] = serverData; }
            else servers.push(serverData);
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
        let cmd = type === 'systemd' ? `journalctl -u ${logPath} -n 500 --no-pager` : `tail -n 500 "${logPath}" || cat "${logPath}"`;
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

    socket.on('install-rootkit', () => {
        socket.emit('security-status', 'Auto-Installing Rootkit Scanners');
        socket.emit('security-data', `\r\n\x1b[36m>>> Auto-Installing rkhunter and chkrootkit...\x1b[0m\r\n`);
        const installCmd = `sudo -n apt-get update && sudo -n apt-get install -y rkhunter chkrootkit`;
        if (sshClient) {
            sshClient.exec(installCmd, (err, stream) => {
                if(err) { socket.emit('security-data', `\x1b[31mError: ${err.message}\x1b[0m\r\n`); socket.emit('security-complete'); return; }
                stream.on('data', d => socket.emit('security-data', d.toString('utf-8')));
                stream.stderr.on('data', d => socket.emit('security-data', d.toString('utf-8')));
                stream.on('close', (code) => {
                    if (code !== 0) {
                        socket.emit('security-data', `\x1b[31mInstallation failed (Code ${code}). Sudo password may be required.\x1b[0m\r\n`);
                        socket.emit('security-complete');
                    } else {
                        socket.emit('security-data', `\x1b[32mInstallation complete. Launching scan...\x1b[0m\r\n`);
                        socket.emit('security-status', 'Rootkit Inspection');
                        sshClient.exec(`sudo -n rkhunter --check --skip-keypress || sudo -n chkrootkit`, handleSecurityStream);
                    }
                });
            });
        } else {
            exec(installCmd, (err, stdout, stderr) => {
                if (stdout) socket.emit('security-data', stdout);
                if (stderr) socket.emit('security-data', stderr);
                if (err) {
                    socket.emit('security-data', `\x1b[31mInstallation failed. Sudo password may be required.\x1b[0m\r\n`);
                    socket.emit('security-complete');
                } else {
                    socket.emit('security-data', `\x1b[32mInstallation complete. Launching scan...\x1b[0m\r\n`);
                    socket.emit('security-status', 'Rootkit Inspection');
                    exec(`sudo -n rkhunter --check --skip-keypress || sudo -n chkrootkit`, (e, out, serr) => {
                        if(out) socket.emit('security-data', out);
                        if(serr) socket.emit('security-data', serr);
                        socket.emit('security-complete');
                    });
                }
            });
        }
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
                else { connectOpts.privateKey = fs.readFileSync(path.resolve(pivotSrv.privateKeyPath || '/root/.ssh/id_ed25519'), 'utf8'); if (decryptedPassphrase) connectOpts.passphrase = decryptedPassphrase; }

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
        else if (type === 'ufw-check' && sshClient) {
            socket.emit('security-status', 'Firewall & Docker Exposure Audit');
            sshClient.exec(`cat /etc/ufw/after.rules | grep -q "BEGIN UFW AND DOCKER" && echo -e "\x1b[32m[Secure] Found existing UFW-Docker integration blocks in /etc/ufw/after.rules.\x1b[0m\n" || echo -e "\x1b[31m[Warning] No UFW-Docker override rules detected in /etc/ufw/after.rules!\x1b[0m\nDisclaimer: This exposure affects publicly accessible VPS Docker ports.\n🔗 Guide: https://github.com/chaifeng/ufw-docker\n" ; echo -e "\x1b[36m>>> Auto-proceeding to UFW Status:\x1b[0m\n" ; sudo ufw status verbose || ufw status verbose`, handleSecurityStream);
        }
        else if (type === 'ufw-status' && sshClient) {
            socket.emit('security-status', 'Firewall Routing Status');
            sshClient.exec(`sudo ufw status verbose || ufw status verbose`, handleSecurityStream);
        }
        else if (type === 'fail2ban' && sshClient) {
            socket.emit('security-status', 'Fail2ban Jails & Active Bans');
            sshClient.exec(`sudo -n fail2ban-client status || fail2ban-client status ; echo -e "\\n\x1b[36m--- Active Banned IPs ---\x1b[0m" ; sudo -n fail2ban-client banned || fail2ban-client banned || echo -e "\x1b[31mFail2ban not found or requires password sudo.\x1b[0m"`, handleSecurityStream);
        }
        else if (type === 'crowdsec' && sshClient) {
            socket.emit('security-status', 'CrowdSec Metrics & Decision Drops');
            sshClient.exec(`sudo -n cscli metrics || cscli metrics ; echo -e "\\n\x1b[36m--- Active Decision List ---\x1b[0m" ; sudo -n cscli decision list || cscli decision list || echo -e "\x1b[31mCrowdSec (cscli) not found or requires password sudo.\x1b[0m"`, handleSecurityStream);
        }
        else if (type === 'rkhunter') {
            socket.emit('security-status', 'Rootkit & Kernel Integrity Scan');
            const checkCmd = `command -v rkhunter >/dev/null 2>&1 || command -v chkrootkit >/dev/null 2>&1`;
            const runCmd = `sudo -n rkhunter --check --skip-keypress || sudo -n chkrootkit`;
            if (sshClient) {
                sshClient.exec(checkCmd, (err, stream) => {
                    stream.on('close', (code) => {
                        if (code !== 0) {
                            socket.emit('rootkit-missing');
                            socket.emit('security-complete');
                        } else {
                            sshClient.exec(runCmd, handleSecurityStream);
                        }
                    });
                });
            } else {
                exec(checkCmd, (err) => {
                    if (err) {
                        socket.emit('rootkit-missing');
                        socket.emit('security-complete');
                    } else {
                        exec(runCmd, (e, out, serr) => {
                            if(out) socket.emit('security-data', out);
                            if(serr) socket.emit('security-data', serr);
                            socket.emit('security-complete');
                        });
                    }
                });
            }
        }
        
        function handleSecurityStream(err, stream) {
            if (err) return socket.emit('security-data', `\x1b[31mError: ${err.message}\x1b[0m\r\n`);
            stream.on('data', d => socket.emit('security-data', d.toString('utf-8')));
            stream.stderr.on('data', d => socket.emit('security-data', d.toString('utf-8')));
            stream.on('close', () => socket.emit('security-complete'));
        }
    });

    socket.on('run-deep-scan', async ({ domains, nmapOrigin, targetServerId }) => {
        socket.emit('security-data', `\x1b[36m>>> Initiating Full Deep Security Batch Scan...\x1b[0m\r\n`);
        
        let logoBase64 = '';
        try { const logoPath = path.join(__dirname, '../public/bastioncc.png'); if (fs.existsSync(logoPath)) logoBase64 = `data:image/png;base64,` + fs.readFileSync(logoPath, 'base64'); } catch(e) {}

        const targetSrv = getServers().find(s => s.id === targetServerId);
        const targetServerName = targetSrv ? targetSrv.name : 'Unknown Server';
        const targetHost = targetSrv ? targetSrv.host : '127.0.0.1';

        let htmlReport = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>BastionCC Security Deep Audit</title>
        <style>body { background: #0f172a; color: #f8fafc; font-family: monospace; padding: 30px; line-height: 1.5; } .header-container { text-align: center; border-bottom: 2px solid #334155; padding-bottom: 20px; margin-bottom: 30px; } .logo { max-width: 220px; height: auto; margin-bottom: 15px; } h1 { color: #f97316; margin: 0 0 5px 0; } .server-subtitle { color: #94a3b8; font-size: 15px; margin-bottom: 10px; } .timestamp { color: #64748b; font-size: 12px; } h2 { color: #38bdf8; margin-top: 30px; border-bottom: 1px solid #334155; padding-bottom: 5px;} h3 { color: #f8fafc; } .section { background: #1e293b; padding: 20px; border-radius: 8px; border: 1px solid #334155; margin-bottom: 20px; overflow-x: auto; } pre { white-space: pre-wrap; word-wrap: break-word; font-size: 13px; } .success { color: #22c55e; } .warning { color: #eab308; } .danger { color: #ef4444; } table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; } th, td { text-align: left; padding: 8px; border-bottom: 1px solid #334155; } th { color: #f97316; }</style></head><body>
        <div class="header-container">${logoBase64 ? `<img src="${logoBase64}" class="logo" alt="BastionCC Logo">` : ''}<h1>BastionCC Deep Audit Report</h1><div class="server-subtitle">Target Server: ${escapeHtmlForReport(targetServerName)} (${escapeHtmlForReport(targetHost)})</div><div class="timestamp">Generated: ${new Date().toLocaleString()}</div></div>`;

        const execPromise = (command) => new Promise(res => exec(command, (err, out, serr) => res(out || serr || (err ? err.message : ''))));
        const sshPromise = (command) => new Promise(res => {
            if (!sshClient) return res('No active remote connection.');
            sshClient.exec(command, (err, stream) => {
                if (err) return res(`SSH Error: ${err.message}`);
                let out = ''; stream.on('data', d => out += d.toString()); stream.stderr.on('data', d => out += d.toString());
                stream.on('close', () => res(out));
            });
        });

        socket.emit('security-status', `1/5 Full Deep Nmap (-A) Scan on ${targetHost}`);
        socket.emit('security-data', `[1/5] Running Full Deep Nmap (-A) Scan on ${targetHost}...\r\n`);
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
                    else { connectOpts.privateKey = fs.readFileSync(path.resolve(pivotSrv.privateKeyPath || '/root/.ssh/id_ed25519'), 'utf8'); if (decryptedPassphrase) connectOpts.passphrase = decryptedPassphrase; }

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
        htmlReport += `<h2>1. Network Profile (Full Deep Nmap -A via ${nmapOrigin === 'local' ? 'Local' : 'Pivot Node'})</h2><div class="section"><pre>${escapeHtmlForReport(nmapOut)}</pre></div>`;

        if (sshClient) {
            socket.emit('security-status', '2/5 Firewall Rules (UFW)');
            socket.emit('security-data', `[2/5] Running Firewall Check...\r\n`);
            htmlReport += `<h2>2. Firewall Rules (UFW)</h2><div class="section"><pre>${escapeHtmlForReport(await sshPromise(`sudo -n ufw status verbose || ufw status verbose || echo "UFW not found or requires password sudo."`))}</pre></div>`;
            
            socket.emit('security-status', '3/5 Intrusion Prevention & Ban Lists');
            socket.emit('security-data', `[3/5] Running Intrusion Detection & Ban Lists...\r\n`);
            const f2bOut = await sshPromise(`sudo -n fail2ban-client status || fail2ban-client status ; echo "\n--- Active Banned IPs ---" ; sudo -n fail2ban-client banned || fail2ban-client banned || echo "Fail2ban not found."`);
            const crowdsecOut = await sshPromise(`sudo -n cscli metrics || cscli metrics ; echo "\n--- Active Decision List ---" ; sudo -n cscli decision list || cscli decision list || echo "CrowdSec not found."`);
            htmlReport += `<h2>3. Intrusion Prevention Status</h2><div class="section"><h3>Fail2ban & Active Bans</h3><pre>${escapeHtmlForReport(f2bOut)}</pre><h3>CrowdSec & Decision List</h3><pre>${escapeHtmlForReport(crowdsecOut)}</pre></div>`;
            
            socket.emit('security-status', '4/5 Rootkit & Kernel Integrity Scanners');
            socket.emit('security-data', `[4/5] Running Rootkit Scanners...\r\n`);
            htmlReport += `<h2>4. Rootkit & Integrity Check</h2><div class="section"><pre>${escapeHtmlForReport(await sshPromise(`sudo -n rkhunter --check --skip-keypress || sudo -n chkrootkit || echo "Neither rkhunter nor chkrootkit installed."`))}</pre></div>`;
        }

        if (domains && domains.length > 0) {
            socket.emit('security-status', '5/5 Web & SSL Domain Audits');
            socket.emit('security-data', `[5/5] Auditing Target Domains...\r\n`);
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
        htmlReport += `</body></html>`;
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
        
        try {
            const pin = activePins.get(socket.id);
            const decryptedPassphrase = config.encryptedPassphrase ? decryptPassphrase(config.encryptedPassphrase, pin) : '';
            
            let connectOpts = { host: config.host, port: parseInt(config.port) || 22, username: config.username, tryKeyboard: true };
            if (config.authMethod === 'password') connectOpts.password = decryptedPassphrase;
            else {
                const resolvedPath = path.resolve(config.privateKeyPath || '');
                if (resolvedPath.startsWith(CONFIG_DIR)) return socket.emit('terminal-data', '\r\n\x1b[31mConfig Error: Access to app data dir denied.\x1b[0m\r\n');
                if (!resolvedPath.includes('/.ssh/') && !resolvedPath.startsWith('/app/keys/')) return socket.emit('terminal-data', '\r\n\x1b[31mConfig Error: Key path restricted.\x1b[0m\r\n');
                connectOpts.privateKey = fs.readFileSync(resolvedPath, 'utf8');
                if (decryptedPassphrase) connectOpts.passphrase = decryptedPassphrase;
            }

            sshClient.on('ready', () => {
                socket.emit('ssh-status', { id: config.id, status: 'Connected' }); sshClient._host = config.host; 
                sshClient.shell({ term: 'xterm-256color', cols: config.cols || 80, rows: config.rows || 24 }, (err, stream) => {
                    if (err) return socket.emit('terminal-data', '\r\nShell error.\r\n');
                    activeShellStream = stream; stream.on('data', d => socket.emit('terminal-data', d.toString('utf-8'))); stream.on('close', () => activeShellStream = null);
                });

                statsInterval = setInterval(() => {
                    sshClient.exec(`echo "{\\"cpu\\":\\"$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%\\", \\"ram\\":\\"$(free -m | awk '/Mem:/ {printf "%dMB / %dMB", $3, $2}')\\", \\"ip\\":\\"$(hostname -I | awk '{print $1}')\\"}"`, (err, stream) => {
                        if (err) return; let data = ''; stream.on('data', chunk => data += chunk.toString());
                        stream.on('close', () => { try { socket.emit('server-stats', JSON.parse(data)); } catch(e){} });
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
server.listen(PORT, '0.0.0.0', () => console.log(`BastionCC v1.5.1 Ready on port ${PORT}`));
