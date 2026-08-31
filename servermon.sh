#!/bin/bash

echo "🚀 Building BastionCC v1.5.1 (Complete Fix: Docker, Security Suite, Password & TOTP)..."

mkdir -p server-dashboard/{public,server,data}
cd server-dashboard

# 1. package.json
cat << 'EOF' > package.json
{
  "name": "server-dashboard",
  "version": "1.5.1",
  "main": "server/index.js",
  "scripts": {
    "start": "node server/index.js"
  }
}
EOF

echo "🔒 Verifying dependencies..."
npm install express express-rate-limit socket.io ssh2 jsonwebtoken xterm xterm-addon-fit --save > /dev/null 2>&1

# 2. Dockerfile
cat << 'EOF' > Dockerfile
FROM node:24-alpine
WORKDIR /app
RUN apk update && apk upgrade --no-cache
RUN apk add --no-cache nmap nmap-scripts curl openssl tzdata
ENV TZ=Europe/London
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "server/index.js"]
EOF

# 3. Backend (server/index.js)
echo "⚙️ Writing v1.5.1 Backend..."
cat << 'EOF' > server/index.js
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
EOF

# 4. Frontend (public/index.html)
echo "🎨 Writing v1.5.1 Frontend..."
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BastionCC Control Center</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script> tailwind.config = { darkMode: 'class', theme: { extend: { colors: { darkBg: '#0f172a', darkNav: '#020617', accent: '#f97316' } } } } </script>
    <link rel="stylesheet" href="/node_modules/xterm/css/xterm.css" />
    <style>
        :root { --accent-color: #f97316; } .text-accent { color: var(--accent-color); } .bg-accent { background-color: var(--accent-color); } .border-accent { border-color: var(--accent-color); }
        .xterm, .xterm-viewport, .xterm-screen { width: 100% !important; height: 100% !important; }
        .no-scrollbar::-webkit-scrollbar { display: none; } .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        @keyframes expandCenter { 0% { transform: scaleX(0); opacity: 0; } 100% { transform: scaleX(1); opacity: 1; } }
        .anim-connected { animation: expandCenter 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; display: inline-block !important; }
    </style>
</head>
<body class="bg-slate-100 text-slate-800 dark:bg-darkBg dark:text-slate-100 h-screen flex overflow-hidden">

    <!-- CHANGELOG DRAWER -->
    <div id="changelog-backdrop" class="fixed inset-0 z-[65] bg-slate-950/50 backdrop-blur-sm hidden transition-opacity" onclick="closeChangelog()"></div>
    <div id="changelog-drawer" class="fixed inset-y-0 right-0 z-[70] w-full max-w-md bg-white dark:bg-darkNav shadow-2xl border-l border-slate-200 dark:border-slate-800 transform translate-x-full transition-transform duration-300 ease-in-out flex flex-col">
        <div class="p-6 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center bg-slate-50 dark:bg-slate-900 shrink-0">
            <h2 class="text-xl font-bold text-accent">Version Changelog</h2>
            <button onclick="closeChangelog()" class="text-slate-500 hover:text-rose-500 transition-colors font-bold p-1 rounded focus:outline-none"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg></button>
        </div>
        <div class="flex-1 overflow-y-auto p-6 space-y-8 text-sm">
            <div class="border-l-4 border-orange-500 pl-4">
                <h3 class="text-lg font-bold text-slate-800 dark:text-white">v1.5.1 <span class="text-xs font-bold text-rose-500 border border-rose-500/30 bg-rose-500/10 rounded px-2 ml-2">HOTFIX</span> <span class="text-sm text-slate-500 font-normal border border-slate-400 rounded px-2 ml-2">Current</span></h3>
                <p class="text-sm text-slate-600 dark:text-slate-400 mt-1">Multi-Factor Authentication & Full UI Restoration</p>
                <ul class="list-disc list-inside text-sm text-slate-700 dark:text-slate-300 mt-2 space-y-1">
                    <li><strong>Authentication Profiles:</strong> Added toggle to switch between strictly enforced Public Key auth and native SSH Password auth for legacy endpoints.</li>
                    <li><strong>Interactive 2FA (TOTP):</strong> Integrated deep `keyboard-interactive` socket forwarding to securely intercept and proxy Google Authenticator codes dynamically during the SSH handshake.</li>
                    <li><strong>Security Grid & Docker Restoration:</strong> Fully restored all 4 security audit panels (Nmap, Web/SSL Matrix, Intrusion Prevention, Firewall) and Docker container management grids.</li>
                </ul>
            </div>
            <div class="border-l-4 border-rose-500 pl-4">
                <h3 class="font-bold text-lg text-slate-900 dark:text-white mb-2">v1.4.1 <span class="text-xs font-bold text-rose-500 border border-rose-500/30 bg-rose-500/10 rounded px-2 ml-1">SECURITY</span></h3>
                <p class="text-slate-600 dark:text-slate-400">Live Status Pulse & Audit Polish: Dynamic tracker for deep Nmap scanning.</p>
            </div>
        </div>
    </div>

    <!-- ROOTKIT INSTALL MODAL -->
    <div id="rootkit-install-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-[500px] shadow-2xl border border-rose-500/50 relative">
            <h2 class="text-xl font-bold mb-4 text-rose-500 flex items-center"><svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg> Rootkit Scanners Missing</h2>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">Neither <code>rkhunter</code> nor <code>chkrootkit</code> were found on the target node.</p>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-6">Would you like BastionCC to attempt to install them automatically via <code>apt-get</code> and launch the scan?</p>
            <div class="flex flex-col space-y-3">
                <button onclick="confirmRootkitInstall()" class="w-full py-2 rounded font-bold bg-rose-500 text-white hover:opacity-90 transition shadow-lg">Yes, Auto-Install & Scan</button>
                <button onclick="document.getElementById('rootkit-install-modal').classList.add('hidden')" class="w-full py-2 rounded font-bold text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 transition mt-2">Cancel</button>
            </div>
        </div>
    </div>

    <!-- DEEP SCAN MODAL -->
    <div id="deep-scan-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-[500px] shadow-2xl border border-accent/50 relative">
            <h2 class="text-xl font-bold mb-4 text-accent">Automated Deep Scan</h2>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">This will sequentially execute Full Nmap (-A), UFW, Fail2ban (with bans), CrowdSec (with decisions), and Rootkit Scanners against the active server, compiling a standalone HTML report.</p>
            <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Nmap Scan Origin (Hub-Spoke)</p>
            <select id="ds-nmap-origin" class="w-full px-3 py-2 rounded bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm mb-4"><option value="local">Local Host</option></select>
            <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Web & SSL Targets (Optional)</p>
            <div class="space-y-2 mb-6" id="ds-domains">
                <input type="text" placeholder="domain1.com" class="w-full px-3 py-2 rounded bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
                <input type="text" placeholder="domain2.com" class="w-full px-3 py-2 rounded bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
            </div>
            <div class="flex space-x-2">
                <button onclick="document.getElementById('deep-scan-modal').classList.add('hidden')" class="w-1/3 py-2 rounded font-bold bg-slate-200 dark:bg-slate-800 hover:opacity-90 transition text-slate-700 dark:text-slate-200">Cancel</button>
                <button onclick="executeDeepScan()" class="w-2/3 py-2 rounded font-bold bg-accent text-white hover:opacity-90 transition">Start Batch Audit</button>
            </div>
        </div>
    </div>

    <!-- UFW DOCKER ADVISORY MODAL -->
    <div id="ufw-docker-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-[500px] shadow-2xl border border-amber-500/50 relative">
            <h2 class="text-xl font-bold mb-4 text-amber-500 flex items-center"><svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg> Docker & UFW Security Advisory</h2>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">Standard UFW rules do <strong>not</strong> block ports published by Docker containers. Because Docker inserts its own iptables rules ahead of UFW, containers bound to public interfaces can remain exposed.</p>
            <div class="flex flex-col space-y-3">
                <button onclick="executeUfwScan(true)" class="w-full py-2 rounded font-bold bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 transition">Yes, I have secured my Docker ports</button>
                <button onclick="executeUfwScan(false)" class="w-full py-2 rounded font-bold bg-accent text-white hover:opacity-90 transition">Not sure — Please scan for me</button>
                <button onclick="document.getElementById('ufw-docker-modal').classList.add('hidden')" class="w-full py-2 rounded font-bold text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 transition mt-2">Cancel</button>
            </div>
        </div>
    </div>

    <!-- PIN RESET & AUTH LOGIC -->
    <div id="pin-reset-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-slate-200 dark:border-slate-800 relative">
            <h2 class="text-xl font-bold mb-6 text-center text-accent">Change Master PIN</h2>
            <form onsubmit="handlePinReset(event)" class="space-y-4">
                <input type="password" id="reset-current" placeholder="Current PIN" required class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none">
                <input type="password" id="reset-new" placeholder="New PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none">
                <input type="password" id="reset-confirm" placeholder="Confirm New PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none">
                <div class="flex space-x-2 pt-2"><button type="button" onclick="closePinReset()" class="w-1/2 py-2 rounded font-bold bg-slate-200 dark:bg-slate-800 hover:opacity-90 transition">Cancel</button><button type="submit" class="w-1/2 py-2 rounded font-bold bg-accent text-white hover:opacity-90 transition">Re-Key Vault</button></div>
            </form>
        </div>
    </div>

    <!-- TOTP MODAL -->
    <div id="totp-modal" class="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-accent/50 relative">
            <h2 class="text-xl font-bold mb-2 text-accent" id="totp-title">Authentication Required</h2>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-6" id="totp-prompt">Please enter your code.</p>
            <form onsubmit="submitTotp(event)" class="space-y-4">
                <input type="text" id="totp-input" required class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono text-lg">
                <div class="flex space-x-2"><button type="button" onclick="document.getElementById('totp-modal').classList.add('hidden')" class="w-1/3 py-2 rounded font-bold bg-slate-200 dark:bg-slate-800 hover:opacity-90 transition">Cancel</button><button type="submit" class="w-2/3 py-2 rounded font-bold bg-accent text-white hover:opacity-90 transition">Submit</button></div>
            </form>
        </div>
    </div>

    <div id="login-screen" class="fixed inset-0 z-[90] flex items-center justify-center bg-slate-950/80 backdrop-blur-md hidden flex-col">
        <img src="/bastioncc.png" alt="BastionCC" class="w-full max-w-sm mb-6 drop-shadow-2xl" onerror="this.style.display='none'">
        <div id="login-view" class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-slate-200 dark:border-slate-800 hidden">
            <h2 class="text-xl font-bold mb-6 text-center text-slate-800 dark:text-slate-100">Vault Access</h2>
            <form onsubmit="handleLogin(event)" class="space-y-4">
                <input type="password" id="login-pass" placeholder="Master PIN" required class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono">
                <button type="submit" class="w-full py-2 rounded font-bold bg-accent text-white hover:opacity-90 transition">Decrypt & Enter</button>
            </form>
        </div>
        <div id="setup-view" class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-slate-200 dark:border-slate-800 hidden">
            <h2 class="text-xl font-bold text-accent text-center mb-6">Initialize BastionCC</h2>
            <form onsubmit="handleSetup(event)" class="space-y-4">
                <input type="password" id="setup-pass" placeholder="New Master PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono">
                <input type="password" id="setup-pass-confirm" placeholder="Confirm Master PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono">
                <button type="submit" class="w-full py-2 rounded font-bold bg-accent text-white hover:opacity-90 transition">Lock & Initialize</button>
            </form>
        </div>
    </div>

    <!-- DIAGNOSTICS MODAL -->
    <div id="diagnostics-modal" class="fixed inset-0 z-[60] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-darkNav w-[95vw] h-[90vh] rounded-xl shadow-2xl border border-slate-800 flex flex-col overflow-hidden">
            <div class="p-4 border-b border-slate-800 flex justify-between items-center bg-slate-900 shrink-0"><h2 id="diag-title" class="text-lg font-bold text-slate-100 font-mono">Diagnostics Viewer</h2><button onclick="closeDiagnostics()" class="text-rose-500 hover:text-rose-400 font-bold px-3 py-1 rounded bg-rose-500/10 transition-colors">Close (ESC)</button></div>
            <div id="view-modal-terminal" class="flex-1 p-2 bg-[#0f172a] relative"></div>
        </div>
    </div>

    <nav id="sidebar" class="w-64 border-r border-slate-200 dark:border-slate-800 flex flex-col transition-all duration-300 ease-in-out bg-white dark:bg-darkNav shrink-0 overflow-hidden">
        <div class="flex items-center justify-center p-6 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/20"><img src="/Bastioncrop.png" alt="BastionCC Badge" class="w-24 h-24 object-contain drop-shadow-lg" onerror="this.style.display='none'"></div>
        <div class="p-4 border-b border-slate-200 dark:border-slate-800 font-bold flex justify-between items-center whitespace-nowrap bg-white dark:bg-darkNav mt-2"><span>Servers</span><button onclick="showAddServerForm()" class="text-xs px-2 py-1 rounded bg-accent text-white hover:opacity-90">+ Add</button></div>
        <div id="server-list" class="flex-1 p-2 space-y-1 overflow-y-auto"></div>
        <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex flex-col space-y-2 whitespace-nowrap shrink-0">
            <div class="flex flex-col space-y-1 mb-2 pb-3 border-b border-slate-200 dark:border-slate-700">
                <div class="text-[10px] font-bold uppercase tracking-wider text-slate-400 text-center mb-1">Server Config Management</div>
                <div class="flex space-x-2">
                    <button onclick="exportVault()" class="w-1/2 py-1.5 flex justify-center items-center text-slate-500 hover:text-accent transition border border-transparent hover:border-slate-200 dark:hover:border-slate-700 rounded bg-slate-50 dark:bg-slate-900/50" title="Export Configs"><svg class="w-3.5 h-3.5 mr-1.5 opacity-70" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path></svg><span class="text-xs font-bold">Export</span></button>
                    <button onclick="document.getElementById('import-upload').click()" class="w-1/2 py-1.5 flex justify-center items-center text-slate-500 hover:text-accent transition border border-transparent hover:border-slate-200 dark:hover:border-slate-700 rounded bg-slate-50 dark:bg-slate-900/50" title="Import Configs"><svg class="w-3.5 h-3.5 mr-1.5 opacity-70" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M5 10l7-7m0 0l7 7m-7-7v18"></path></svg><span class="text-xs font-bold">Import</span></button>
                    <input type="file" id="import-upload" accept=".json" class="hidden" onchange="importVault(event)">
                </div>
            </div>
            <button onclick="openPinReset()" class="w-full py-1.5 flex justify-center items-center text-slate-500 hover:text-accent transition border border-transparent hover:border-slate-200 dark:hover:border-slate-700 rounded bg-slate-50 dark:bg-slate-900/50 mb-1"><svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg><span class="text-xs font-bold">Change PIN</span></button>
            <button onclick="logout()" class="w-full py-1.5 text-xs font-bold rounded bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-700 transition">Logout</button>
            <button onclick="emergencyLock()" class="w-full py-1.5 text-xs font-bold rounded bg-rose-100 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 hover:bg-rose-500 hover:text-white transition">Emergency Lock</button>
            <div class="flex items-center justify-center pt-2 pb-1"><button onclick="document.documentElement.classList.toggle('dark')" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition"><svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path></svg></button></div>
            <div class="text-center mt-1 text-[10px] text-slate-400 font-medium tracking-wide"><span>Created by Gemini AI | </span><span onclick="openChangelog()" class="cursor-pointer hover:text-accent font-bold transition">v1.5.1 Changelog</span></div>
        </div>
    </nav>

    <main class="flex-1 flex flex-col p-6 bg-slate-50 dark:bg-darkBg relative transition-colors overflow-hidden">
        <header class="flex justify-between items-end mb-4 min-h-[56px] shrink-0">
            <div class="flex items-end space-x-3">
                <button onclick="toggleSidebar()" class="mb-1 p-1 text-slate-500 hover:text-accent transition focus:outline-none"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg></button>
                <div>
                    <h1 id="header-title" class="text-2xl font-bold">Select a Server</h1>
                    <div id="tabs" class="space-x-4 mt-2 hidden">
                        <button onclick="switchTab('terminal')" id="tab-terminal" class="text-sm font-semibold text-accent border-b-2 border-accent pb-1 transition-colors">Terminal</button>
                        <button onclick="switchTab('files')" id="tab-files" class="text-sm font-semibold text-slate-500 pb-1 transition-colors">File Explorer</button>
                        <button onclick="switchTab('docker')" id="tab-docker" class="text-sm font-semibold text-slate-500 pb-1 transition-colors hidden">Containers</button>
                        <button onclick="switchTab('logs')" id="tab-logs" class="text-sm font-semibold text-slate-500 pb-1 transition-colors hidden">Logs</button>
                        <button onclick="switchTab('security')" id="tab-security" class="text-sm font-semibold text-slate-500 pb-1 transition-colors hidden">Security</button>
                    </div>
                </div>
            </div>
            
            <div class="flex flex-col items-end space-y-2 overflow-hidden">
                <div id="macro-buttons" class="flex space-x-2 overflow-x-auto w-full justify-end hidden"></div>
                <div id="telemetry-bar" class="hidden text-xs font-mono text-slate-400 bg-slate-200 dark:bg-slate-900 border border-slate-300 dark:border-slate-800 rounded-lg px-4 py-1.5 flex space-x-6 items-center shadow-inner">
                    <span class="flex items-center space-x-1.5"><span class="text-emerald-500">●</span> <span>CPU: <span id="stat-cpu" class="text-slate-700 dark:text-slate-300 font-bold">--</span></span></span>
                    <span class="flex items-center space-x-1.5"><span class="text-blue-500">●</span> <span>RAM: <span id="stat-ram" class="text-slate-700 dark:text-slate-300 font-bold">--</span></span></span>
                    <span class="flex items-center space-x-1.5"><span class="text-purple-500">●</span> <span>IP: <span id="stat-ip" class="text-slate-700 dark:text-slate-300 font-bold">--</span></span></span>
                </div>
            </div>
        </header>

        <div class="flex-1 relative rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm bg-slate-900 overflow-hidden min-h-0" onclick="closeAllDropdowns()">
            <div id="view-terminal" class="absolute inset-0 p-2 hidden"></div>
            
            <div id="view-files" class="absolute inset-0 bg-white dark:bg-darkNav p-4 hidden flex-col border-4 border-transparent">
                <div class="text-sm border-b border-slate-200 dark:border-slate-800 pb-2 mb-2 flex space-x-2"><button id="btn-sftp-up" class="px-2 bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 transition rounded font-semibold text-xs">UP</button><span id="sftp-path" class="font-mono text-slate-500 py-1">/root</span></div>
                <div id="sftp-grid" class="flex-1 overflow-y-auto"></div>
            </div>

            <div id="view-logs" class="absolute inset-0 bg-white dark:bg-darkNav p-4 hidden flex-col">
                <div class="flex justify-between items-center mb-2 space-x-4 border-b border-slate-200 dark:border-slate-800 pb-3">
                    <div id="log-buttons" class="flex space-x-2 overflow-visible items-center"></div>
                    <div class="flex space-x-2 shrink-0 items-center bg-slate-100 dark:bg-slate-900 p-1.5 rounded-lg border border-slate-300 dark:border-slate-700">
                        <svg class="w-4 h-4 text-slate-400 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                        <input type="text" id="log-grep-input" placeholder="Grep filter..." class="w-48 px-2 py-1 text-sm bg-transparent text-slate-800 dark:text-slate-200 outline-none">
                    </div>
                </div>
                <div id="log-terminal" class="flex-1 bg-[#0f172a] rounded overflow-hidden p-2"></div>
            </div>

            <div id="view-docker" class="absolute inset-0 bg-white dark:bg-darkNav p-4 hidden flex-col overflow-y-auto">
                <table class="w-full text-left text-sm text-slate-500 dark:text-slate-400 select-none">
                    <thead class="text-xs text-slate-700 uppercase bg-slate-100 dark:bg-slate-800 dark:text-slate-300">
                        <tr>
                            <th scope="col" class="px-4 py-3 rounded-tl-lg cursor-pointer hover:bg-slate-200 dark:hover:bg-slate-700 transition sort-btn" data-col="name">Container <span id="sort-ind-name" class="text-[10px] ml-1"></span></th>
                            <th scope="col" class="px-4 py-3 cursor-pointer hover:bg-slate-200 dark:hover:bg-slate-700 transition sort-btn" data-col="image">Image <span id="sort-ind-image" class="text-[10px] ml-1"></span></th>
                            <th scope="col" class="px-4 py-3 text-center cursor-pointer hover:bg-slate-200 dark:hover:bg-slate-700 transition sort-btn" data-col="cpu">CPU / RAM <span id="sort-ind-cpu" class="text-[10px] ml-1"></span></th>
                            <th scope="col" class="px-4 py-3 rounded-tr-lg text-right">Actions</th>
                        </tr>
                    </thead>
                    <tbody id="docker-grid"></tbody>
                </table>
                <div id="docker-empty-state" class="hidden text-center py-10 text-slate-400">No Docker containers running or detected.</div>
            </div>

            <div id="view-security" class="absolute inset-0 bg-slate-50 dark:bg-slate-900 p-4 hidden flex-col overflow-y-auto">
                <div class="flex justify-between items-center mb-4">
                    <h2 class="text-xl font-bold">Security Audit Suite</h2>
                    <div class="flex space-x-2">
                        <button onclick="runSecurityScan('rkhunter')" class="bg-slate-200 dark:bg-slate-700 px-4 py-2 rounded text-sm font-bold shadow hover:bg-slate-300 dark:hover:bg-slate-600 transition">Local Rootkit Scan</button>
                        <button onclick="openDeepScanModal()" class="bg-accent text-white px-4 py-2 rounded text-sm font-bold shadow hover:bg-orange-600 transition">Deep Batch Scan & Export</button>
                    </div>
                </div>
                
                <!-- Live Status Pulse Indicator -->
                <div id="scan-status-container" class="hidden w-full border border-accent rounded-[10px] bg-transparent p-3 mb-6 flex items-center justify-between shadow-sm">
                    <div class="flex items-center space-x-2">
                        <span class="w-2.5 h-2.5 rounded-full bg-accent animate-ping"></span>
                        <span class="text-sm font-mono text-slate-700 dark:text-slate-200 font-semibold">
                            Now Testing - <span id="scan-status-text" class="text-accent">Initializing Engine</span><span id="scan-status-dots" class="inline-block w-8 text-left text-accent font-bold"></span><span class="text-accent animate-pulse">_</span>
                        </span>
                    </div>
                    <span class="text-xs font-mono text-slate-400 uppercase tracking-widest">Active Probe</span>
                </div>

                <div class="grid grid-cols-1 xl:grid-cols-2 gap-6 mb-6">
                    <!-- Nmap -->
                    <div class="border border-slate-200 dark:border-slate-700 rounded-lg p-4 bg-white dark:bg-darkNav flex flex-col justify-between shadow-sm">
                        <div>
                            <div class="flex items-center mb-2"><svg class="w-5 h-5 text-accent mr-2" fill="currentColor" viewBox="0 0 640 512"><path d="M312 32c-13.3 0-24 10.7-24 24s10.7 24 24 24h25.7l34.6 64H222.9l27.4-73.1c3.2-8.5-1.1-18.1-9.6-21.3s-18.1 1.1-21.3 9.6L182.2 144H160c-35.3 0-64 28.7-64 64v32h16c22.1 0 40 17.9 40 40v32c0 22.1-17.9 40-40 40H96v64c0 35.3 28.7 64 64 64h22.9l-27.4 73.1c-3.2 8.5 1.1 18.1 9.6 21.3s18.1-1.1 21.3-9.6L225.8 400h188.4l37.2 99.3c3.2 8.5 12.8 12.8 21.3 9.6s12.8-12.8 9.6-21.3L454.9 400H480c35.3 0 64-28.7 64-64v-64h-16c-22.1 0-40-17.9-40-40v-32c0-22.1 17.9-40 40-40h16v-32c0-35.3-28.7-64-64-64H382.7l-34.6-64H376c13.3 0 24-10.7 24-24s-10.7-24-24-24h-64z"/></svg><h3 class="font-bold">Hub-and-Spoke Network Auditing</h3></div>
                            <p class="text-xs text-slate-500 mb-3">Scan Origin: <select id="sec-nmap-origin" class="bg-transparent border-b border-slate-400 outline-none cursor-pointer"><option value="local">Local Host</option></select></p>
                            <p class="text-sm mb-4">Discover open ports on active server target.</p>
                        </div>
                        <div>
                            <div class="flex space-x-2 mb-2">
                                <button onclick="document.getElementById('sec-nmap-flags').value='-F'" class="bg-slate-200 dark:bg-slate-800 text-xs px-3 py-1 rounded hover:bg-slate-300 dark:hover:bg-slate-700 transition">Quick (-F)</button>
                                <button onclick="document.getElementById('sec-nmap-flags').value='-A'" class="bg-slate-200 dark:bg-slate-800 text-xs px-3 py-1 rounded hover:bg-slate-300 dark:hover:bg-slate-700 transition">Deep (-A)</button>
                                <button onclick="document.getElementById('sec-nmap-flags').value='--top-ports 1000'" class="bg-slate-200 dark:bg-slate-800 text-xs px-3 py-1 rounded hover:bg-slate-300 dark:hover:bg-slate-700 transition">Top 1000</button>
                            </div>
                            <div class="flex">
                                <span class="bg-slate-200 dark:bg-slate-700 px-3 py-2 rounded-l text-sm border-r border-slate-300 dark:border-slate-600 font-mono">nmap</span>
                                <input type="text" id="sec-nmap-flags" placeholder="Custom flags" class="flex-1 bg-slate-50 dark:bg-slate-900 px-3 py-2 text-sm outline-none border-y border-slate-200 dark:border-slate-700 font-mono">
                                <button onclick="runSecurityScan('nmap')" class="bg-accent text-white px-4 py-2 rounded-r text-sm font-bold hover:bg-orange-600 transition">Run</button>
                            </div>
                        </div>
                    </div>

                    <!-- Web & SSL -->
                    <div class="border border-slate-200 dark:border-slate-700 rounded-lg p-4 bg-white dark:bg-darkNav flex flex-col justify-between shadow-sm">
                        <div>
                            <div class="flex items-center mb-2"><svg class="w-5 h-5 text-accent mr-2" fill="currentColor" viewBox="0 0 512 512"><path d="M256 0c141.4 0 256 114.6 256 256s-114.6 256-256 256S0 397.4 0 256 114.6 0 256 0zM224 160c0-17.7-14.3-32-32-32s-32 14.3-32 32v32h64v-32zm64 32v-32c0-53-43-96-96-96s-96 43-96 96v32c-17.7 0-32 14.3-32 32v128c0 17.7 14.3 32 32 32h192c17.7 0 32-14.3 32-32V224c0-17.7-14.3-32-32-32h-64z"/></svg><h3 class="font-bold">Web & SSL Auditor</h3></div>
                            <div class="flex items-center mb-3 group">
                                <span class="text-xs text-slate-500 mr-2 shrink-0">Target:</span>
                                <div class="flex w-full rounded border border-slate-400 group-focus-within:border-accent overflow-hidden transition-colors">
                                    <span class="bg-slate-200 dark:bg-slate-800 text-slate-500 text-xs px-2 py-1.5 border-r border-slate-400">https://</span>
                                    <input type="text" id="sec-curl-url" value="your.domain.com" class="bg-transparent outline-none text-sm w-full font-mono text-accent px-2 py-1">
                                </div>
                            </div>
                            <p class="text-sm mb-4">Analyze HTTP security headers & certs.</p>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="runSecurityScan('curl')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">Analyze Headers</button>
                            <button onclick="runSecurityScan('ssl')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">Check SSL Expiry</button>
                        </div>
                    </div>

                    <!-- Intrusion -->
                    <div class="border border-slate-200 dark:border-slate-700 rounded-lg p-4 bg-white dark:bg-darkNav flex flex-col justify-between shadow-sm">
                        <div>
                            <div class="flex items-center mb-2"><svg class="w-5 h-5 text-accent mr-2" fill="currentColor" viewBox="0 0 512 512"><path d="M256 0c-1.3 0-2.6 .1-3.9 .2L37.7 44.5C14.7 48.7 0 69.8 0 93.4V202.9c0 119 75.3 223.8 186.2 260l60.1 19.5c6.3 2.1 13.1 2.1 19.4 0l60.1-19.5C436.7 426.7 512 321.9 512 202.9V93.4c0-23.6-14.7-44.7-37.7-48.9L259.9 .2C258.6 .1 257.3 0 256 0zM256 64V439.4l-42.5-13.8C121.2 395.7 64 308.2 64 202.9V99.5L256 64z"/></svg><h3 class="font-bold">Intrusion Prevention & Bans</h3></div>
                            <p class="text-xs text-slate-500 mb-3">Target: <span class="text-accent">Active SSH Session</span></p>
                            <p class="text-sm mb-4">Monitor active bans & threat decisions.</p>
                        </div>
                        <div class="flex space-x-2">
                            <button onclick="runSecurityScan('fail2ban')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">Fail2Ban + Bans</button>
                            <button onclick="runSecurityScan('crowdsec')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">CrowdSec + Decisions</button>
                        </div>
                    </div>

                    <!-- Firewall -->
                    <div class="border border-slate-200 dark:border-slate-700 rounded-lg p-4 bg-white dark:bg-darkNav flex flex-col justify-between shadow-sm">
                        <div>
                            <div class="flex items-center mb-2"><svg class="w-5 h-5 text-accent mr-2" fill="currentColor" viewBox="0 0 640 512"><path d="M0 64c0-17.7 14.3-32 32-32H256v96H0V64zM288 32H608c17.7 0 32 14.3 32 32v64H288V32zM0 160h64v96H0V160zm96 0H384v96H96V160zm320 0H640v96H416V160zM0 288H256v96H0V288zm288 0H640v96H288V288zM0 416h64v64c0 17.7 14.3 32 32 32h160V416H0zm288 0v96H608c17.7 0 32-14.3 32-32V416H288z"/></svg><h3 class="font-bold">Firewall Status</h3></div>
                            <p class="text-xs text-slate-500 mb-3">Target: <span class="text-accent">Active SSH Session</span></p>
                            <p class="text-sm mb-4">Review active firewall routing rules.</p>
                        </div>
                        <button onclick="initUfwCheck()" class="w-full bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">UFW Status</button>
                    </div>
                </div>

                <div class="bg-[#1e1e1e] rounded-lg p-4 border border-slate-700 flex-1 overflow-y-auto shadow-inner min-h-[200px]">
                    <div id="securityTerm" class="font-mono text-sm text-sky-400 whitespace-pre">
                        <p class="text-slate-500">BastionCC Security Audit Engine v1.5.1</p>
                        <p class="text-slate-500">Ready for target acquisition...</p>
                        <p class="text-accent mt-2">> _</p>
                    </div>
                </div>
            </div>

            <!-- ADD/EDIT SERVER -->
            <div id="view-add-server" class="absolute inset-0 bg-white dark:bg-darkNav p-8 hidden flex-col overflow-y-auto">
                <h2 id="form-header-title" class="text-2xl font-bold mb-6">Add New Server</h2>
                <div class="space-y-4 max-w-2xl">
                    <input type="text" id="frm-name" placeholder="Server Name" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 text-slate-900 dark:text-slate-100 outline-none focus:border-accent">
                    <div class="grid grid-cols-2 gap-4"><input type="text" id="frm-host" placeholder="IP / Hostname" class="px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none focus:border-accent"><input type="number" id="frm-port" value="22" class="px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none focus:border-accent"></div>
                    <div class="grid grid-cols-2 gap-4">
                        <div class="col-span-1"><label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Username</label><input type="text" id="frm-user" value="root" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none focus:border-accent"></div>
                        <div class="col-span-1">
                            <label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Feature Management</label>
                            <div class="flex space-x-2">
                                <label class="flex items-center space-x-1 text-xs cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700"><input type="checkbox" id="frm-docker" checked> <span>Docker</span></label>
                                <label class="flex items-center space-x-1 text-xs cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700"><input type="checkbox" id="frm-logs" checked> <span>Logs</span></label>
                                <label class="flex items-center space-x-1 text-xs cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700"><input type="checkbox" id="frm-security" checked> <span>Security</span></label>
                            </div>
                        </div>
                    </div>
                    
                    <!-- AUTH TOGGLE -->
                    <div class="col-span-2 mt-2 mb-2 p-3 bg-slate-50 dark:bg-slate-900/50 rounded border border-slate-200 dark:border-slate-800">
                        <label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">Authentication Method</label>
                        <div class="flex items-center space-x-3">
                            <span class="text-sm font-semibold text-accent" id="lbl-auth-key">Public Key</span>
                            <label class="relative inline-flex items-center cursor-pointer">
                                <input type="checkbox" id="frm-auth-method" class="sr-only peer" onchange="toggleAuthMethod()">
                                <div class="w-11 h-6 bg-slate-300 peer-focus:outline-none rounded-full peer dark:bg-slate-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-accent"></div>
                            </label>
                            <span class="text-sm text-slate-500 font-semibold" id="lbl-auth-pass">Password / TOTP</span>
                        </div>
                    </div>

                    <div id="div-key-type">
                        <label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">SSH Key Type & Path</label>
                        <div class="flex space-x-2">
                            <select id="frm-key-type" onchange="toggleCustomKeyPath()" class="w-1/3 px-3 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm"><option value="/root/.ssh/id_ed25519">id_ed25519</option><option value="/root/.ssh/id_rsa">id_rsa</option><option value="/root/.ssh/id_ecdsa">id_ecdsa</option><option value="custom">Custom Path...</option></select>
                            <input type="text" id="frm-key-custom" placeholder="e.g. /home/user/.ssh/custom_key" class="hidden flex-1 px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm">
                        </div>
                    </div>
                    <div><label id="lbl-passphrase" class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">SSH Key Passphrase (Stored Encrypted At Rest)</label><input type="password" id="frm-passphrase" placeholder="Leave blank if key has no passphrase (or keep current)" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none"></div>

                    <div class="mt-6 border-t border-slate-200 dark:border-slate-700 pt-4">
                        <div class="flex justify-between items-center mb-2"><h3 class="font-bold">Quick Action Macros</h3><div class="flex space-x-2"><select id="macro-clone-select" onchange="cloneMacros(this.value)" class="text-xs px-2 py-1 outline-none rounded bg-slate-100 dark:bg-slate-900 border border-slate-300 dark:border-slate-700"><option value="">-- Import From --</option></select><button type="button" onclick="addMacroRow()" class="text-xs px-2 py-1 bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 rounded font-semibold">+ Add Row</button></div></div>
                        <div id="macro-builder" class="space-y-2"></div>
                    </div>
                    <div class="mt-6 border-t border-slate-200 dark:border-slate-700 pt-4">
                        <div class="flex justify-between items-center mb-2"><h3 class="font-bold">Custom Log Paths</h3><div class="flex space-x-2"><select id="log-clone-select" onchange="cloneLogs(this.value)" class="text-xs px-2 py-1 outline-none rounded bg-slate-100 dark:bg-slate-900 border border-slate-300 dark:border-slate-700"><option value="">-- Import From --</option></select><button type="button" onclick="addLogPathRow()" class="text-xs px-2 py-1 bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 rounded font-semibold">+ Add Log</button></div></div>
                        <div id="log-builder" class="space-y-2"></div>
                    </div>
                    <div class="pt-6 pb-12 flex justify-between items-center border-t border-slate-200 dark:border-slate-700">
                        <button onclick="saveServer()" class="px-6 py-2 rounded bg-accent text-white font-bold hover:opacity-90">Save Configuration</button>
                        <button id="delete-server-btn" onclick="deleteServer()" class="px-4 py-2 rounded bg-rose-500/10 hover:bg-rose-500 hover:text-white text-rose-500 font-bold text-sm hidden">Delete Server</button>
                    </div>
                </div>
            </div>
        </div>
    </main>

    <script src="/node_modules/xterm/lib/xterm.js"></script>
    <script src="/node_modules/xterm-addon-fit/lib/xterm-addon-fit.js"></script>
    <script src="/socket.io/socket.io.js"></script>
    <script>
        let socket, term, fitAddon, modalTerm, modalFitAddon, logTerm, logFitAddon;
        let authToken = null, currentPin = null; let serversData = [];
        let activeServerId = null, editingServerId = null; let currentSftpPath = '/root'; let downloadedChunks = [];
        let currentDockerRaw = []; let dSort = { col: 'name', dir: 1 };
        let liveLogLines = []; let currentLogPartial = ''; let dotInterval = null; let dotCount = 0;
        let currentTotpServerId = null;

        function escapeHtml(str) { return String(str).replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m])); }

        window.addEventListener('DOMContentLoaded', async () => {
            try {
                const data = await (await fetch('/api/status')).json();
                document.getElementById('login-screen').classList.remove('hidden'); document.getElementById('login-screen').classList.add('flex');
                if (data.needsSetup) { document.getElementById('setup-view').classList.remove('hidden'); document.getElementById('login-view').classList.add('hidden'); }
                else { document.getElementById('login-view').classList.remove('hidden'); document.getElementById('setup-view').classList.add('hidden'); }
            } catch (e) {}
            document.getElementById('btn-sftp-up').addEventListener('click', navUp); 
            document.getElementById('log-grep-input').addEventListener('input', renderFilteredLogs);
            document.querySelectorAll('.sort-btn').forEach(btn => btn.addEventListener('click', () => sortDocker(btn.dataset.col)));
        });

        function toggleAuthMethod() {
            const isPass = document.getElementById('frm-auth-method').checked;
            const keyTypeDiv = document.getElementById('div-key-type');
            const passLabel = document.getElementById('lbl-passphrase');
            const passInput = document.getElementById('frm-passphrase');
            if (isPass) {
                document.getElementById('lbl-auth-key').classList.replace('text-accent', 'text-slate-500');
                document.getElementById('lbl-auth-pass').classList.replace('text-slate-500', 'text-accent');
                keyTypeDiv.classList.add('hidden'); passLabel.innerText = 'Server Password (Encrypted At Rest)'; passInput.placeholder = 'Enter the server password';
            } else {
                document.getElementById('lbl-auth-key').classList.replace('text-slate-500', 'text-accent');
                document.getElementById('lbl-auth-pass').classList.replace('text-accent', 'text-slate-500');
                keyTypeDiv.classList.remove('hidden'); passLabel.innerText = 'SSH Key Passphrase (Stored Encrypted At Rest)'; passInput.placeholder = 'Leave blank if key has no passphrase';
            }
        }

        function submitTotp(e) {
            e.preventDefault(); const val = document.getElementById('totp-input').value;
            document.getElementById('totp-modal').classList.add('hidden');
            socket.emit(`ssh-keyboard-interactive-response-${currentTotpServerId}`, [val]);
        }

        function updateNmapDropdown(activeId) {
            const html = `<option value="local">Local Host</option>` + serversData.map(s => `<option value="${s.id}">${escapeHtml(s.name)}${s.id === activeId ? ' (Active)' : ''}</option>`).join('');
            const sel1 = document.getElementById('sec-nmap-origin'); if (sel1) { sel1.innerHTML = html; sel1.value = 'local'; }
            const sel2 = document.getElementById('ds-nmap-origin'); if (sel2) { sel2.innerHTML = html; sel2.value = 'local'; }
        }

        function openDeepScanModal() { document.getElementById('deep-scan-modal').classList.remove('hidden'); }
        function executeDeepScan() {
            const domains = Array.from(document.getElementById('ds-domains').querySelectorAll('input')).map(i => i.value.trim()).filter(Boolean);
            const nmapOrigin = document.getElementById('ds-nmap-origin').value;
            document.getElementById('deep-scan-modal').classList.add('hidden'); document.getElementById('securityTerm').innerHTML = '';
            startStatusPulse('Initializing Deep Batch Engine');
            socket.emit('run-deep-scan', { domains, nmapOrigin, targetServerId: activeServerId });
        }

        function startStatusPulse(initialText) {
            const container = document.getElementById('scan-status-container');
            const textEl = document.getElementById('scan-status-text');
            const dotsEl = document.getElementById('scan-status-dots');
            textEl.innerText = initialText || 'Running Security Audit';
            container.classList.remove('hidden');
            clearInterval(dotInterval); dotCount = 0;
            dotInterval = setInterval(() => { dotCount = (dotCount + 1) % 6; dotsEl.innerText = '.'.repeat(dotCount); }, 350);
        }

        function updateStatusPulse(newText) { const textEl = document.getElementById('scan-status-text'); if (textEl) textEl.innerText = newText; }
        function stopStatusPulse() { clearInterval(dotInterval); const container = document.getElementById('scan-status-container'); if (container) container.classList.add('hidden'); }

        function exportVault() {
            if (serversData.length === 0) return alert('Your vault is empty.');
            const safeData = serversData.map(s => { const { encryptedPassphrase, passphrase, tempPlaintext, ...rest } = s; return rest; });
            const blob = new Blob([JSON.stringify(safeData, null, 2)], { type: 'application/json' }); const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `bastioncc-vault-${new Date().toISOString().slice(0,10)}.json`; a.click(); URL.revokeObjectURL(a.href);
        }
        function importVault(e) {
            const file = e.target.files[0]; if (!file) return; const reader = new FileReader();
            reader.onload = async (event) => {
                try {
                    const imported = JSON.parse(event.target.result); if (!Array.isArray(imported)) throw new Error('Invalid JSON.');
                    if (confirm(`Import ${imported.length} server configurations?`)) { imported.forEach(srv => { delete srv.passphrase; delete srv.encryptedPassphrase; srv.id = 'srv_' + Math.random().toString(36).substr(2, 9); socket.emit('save-server', srv); }); alert('Vault import complete.'); }
                } catch (err) { alert('Error parsing JSON.'); } e.target.value = ''; 
            }; reader.readAsText(file);
        }

        function toggleCustomKeyPath() { const sel = document.getElementById('frm-key-type'), cust = document.getElementById('frm-key-custom'); if (sel.value === 'custom') cust.classList.remove('hidden'); else { cust.classList.add('hidden'); cust.value = ''; } }
        function openChangelog() { document.getElementById('changelog-backdrop').classList.remove('hidden'); setTimeout(() => document.getElementById('changelog-drawer').classList.remove('translate-x-full'), 10); }
        function closeChangelog() { document.getElementById('changelog-drawer').classList.add('translate-x-full'); setTimeout(() => document.getElementById('changelog-backdrop').classList.add('hidden'), 300); }
        function openPinReset() { document.getElementById('reset-current').value = ''; document.getElementById('reset-new').value = ''; document.getElementById('reset-confirm').value = ''; document.getElementById('pin-reset-modal').classList.remove('hidden'); }
        function closePinReset() { document.getElementById('pin-reset-modal').classList.add('hidden'); }

        async function handlePinReset(e) {
            e.preventDefault(); const cur = document.getElementById('reset-current').value, newP = document.getElementById('reset-new').value, conf = document.getElementById('reset-confirm').value;
            if (newP !== conf) return alert('New PINs do not match!'); if (newP.length < 4) return alert('New PIN must be at least 4 characters.');
            try { const res = await fetch('/api/reset-pin', { method: 'POST', headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + authToken }, body: JSON.stringify({ currentPin: cur, newPin: newP }) }); const data = await res.json(); if (data.success) { alert('Master PIN changed. Vault re-keyed. You will now be logged out.'); logout(); } else alert(data.message || 'PIN Reset Failed.'); } catch (err) { alert('Network error.'); }
        }

        function toggleSidebar() {
            const sb = document.getElementById('sidebar');
            if (sb.classList.contains('w-64')) { sb.classList.remove('w-64'); sb.classList.add('w-0'); sb.classList.remove('border-r'); } else { sb.classList.remove('w-0'); sb.classList.add('w-64'); sb.classList.add('border-r'); }
            setTimeout(() => { if (fitAddon && term) try { fitAddon.fit(); } catch(e){} if (logFitAddon && logTerm) try { logFitAddon.fit(); } catch(e){} }, 310);
        }

        function logout() { if (socket) socket.disconnect(); window.location.reload(); }
        function emergencyLock() { if (confirm("🚨 EMERGENCY LOCK 🚨\n\nProceed?")) { if (socket) socket.emit('emergency-lock'); setTimeout(() => logout(), 200); } }

        async function handleSetup(e) {
            e.preventDefault(); const pin = document.getElementById('setup-pass').value, conf = document.getElementById('setup-pass-confirm').value;
            if (pin !== conf) return alert('PINs do not match!');
            const data = await (await fetch('/api/setup', { method: 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ pin }) })).json();
            if (data.success) { authToken = data.token; currentPin = pin; document.getElementById('login-screen').classList.add('hidden'); document.getElementById('login-screen').classList.remove('flex'); initSocket(authToken, currentPin); }
        }

        async function handleLogin(e) {
            e.preventDefault(); const pin = document.getElementById('login-pass').value;
            const data = await (await fetch('/api/login', { method: 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ pin }) })).json();
            if (data.success) { authToken = data.token; currentPin = pin; document.getElementById('login-screen').classList.add('hidden'); document.getElementById('login-screen').classList.remove('flex'); initSocket(authToken, currentPin); }
        }

        function initSocket(token, pin) {
            socket = io({ auth: { token, pin } });
            const termContainer = document.getElementById('view-terminal'); termContainer.classList.remove('hidden');
            term = new Terminal({ theme: { background: '#0f172a', foreground: '#f8fafc' }, convertEol: true }); fitAddon = new FitAddon.FitAddon(); term.loadAddon(fitAddon); term.open(termContainer);
            modalTerm = new Terminal({ theme: { background: '#0f172a', foreground: '#f8fafc' }, convertEol: true }); modalFitAddon = new FitAddon.FitAddon(); modalTerm.loadAddon(modalFitAddon); modalTerm.open(document.getElementById('view-modal-terminal'));
            logTerm = new Terminal({ theme: { background: '#0f172a', foreground: '#f8fafc' }, convertEol: true, disableStdin: true }); logFitAddon = new FitAddon.FitAddon(); logTerm.loadAddon(logFitAddon); logTerm.open(document.getElementById('log-terminal'));
            
            const secContainer = document.getElementById('securityTerm');
            term.onResize(size => socket.emit('terminal-resize', { cols: size.cols, rows: size.rows }));
            setTimeout(() => { try { fitAddon.fit(); logFitAddon.fit(); } catch(e) {} }, 50);
            
            window.addEventListener('resize', () => {
                if(!document.getElementById('view-terminal').classList.contains('hidden')) try { fitAddon.fit(); } catch(e) {}
                if(!document.getElementById('view-logs').classList.contains('hidden')) try { logFitAddon.fit(); } catch(e) {}
                if(!document.getElementById('diagnostics-modal').classList.contains('hidden')) try { modalFitAddon.fit(); } catch(e) {}
            });
            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape' && !document.getElementById('diagnostics-modal').classList.contains('hidden')) closeDiagnostics();
                if (e.key === 'Escape' && !document.getElementById('changelog-drawer').classList.contains('translate-x-full')) closeChangelog();
                if (e.key === 'Escape' && !document.getElementById('pin-reset-modal').classList.contains('hidden')) closePinReset();
                if (e.key === 'Escape' && !document.getElementById('totp-modal').classList.contains('hidden')) document.getElementById('totp-modal').classList.add('hidden');
            });

            socket.on('ssh-keyboard-interactive', (data) => {
                currentTotpServerId = data.id;
                document.getElementById('totp-title').innerText = data.name || 'Authentication Required';
                document.getElementById('totp-prompt').innerText = (data.prompts && data.prompts[0]) ? data.prompts[0].prompt : 'Enter your 2FA code:';
                document.getElementById('totp-input').value = '';
                document.getElementById('totp-input').type = (data.prompts && data.prompts[0] && !data.prompts[0].echo) ? 'password' : 'text';
                document.getElementById('totp-modal').classList.remove('hidden');
                setTimeout(() => document.getElementById('totp-input').focus(), 100);
            });

            term.onData(data => socket.emit('terminal-input', data));
            socket.on('terminal-data', data => term.write(data)); socket.on('modal-data', data => modalTerm.write(data));
            
            socket.on('security-data', data => { const rawFormat = String(data).replace(/\n/g, '<br>').replace(/\x1b\[[0-9;]*m/g, ''); secContainer.innerHTML += `<div>${rawFormat}</div>`; secContainer.parentElement.scrollTop = secContainer.parentElement.scrollHeight; });
            socket.on('security-status', (text) => updateStatusPulse(text));
            socket.on('security-complete', stopStatusPulse);
            
            socket.on('rootkit-missing', () => { document.getElementById('rootkit-install-modal').classList.remove('hidden'); });

            socket.on('deep-scan-complete', (htmlContent) => {
                stopStatusPulse();
                const blob = new Blob([htmlContent], { type: 'text/html' }), a = document.createElement('a');
                a.href = URL.createObjectURL(blob); a.download = `BastionCC_DeepAudit_${new Date().toISOString().slice(0,10)}.html`; a.click(); URL.revokeObjectURL(a.href);
            });

            socket.on('log-data', data => {
                if(!data) return; const filter = document.getElementById('log-grep-input').value.toLowerCase(), parts = data.split(/\r?\n/);
                if(parts.length === 1) currentLogPartial += parts[0];
                else {
                    liveLogLines.push(currentLogPartial + parts[0]);
                    for(let i=1; i<parts.length - 1; i++) liveLogLines.push(parts[i]);
                    currentLogPartial = parts[parts.length - 1];
                }
                if(liveLogLines.length > 3000) liveLogLines = liveLogLines.slice(-3000);
                if(filter) {
                    const newLines = [currentLogPartial + parts[0], ...parts.slice(1, -1)].filter(line => line.toLowerCase().includes(filter)).join('\r\n');
                    if(newLines) logTerm.write((liveLogLines.length===1 ? '' : '\r\n') + newLines);
                } else logTerm.write(data);
            });

            socket.on('log-folder-data', ({ folderPath, files, buttonId }) => {
                const bw = document.getElementById(buttonId); if (!bw) return; let dd = bw.querySelector('.folder-dropdown');
                if (!dd) { dd = document.createElement('div'); dd.className = "folder-dropdown absolute top-[calc(100%+4px)] left-0 mt-1 w-64 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg shadow-xl z-10 max-h-64 overflow-y-auto no-scrollbar"; bw.appendChild(dd); }
                if (files.length === 0) dd.innerHTML = `<div class="p-3 text-xs text-slate-500 italic">No logs found.</div>`;
                else {
                    const cleanPath = folderPath.replace(/\/$/, '');
                    dd.innerHTML = files.map(f => `<div data-path="${escapeHtml(cleanPath)}/${escapeHtml(f)}" class="log-file-item p-2 border-b border-slate-100 dark:border-slate-700 text-xs font-mono cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-700 transition truncate">${escapeHtml(f)}</div>`).join('');
                    dd.querySelectorAll('.log-file-item').forEach(el => el.addEventListener('click', (ev) => { ev.stopPropagation(); fetchLog('file', el.dataset.path); closeAllDropdowns(); }));
                }
                closeAllDropdowns(); dd.classList.remove('hidden');
            });

            socket.on('server-stats', data => { document.getElementById('telemetry-bar').classList.remove('hidden'); document.getElementById('stat-cpu').innerText = data.cpu; document.getElementById('stat-ram').innerText = data.ram; document.getElementById('stat-ip').innerText = data.ip; });
            socket.on('docker-data', data => {
                if (!data.ps || data.ps.length === 0) currentDockerRaw = [];
                else currentDockerRaw = data.ps.map(p => { const stat = (data.stats || []).find(s => s.Name === p.Names) || { CPUPerc: '--', MemUsage: '--' }; return { ...p, CPUPerc: stat.CPUPerc, MemUsage: stat.MemUsage }; });
                renderDockerGrid();
            });

            socket.on('servers-list', (list) => { serversData = list; renderSidebar(); updateCloneDropdowns(); });
            socket.on('ssh-status', (data) => { document.querySelectorAll('.srv-indicator').forEach(el => { el.classList.add('hidden'); el.classList.remove('anim-connected'); }); const ind = document.getElementById('ind-' + data.id); if (ind) { ind.classList.remove('hidden'); ind.classList.add('anim-connected'); } switchTab('terminal'); term.focus(); });
            
            socket.on('sftp-list-data', renderSftpGrid);
            socket.on('sftp-download-chunk', ({chunk}) => downloadedChunks.push(new Uint8Array(chunk)));
            socket.on('sftp-download-complete', (filePath) => { const blob = new Blob(downloadedChunks), url = window.URL.createObjectURL(blob), a = document.createElement('a'); a.href = url; a.download = filePath.split('/').pop(); a.click(); window.URL.revokeObjectURL(url); downloadedChunks = []; });
            socket.on('sftp-upload-complete', () => socket.emit('sftp-list', currentSftpPath));
            socket.on('connect_error', (err) => { if (err.message === 'System requires setup' || err.message === 'Invalid token') logout(); });
        }

        function closeAllDropdowns() { document.querySelectorAll('.folder-dropdown').forEach(el => el.classList.add('hidden')); }
        function confirmRootkitInstall() { document.getElementById('rootkit-install-modal').classList.add('hidden'); document.getElementById('securityTerm').innerHTML = ''; startStatusPulse('Auto-Installing Rootkit Scanners'); socket.emit('install-rootkit'); }

        function runSecurityScan(type) {
            if (!activeServerId && type === 'nmap') return alert('Please select a target server from the sidebar first.');
            document.getElementById('securityTerm').innerHTML = '';
            startStatusPulse(`Initiating ${type.toUpperCase()}`);
            const payload = { type, targetServerId: activeServerId };
            if (type === 'nmap') { payload.flags = document.getElementById('sec-nmap-flags').value; payload.origin = document.getElementById('sec-nmap-origin').value; } 
            else if (type === 'curl' || type === 'ssl') payload.targetUrl = document.getElementById('sec-curl-url').value;
            socket.emit('security-scan', payload);
        }

        function initUfwCheck() { const srv = serversData.find(s => s.id === activeServerId); if (srv && srv.dockerEnabled !== false) document.getElementById('ufw-docker-modal').classList.remove('hidden'); else runSecurityScan('ufw-status'); }
        function executeUfwScan(isSecured) { document.getElementById('ufw-docker-modal').classList.add('hidden'); if (isSecured) runSecurityScan('ufw-status'); else runSecurityScan('ufw-check'); }

        function renderFilteredLogs() {
            logTerm.clear(); const activeFilter = document.getElementById('log-grep-input').value.toLowerCase();
            logTerm.write(liveLogLines.filter(line => !activeFilter || line.toLowerCase().includes(activeFilter)).join('\r\n') + (currentLogPartial ? '\r\n' + currentLogPartial : ''));
        }

        function fetchLog(type, path) { logTerm.clear(); logTerm.writeln(`\x1b[36mFetching [${type}]: ${path}...\x1b[0m\r\n`); socket.emit('fetch-server-log', { type, path }); }
        function scanLogFolder(path, btn, e) { e.stopPropagation(); socket.emit('scan-log-folder', { path, buttonId: btn.parentElement.id }); }
        function sortDocker(col) { if (dSort.col === col) dSort.dir *= -1; else { dSort.col = col; dSort.dir = 1; } renderDockerGrid(); }

        function renderDockerGrid() {
            const grid = document.getElementById('docker-grid');
            if (currentDockerRaw.length === 0) { grid.innerHTML = ''; document.getElementById('docker-empty-state').classList.remove('hidden'); return; }
            document.getElementById('docker-empty-state').classList.add('hidden');
            ['name', 'image', 'cpu'].forEach(c => { const el = document.getElementById('sort-ind-' + c); if (el) el.innerText = dSort.col === c ? (dSort.dir === 1 ? '▲' : '▼') : ''; });

            const sortedData = [...currentDockerRaw].sort((a, b) => {
                let vA, vB;
                if (dSort.col === 'name') { vA = a.Names.toLowerCase(); vB = b.Names.toLowerCase(); } else if (dSort.col === 'image') { vA = a.Image.toLowerCase(); vB = b.Image.toLowerCase(); } else if (dSort.col === 'cpu') { vA = parseFloat(a.CPUPerc) || 0; vB = parseFloat(b.CPUPerc) || 0; }
                if (vA < vB) return -1 * dSort.dir; if (vA > vB) return 1 * dSort.dir; return 0;
            });

            grid.innerHTML = sortedData.map(p => `
                <tr class="border-b border-slate-200 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td class="px-4 py-3"><div class="flex items-center space-x-3"><div class="w-2.5 h-2.5 rounded-full ${p.State === 'running' ? 'bg-emerald-500' : 'bg-slate-500'} shrink-0 shadow-sm"></div><div><div class="font-bold text-slate-800 dark:text-slate-200">${escapeHtml(p.Names)}</div><div class="text-xs opacity-70">${escapeHtml(p.Status)}</div></div></div></td>
                    <td class="px-4 py-3 font-mono text-xs opacity-80">${escapeHtml(p.Image)}</td>
                    <td class="px-4 py-3 text-center"><div class="text-xs font-bold text-slate-700 dark:text-slate-300">${p.CPUPerc}</div><div class="text-[10px] opacity-70">${p.MemUsage}</div></td>
                    <td class="px-4 py-3 text-right whitespace-nowrap"><div class="flex items-center justify-end space-x-1.5">
                        <button data-action="start" data-container="${escapeHtml(p.Names)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-slate-200 dark:bg-slate-700 hover:bg-emerald-500 hover:text-white transition"><svg class="w-4 h-4 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path></svg></button>
                        <button data-action="stop" data-container="${escapeHtml(p.Names)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-slate-200 dark:bg-slate-700 hover:bg-amber-500 hover:text-white transition"><svg class="w-4 h-4 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg></button>
                        <button data-action="restart" data-container="${escapeHtml(p.Names)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-slate-200 dark:bg-slate-700 hover:bg-blue-500 hover:text-white transition"><svg class="w-4 h-4 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg></button>
                        <span class="inline-block w-px h-4 bg-slate-300 dark:bg-slate-600 mx-1"></span>
                        <button data-action="console" data-container="${escapeHtml(p.Names)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-slate-200 dark:bg-slate-700 hover:bg-indigo-500 hover:text-white transition font-mono text-xs font-bold leading-none">>_</button>
                        <button data-action="logs" data-container="${escapeHtml(p.Names)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-slate-200 dark:bg-slate-700 hover:bg-purple-500 hover:text-white transition"><svg class="w-4 h-4 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg></button>
                        <button data-action="scan" data-image="${escapeHtml(p.Image)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-slate-200 dark:bg-slate-700 hover:bg-cyan-500 hover:text-white transition"><svg class="w-4 h-4 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg></button>
                        <span class="inline-block w-px h-4 bg-slate-300 dark:bg-slate-600 mx-1"></span>
                        <button data-action="remove" data-container="${escapeHtml(p.Names)}" class="docker-btn flex items-center justify-center w-7 h-7 rounded bg-rose-100 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 hover:bg-rose-500 hover:text-white transition"><svg class="w-4 h-4 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg></button>
                    </div></td>
                </tr>
            `).join('');
            grid.querySelectorAll('.docker-btn').forEach(btn => btn.addEventListener('click', () => { const a = btn.dataset.action, c = btn.dataset.container, i = btn.dataset.image; if (a === 'console') execDocker(c); else if (a === 'logs') viewLogs(c); else if (a === 'scan') scanDocker(i); else if (a === 'remove') { if(confirm(`Force Stop & Remove ${c}?`)) socket.emit('docker-action', { action: a, container: c }); } else socket.emit('docker-action', { action: a, container: c }); }));
        }

        function viewLogs(c) { document.getElementById('diag-title').innerText = `Logs: ${c}`; document.getElementById('diagnostics-modal').classList.remove('hidden'); modalTerm.clear(); setTimeout(() => { try { modalFitAddon.fit(); } catch(e){} }, 150); socket.emit('docker-logs', { container: c }); }
        function scanDocker(i) { document.getElementById('diag-title').innerText = `Grype Scan: ${i}`; document.getElementById('diagnostics-modal').classList.remove('hidden'); modalTerm.clear(); setTimeout(() => { try { modalFitAddon.fit(); } catch(e){} }, 150); socket.emit('docker-scan', { image: i }); }
        function closeDiagnostics() { document.getElementById('diagnostics-modal').classList.add('hidden'); }
        function execDocker(c) { switchTab('terminal'); socket.emit('terminal-input', `docker exec -it ${c} /bin/bash || docker exec -it ${c} /bin/sh\r`); term.focus(); }

        function switchTab(tab) {
            document.getElementById('view-add-server').classList.add('hidden');
            document.getElementById('macro-buttons').classList.add('hidden');
            ['terminal', 'files', 'docker', 'logs', 'security'].forEach(t => { document.getElementById('view-'+t).classList.add('hidden'); document.getElementById('view-'+t).classList.remove('flex'); document.getElementById('tab-'+t).className = "text-sm font-semibold text-slate-500 pb-1 transition-colors" + (document.getElementById('tab-'+t).classList.contains('hidden') ? ' hidden' : ''); });
            const actCls = "text-sm font-semibold text-accent border-b-2 border-accent pb-1 transition-colors";
            if(tab === 'terminal') { document.getElementById('view-terminal').classList.remove('hidden'); document.getElementById('tab-terminal').className = actCls; document.getElementById('macro-buttons').classList.remove('hidden'); if(term) setTimeout(() => { try { fitAddon.fit(); } catch(e){} }, 50); } 
            else if (tab === 'files') { document.getElementById('view-files').classList.remove('hidden'); document.getElementById('view-files').classList.add('flex'); document.getElementById('tab-files').className = actCls; socket.emit('sftp-list', currentSftpPath); } 
            else if (tab === 'docker') { document.getElementById('view-docker').classList.remove('hidden'); document.getElementById('view-docker').classList.add('flex'); document.getElementById('tab-docker').className = actCls; } 
            else if (tab === 'logs') { document.getElementById('view-logs').classList.remove('hidden'); document.getElementById('view-logs').classList.add('flex'); document.getElementById('tab-logs').className = actCls; if(logTerm) setTimeout(() => { try { logFitAddon.fit(); } catch(e){} }, 50); } 
            else if (tab === 'security') { document.getElementById('view-security').classList.remove('hidden'); document.getElementById('view-security').classList.add('flex'); document.getElementById('tab-security').className = actCls; }
        }

        function renderSidebar() {
            const list = document.getElementById('server-list');
            list.innerHTML = serversData.map(s => `
                <div data-id="${s.id}" class="server-item p-2.5 rounded-lg border-b border-slate-200 dark:border-slate-800/60 cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800 transition flex justify-between items-center group mb-1">
                    <span class="text-sm font-medium truncate pr-2 pointer-events-none">${escapeHtml(s.name)}</span>
                    <div class="flex items-center space-x-2 shrink-0 pointer-events-none">
                        <span id="ind-${s.id}" class="srv-indicator hidden origin-center text-[9px] font-bold uppercase tracking-widest bg-emerald-500/10 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30 px-2 py-0.5 rounded-full shadow-sm">CONNECTED</span>
                        <button data-id="${s.id}" class="edit-server-btn pointer-events-auto opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-accent focus:outline-none"><svg class="w-3.5 h-3.5 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg></button>
                    </div>
                </div>`).join('');
            list.querySelectorAll('.server-item').forEach(el => el.addEventListener('click', () => connectServer(el.dataset.id)));
            list.querySelectorAll('.edit-server-btn').forEach(btn => btn.addEventListener('click', (e) => editServer(btn.dataset.id, e)));
        }

        function updateCloneDropdowns() {
            const h = '<option value="">-- Import From --</option>' + serversData.map(s => `<option value="${s.id}">${escapeHtml(s.name)}</option>`).join('');
            document.getElementById('macro-clone-select').innerHTML = h; document.getElementById('log-clone-select').innerHTML = h;
        }

        function cloneMacros(id) { const s = serversData.find(x => x.id === id); if (s && s.macros) s.macros.forEach(m => addMacroRow(m.label, m.cmd, m.auto)); document.getElementById('macro-clone-select').value = ''; }
        function cloneLogs(id) { const s = serversData.find(x => x.id === id); if (s && s.customLogs) s.customLogs.forEach(l => addLogPathRow(l.label, l.type || 'file', l.path)); document.getElementById('log-clone-select').value = ''; }

        function connectServer(id) {
            const srv = serversData.find(s => s.id === id); activeServerId = srv.id;
            document.getElementById('telemetry-bar').classList.add('hidden'); document.getElementById('stat-cpu').innerText = '--'; document.getElementById('stat-ram').innerText = '--'; document.getElementById('stat-ip').innerText = '--';
            document.getElementById('header-title').innerText = srv.name; document.getElementById('tabs').classList.remove('hidden');
            
            updateNmapDropdown(srv.id);

            if (srv.dockerEnabled !== false) document.getElementById('tab-docker').classList.remove('hidden'); else document.getElementById('tab-docker').classList.add('hidden');
            if (srv.logsEnabled !== false) document.getElementById('tab-logs').classList.remove('hidden'); else document.getElementById('tab-logs').classList.add('hidden');
            if (srv.securityEnabled !== false) document.getElementById('tab-security').classList.remove('hidden'); else document.getElementById('tab-security').classList.add('hidden');
            
            const lc = document.getElementById('log-buttons'); let lh = `<button data-type="systemd" data-path="syslog" class="log-trigger-btn whitespace-nowrap px-4 py-1.5 text-xs font-bold rounded bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 transition">Syslog</button>`;
            (srv.customLogs || []).forEach((l, idx) => {
                if (l.type === 'folder') lh += `<div id="log-btn-wrap-${idx}" class="relative inline-block shrink-0"><button data-type="folder" data-path="${escapeHtml(l.path)}" class="log-trigger-btn whitespace-nowrap px-4 py-1.5 text-xs font-bold rounded bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 flex items-center">${escapeHtml(l.label)} <svg class="w-3 h-3 ml-1 opacity-70 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg></button></div>`;
                else lh += `<button data-type="${l.type}" data-path="${escapeHtml(l.path)}" class="log-trigger-btn shrink-0 whitespace-nowrap px-4 py-1.5 text-xs font-bold rounded bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700">${escapeHtml(l.label)}</button>`;
            }); lc.innerHTML = lh;
            lc.querySelectorAll('.log-trigger-btn').forEach(btn => btn.addEventListener('click', (e) => { if(btn.dataset.type === 'folder') scanLogFolder(btn.dataset.path, btn, e); else fetchLog(btn.dataset.type, btn.dataset.path); }));

            document.getElementById('macro-buttons').innerHTML = (srv.macros || []).map(m => `<button data-cmd="${btoa(m.cmd)}" data-auto="${m.auto}" class="macro-trigger-btn whitespace-nowrap px-3 py-1.5 text-xs font-semibold rounded bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700">${escapeHtml(m.label)}</button>`).join('');
            document.getElementById('macro-buttons').querySelectorAll('.macro-trigger-btn').forEach(btn => btn.addEventListener('click', () => { const cmd = atob(btn.dataset.cmd); socket.emit('terminal-input', btn.dataset.auto === 'true' ? cmd + '\r' : cmd); switchTab('terminal'); term.focus(); }));

            switchTab('terminal'); try { fitAddon.fit(); } catch(e) {} term.clear(); term.writeln(`Connecting to ${escapeHtml(srv.host)}...\r\n`);
            socket.emit('connect-ssh', { ...srv, cols: term.cols || 80, rows: term.rows || 24 });
        }

        function showAddServerForm() {
            editingServerId = null; document.getElementById('telemetry-bar').classList.add('hidden');
            ['name','host','key-custom','passphrase'].forEach(id => document.getElementById('frm-'+id).value = '');
            document.getElementById('frm-port').value = '22'; document.getElementById('frm-user').value = 'root'; document.getElementById('frm-key-type').value = '/root/.ssh/id_ed25519'; document.getElementById('frm-key-custom').classList.add('hidden');
            ['docker','logs','security'].forEach(id => document.getElementById('frm-'+id).checked = true);
            document.getElementById('frm-auth-method').checked = false; toggleAuthMethod();
            document.getElementById('macro-builder').innerHTML = ''; document.getElementById('log-builder').innerHTML = ''; document.getElementById('delete-server-btn').classList.add('hidden');
            ['terminal', 'files', 'docker', 'logs', 'security'].forEach(t => document.getElementById('view-'+t).classList.add('hidden')); document.getElementById('tabs').classList.add('hidden');
            document.getElementById('view-add-server').classList.remove('hidden'); document.getElementById('view-add-server').classList.add('flex');
            document.getElementById('form-header-title').innerText = "Add New Server"; document.getElementById('header-title').innerText = "Configuration"; document.getElementById('macro-buttons').innerHTML = '';
        }

        function editServer(id, event) {
            event.stopPropagation(); editingServerId = id; document.getElementById('telemetry-bar').classList.add('hidden'); document.getElementById('delete-server-btn').classList.remove('hidden');
            const srv = serversData.find(s => s.id === id);
            document.getElementById('frm-name').value = srv.name; document.getElementById('frm-host').value = srv.host; document.getElementById('frm-port').value = srv.port || '22'; document.getElementById('frm-user').value = srv.username || 'root';
            const kp = srv.privateKeyPath || '/root/.ssh/id_ed25519';
            if (['/root/.ssh/id_ed25519', '/root/.ssh/id_rsa', '/root/.ssh/id_ecdsa'].includes(kp)) { document.getElementById('frm-key-type').value = kp; document.getElementById('frm-key-custom').classList.add('hidden'); } else { document.getElementById('frm-key-type').value = 'custom'; document.getElementById('frm-key-custom').value = kp; document.getElementById('frm-key-custom').classList.remove('hidden'); }
            document.getElementById('frm-passphrase').value = '';
            document.getElementById('frm-docker').checked = srv.dockerEnabled !== false; document.getElementById('frm-logs').checked = srv.logsEnabled !== false; document.getElementById('frm-security').checked = srv.securityEnabled !== false;
            document.getElementById('frm-auth-method').checked = srv.authMethod === 'password'; toggleAuthMethod();
            document.getElementById('macro-builder').innerHTML = ''; (srv.macros || []).forEach(m => addMacroRow(m.label, m.cmd, m.auto));
            document.getElementById('log-builder').innerHTML = ''; (srv.customLogs || []).forEach(l => addLogPathRow(l.label, l.type || 'file', l.path));
            ['terminal', 'files', 'docker', 'logs', 'security'].forEach(t => document.getElementById('view-'+t).classList.add('hidden')); document.getElementById('tabs').classList.add('hidden');
            document.getElementById('view-add-server').classList.remove('hidden'); document.getElementById('view-add-server').classList.add('flex');
            document.getElementById('form-header-title').innerText = "Edit Server"; document.getElementById('header-title').innerText = "Configuration"; document.getElementById('macro-buttons').innerHTML = '';
        }

        function deleteServer() { const srv = serversData.find(s => s.id === editingServerId); if (confirm(`⚠️ DELETE SERVER ⚠️\n\nDelete "${srv ? srv.name : 'this server'}"?`)) { socket.emit('delete-server', editingServerId); document.getElementById('view-add-server').classList.add('hidden'); switchTab('terminal'); } }

        function addMacroRow(label = '', cmd = '', auto = true) {
            const div = document.createElement('div'); div.className = "flex space-x-2 macro-row items-center";
            div.innerHTML = `<div class="flex flex-col space-y-0.5 mr-1"><button type="button" class="btn-up text-[10px] leading-none text-slate-400 hover:text-accent">▲</button><button type="button" class="btn-down text-[10px] leading-none text-slate-400 hover:text-accent">▼</button></div><input type="text" value="${escapeHtml(label)}" placeholder="Label" class="m-label w-1/4 px-3 py-1.5 text-sm rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none"><input type="text" value="${escapeHtml(cmd)}" placeholder="Command" class="m-cmd flex-1 px-3 py-1.5 text-sm rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none"><label class="flex items-center space-x-1 text-xs cursor-pointer"><input type="checkbox" class="m-auto cursor-pointer" ${auto ? 'checked' : ''}> <span>Auto-Run</span></label><button type="button" class="btn-del text-rose-500 px-2 font-bold hover:text-rose-600">X</button>`;
            div.querySelector('.btn-up').addEventListener('click', () => moveMacroUp(div)); div.querySelector('.btn-down').addEventListener('click', () => moveMacroDown(div)); div.querySelector('.btn-del').addEventListener('click', () => div.remove()); document.getElementById('macro-builder').appendChild(div);
        }

        function addLogPathRow(label = '', type = 'file', path = '') {
            const div = document.createElement('div'); div.className = "flex flex-col space-y-1 log-row p-3 rounded-lg bg-slate-50 dark:bg-slate-900/40 border border-slate-200 dark:border-slate-800";
            div.innerHTML = `<div class="flex space-x-2 items-center"><div class="flex flex-col space-y-0.5 mr-1"><button type="button" class="btn-up text-[10px] leading-none text-slate-400 hover:text-accent">▲</button><button type="button" class="btn-down text-[10px] leading-none text-slate-400 hover:text-accent">▼</button></div><input type="text" value="${escapeHtml(label)}" placeholder="Label" class="l-label w-1/4 px-3 py-1.5 text-sm rounded bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 outline-none"><select class="l-type w-28 px-2 py-1.5 text-sm rounded bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 outline-none"><option value="file" ${type === 'file' ? 'selected' : ''}>File</option><option value="folder" ${type === 'folder' ? 'selected' : ''}>Folder</option><option value="systemd" ${type === 'systemd' ? 'selected' : ''}>Systemd</option></select><input type="text" value="${escapeHtml(path)}" placeholder="Path or Service" class="l-path flex-1 px-3 py-1.5 text-sm rounded bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-700 outline-none"><button type="button" class="btn-del text-rose-500 px-2 font-bold hover:text-rose-600">X</button></div><div class="log-hint text-[11px] text-slate-400 italic pl-10 ${type === 'systemd' ? '' : 'hidden'}">💡 Systemd Service name only</div>`;
            div.querySelector('.l-type').addEventListener('change', (e) => { const h = e.target.parentElement.parentElement.querySelector('.log-hint'); e.target.value === 'systemd' ? h.classList.remove('hidden') : h.classList.add('hidden'); });
            div.querySelector('.btn-up').addEventListener('click', () => moveMacroUp(div.querySelector('.btn-up'))); div.querySelector('.btn-down').addEventListener('click', () => moveMacroDown(div.querySelector('.btn-down'))); div.querySelector('.btn-del').addEventListener('click', () => div.remove()); document.getElementById('log-builder').appendChild(div);
        }

        function moveMacroUp(el) { const row = el.closest ? el.closest('.macro-row') || el.closest('.log-row') : el.parentElement.parentElement.parentElement; if (row && row.previousElementSibling) row.parentElement.insertBefore(row, row.previousElementSibling); }
        function moveMacroDown(el) { const row = el.closest ? el.closest('.macro-row') || el.closest('.log-row') : el.parentElement.parentElement.parentElement; if (row && row.nextElementSibling) row.parentElement.insertBefore(row.nextElementSibling, row); }

        function saveServer() {
            const macros = Array.from(document.querySelectorAll('.macro-row')).map(r => ({ label: r.querySelector('.m-label').value, cmd: r.querySelector('.m-cmd').value, auto: r.querySelector('.m-auto').checked })).filter(m => m.label && m.cmd);
            const customLogs = Array.from(document.querySelectorAll('.log-row')).map(r => ({ label: r.querySelector('.l-label').value, type: r.querySelector('.l-type').value, path: r.querySelector('.l-path').value })).filter(l => l.label && l.path);
            let finalKeyPath = document.getElementById('frm-key-type').value; if (finalKeyPath === 'custom') finalKeyPath = document.getElementById('frm-key-custom').value;
            const authMethod = document.getElementById('frm-auth-method').checked ? 'password' : 'key';
            socket.emit('save-server', { id: editingServerId, name: document.getElementById('frm-name').value, host: document.getElementById('frm-host').value, port: document.getElementById('frm-port').value, username: document.getElementById('frm-user').value, privateKeyPath: finalKeyPath, passphrase: document.getElementById('frm-passphrase').value, authMethod, dockerEnabled: document.getElementById('frm-docker').checked, logsEnabled: document.getElementById('frm-logs').checked, securityEnabled: document.getElementById('frm-security').checked, macros, customLogs });
            document.getElementById('view-add-server').classList.add('hidden'); switchTab('terminal');
        }

        function renderSftpGrid(data) {
            currentSftpPath = data.path; document.getElementById('sftp-path').innerText = currentSftpPath;
            document.getElementById('sftp-grid').innerHTML = data.items.map(i => `<div data-name="${escapeHtml(i.name)}" data-isdir="${i.isDir}" class="sftp-item p-2 border-b border-slate-200 dark:border-slate-800 text-sm font-mono cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800 flex justify-between transition-colors"><span class="pointer-events-none">${i.isDir ? '📁' : '📄'} ${escapeHtml(i.name)}</span><span class="text-slate-500 pointer-events-none">${i.isDir ? '' : Math.round(i.size/1024)+' KB'}</span></div>`).join('');
            document.getElementById('sftp-grid').querySelectorAll('.sftp-item').forEach(el => el.addEventListener('dblclick', () => { if(el.dataset.isdir === 'true') navDir(el.dataset.name); else downloadFile(el.dataset.name); }));
        }

        function navDir(folder) { const sep = currentSftpPath.endsWith('/') ? '' : '/'; socket.emit('sftp-list', currentSftpPath + sep + folder); }
        function navUp() { const parts = currentSftpPath.split('/').filter(Boolean); parts.pop(); socket.emit('sftp-list', '/' + (parts.length > 0 ? parts.join('/') : '')); }
        function downloadFile(filename) { downloadedChunks = []; const sep = currentSftpPath.endsWith('/') ? '' : '/'; socket.emit('sftp-download', currentSftpPath + sep + filename); }

        const dropZone = document.getElementById('view-files');
        dropZone.addEventListener('dragover', (e) => { e.preventDefault(); dropZone.classList.add('border-accent'); }); dropZone.addEventListener('dragleave', (e) => { e.preventDefault(); dropZone.classList.remove('border-accent'); });
        dropZone.addEventListener('drop', (e) => {
            e.preventDefault(); dropZone.classList.remove('border-accent'); const file = e.dataTransfer.files[0]; if (!file) return;
            const remotePath = currentSftpPath + (currentSftpPath.endsWith('/') ? '' : '/') + file.name; socket.emit('sftp-upload-start', { remotePath });
            const reader = new FileReader(); let offset = 0;
            reader.onload = (e) => { socket.emit('sftp-upload-chunk', { remotePath, chunk: e.target.result }); offset += 65536; if (offset < file.size) readNextChunk(); else socket.emit('sftp-upload-end', { remotePath }); };
            function readNextChunk() { reader.readAsArrayBuffer(file.slice(offset, offset + 65536)); } readNextChunk();
        });
    </script>
</body>
</html>
EOF

echo "✨ BastionCC v1.5.1 Build completed successfully!"
