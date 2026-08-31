#!/bin/bash

echo "🚀 Building BastionCC v1.8.6 (Two-Column Tagged Changelog Grid, Streamlined Sidebar & Updated Branding)..."

mkdir -p server-dashboard/{public,server,data}
cd server-dashboard

# 1. package.json
cat << 'EOF' > package.json
{
  "name": "server-dashboard",
  "version": "1.8.6",
  "main": "server/index.js",
  "scripts": {
    "start": "node server/index.js"
  }
}
EOF

echo "🔒 Verifying dependencies..."
npm install express express-rate-limit socket.io ssh2 jsonwebtoken xterm xterm-addon-fit --save > /dev/null 2>&1

# 2. public/changelog.json (Tagged Full History Archive)
cat << 'EOF' > public/changelog.json
[
  {
    "version": "v1.8.6",
    "badge": "CURRENT RELEASE",
    "borderColor": "border-emerald-500",
    "title": "Syslog Streamer Modernization, PIN Modal Fix & 5-Domain Deep Audit",
    "changes": [
      {
        "tag": "BUG FIX",
        "text": "PIN Reset Modal: Bound openPinReset and closePinReset to the global window scope, fully restoring modal functionality."
      },
      {
        "tag": "CORE",
        "text": "Syslog Streamer Modernization: Upgraded Syslog streaming and deep threat triage to unfiltered journalctl (-n 500 / -n 10000) with legacy /var/log fallbacks."
      },
      {
        "tag": "FEATURE",
        "text": "5-Domain Deep Audits: Expanded target capacity back to 5 concurrent domains for SSL/TLS and HTTP header audit reports."
      },
      {
        "tag": "CORE",
        "text": "Version Bump & Telemetry Sync: Updated application metadata, package schemas, and build telemetry to v1.8.6."
      }
    ]
  },
  {
    "version": "v1.8.5",
    "borderColor": "border-slate-600",
    "title": "Critical Security Hardening & Remote Command Confinement",
    "changes": [
      {
        "tag": "SECURITY",
        "text": "Remote Shell Injection Defense: Enforced strict parameter allowlisting (['ip', 'subnet']) on threat defense execution pipelines, eliminating remote shell injection vectors."
      },
      {
        "tag": "SECURITY",
        "text": "Unified Key Path Confinement: Extracted a centralized key path validator (isValidKeyPath) enforcing strict directory boundaries across SSH connections, Nmap pivots, Deep Batch pivots, and server save routines."
      },
      {
        "tag": "SECURITY",
        "text": "Self-Lockout DNS Resolution: Implemented backend host IP discovery via dns.promises.lookup to accurately identify and protect host WAN addresses from accidental bans."
      },
      {
        "tag": "CORE",
        "text": "Version Bump & Telemetry Sync: Synchronized application metadata, package schemas, and attribution links to v1.8.5."
      }
    ]
  },
  {
    "version": "v1.8.0 – v1.8.4",
    "borderColor": "border-slate-600",
    "title": "Self-Lockout Shield, Triage Context Guidance & Themed UI Enhancements",
    "changes": [
      {
        "tag": "SECURITY",
        "text": "Self-Lockout Protection: Client-side guard automatically disables block actions on host addresses with a 'Host Protected' badge."
      },
      {
        "tag": "UI / UX",
        "text": "Threat Triage Context: Added clear subtext explaining deep 10,000-line reverse proxy error log inspection."
      },
      {
        "tag": "UI / UX",
        "text": "Themed Scrollbars & Grep Clarity: Integrated slim 6px dark-mode scrollbars with orange hover accents and updated grep buffer placeholders."
      },
      {
        "tag": "CORE",
        "text": "Version Bump & Metadata Sync: Upgraded dashboard build metadata and telemetry schemas."
      }
    ]
  },
  {
    "version": "v1.7.9",
    "borderColor": "border-slate-600",
    "title": "Log Grep Buffer Clarity & Themed Scrollbars",
    "changes": [
      {
        "tag": "SECURITY",
        "text": "Host IP Threat Auto-Suppression: Auto-discovers server interface IPs (hostname -I) and resolves hostnames to filter self-referencing IPs from threat triage queues."
      },
      {
        "tag": "UI / UX",
        "text": "Log Grep Buffer Clarity: Updated live log search placeholder to 'Grep (last 500 lines)...' to distinguish live buffer from deep scans."
      },
      {
        "tag": "UI / UX",
        "text": "Custom Themed Scrollbars: Implemented slim 6px dark-mode scrollbars with signature orange hover accents across all panels and modals."
      },
      {
        "tag": "CORE",
        "text": "Version Bump & Metadata Sync: Synchronized system metadata, changelog archive, and telemetry build scripts to v1.8.0."
      }
    ]
  },
  {
    "version": "v1.7.8",
    "borderColor": "border-slate-600",
    "title": "Sidebar Navigation Refinement & Security Action Isolation",
    "changes": [
      {
        "tag": "UI / UX",
        "text": "Sidebar Action Reordering: Grouped Demo Mode directly with AbuseIPDB key configuration."
      },
      {
        "tag": "UI / UX",
        "text": "Security Action Isolation: Added a divider separator and positioned Change PIN directly above Emergency Lock."
      },
      {
        "tag": "CORE",
        "text": "Version Bump & Metadata Sync: Synchronized changelog and system metadata across all layers to v1.8.0."
      }
    ]
  },
  {
    "version": "v1.7.7",
    "borderColor": "border-slate-600",
    "title": "Two-Column Tagged Changelog Grid & Streamlined Navigation",
    "changes": [
      {
        "tag": "UI / UX",
        "text": "Two-Column Changelog Layout: Implemented a fixed-width 76px column grid for categorization badges, providing perfectly left-aligned changelog descriptions."
      },
      {
        "tag": "UI / UX",
        "text": "Expanded Release Drawer: Widened the slide-out history panel to max-w-xl to allow comfortable reading space for multi-line release items."
      },
      {
        "tag": "UI / UX",
        "text": "Streamlined Navigation: Reordered sidebar actions (Config -> AbuseIPDB -> Change PIN -> Demo Mode -> Emergency Lock) and decommissioned redundant Logout button."
      },
      {
        "tag": "CORE",
        "text": "Updated Footer Attribution: Formatted custom branding and positioned the version link directly beneath."
      }
    ]
  },
  {
    "version": "v1.7.6",
    "borderColor": "border-slate-600",
    "title": "Deterministic Demo Mode & Real-Time Text Obfuscation Engine",
    "changes": [
      {
        "tag": "FEATURE",
        "text": "Deterministic Demo Mode: Added an on-the-fly privacy mode that intercepts logs, threat queues, security audits, and modals to mask IPv4 addresses and domains into clean, realistic mock data."
      },
      {
        "tag": "UI / UX",
        "text": "Video-Ready Privacy Toggle: Instant UI switch with persistent state and an on-screen status badge, avoiding messy video blur artifacts."
      },
      {
        "tag": "CORE",
        "text": "Client-Side Zero-Leak Pipeline: Sanitizes live xterm.js log streams and diagnostics output without modifying underlying backend state or defense execution."
      }
    ]
  },
  {
    "version": "v1.7.5",
    "borderColor": "border-slate-600",
    "title": "Server-Side CPU Delta Calculation Engine & Tagged Changelogs",
    "changes": [
      {
        "tag": "CORE",
        "text": "Server-Side CPU Calculation: Offloaded CPU delta parsing to Node.js backend memory cache, computing accurate 5-second interval ticks from /proc/stat."
      },
      {
        "tag": "BUG FIX",
        "text": "Eliminated --% Gauge Bug: Fixed subshell arithmetic parsing errors on minimal Linux distributions and kernel virtualization layers."
      },
      {
        "tag": "UI / UX",
        "text": "Inline Changelog Tags: Restored color-coded category badges ([SECURITY], [FEATURE], [BUG FIX], [UI / UX], [CORE]) across the release history."
      },
      {
        "tag": "CORE",
        "text": "Static Asset Immunity: Confirmed public/changelog.json serves release history reliably without interference from host volume mounts."
      }
    ]
  },
  {
    "version": "v1.7.4",
    "borderColor": "border-slate-600",
    "title": "Static Public Changelog & Telemetry Refactoring",
    "changes": [
      {
        "tag": "CORE",
        "text": "Static Public Changelog: Migrated changelog storage to public/changelog.json to ensure Docker volume mounts never mask the release history drawer."
      },
      {
        "tag": "UI / UX",
        "text": "Dynamic Header Telemetry: Polling multi-metric memory (Used / Total, Free, Cache) with responsive gauge formatting."
      }
    ]
  },
  {
    "version": "v1.7.3",
    "borderColor": "border-slate-600",
    "title": "Decoupled JSON Changelog, Advanced RAM Telemetry & Deep Scan Hardening",
    "changes": [
      {
        "tag": "CORE",
        "text": "Decoupled Release Archive: Migrated full changelog history from HTML into a standalone data schema with dynamic loading."
      },
      {
        "tag": "FEATURE",
        "text": "Comprehensive RAM Telemetry: Expanded memory monitoring to show Total, Used, Cached, and Free memory metrics."
      },
      {
        "tag": "SECURITY",
        "text": "Deep Scan Firewall Timeout: Hardened Step 2 (Firewall Subsystem) with strict non-blocking timeouts to prevent infinite SSH pipe hangs."
      },
      {
        "tag": "UI / UX",
        "text": "Interactive Vector Map Tooltips: Fully resolved marker hover cards showing ISO country name, total bans, and severity tier distribution."
      }
    ]
  },
  {
    "version": "v1.7.2",
    "borderColor": "border-slate-600",
    "title": "Banned IPs Report Integration & Streamlined Architecture",
    "changes": [
      {
        "tag": "FEATURE",
        "text": "Deep Audit Banned IPs Section: Added dedicated Section 4 to Deep Batch HTML exports containing the complete history of manual bans, country origins, defense engines, and severity ratings."
      },
      {
        "tag": "CORE",
        "text": "Decommissioned Rootkit Scanners: Fully removed rkhunter and chkrootkit from backend commands and frontend UI to guarantee 100% non-blocking terminal execution."
      },
      {
        "tag": "UI / UX",
        "text": "Refined UI Styling: Cleaned 1px orange transparent border for the Threats By Country button without emoji prefixes."
      }
    ]
  },
  {
    "version": "v1.7.0 – v1.7.1",
    "borderColor": "border-slate-600",
    "title": "Threats By Country Map & Universal Multi-Engine Firewall Adapter",
    "changes": [
      {
        "tag": "FEATURE",
        "text": "Threats By Country Visual Map: Interactive vector map rendering tiered density markers (Green 1-15, Orange 16-50, Purple 51+)."
      },
      {
        "tag": "SECURITY",
        "text": "Universal Multi-Engine Firewall Adapter: Dynamically detects and adapts commands across UFW, Firewalld, Nftables, and native Iptables."
      },
      {
        "tag": "CORE",
        "text": "Nmap Attribution: Integrated mandatory Nmap Project licensing credits across web dashboards and exported reports."
      }
    ]
  },
  {
    "version": "v1.6.0 – v1.6.8",
    "borderColor": "border-slate-600",
    "title": "Hybrid Threat Severity Scoring & Server-Side WHOIS Relay",
    "changes": [
      {
        "tag": "SECURITY",
        "text": "Hybrid 1–5 scoring engine pairing AbuseIPDB with zero-key local heuristics."
      },
      {
        "tag": "FEATURE",
        "text": "Server-side WHOIS relay eliminating CORS and client-side adblocker issues."
      },
      {
        "tag": "SECURITY",
        "text": "3-Engine ban deduplication across CrowdSec, Fail2ban, and UFW with inline row feedback."
      }
    ]
  },
  {
    "version": "v1.5.0",
    "borderColor": "border-sky-500",
    "title": "Hub-and-Spoke Auditing, Web Header Policy Matrix & Multi-Server Pivots",
    "changes": [
      {
        "tag": "SECURITY",
        "text": "Cross-server hub-and-spoke Nmap auditing through remote pivot nodes."
      },
      {
        "tag": "FEATURE",
        "text": "HTTP security header matrix grading with missing policy recommendations."
      },
      {
        "tag": "SECURITY",
        "text": "SSL/TLS certificate expiration detection and domain triage."
      }
    ]
  },
  {
    "version": "v1.4.0",
    "borderColor": "border-indigo-500",
    "title": "Live Docker Telemetry, Container Controls & Vulnerability Scanner",
    "changes": [
      {
        "tag": "FEATURE",
        "text": "Live streaming of Docker container statuses, memory footprint, and CPU load."
      },
      {
        "tag": "SECURITY",
        "text": "Integrated Grype container image vulnerability scanner modal."
      },
      {
        "tag": "CORE",
        "text": "Container lifecycle actions (start, stop, restart, attach shell, view logs, destroy)."
      }
    ]
  },
  {
    "version": "v1.3.0",
    "borderColor": "border-emerald-500",
    "title": "Full Remote File Explorer, Chunked Stream Uploads & Downloads",
    "changes": [
      {
        "tag": "FEATURE",
        "text": "Dual-pane SFTP file browser with directory tree traversal."
      },
      {
        "tag": "CORE",
        "text": "64KB chunked binary streaming for seamless uploads and downloads."
      },
      {
        "tag": "UI / UX",
        "text": "Drag-and-drop file upload target zone."
      }
    ]
  },
  {
    "version": "v1.2.0",
    "borderColor": "border-amber-500",
    "title": "Interactive Xterm.js Shell & Configurable Macro Automation",
    "changes": [
      {
        "tag": "FEATURE",
        "text": "Full Xterm.js terminal integration with window resize synchronization."
      },
      {
        "tag": "CORE",
        "text": "Custom quick-action macro builder with auto-execution flags and drag-reordering."
      },
      {
        "tag": "UI / UX",
        "text": "Multi-log viewer supporting systemd journalctl, files, and wildcard folders."
      }
    ]
  },
  {
    "version": "v1.1.0",
    "borderColor": "border-rose-500",
    "title": "AES-256-GCM Vault Encryption, Path Traversal Defense & Emergency Lock",
    "changes": [
      {
        "tag": "SECURITY",
        "text": "Master PIN scrypt key derivation and AES-256-GCM authenticated vault storage."
      },
      {
        "tag": "SECURITY",
        "text": "Emergency Lock panic trigger to instantly purge decrypters and disconnect all sessions."
      },
      {
        "tag": "SECURITY",
        "text": "Path traversal guards restricting SSH key access strictly to allowed directories."
      }
    ]
  },
  {
    "version": "v1.0.0",
    "borderColor": "border-slate-500",
    "title": "Initial Production Release: Multi-Server Linux Dashboard",
    "changes": [
      {
        "tag": "CORE",
        "text": "Multi-server fleet management supporting password, SSH key, and TOTP authentication."
      },
      {
        "tag": "FEATURE",
        "text": "Live host resource monitoring (CPU, RAM, and network IPs)."
      },
      {
        "tag": "CORE",
        "text": "Centralized configuration export and import routines."
      }
    ]
  },
  {
    "version": "v0.3.0 – v0.9.0",
    "borderColor": "border-slate-700",
    "title": "Host Telemetry & Systemd Log Streaming Prototype",
    "changes": [
      {
        "tag": "CORE",
        "text": "Early prototype streaming systemd journal output and system metrics over WebSockets."
      },
      {
        "tag": "CORE",
        "text": "Foundational SSH connection multiplexer."
      }
    ]
  }
]
EOF

# 3. Dockerfile
cat << 'EOF' > Dockerfile
FROM node:24-alpine
WORKDIR /app
RUN apk update && apk upgrade --no-cache
RUN apk add --no-cache nmap nmap-scripts curl openssl tzdata whois
ENV TZ=Europe/London
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "server/index.js"]
EOF

# 4. Backend (server/index.js)
echo "⚙️ Writing v1.8.5 Backend..."
cat << 'EOF' > server/index.js
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
app.use('/node_modules/xterm', express.static(path.join(__dirname, '../node_modules/xterm')));
app.use('/node_modules/xterm-addon-fit', express.static(path.join(__dirname, '../node_modules/xterm-addon-fit')));
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
    servers = servers.map(s => { if (s.encryptedPassphrase) s.tempPlaintext = decryptPassphrase(s.encryptedPassphrase, currentPin); return s; });
    
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
    
    servers = servers.map(s => { if (s.tempPlaintext) { s.encryptedPassphrase = encryptPassphrase(s.tempPlaintext, newPin); delete s.tempPlaintext; } return s; });
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
        const req = https.get(url, { headers: { 'User-Agent': 'BastionCC/1.8.6', ...headers }, timeout: 4000 }, (res) => {
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
        const servers = getServers(); servers.forEach(s => delete s.encryptedPassphrase);
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
        if (serverData.privateKeyPath && !isValidKeyPath(serverData.privateKeyPath)) {
            serverData.privateKeyPath = '/root/.ssh/id_ed25519';
        }
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
                    const kPath = pivotSrv.privateKeyPath || '/root/.ssh/id_ed25519';
                    if (!isValidKeyPath(kPath)) { socket.emit('security-data', '\x1b[31mError: Pivot SSH key path restricted.\x1b[0m\r\n'); socket.emit('security-complete'); return; }
                    connectOpts.privateKey = fs.readFileSync(path.resolve(kPath), 'utf8');
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
                        const kPath = pivotSrv.privateKeyPath || '/root/.ssh/id_ed25519';
                        if (!isValidKeyPath(kPath)) return res("Pivot Error: SSH key path restricted.");
                        connectOpts.privateKey = fs.readFileSync(path.resolve(kPath), 'utf8');
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
                const kPath = config.privateKeyPath || '/root/.ssh/id_ed25519';
                if (!isValidKeyPath(kPath)) return socket.emit('terminal-data', '\r\n\x1b[31mConfig Error: Key path restricted.\x1b[0m\r\n');
                connectOpts.privateKey = fs.readFileSync(path.resolve(kPath), 'utf8');
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
server.listen(PORT, '0.0.0.0', () => console.log(`BastionCC v1.8.6 Ready on port ${PORT}`));
EOF

# 5. Frontend (public/index.html)
echo "🎨 Writing v1.8.5 Frontend..."
cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en" class="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BastionCC Control Center</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script>

    // Global PIN Modal Handlers
    // Global PIN Modal Handlers (Targeting original pin-reset-modal)
    window.openPinReset = function() {
        const modal = document.getElementById('pin-reset-modal');
        if (modal) {
            modal.classList.remove('hidden');
            const inp = modal.querySelector('input');
            if (inp) { inp.value = ''; inp.focus(); }
        }
    };

    window.closePinReset = function() {
        const modal = document.getElementById('pin-reset-modal');
        if (modal) modal.classList.add('hidden');
    };

    window.submitPinReset = function() {
        const inp = document.getElementById('pinResetInput');
        const msg = document.getElementById('pinResetMsg');
        const newPin = inp ? inp.value.trim() : '';
        if (!/^[0-9]{4,8}$/.test(newPin)) {
            if (msg) { 
                msg.className = 'text-xs text-center text-rose-400';
                msg.innerText = 'PIN must be between 4 and 8 digits.'; 
                msg.classList.remove('hidden'); 
            }
            return;
        }
        if (typeof socket !== 'undefined' && socket) {
            socket.emit('set-pin', { pin: newPin });
        }
        sessionStorage.setItem('bastion_pin', newPin);
        if (msg) { 
            msg.className = 'text-xs text-center text-emerald-400';
            msg.innerText = 'PIN updated successfully!'; 
            msg.classList.remove('hidden'); 
        }
        setTimeout(() => { window.closePinReset(); }, 800);
    };

 tailwind.config = { darkMode: 'class', theme: { extend: { colors: { darkBg: '#0f172a', darkNav: '#020617', accent: '#f97316' } } } } </script>
    <link rel="stylesheet" href="/node_modules/xterm/css/xterm.css" />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/jsvectormap/dist/css/jsvectormap.min.css" />
    <script src="https://cdn.jsdelivr.net/npm/jsvectormap"></script>
    <script src="https://cdn.jsdelivr.net/npm/jsvectormap/dist/maps/world.js"></script>
    <style>
        :root { --accent-color: #f97316; } .text-accent { color: var(--accent-color); } .bg-accent { background-color: var(--accent-color); } .border-accent { border-color: var(--accent-color); }
        .xterm, .xterm-viewport, .xterm-screen { width: 100% !important; height: 100% !important; }
        .no-scrollbar::-webkit-scrollbar { display: none; } .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        ::-webkit-scrollbar { width: 6px; height: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: #334155; border-radius: 9999px; transition: background-color 0.2s ease; }
        ::-webkit-scrollbar-thumb:hover { background: #f97316; }
        * { scrollbar-width: thin; scrollbar-color: #334155 transparent; }
        *:hover { scrollbar-color: #f97316 transparent; }
        @keyframes expandCenter { 0% { transform: scaleX(0); opacity: 0; } 100% { transform: scaleX(1); opacity: 1; } }
        .anim-connected { animation: expandCenter 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275) forwards; display: inline-block !important; }
        @keyframes slideInDown { 0% { transform: translateY(-100%); opacity: 0; } 100% { transform: translateY(0); opacity: 1; } }
        .toast-animate { animation: slideInDown 0.25s ease-out forwards; }
        .jvm-tooltip { background: #020617 !important; border: 1px solid #f97316 !important; border-radius: 8px !important; color: #f8fafc !important; font-family: monospace !important; padding: 10px 14px !important; box-shadow: 0 10px 25px rgba(0,0,0,0.7) !important; pointer-events: none !important; z-index: 9999 !important; }
    </style>
</head>
<body class="bg-slate-100 text-slate-800 dark:bg-darkBg dark:text-slate-100 h-screen flex overflow-hidden">

    <!-- FLOATING TOAST NOTIFICATION CONTAINER -->
    <div id="toast-container" class="fixed top-5 right-5 z-[110] flex flex-col space-y-2 pointer-events-none"></div>

    <!-- DEMO MODE FLOATING BADGE -->
    <div id="demo-mode-indicator" class="hidden fixed bottom-4 right-6 z-[105] pointer-events-none bg-accent/90 text-slate-950 font-mono font-bold text-xs px-3.5 py-1.5 rounded-full shadow-2xl flex items-center space-x-2 border border-accent/40 animate-pulse">
        <span class="w-2 h-2 rounded-full bg-slate-950"></span>
        <span>DEMO MODE ACTIVE (PII OBFUSCATED)</span>
    </div>

    <!-- THREATS BY COUNTRY VISUAL MAP MODAL -->
    <div id="threat-map-modal" class="fixed inset-0 z-[87] flex items-center justify-center bg-slate-950/85 backdrop-blur-md hidden p-4">
        <div class="bg-white dark:bg-darkNav p-6 rounded-xl w-[85vw] max-w-6xl h-[85vh] shadow-2xl border border-accent/50 relative flex flex-col overflow-hidden">
            <div class="flex justify-between items-center pb-3 border-b border-slate-200 dark:border-slate-800 shrink-0">
                <div>
                    <h2 class="text-lg font-bold text-slate-900 dark:text-white">Threats By Country — Historical Geo-Telemetry</h2>
                    <p class="text-xs text-slate-500">Persistent log of manual ban actions categorized by ISO registry origin</p>
                </div>
                <button onclick="closeThreatMapModal()" class="text-slate-400 hover:text-rose-500 font-bold p-1 rounded">✕</button>
            </div>

            <div class="flex-1 flex flex-col md:flex-row gap-4 p-2 mt-2 min-h-0">
                <div class="flex-1 bg-slate-100 dark:bg-slate-950/80 rounded-xl border border-slate-200 dark:border-slate-800 relative overflow-hidden flex items-center justify-center p-2">
                    <div id="jvm-map-container" class="w-full h-full"></div>
                </div>
                <div class="w-full md:w-72 bg-slate-50 dark:bg-slate-900/60 rounded-xl border border-slate-200 dark:border-slate-800 p-4 flex flex-col shrink-0 overflow-y-auto">
                    <h3 class="text-xs font-bold uppercase tracking-wider text-accent mb-3">Threat Density Tiers</h3>
                    <div class="space-y-2 mb-4 text-xs font-mono">
                        <div class="flex items-center space-x-2"><span class="w-3 h-3 rounded-full bg-emerald-500 inline-block"></span> <span>1 – 15 Threats (Low)</span></div>
                        <div class="flex items-center space-x-2"><span class="w-3 h-3 rounded-full bg-orange-500 inline-block"></span> <span>16 – 50 Threats (Moderate)</span></div>
                        <div class="flex items-center space-x-2"><span class="w-3 h-3 rounded-full bg-purple-500 inline-block"></span> <span>51+ Threats (High Density)</span></div>
                    </div>
                    <h3 class="text-xs font-bold uppercase tracking-wider text-accent mb-2">Top Origin Nations</h3>
                    <div id="top-threat-countries-list" class="space-y-2 flex-1"></div>
                    <div class="pt-3 border-t border-slate-200 dark:border-slate-800 text-[10px] text-slate-400">
                        Zero external API calls. Sourced from local ban audit ledger.
                    </div>
                </div>
            </div>

            <div class="pt-3 border-t border-slate-200 dark:border-slate-800 flex justify-end shrink-0">
                <button onclick="closeThreatMapModal()" class="px-5 py-2 rounded-[10px] text-xs font-bold bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:opacity-90 transition">Close Telemetry</button>
            </div>
        </div>
    </div>

    <!-- ABUSEIPDB CONFIGURATION MODAL -->
    <div id="abuseipdb-modal" class="fixed inset-0 z-[86] flex items-center justify-center bg-slate-950/80 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-7 rounded-xl w-full max-w-xl shadow-2xl border border-accent/50 relative flex flex-col max-h-[90vh] overflow-y-auto">
            <div class="flex justify-between items-center mb-4 border-b border-slate-200 dark:border-slate-800 pb-3">
                <div class="flex items-center space-x-2.5">
                    <svg class="w-5 h-5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path></svg>
                    <h2 class="text-lg font-bold text-slate-900 dark:text-white">AbuseIPDB Threat Intelligence Key</h2>
                </div>
                <button onclick="closeAbuseIpDbModal()" class="text-slate-400 hover:text-rose-500 font-bold p-1 rounded">✕</button>
            </div>

            <div class="space-y-4 text-xs text-slate-600 dark:text-slate-300">
                <div class="bg-slate-100 dark:bg-slate-900/60 p-3.5 rounded-lg border border-slate-200 dark:border-slate-800 leading-relaxed">
                    This feature is only required for WHOIS threat severity modeling. BastionCC includes an autonomous <strong>Local Heuristic model</strong> that operates 100% locally with zero 3rd-party dependencies. If you already have a free <strong>AbuseIPDB API key</strong>, you can enter it below to enable global crowd-sourced threat intelligence.
                </div>

                <div class="overflow-x-auto border border-slate-200 dark:border-slate-800 rounded-lg">
                    <table class="w-full text-left text-[11px]">
                        <thead class="bg-slate-200 dark:bg-slate-800/80 text-slate-700 dark:text-slate-300 font-bold uppercase">
                            <tr>
                                <th class="p-2.5">Feature</th>
                                <th class="p-2.5 text-accent">AbuseIPDB API</th>
                                <th class="p-2.5 text-emerald-500">Local Heuristics</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-200 dark:divide-slate-800">
                            <tr><td class="p-2 font-semibold">Setup</td><td class="p-2">API key required</td><td class="p-2 text-emerald-400 font-bold">Zero-Key Plug & Play</td></tr>
                            <tr><td class="p-2 font-semibold">First-Hit Threat Detection</td><td class="p-2 text-emerald-400 font-bold">Instant global recognition</td><td class="p-2">Requires local hit density</td></tr>
                            <tr><td class="p-2 font-semibold">Daily Query Capacity</td><td class="p-2">1,000 queries / day (Free)</td><td class="p-2 text-emerald-400 font-bold">Unlimited</td></tr>
                            <tr><td class="p-2 font-semibold">Attribution Detail</td><td class="p-2">Specific attack categories</td><td class="p-2">Hit density + Datacenter ASN</td></tr>
                            <tr><td class="p-2 font-semibold">Privacy / Exposure</td><td class="p-2">IP queried via AbuseIPDB</td><td class="p-2 text-emerald-400 font-bold">100% Local / In-Memory</td></tr>
                        </tbody>
                    </table>
                </div>

                <div class="flex items-center justify-between pt-1">
                    <span class="font-semibold text-slate-500">Current Threat Engine:</span>
                    <span id="abuseipdb-status-pill" class="px-2.5 py-1 rounded-full font-bold text-[10px] tracking-wide border bg-slate-200 dark:bg-slate-800 text-slate-400 border-slate-300 dark:border-slate-700">Checking status...</span>
                </div>

                <div class="space-y-2 pt-2 border-t border-slate-200 dark:border-slate-800">
                    <label class="block font-bold text-slate-700 dark:text-slate-300">Enter / Update AbuseIPDB Key</label>
                    <input type="password" id="abuseipdb-key-input" placeholder="Paste your 80-character API key" class="w-full px-3 py-2 text-xs font-mono rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none focus:border-accent">
                </div>
            </div>

            <div class="flex justify-between items-center mt-6 pt-3 border-t border-slate-200 dark:border-slate-800">
                <button id="btn-delete-abuse-key" onclick="deleteAbuseIpDbKey()" class="px-3 py-2 rounded-[10px] text-xs font-bold bg-rose-500/10 text-rose-500 hover:bg-rose-500 hover:text-white border border-rose-500/30 transition hidden">Delete Key</button>
                <div class="flex space-x-2 ml-auto">
                    <button onclick="closeAbuseIpDbModal()" class="px-4 py-2 rounded-[10px] text-xs font-bold bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:opacity-90 transition">Cancel</button>
                    <button onclick="saveAbuseIpDbKey()" class="px-4 py-2 rounded-[10px] text-xs font-bold bg-accent text-white hover:opacity-90 transition shadow-md">Save Key</button>
                </div>
            </div>
        </div>
    </div>

    <!-- THREAT DEFENSE CONFIRMATION MODAL -->
    <div id="defense-modal" class="fixed inset-0 z-[88] flex items-center justify-center bg-slate-950/80 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-7 rounded-xl w-full max-w-xl shadow-2xl border border-rose-500/50 relative flex flex-col">
            <div class="flex items-center space-x-3 mb-4 pb-3 border-b border-slate-200 dark:border-slate-800">
                <span class="w-10 h-10 rounded-lg bg-rose-500/10 text-rose-500 border border-rose-500/30 flex items-center justify-center text-xl font-bold">🛡️</span>
                <div>
                    <h3 class="text-lg font-bold text-slate-900 dark:text-white">Confirm Threat Defense</h3>
                    <p class="text-xs text-slate-500">Autonomous multi-tier enforcement cascade</p>
                </div>
            </div>
            <div class="space-y-4 mb-6 text-sm text-slate-600 dark:text-slate-300">
                <div class="p-4 bg-slate-100 dark:bg-slate-900/70 rounded-lg border border-slate-200 dark:border-slate-800 space-y-2 font-mono">
                    <div class="flex items-center justify-between"><span class="text-slate-400">Target:</span> <span id="defense-target-ip" class="text-rose-500 font-bold text-base"></span></div>
                    <div class="flex items-center justify-between"><span class="text-slate-400">Mode:</span> <span id="defense-target-mode" class="font-semibold text-slate-800 dark:text-slate-200"></span></div>
                    <div id="defense-whois-preview" class="text-xs text-slate-500 pt-2 border-t border-slate-200 dark:border-slate-800"></div>
                </div>
                <div class="text-xs text-slate-500 bg-amber-500/10 dark:bg-amber-500/5 p-3 rounded border border-amber-500/20 flex items-start space-x-2.5">
                    <span class="text-amber-500 font-bold text-base leading-none">⚙️</span>
                    <span><strong>Cascade Strategy:</strong> BastionCC initiates ban enforcement via <strong>CrowdSec</strong>, then <strong>Fail2ban</strong>, falling back to discovered native firewall rules (<strong>UFW / Firewalld / Nftables / Iptables</strong>).</span>
                </div>
            </div>
            <div class="flex space-x-3 pt-2 border-t border-slate-200 dark:border-slate-800">
                <button onclick="closeDefenseModal()" class="w-1/3 py-2.5 rounded-[10px] text-sm font-bold bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 transition">Cancel</button>
                <button id="btn-confirm-defense" onclick="submitDefenseAction()" class="w-2/3 py-2.5 rounded-[10px] text-sm font-bold bg-rose-600 text-white hover:bg-rose-700 transition shadow-lg flex items-center justify-center space-x-2">
                    <span>Confirm Block</span>
                </button>
            </div>
        </div>
    </div>

    <!-- DYNAMIC TWO-COLUMN CHANGELOG DRAWER -->
    <div id="changelog-backdrop" class="fixed inset-0 z-[65] bg-slate-950/50 backdrop-blur-sm hidden transition-opacity" onclick="closeChangelog()"></div>
    <div id="changelog-drawer" class="fixed inset-y-0 right-0 z-[70] w-full max-w-xl bg-white dark:bg-darkNav shadow-2xl border-l border-slate-200 dark:border-slate-800 transform translate-x-full transition-transform duration-300 ease-in-out flex flex-col">
        <div class="p-6 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center bg-slate-50 dark:bg-slate-900 shrink-0">
            <h2 class="text-xl font-bold text-accent">Version Changelog</h2>
            <button onclick="closeChangelog()" class="text-slate-500 hover:text-rose-500 transition-colors font-bold p-1 rounded focus:outline-none"><svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg></button>
        </div>
        <div id="changelog-items-container" class="flex-1 overflow-y-auto p-6 space-y-8 text-sm">
            <div class="text-slate-400 text-xs font-mono text-center py-6">Loading release history...</div>
        </div>
    </div>

    <!-- WHOIS MODAL -->
    <div id="whois-modal" class="fixed inset-0 z-[85] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-7 rounded-xl w-full max-w-xl shadow-2xl border border-accent/50 relative flex flex-col max-h-[85vh]">
            <div class="flex justify-between items-center mb-4 border-b border-slate-200 dark:border-slate-800 pb-3">
                <h2 class="text-lg font-bold text-accent flex items-center" id="whois-title">🌐 IP Intelligence & WHOIS</h2>
                <button onclick="closeWhoisModal()" class="text-slate-400 hover:text-rose-500 font-bold p-1 rounded">✕</button>
            </div>
            <div id="whois-content" class="overflow-y-auto space-y-3 font-mono text-sm text-slate-700 dark:text-slate-300"></div>
            <div class="mt-5 pt-3 border-t border-slate-200 dark:border-slate-800 flex justify-end">
                <button onclick="closeWhoisModal()" class="px-5 py-2 rounded-[10px] text-sm font-bold bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300 hover:opacity-90 transition">Close</button>
            </div>
        </div>
    </div>

    <!-- DEEP SCAN MODAL -->
    <div id="deep-scan-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-[500px] shadow-2xl border border-accent/50 relative">
            <h2 class="text-xl font-bold mb-4 text-accent">Automated Deep Scan</h2>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">This will sequentially execute Full Nmap (-A), Host Firewall, Fail2ban (with bans), CrowdSec (with decisions), and compile your complete Historical Banned IPs audit into a standalone HTML report.</p>
            <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Nmap Scan Origin (Hub-Spoke)</p>
            <select id="ds-nmap-origin" class="w-full px-3 py-2 rounded-[10px] bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm mb-4"><option value="local">Local Host</option></select>
            <p class="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">Web & SSL Targets (Optional)</p>
            <div class="space-y-2 mb-6" id="ds-domains">
                    <input type="text" placeholder="domain1.com" class="w-full px-3 py-2 rounded-[10px] bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
                    <input type="text" placeholder="domain2.com (optional)" class="w-full px-3 py-2 rounded-[10px] bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
                    <input type="text" placeholder="domain3.com (optional)" class="w-full px-3 py-2 rounded-[10px] bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
                    <input type="text" placeholder="domain4.com (optional)" class="w-full px-3 py-2 rounded-[10px] bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
                    <input type="text" placeholder="domain5.com (optional)" class="w-full px-3 py-2 rounded-[10px] bg-slate-50 dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-sm font-mono">
                </div>
            <div class="flex space-x-2">
                <button onclick="document.getElementById('deep-scan-modal').classList.add('hidden')" class="w-1/3 py-2 rounded-[10px] font-bold bg-slate-200 dark:bg-slate-800 hover:opacity-90 transition text-slate-700 dark:text-slate-200">Cancel</button>
                <button onclick="executeDeepScan()" class="w-2/3 py-2 rounded-[10px] font-bold bg-accent text-white hover:opacity-90 transition">Start Batch Audit</button>
            </div>
        </div>
    </div>

    <!-- UFW DOCKER ADVISORY MODAL -->
    <div id="ufw-docker-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-[500px] shadow-2xl border border-amber-500/50 relative">
            <h2 class="text-xl font-bold mb-4 text-amber-500 flex items-center"><svg class="w-6 h-6 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg> Docker & Firewall Advisory</h2>
            <p class="text-sm text-slate-600 dark:text-slate-300 mb-4">Standard firewall rules often do <strong>not</strong> block ports published by Docker containers because Docker inserts its own packet filtering rules ahead of host chains.</p>
            <div class="flex flex-col space-y-3">
                <button onclick="executeFirewallScan(true)" class="w-full py-2 rounded-[10px] font-bold bg-slate-200 dark:bg-slate-800 hover:bg-slate-300 dark:hover:bg-slate-700 transition">Yes, I have secured my Docker ports</button>
                <button onclick="executeFirewallScan(false)" class="w-full py-2 rounded-[10px] font-bold bg-accent text-white hover:opacity-90 transition">Not sure — Please scan for me</button>
                <button onclick="document.getElementById('ufw-docker-modal').classList.add('hidden')" class="w-full py-2 rounded-[10px] font-bold text-slate-500 hover:text-slate-700 dark:hover:text-slate-300 transition mt-2">Cancel</button>
            </div>
        </div>
    </div>

    <!-- PIN RESET MODAL -->
    <div id="pin-reset-modal" class="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-slate-200 dark:border-slate-800 relative">
            <h2 class="text-xl font-bold mb-6 text-center text-accent">Change Master PIN</h2>
            <form onsubmit="handlePinReset(event)" class="space-y-4">
                <input type="password" id="reset-current" placeholder="Current PIN" required class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none">
                <input type="password" id="reset-new" placeholder="New PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none">
                <input type="password" id="reset-confirm" placeholder="Confirm New PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none">
                <div class="flex space-x-2 pt-2"><button type="button" onclick="closePinReset()" class="w-1/2 py-2 rounded-[10px] font-bold bg-slate-200 dark:bg-slate-800 hover:opacity-90 transition">Cancel</button><button type="submit" class="w-1/2 py-2 rounded-[10px] font-bold bg-accent text-white hover:opacity-90 transition">Re-Key Vault</button></div>
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
                <div class="flex space-x-2"><button type="button" onclick="document.getElementById('totp-modal').classList.add('hidden')" class="w-1/3 py-2 rounded-[10px] font-bold bg-slate-200 dark:bg-slate-800 hover:opacity-90 transition">Cancel</button><button type="submit" class="w-2/3 py-2 rounded-[10px] font-bold bg-accent text-white hover:opacity-90 transition">Submit</button></div>
            </form>
        </div>
    </div>

    <div id="login-screen" class="fixed inset-0 z-[90] flex items-center justify-center bg-slate-950/80 backdrop-blur-md hidden flex-col">
        <img src="/bastioncc.png" alt="BastionCC" class="w-full max-w-sm mb-6 drop-shadow-2xl" onerror="this.style.display='none'">
        <div id="login-view" class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-slate-200 dark:border-slate-800 hidden">
            <h2 class="text-xl font-bold mb-6 text-center text-slate-800 dark:text-slate-100">Vault Access</h2>
            <form onsubmit="handleLogin(event)" class="space-y-4">
                <input type="password" id="login-pass" placeholder="Master PIN" required class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono">
                <button type="submit" class="w-full py-2 rounded-[10px] font-bold bg-accent text-white hover:opacity-90 transition">Decrypt & Enter</button>
            </form>
        </div>
        <div id="setup-view" class="bg-white dark:bg-darkNav p-8 rounded-xl w-96 shadow-2xl border border-slate-200 dark:border-slate-800 hidden">
            <h2 class="text-xl font-bold text-accent text-center mb-6">Initialize BastionCC</h2>
            <form onsubmit="handleSetup(event)" class="space-y-4">
                <input type="password" id="setup-pass" placeholder="New Master PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono">
                <input type="password" id="setup-pass-confirm" placeholder="Confirm Master PIN" required minlength="4" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none text-center tracking-widest font-mono">
                <button type="submit" class="w-full py-2 rounded-[10px] font-bold bg-accent text-white hover:opacity-90 transition">Lock & Initialize</button>
            </form>
        </div>
    </div>

    <!-- DIAGNOSTICS MODAL -->
    <div id="diagnostics-modal" class="fixed inset-0 z-[60] flex items-center justify-center bg-slate-950/90 backdrop-blur-sm hidden p-4">
        <div class="bg-darkNav w-[95vw] h-[90vh] rounded-xl shadow-2xl border border-slate-800 flex flex-col overflow-hidden">
            <div class="p-4 border-b border-slate-800 flex justify-between items-center bg-slate-900 shrink-0"><h2 id="diag-title" class="text-lg font-bold text-slate-100 font-mono">Diagnostics Viewer</h2><button onclick="closeDiagnostics()" class="text-rose-500 hover:text-rose-400 font-bold px-3 py-1 rounded-[10px] bg-rose-500/10 transition-colors">Close (ESC)</button></div>
            <div id="view-modal-terminal" class="flex-1 p-2 bg-[#0f172a] relative"></div>
        </div>
    </div>

    <nav id="sidebar" class="w-64 border-r border-slate-200 dark:border-slate-800 flex flex-col transition-all duration-300 ease-in-out bg-white dark:bg-darkNav shrink-0 overflow-hidden">
        <div class="flex items-center justify-center p-6 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/20"><img src="/Bastioncrop.png" alt="BastionCC Badge" class="w-24 h-24 object-contain drop-shadow-lg" onerror="this.style.display='none'"></div>
        <div class="p-4 border-b border-slate-200 dark:border-slate-800 font-bold flex justify-between items-center whitespace-nowrap bg-white dark:bg-darkNav mt-2"><span>Servers</span><button onclick="showAddServerForm()" class="text-xs px-2 py-1 rounded bg-accent text-white hover:opacity-90">+ Add</button></div>
        <div id="server-list" class="flex-1 p-2 space-y-1 overflow-y-auto"></div>
        <div class="p-4 border-t border-slate-200 dark:border-slate-800 flex flex-col space-y-2 whitespace-nowrap shrink-0">
            <div class="flex flex-col space-y-1 mb-1 pb-2 border-b border-slate-200 dark:border-slate-700">
                <div class="text-[10px] font-bold uppercase tracking-wider text-slate-400 text-center mb-1">Server Config Management</div>
                <div class="flex space-x-2">
                    <button onclick="exportVault()" class="w-1/2 py-1.5 flex justify-center items-center text-slate-500 hover:text-accent transition border border-transparent hover:border-slate-200 dark:hover:border-slate-700 rounded bg-slate-50 dark:bg-slate-900/50" title="Export Configs"><svg class="w-3.5 h-3.5 mr-1.5 opacity-70" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3"></path></svg><span class="text-xs font-bold">Export</span></button>
                    <button onclick="document.getElementById('import-upload').click()" class="w-1/2 py-1.5 flex justify-center items-center text-slate-500 hover:text-accent transition border border-transparent hover:border-slate-200 dark:hover:border-slate-700 rounded bg-slate-50 dark:bg-slate-900/50" title="Import Configs"><svg class="w-3.5 h-3.5 mr-1.5 opacity-70" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M5 10l7-7m0 0l7 7m-7-7v18"></path></svg><span class="text-xs font-bold">Import</span></button>
                    <input type="file" id="import-upload" accept=".json" class="hidden" onchange="importVault(event)">
                </div>
            </div>

            <!-- 1. ABUSEIPDB API KEY BUTTON -->
            <button onclick="openAbuseIpDbModal()" class="w-full py-1.5 px-3 flex items-center justify-center space-x-2 text-xs font-semibold rounded-[10px] border border-accent bg-transparent text-slate-700 dark:text-slate-300 hover:bg-accent/10 hover:text-accent transition shadow-sm mb-0.5">
                <svg class="w-3.5 h-3.5 text-accent shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z"></path></svg>
                <span class="truncate">AbuseIPDB API Key</span>
            </button>

            <!-- 2. DEMO MODE TOGGLE -->
            <button onclick="toggleDemoMode()" id="sidebar-demo-btn" class="w-full py-1.5 px-3 flex items-center justify-between text-xs font-semibold rounded-[10px] border border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-900/50 text-slate-700 dark:text-slate-300 hover:border-accent transition shadow-sm mb-0.5">
                <span class="flex items-center space-x-2"><span class="text-sm">🕶️</span> <span>Demo Mode</span></span>
                <span id="demo-toggle-chip" class="text-[9px] font-bold px-1.5 py-0.5 rounded bg-slate-200 dark:bg-slate-800 text-slate-400">OFF</span>
            </button>

            <!-- SEPARATOR BETWEEN UTILITIES & SECURITY ACTIONS -->
            <div class="border-t border-slate-200 dark:border-slate-700/80 my-1"></div>

            <!-- 3. CHANGE PIN -->
            <button onclick="openPinReset()" class="w-full py-1.5 flex justify-center items-center text-slate-500 hover:text-accent transition border border-transparent hover:border-slate-200 dark:hover:border-slate-700 rounded bg-slate-50 dark:bg-slate-900/50 mb-0.5"><svg class="w-4 h-4 mr-1.5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path></svg><span class="text-xs font-bold">Change PIN</span></button>

            <!-- 4. EMERGENCY LOCK (Sole explicit exit action) -->
            <button onclick="emergencyLock()" class="w-full py-1.5 text-xs font-bold rounded bg-rose-100 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 hover:bg-rose-500 hover:text-white transition">Emergency Lock</button>
            
            <div class="flex items-center justify-center pt-2 pb-0.5"><button onclick="document.documentElement.classList.toggle('dark')" class="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition"><svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path></svg></button></div>
            
            <!-- FOOTER ATTRIBUTION WITH DEDICATED VERSION SUB-LINE -->
            <div class="text-center mt-1 text-[10px] text-slate-400 font-medium tracking-wide flex flex-col space-y-0.5">
                <span>Ideas/UI by BigBazookas, realised by Gemini AI</span>
                <div><span onclick="openChangelog()" class="cursor-pointer hover:text-accent font-bold transition">v1.8.6 Changelog</span></div>
            </div>
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
                <div class="flex justify-between items-center mb-2 space-x-4 border-b border-slate-200 dark:border-slate-800 pb-3 flex-wrap gap-y-2">
                    <div id="log-buttons" class="flex space-x-2 overflow-visible items-center"></div>
                    <div class="flex items-center space-x-2 shrink-0">
                        <button id="btn-scan-threats" onclick="scanCurrentLogForThreats()" class="flex items-center space-x-2 px-3 py-1.5 text-xs font-semibold rounded-[10px] border border-accent bg-transparent text-slate-600 dark:text-slate-300 hover:border-accent hover:bg-accent/10 hover:text-accent dark:hover:text-white transition-all shadow-sm">
                            <svg class="w-3.5 h-3.5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                            <span>Scan for Threats</span>
                        </button>
                        <div class="flex space-x-2 shrink-0 items-center bg-slate-100 dark:bg-slate-900 p-1.5 rounded-lg border border-slate-300 dark:border-slate-700">
                            <svg class="w-4 h-4 text-slate-400 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                            <input type="text" id="log-grep-input" placeholder="Grep (last 500 lines)..." class="w-44 px-2 py-0.5 text-sm bg-transparent text-slate-800 dark:text-slate-200 outline-none">
                        </div>
                    </div>
                </div>
                
                <div id="log-terminal-container" class="flex-1 bg-[#0f172a] rounded overflow-hidden p-2 relative flex flex-col min-h-0">
                    <div id="log-terminal" class="flex-1"></div>
                </div>

                <div id="threat-triage-panel" class="hidden mt-3 p-4 bg-slate-50 dark:bg-slate-900/90 border border-amber-500/40 rounded-xl max-h-72 overflow-y-auto shrink-0 shadow-xl transition-all">
                    <div class="flex justify-between items-center mb-3 border-b border-slate-200 dark:border-slate-800 pb-2">
                        <div class="flex items-center space-x-2">
                            <span class="w-2.5 h-2.5 rounded-full bg-amber-500 animate-ping"></span>
                            <div>
                                <h3 class="text-sm font-bold text-amber-500 uppercase tracking-wider flex items-center">🚨 Threat Triage Queue (Top 25 Actionable Threats)</h3>
                                <p class="text-[11px] text-slate-400 mt-1 font-normal tracking-normal lowercase first-letter:capitalize">Deep scan inspects 10,000 log lines. Host WAN or reverse proxy IPs appearing in 401/403 logs are listed for review.</p>
                            </div>
                            <span id="threat-count-badge" class="text-[10px] font-mono px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-400 font-bold"></span>
                        </div>
                        <button onclick="document.getElementById('threat-triage-panel').classList.add('hidden')" class="text-xs text-slate-400 hover:text-rose-500 font-bold px-2 py-1 rounded bg-slate-200 dark:bg-slate-800 transition">✕ Close Queue</button>
                    </div>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left text-xs text-slate-600 dark:text-slate-300 select-none">
                            <thead class="text-[11px] uppercase bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-400">
                                <tr>
                                    <th class="px-3 py-2 rounded-l">Offender IP</th>
                                    <th class="px-3 py-2 text-center">Failed Hits / 401s</th>
                                    <th class="px-3 py-2">Geolocation & ISP</th>
                                    <th class="px-3 py-2 text-right rounded-r">Autonomous Defense</th>
                                </tr>
                            </thead>
                            <tbody id="threat-table-body" class="font-mono"></tbody>
                        </table>
                    </div>
                </div>
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
                        <button onclick="openDeepScanModal()" class="bg-accent text-white px-4 py-2 rounded-[10px] text-sm font-bold shadow hover:bg-orange-600 transition">Deep Batch Scan & Export</button>
                    </div>
                </div>
                
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
                            <div class="flex mb-2">
                                <span class="bg-slate-200 dark:bg-slate-700 px-3 py-2 rounded-l text-sm border-r border-slate-300 dark:border-slate-600 font-mono">nmap</span>
                                <input type="text" id="sec-nmap-flags" placeholder="Custom flags" class="flex-1 bg-slate-50 dark:bg-slate-900 px-3 py-2 text-sm outline-none border-y border-slate-200 dark:border-slate-700 font-mono">
                                <button onclick="runSecurityScan('nmap')" class="bg-accent text-white px-4 py-2 rounded-r text-sm font-bold hover:bg-orange-600 transition">Run</button>
                            </div>
                            <div class="text-[10px] text-slate-400 italic">Nmap Security Scanner is (C) 1996–2026 Nmap Software LLC | https://nmap.org</div>
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
                            <button onclick="runSecurityScan('curl')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded-[10px] hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">Analyze Headers</button>
                            <button onclick="runSecurityScan('ssl')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded-[10px] hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">Check SSL Expiry</button>
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
                            <button onclick="runSecurityScan('fail2ban')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-xs px-2.5 py-2 rounded-[10px] hover:bg-slate-300 dark:hover:bg-slate-700 font-semibold transition">Fail2Ban + Bans</button>
                            <button onclick="runSecurityScan('crowdsec')" class="flex-1 bg-slate-200 dark:bg-slate-800 text-xs px-2.5 py-2 rounded-[10px] hover:bg-slate-300 dark:hover:bg-slate-700 font-semibold transition">CrowdSec</button>
                            <button onclick="openThreatMapModal()" class="flex-1 px-2.5 py-2 text-xs font-semibold rounded-[10px] border border-accent bg-transparent text-slate-700 dark:text-slate-300 hover:bg-accent/10 hover:text-accent transition shadow-sm text-center">Threats By Country</button>
                        </div>
                    </div>

                    <!-- Universal Firewall -->
                    <div class="border border-slate-200 dark:border-slate-700 rounded-lg p-4 bg-white dark:bg-darkNav flex flex-col justify-between shadow-sm">
                        <div>
                            <div class="flex items-center mb-2"><svg class="w-5 h-5 text-accent mr-2" fill="currentColor" viewBox="0 0 640 512"><path d="M0 64c0-17.7 14.3-32 32-32H256v96H0V64zM288 32H608c17.7 0 32 14.3 32 32v64H288V32zM0 160h64v96H0V160zm96 0H384v96H96V160zm320 0H640v96H416V160zM0 288H256v96H0V288zm288 0H640v96H288V288zM0 416h64v64c0 17.7 14.3 32 32 32h160V416H0zm288 0v96H608c17.7 0 32-14.3 32-32V416H288z"/></svg><h3 class="font-bold">Firewall Routing Status</h3></div>
                            <p class="text-xs text-slate-500 mb-3">Auto-Probe: <span class="text-accent">UFW / Firewalld / Nftables / Iptables</span></p>
                            <p class="text-sm mb-4">Inspect live firewall rules on connected node.</p>
                        </div>
                        <button onclick="initFirewallCheck()" class="w-full bg-slate-200 dark:bg-slate-800 text-sm px-3 py-2 rounded-[10px] hover:bg-slate-300 dark:hover:bg-slate-700 font-medium transition">Inspect Active Firewall</button>
                    </div>
                </div>

                <div class="bg-[#1e1e1e] rounded-lg p-4 border border-slate-700 flex-1 overflow-y-auto shadow-inner min-h-[200px]">
                    <div id="securityTerm" class="font-mono text-sm text-sky-400 whitespace-pre">
                        <p class="text-slate-500">BastionCC Security Audit Engine v1.8.5</p>
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
                        <div class="col-span-1">
                            <label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Username</label>
                            <input type="text" id="frm-user" value="root" class="w-full px-4 py-2 rounded bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 outline-none focus:border-accent">
                        </div>
                        <div class="col-span-1">
                            <label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Sudo Privileges</label>
                            <label class="flex items-center space-x-2 cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-3 py-2 rounded border border-slate-200 dark:border-slate-700">
                                <input type="checkbox" id="frm-sudo" checked class="accent-orange-500">
                                <span class="text-xs font-semibold">User is a Member of Sudo</span>
                            </label>
                        </div>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Feature Management</label>
                        <div class="flex space-x-2">
                            <label class="flex items-center space-x-1 text-xs cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700"><input type="checkbox" id="frm-docker" checked> <span>Docker</span></label>
                            <label class="flex items-center space-x-1 text-xs cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700"><input type="checkbox" id="frm-logs" checked> <span>Logs</span></label>
                            <label class="flex items-center space-x-1 text-xs cursor-pointer bg-slate-100 dark:bg-slate-800/50 px-2 py-1.5 rounded border border-slate-200 dark:border-slate-700"><input type="checkbox" id="frm-security" checked> <span>Security</span></label>
                        </div>
                    </div>
                    
                    <div class="mt-2 mb-2 p-3 bg-slate-50 dark:bg-slate-900/50 rounded border border-slate-200 dark:border-slate-800">
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
        let activeLogSource = { type: 'systemd', path: 'syslog' };
        const whoisCache = new Map();
        let pendingDefense = { ip: null, mode: null, rowIndex: null };
        let activeVectorMap = null;

        // --- DETERMINISTIC DEMO MODE OBFUSCATION ENGINE ---
        let isDemoMode = localStorage.getItem('bastioncc_demo_mode') === 'true';
        const demoIpMap = new Map();
        let demoIpCounter = 10;

        function getDeterministicMockIp(realIp) {
            if (!demoIpMap.has(realIp)) {
                demoIpCounter++;
                const oct3 = Math.floor(demoIpCounter / 250);
                const oct4 = (demoIpCounter % 250) + 1;
                demoIpMap.set(realIp, `10.0.${oct3}.${oct4}`);
            }
            return demoIpMap.get(realIp);
        }

        function maskDemoText(text) {
            if (!isDemoMode || !text) return text;
            const str = String(text);
            const ipRegex = /\b(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b/g;
            const domainRegex = /https?:\/\/([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g;
            
            let masked = str.replace(domainRegex, (match, host) => {
                return match.replace(host, 'app.demo-internal.net');
            });
            masked = masked.replace(ipRegex, match => getDeterministicMockIp(match));
            return masked;
        }

        function updateDemoModeUI() {
            const chip = document.getElementById('demo-toggle-chip');
            const ind = document.getElementById('demo-mode-indicator');
            if (isDemoMode) {
                chip.innerText = 'ON';
                chip.className = 'text-[9px] font-bold px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30';
                ind.classList.remove('hidden');
            } else {
                chip.innerText = 'OFF';
                chip.className = 'text-[9px] font-bold px-1.5 py-0.5 rounded bg-slate-200 dark:bg-slate-800 text-slate-400';
                ind.classList.add('hidden');
            }
        }

        function toggleDemoMode() {
            isDemoMode = !isDemoMode;
            localStorage.setItem('bastioncc_demo_mode', isDemoMode);
            updateDemoModeUI();
            showToast(isDemoMode ? '🕶️ Demo Mode Enabled (PII Obfuscated)' : 'Demo Mode Disabled (Live Telemetry)');
            if (activeLogSource && activeLogSource.path) renderFilteredLogs();
            renderSidebar();
        }

        function escapeHtml(str) { return String(str).replace(/[&<>"']/g, m => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m])); }

        function showToast(message, type = 'success') {
            const container = document.getElementById('toast-container');
            const toast = document.createElement('div');
            const isSuccess = type === 'success';
            toast.className = `pointer-events-auto flex items-center space-x-2 px-4 py-2.5 rounded-[10px] shadow-2xl text-xs font-semibold text-white border transition-all duration-300 toast-animate ${
                isSuccess ? 'bg-slate-900 border-emerald-500 text-emerald-400' : 'bg-slate-900 border-rose-500 text-rose-400'
            }`;
            toast.innerHTML = `
                <span class="text-sm">${isSuccess ? '✔' : '❌'}</span>
                <span>${escapeHtml(message)}</span>
            `;
            container.appendChild(toast);
            setTimeout(() => {
                toast.style.opacity = '0';
                toast.style.transform = 'translateY(-10px)';
                setTimeout(() => toast.remove(), 300);
            }, 4000);
        }

        window.addEventListener('DOMContentLoaded', async () => {
            updateDemoModeUI();
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

        function getTagBadge(tag) {
            const t = (tag || '').toUpperCase();
            let colorCls = 'bg-slate-500/10 text-slate-400 border-slate-500/30';
            if (t === 'SECURITY') colorCls = 'bg-rose-500/10 text-rose-400 border-rose-500/30';
            else if (t === 'FEATURE') colorCls = 'bg-orange-500/10 text-orange-400 border-orange-500/30';
            else if (t === 'BUG FIX') colorCls = 'bg-amber-500/10 text-amber-400 border-amber-500/30';
            else if (t === 'UI / UX') colorCls = 'bg-sky-500/10 text-sky-400 border-sky-500/30';
            else if (t === 'CORE') colorCls = 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
            return `<span class="w-[76px] text-center text-[9px] font-bold py-0.5 rounded border ${colorCls} uppercase tracking-wide block shrink-0 font-mono select-none">${escapeHtml(t)}</span>`;
        }

        // --- DYNAMIC TWO-COLUMN CHANGELOG LOADER ---
        async function openChangelog() {
            document.getElementById('changelog-backdrop').classList.remove('hidden');
            setTimeout(() => document.getElementById('changelog-drawer').classList.remove('translate-x-full'), 10);
            
            const container = document.getElementById('changelog-items-container');
            try {
                const res = await fetch('/changelog.json');
                const logs = await res.json();
                if (Array.isArray(logs) && logs.length > 0) {
                    container.innerHTML = logs.map(item => `
                        <div class="border-l-4 ${item.borderColor || 'border-slate-600'} pl-4">
                            <h3 class="text-base font-bold text-slate-800 dark:text-white flex items-center">
                                <span>${escapeHtml(item.version)}</span>
                                ${item.badge ? `<span class="text-xs font-bold text-emerald-500 border border-emerald-500/30 bg-emerald-500/10 rounded px-2 ml-2">${escapeHtml(item.badge)}</span>` : ''}
                            </h3>
                            <p class="text-xs text-slate-500 mt-1 font-semibold">${escapeHtml(item.title)}</p>
                            <ul class="text-xs text-slate-700 dark:text-slate-300 mt-3 space-y-2.5 leading-relaxed">
                                ${(item.changes || []).map(c => {
                                    if (typeof c === 'object' && c.tag) {
                                        return `
                                            <li class="grid grid-cols-[76px_1fr] items-start gap-2.5">
                                                ${getTagBadge(c.tag)}
                                                <span class="leading-relaxed">${escapeHtml(c.text)}</span>
                                            </li>
                                        `;
                                    }
                                    return `<li class="list-disc list-inside">${escapeHtml(c)}</li>`;
                                }).join('')}
                            </ul>
                        </div>
                    `).join('');
                } else {
                    container.innerHTML = `<div class="text-slate-400 text-xs font-mono text-center py-6">No changelog records available.</div>`;
                }
            } catch(e) {
                container.innerHTML = `<div class="text-rose-400 text-xs font-mono text-center py-6">Failed to load changelog records.</div>`;
            }
        }

        function closeChangelog() {
            document.getElementById('changelog-drawer').classList.add('translate-x-full');
            setTimeout(() => document.getElementById('changelog-backdrop').classList.add('hidden'), 300);
        }

        // --- THREATS BY COUNTRY VECTOR MAP WITH RELIABLE TOOLTIP RENDERING ---
        function openThreatMapModal() {
            document.getElementById('threat-map-modal').classList.remove('hidden');
            socket.emit('fetch-threat-map-data');
        }

        function closeThreatMapModal() {
            document.getElementById('threat-map-modal').classList.add('hidden');
        }

        function renderVectorThreatMap(countryMap) {
            const container = document.getElementById('jvm-map-container');
            container.innerHTML = '';
            
            const markers = [];
            const topListEl = document.getElementById('top-threat-countries-list');
            topListEl.innerHTML = '';

            const sortedCountries = Object.entries(countryMap).sort((a, b) => b[1].total - a[1].total);

            sortedCountries.forEach(([code, data]) => {
                if (data.coords) {
                    let dotColor = '#22c55e'; // Green for 1-15
                    let dotRadius = 5;
                    if (data.total >= 51) {
                        dotColor = '#a855f7'; // Purple for 51+
                        dotRadius = 9;
                    } else if (data.total >= 16) {
                        dotColor = '#f97316'; // Orange for 16-50
                        dotRadius = 7;
                    }

                    markers.push({
                        name: `<div style="text-align:left; font-family:monospace; min-width:180px;"><div style="font-weight:bold; color:#f97316; border-bottom:1px solid rgba(249,115,22,0.4); padding-bottom:3px; margin-bottom:4px;">${escapeHtml(data.countryName)} (${code})</div><div style="font-weight:bold; color:#f8fafc; margin-bottom:4px;">Total Banned: <span style="color:#fb923c;">${data.total}</span></div><div style="font-size:11px; color:#cbd5e1; line-height:1.4;"><div>🔴 High Threat: <b>${data.breakdown['High (Score 5)']}</b></div><div>🟡 Moderate Threat: <b>${data.breakdown['Moderate (Score 3)']}</b></div><div>🟢 Low Threat: <b>${data.breakdown['Low (Score 1)']}</b></div></div></div>`,
                        coords: data.coords,
                        style: { fill: dotColor, stroke: '#0f172a', strokeWidth: 1.5, r: dotRadius }
                    });
                }
            });

            if (sortedCountries.length === 0) {
                topListEl.innerHTML = `<div class="p-2 text-center text-slate-500 italic text-xs font-mono">No manual bans recorded yet.</div>`;
            } else {
                topListEl.innerHTML = sortedCountries.slice(0, 6).map(([code, data]) => {
                    let badgeClass = 'bg-emerald-500/20 text-emerald-400';
                    if (data.total >= 51) badgeClass = 'bg-purple-500/20 text-purple-400';
                    else if (data.total >= 16) badgeClass = 'bg-orange-500/20 text-orange-400';

                    return `
                        <div class="flex items-center justify-between p-2 rounded bg-white dark:bg-slate-950/40 border border-slate-200 dark:border-slate-800 text-xs font-mono">
                            <span class="font-bold text-slate-800 dark:text-slate-200">${escapeHtml(data.countryName)} (${code})</span>
                            <span class="px-2 py-0.5 rounded font-bold ${badgeClass}">${data.total} bans</span>
                        </div>
                    `;
                }).join('');
            }

            try {
                activeVectorMap = new jsVectorMap({
                    selector: '#jvm-map-container',
                    map: 'world',
                    zoomButtons: true,
                    zoomOnScroll: true,
                    regionStyle: {
                        initial: { fill: '#1e293b', fillOpacity: 0.9, stroke: '#0f172a', strokeWidth: 0.5 },
                        hover: { fill: '#334155' }
                    },
                    markers: markers,
                    onMarkerTooltipShow(event, tooltip, index) {
                        const marker = markers[index];
                        if (marker && marker.name) {
                            if (typeof tooltip.text === 'function') {
                                tooltip.text(marker.name, true);
                            } else if (typeof tooltip.setContent === 'function') {
                                tooltip.setContent(marker.name);
                            }
                        }
                    }
                });
            } catch(e) {
                console.error("Vector map render exception:", e);
            }
        }

        // --- ABUSEIPDB CONFIGURATION LOGIC ---
        async function openAbuseIpDbModal() {
            try {
                const res = await fetch('/api/abuseipdb-status', { headers: { 'Authorization': 'Bearer ' + authToken } });
                const data = await res.json();
                const pill = document.getElementById('abuseipdb-status-pill');
                const delBtn = document.getElementById('btn-delete-abuse-key');
                if (data.hasKey) {
                    pill.className = 'px-2.5 py-1 rounded-full font-bold text-[10px] tracking-wide border bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
                    pill.innerText = '✔ AbuseIPDB Active (Global Intelligence)';
                    delBtn.classList.remove('hidden');
                } else {
                    pill.className = 'px-2.5 py-1 rounded-full font-bold text-[10px] tracking-wide border bg-slate-200 dark:bg-slate-800 text-slate-400 border-slate-300 dark:border-slate-700';
                    pill.innerText = 'Local Heuristics Mode (No Key Set)';
                    delBtn.classList.add('hidden');
                }
                document.getElementById('abuseipdb-key-input').value = '';
                document.getElementById('abuseipdb-modal').classList.remove('hidden');
            } catch(e) { showToast('Error checking AbuseIPDB status.', 'error'); }
        }

        function closeAbuseIpDbModal() { document.getElementById('abuseipdb-modal').classList.add('hidden'); }

        async function saveAbuseIpDbKey() {
            const key = document.getElementById('abuseipdb-key-input').value.trim();
            if (!key) return showToast('Please enter an API key or click Cancel.', 'error');
            try {
                const res = await fetch('/api/abuseipdb-key', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + authToken },
                    body: JSON.stringify({ apiKey: key, pin: currentPin })
                });
                const data = await res.json();
                if (data.success) {
                    whoisCache.clear();
                    showToast('AbuseIPDB Key saved & encrypted.');
                    closeAbuseIpDbModal();
                } else {
                    showToast(data.message || 'Failed to save key.', 'error');
                }
            } catch(e) { showToast('Network error saving key.', 'error'); }
        }

        async function deleteAbuseIpDbKey() {
            try {
                const res = await fetch('/api/abuseipdb-key', {
                    method: 'DELETE',
                    headers: { 'Authorization': 'Bearer ' + authToken }
                });
                const data = await res.json();
                if (data.success) {
                    whoisCache.clear();
                    showToast('AbuseIPDB Key removed. Reverted to local heuristics.');
                    closeAbuseIpDbModal();
                }
            } catch(e) { showToast('Network error deleting key.', 'error'); }
        }

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
            const html = `<option value="local">Local Host</option>` + serversData.map(s => `<option value="${s.id}">${escapeHtml(maskDemoText(s.name))}${s.id === activeId ? ' (Active)' : ''}</option>`).join('');
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
            if (serversData.length === 0) return showToast('Your vault is empty.', 'error');
            const safeData = serversData.map(s => { const { encryptedPassphrase, passphrase, tempPlaintext, ...rest } = s; return rest; });
            const blob = new Blob([JSON.stringify(safeData, null, 2)], { type: 'application/json' }); const a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = `bastioncc-vault-${new Date().toISOString().slice(0,10)}.json`; a.click(); URL.revokeObjectURL(a.href);
        }
        function importVault(e) {
            const file = e.target.files[0]; if (!file) return; const reader = new FileReader();
            reader.onload = async (event) => {
                try {
                    const imported = JSON.parse(event.target.result); if (!Array.isArray(imported)) throw new Error('Invalid JSON.');
                    imported.forEach(srv => { delete srv.passphrase; delete srv.encryptedPassphrase; srv.id = 'srv_' + Math.random().toString(36).substr(2, 9); socket.emit('save-server', srv); });
                    showToast(`Imported ${imported.length} server configurations.`);
                } catch (err) { showToast('Error parsing JSON vault file.', 'error'); } e.target.value = ''; 
            }; reader.readAsText(file);
        }

        function toggleCustomKeyPath() { const sel = document.getElementById('frm-key-type'), cust = document.getElementById('frm-key-custom'); if (sel.value === 'custom') cust.classList.remove('hidden'); else { cust.classList.add('hidden'); cust.value = ''; } }

        function toggleSidebar() {
            const sb = document.getElementById('sidebar');
            if (sb.classList.contains('w-64')) { sb.classList.remove('w-64'); sb.classList.add('w-0'); sb.classList.remove('border-r'); } else { sb.classList.remove('w-0'); sb.classList.add('w-64'); sb.classList.add('border-r'); }
            setTimeout(() => { if (fitAddon && term) try { fitAddon.fit(); } catch(e){} if (logFitAddon && logTerm) try { logFitAddon.fit(); } catch(e){} }, 310);
        }

        function emergencyLock() { socket.emit('emergency-lock'); showToast('🚨 Emergency Lock Executed! Purging session...', 'error'); setTimeout(() => window.location.reload(), 500); }

        async function handleSetup(e) {
            e.preventDefault(); const pin = document.getElementById('setup-pass').value, conf = document.getElementById('setup-pass-confirm').value;
            if (pin !== conf) return showToast('PINs do not match!', 'error');
            const data = await (await fetch('/api/setup', { method: 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ pin }) })).json();
            if (data.success) { authToken = data.token; currentPin = pin; document.getElementById('login-screen').classList.add('hidden'); document.getElementById('login-screen').classList.remove('flex'); initSocket(authToken, currentPin); }
        }

        async function handleLogin(e) {
            e.preventDefault(); const pin = document.getElementById('login-pass').value;
            const data = await (await fetch('/api/login', { method: 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ pin }) })).json();
            if (data.success) { authToken = data.token; currentPin = pin; document.getElementById('login-screen').classList.add('hidden'); document.getElementById('login-screen').classList.remove('flex'); initSocket(authToken, currentPin); }
            else { showToast('Invalid Master PIN', 'error'); }
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
                if (e.key === 'Escape' && !document.getElementById('whois-modal').classList.contains('hidden')) closeWhoisModal();
                if (e.key === 'Escape' && !document.getElementById('defense-modal').classList.contains('hidden')) closeDefenseModal();
                if (e.key === 'Escape' && !document.getElementById('abuseipdb-modal').classList.contains('hidden')) closeAbuseIpDbModal();
                if (e.key === 'Escape' && !document.getElementById('threat-map-modal').classList.contains('hidden')) closeThreatMapModal();
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
            socket.on('terminal-data', data => term.write(data)); 
            socket.on('modal-data', data => modalTerm.write(maskDemoText(data)));
            
            socket.on('security-data', data => { 
                const cleanData = maskDemoText(data);
                const rawFormat = String(cleanData).replace(/\n/g, '<br>').replace(/\x1b\[[0-9;]*m/g, ''); 
                secContainer.innerHTML += `<div>${rawFormat}</div>`; 
                secContainer.parentElement.scrollTop = secContainer.parentElement.scrollHeight; 
            });
            socket.on('security-status', (text) => updateStatusPulse(maskDemoText(text)));
            socket.on('security-complete', stopStatusPulse);

            socket.on('threat-map-data', renderVectorThreatMap);

            socket.on('deep-scan-complete', (htmlContent) => {
                stopStatusPulse();
                const cleanReport = maskDemoText(htmlContent);
                const blob = new Blob([cleanReport], { type: 'text/html' }), a = document.createElement('a');
                a.href = URL.createObjectURL(blob); a.download = `BastionCC_DeepAudit_${new Date().toISOString().slice(0,10)}.html`; a.click(); URL.revokeObjectURL(a.href);
            });

            socket.on('log-data', data => {
                if(!data) return; 
                const rawText = maskDemoText(data);
                const filter = document.getElementById('log-grep-input').value.toLowerCase(), parts = rawText.split(/\r?\n/);
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
                } else logTerm.write(rawText);
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

            // Threat scanner responses
            socket.on('log-threats-result', handleLogThreatsResult);
            socket.on('block-threat-result', handleBlockThreatResult);
            socket.on('whois-result', handleWhoisResult);

            // Server telemetry listener with enhanced RAM formatting and live dynamic CPU tick calculation
            socket.on('server-stats', data => {
                document.getElementById('telemetry-bar').classList.remove('hidden');
                document.getElementById('stat-cpu').innerText = data.cpu || '--%';
                
                if (data.ram) {
                    const params = new URLSearchParams(data.ram);
                    const usedMB = parseInt(params.get('used')) || 0;
                    const totalMB = parseInt(params.get('total')) || 0;
                    const freeMB = parseInt(params.get('free')) || 0;
                    const cacheMB = parseInt(params.get('cache')) || 0;
                    
                    const formatSize = (mb) => mb >= 1024 ? (mb / 1024).toFixed(1) + 'GB' : mb + 'MB';
                    document.getElementById('stat-ram').innerHTML = `
                        <span class="text-slate-200">${formatSize(usedMB)}</span> / <span class="text-slate-400">${formatSize(totalMB)}</span>
                        <span class="text-slate-500 mx-1">|</span> Free: <span class="text-emerald-400">${formatSize(freeMB)}</span>
                        <span class="text-slate-500 mx-1">|</span> Cache: <span class="text-amber-400">${formatSize(cacheMB)}</span>
                    `;
                }
            });

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
            socket.on('connect_error', (err) => { if (err.message === 'System requires setup' || err.message === 'Invalid token') window.location.reload(); });
        }

        function closeAllDropdowns() { document.querySelectorAll('.folder-dropdown').forEach(el => el.classList.add('hidden')); }

        function runSecurityScan(type) {
            if (!activeServerId && type === 'nmap') return showToast('Please select a target server from the sidebar first.', 'error');
            document.getElementById('securityTerm').innerHTML = '';
            startStatusPulse(`Initiating ${type.toUpperCase()}`);
            const payload = { type, targetServerId: activeServerId };
            if (type === 'nmap') { payload.flags = document.getElementById('sec-nmap-flags').value; payload.origin = document.getElementById('sec-nmap-origin').value; } 
            else if (type === 'curl' || type === 'ssl') payload.targetUrl = document.getElementById('sec-curl-url').value;
            socket.emit('security-scan', payload);
        }

        function initFirewallCheck() {
            const srv = serversData.find(s => s.id === activeServerId);
            if (srv && srv.dockerEnabled !== false) document.getElementById('ufw-docker-modal').classList.remove('hidden');
            else executeFirewallScan(true);
        }
        function executeFirewallScan(isSecured) {
            document.getElementById('ufw-docker-modal').classList.add('hidden');
            runSecurityScan('firewall-check');
        }

        function renderFilteredLogs() {
            logTerm.clear(); const activeFilter = document.getElementById('log-grep-input').value.toLowerCase();
            logTerm.write(liveLogLines.filter(line => !activeFilter || line.toLowerCase().includes(activeFilter)).join('\r\n') + (currentLogPartial ? '\r\n' + currentLogPartial : ''));
        }

        function fetchLog(type, path) {
            activeLogSource = { type, path };
            logTerm.clear(); logTerm.writeln(`\x1b[36mFetching [${type}]: ${maskDemoText(path)}...\x1b[0m\r\n`);
            socket.emit('fetch-server-log', { type, path });
        }

        function scanLogFolder(path, btn, e) { e.stopPropagation(); socket.emit('scan-log-folder', { path, buttonId: btn.parentElement.id }); }
        function sortDocker(col) { if (dSort.col === col) dSort.dir *= -1; else { dSort.col = col; dSort.dir = 1; } renderDockerGrid(); }

        function scanCurrentLogForThreats() {
            if (!activeLogSource || !activeLogSource.path) return showToast('Please open a log file or systemd journal first.', 'error');
            const btn = document.getElementById('btn-scan-threats');
            btn.innerHTML = `<svg class="w-3.5 h-3.5 text-accent animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg><span>Scanning...</span>`;
            btn.disabled = true;
            socket.emit('scan-log-threats', { type: activeLogSource.type, path: activeLogSource.path });
        }

        function handleLogThreatsResult({ logPath, threats, error }) {
            const btn = document.getElementById('btn-scan-threats');
            btn.innerHTML = `<svg class="w-3.5 h-3.5 text-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg><span>Scan for Threats</span>`;
            btn.disabled = false;

            if (error) return showToast(`Threat Scan Error: ${error}`, 'error');
            
            const panel = document.getElementById('threat-triage-panel');
            const tbody = document.getElementById('threat-table-body');
            const badge = document.getElementById('threat-count-badge');
            
            if (!threats || threats.length === 0) {
                tbody.innerHTML = `<tr><td colspan="4" class="p-4 text-center text-emerald-500 font-semibold">✔ No unbanned malicious actors or repeated failure markers detected in this log.</td></tr>`;
                badge.innerText = `0 Threats`;
                panel.classList.remove('hidden');
                return;
            }

            badge.innerText = `${threats.length} Actionable Threats`;
            const srv = serversData.find(s => s.id === activeServerId);
            const isSudo = srv && srv.isSudo !== false;

            tbody.innerHTML = threats.map((t, idx) => {
                const rowId = `threat-row-${idx}`;
                const displayIp = maskDemoText(t.ip);
                const isHostSelf = !!(t.isHost || (srv && (srv.host === t.ip || srv.ip === t.ip)));
                return `
                    <tr id="${rowId}" class="border-b border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800/60 transition">
                        <td class="px-3 py-2.5 font-bold text-slate-800 dark:text-slate-200 text-xs">${escapeHtml(displayIp)}</td>
                        <td class="px-3 py-2.5 text-center"><span class="px-2 py-0.5 rounded font-bold text-xs bg-rose-500/10 text-rose-500 border border-rose-500/30">${t.count}</span></td>
                        <td class="px-3 py-2.5" id="geo-cell-${idx}">
                            <button onclick="lookupWhois('${t.ip}', 'geo-cell-${idx}')" class="px-2.5 py-1 rounded bg-slate-200 dark:bg-slate-800 hover:bg-accent hover:text-white transition text-[11px] font-semibold flex items-center space-x-1">
                                <span>🌐</span><span>Lookup WHOIS</span>
                            </button>
                        </td>
                        <td class="px-3 py-2.5 text-right whitespace-nowrap" id="action-cell-${idx}">
                            <div class="flex items-center justify-end space-x-2">
                                <div id="inline-status-${idx}" class="hidden text-[11px] font-bold px-2 py-0.5 rounded border transition-all"></div>
                                ${isHostSelf ? `
                                    <span class="px-2.5 py-1 text-xs font-semibold rounded bg-slate-800 text-slate-400 border border-slate-700 cursor-not-allowed select-none" title="Host IP is protected from accidental lockout">Host Protected</span>
                                ` : isSudo ? `
                                    <button onclick="promptDefenseModal('${t.ip}', 'ip', ${idx})" class="px-2.5 py-1 text-[11px] font-bold rounded-[10px] bg-rose-500/10 border border-rose-500/30 text-rose-500 hover:bg-rose-500 hover:text-white transition">🛡️ Block IP</button>
                                    <button onclick="promptDefenseModal('${t.ip}', 'subnet', ${idx})" class="px-2.5 py-1 text-[11px] font-bold rounded-[10px] bg-amber-500/10 border border-amber-500/30 text-amber-500 hover:bg-amber-500 hover:text-white transition">Block /24</button>
                                ` : `
                                    <div class="relative inline-block group cursor-not-allowed">
                                        <button disabled class="px-2.5 py-1 text-[11px] font-bold rounded-[10px] bg-slate-200 dark:bg-slate-800 text-slate-400 opacity-50 pointer-events-none flex items-center space-x-1"><span>🔒</span><span>Block IP</span></button>
                                        <div class="absolute bottom-full right-0 mb-1.5 hidden group-hover:block w-48 p-2 bg-slate-900 border border-slate-700 text-[10px] text-slate-300 rounded shadow-xl text-center z-50 pointer-events-none">This action requires the SSH user to be in the Sudoers Group.</div>
                                    </div>
                                    <div class="relative inline-block group cursor-not-allowed">
                                        <button disabled class="px-2.5 py-1 text-[11px] font-bold rounded-[10px] bg-slate-200 dark:bg-slate-800 text-slate-400 opacity-50 pointer-events-none flex items-center space-x-1"><span>🔒</span><span>Block /24</span></button>
                                        <div class="absolute bottom-full right-0 mb-1.5 hidden group-hover:block w-48 p-2 bg-slate-900 border border-slate-700 text-[10px] text-slate-300 rounded shadow-xl text-center z-50 pointer-events-none">This action requires the SSH user to be in the Sudoers Group.</div>
                                    </div>
                                `}
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');

            panel.classList.remove('hidden');
        }

        function lookupWhois(ip, cellId) {
            const cell = document.getElementById(cellId);
            if (!cell) return;
            cell.innerHTML = `<span class="text-[11px] text-slate-400 animate-pulse">Querying registry...</span>`;

            if (whoisCache.has(ip)) {
                renderWhoisBadge(ip, whoisCache.get(ip), cell);
                return;
            }

            socket.emit('resolve-whois', { ip, cellId });
        }

        function handleWhoisResult({ ip, cellId, success, data }) {
            const cell = document.getElementById(cellId);
            if (!cell) return;

            if (success && data) {
                whoisCache.set(ip, data);
                renderWhoisBadge(ip, data, cell);
            } else {
                cell.innerHTML = `<span class="text-[11px] text-slate-400">Lookup unavailable</span>`;
            }
        }

        function renderWhoisBadge(ip, data, cell) {
            const flag = data.country_flag || '🌐';
            const country = data.country || 'Unknown';
            const isp = maskDemoText(data.isp || data.org || 'Unknown Org');
            cell.innerHTML = `
                <div class="flex items-center space-x-2 cursor-pointer group" onclick="openWhoisModal('${ip}')" title="Click for full ASN, WHOIS & Threat Intelligence">
                    <span class="text-base">${flag}</span>
                    <span class="text-slate-800 dark:text-slate-200 font-semibold group-hover:text-accent transition text-xs whitespace-normal">${escapeHtml(country)} (${escapeHtml(isp)})</span>
                </div>
            `;
        }

        function openWhoisModal(ip) {
            const data = whoisCache.get(ip);
            if (!data) return;
            const maskedIp = maskDemoText(ip);
            document.getElementById('whois-title').innerHTML = `🌐 Threat & WHOIS Intel: <span class="text-slate-800 dark:text-white font-mono ml-2">${escapeHtml(maskedIp)}</span>`;
            const content = document.getElementById('whois-content');
            
            const threat = data.threat || { score: 1, level: 'Low Threat', engine: 'Local Heuristics', confidence: 0 };
            let pillClass = 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
            let pillEmoji = '🟢';
            if (threat.score >= 5) { pillClass = 'bg-rose-500/20 text-rose-400 border-rose-500/30'; pillEmoji = '🔴'; }
            else if (threat.score >= 3) { pillClass = 'bg-amber-500/20 text-amber-400 border-amber-500/30'; pillEmoji = '🟡'; }

            content.innerHTML = `
                <div class="p-3.5 rounded-lg border ${pillClass} space-y-1.5 font-mono">
                    <div class="flex items-center justify-between">
                        <span class="text-xs uppercase font-bold tracking-wider">Threat Score Severity</span>
                        <span class="text-xs font-bold px-2 py-0.5 rounded-full border ${pillClass}">${pillEmoji} Score ${threat.score}/5: ${escapeHtml(threat.level)}</span>
                    </div>
                    <div class="text-[11px] opacity-80 flex items-center justify-between pt-1 border-t border-current/20">
                        <span>Source: <strong>${escapeHtml(threat.engine)}</strong></span>
                        <span>Confidence: <strong>${threat.confidence}%</strong></span>
                    </div>
                    ${threat.totalReports !== null ? `
                        <div class="text-[11px] opacity-80 flex items-center justify-between">
                            <span>Total Abuse Reports: <strong>${threat.totalReports}</strong></span>
                            <span>Last Seen: <strong>${escapeHtml(threat.lastReportedAt || 'N/A')}</strong></span>
                        </div>
                    ` : ''}
                </div>

                <div class="p-4 bg-slate-100 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 space-y-2 text-sm">
                    <div><span class="text-slate-400">Country / Region:</span> <span class="font-bold text-slate-800 dark:text-slate-100">${escapeHtml(data.country || 'N/A')} ${data.country_flag || ''} (${escapeHtml(data.region || '')}${data.city ? ', ' + escapeHtml(data.city) : ''})</span></div>
                    <div><span class="text-slate-400">ISP / Carrier:</span> <span class="text-accent font-semibold">${escapeHtml(maskDemoText(data.isp || 'N/A'))}</span></div>
                    <div><span class="text-slate-400">Organization:</span> <span class="text-slate-800 dark:text-slate-200">${escapeHtml(maskDemoText(data.org || 'N/A'))}</span></div>
                    <div><span class="text-slate-400">ASN Identifier:</span> <span class="text-slate-800 dark:text-slate-200 font-mono">${escapeHtml(data.asn || 'N/A')}</span></div>
                    <div><span class="text-slate-400">Infrastructure Type:</span> <span class="text-slate-800 dark:text-slate-200 font-mono">${escapeHtml(threat.usageType || 'N/A')}</span></div>
                    <div><span class="text-slate-400">Queried Host / Range:</span> <span class="text-slate-800 dark:text-slate-200 font-mono">${escapeHtml(maskedIp)}</span></div>
                </div>
            `;
            document.getElementById('whois-modal').classList.remove('hidden');
        }

        function closeWhoisModal() { document.getElementById('whois-modal').classList.add('hidden'); }

        function promptDefenseModal(ip, mode, rowIndex) {
            pendingDefense = { ip, mode, rowIndex };
            const displayTarget = maskDemoText(ip);
            const targetLabel = mode === 'subnet' ? `${displayTarget.split('.').slice(0,3).join('.')}.0/24 (Full /24 Subnet)` : `${displayTarget} (Single Host)`;
            document.getElementById('defense-target-ip').innerText = targetLabel;
            document.getElementById('defense-target-mode').innerText = mode === 'subnet' ? 'Class C Subnet CIDR Drop' : 'Single IPv4 Ban Drop';
            
            const whois = whoisCache.get(ip);
            const previewEl = document.getElementById('defense-whois-preview');
            if (whois) {
                previewEl.innerHTML = `<span>Origin:</span> <strong class="text-slate-700 dark:text-slate-200">${escapeHtml(whois.country)}</strong> &bull; <span>ISP:</span> <strong class="text-slate-700 dark:text-slate-200">${escapeHtml(maskDemoText(whois.isp))}</strong>`;
                previewEl.classList.remove('hidden');
            } else {
                previewEl.classList.add('hidden');
            }

            document.getElementById('defense-modal').classList.remove('hidden');
        }

        function closeDefenseModal() { 
            document.getElementById('defense-modal').classList.add('hidden'); 
            pendingDefense = { ip: null, mode: null, rowIndex: null };
        }

        function submitDefenseAction() {
            if (!pendingDefense.ip) return;
            const { ip, mode, rowIndex } = pendingDefense;
            const whois = whoisCache.get(ip) || {};
            const threat = whois.threat || {};
            
            const btn = document.getElementById('btn-confirm-defense');
            btn.innerHTML = `<span class="animate-spin mr-1">⚙️</span> <span>Applying Ban...</span>`;
            btn.disabled = true;

            socket.emit('block-threat', { 
                ip, 
                mode, 
                rowIndex,
                countryCode: whois.country_code || 'XX',
                countryName: whois.country || 'Unknown',
                score: threat.score || 3,
                severity: threat.level || 'Manual Threat Ban'
            });
        }

        function handleBlockThreatResult({ success, ip, targetBlock, rowIndex, engine, message }) {
            const btn = document.getElementById('btn-confirm-defense');
            btn.innerHTML = `<span>Confirm Block</span>`;
            btn.disabled = false;
            closeDefenseModal();

            const inlineEl = document.getElementById(`inline-status-${rowIndex}`);
            const targetRow = document.getElementById(`threat-row-${rowIndex}`);

            if (inlineEl) {
                if (success) {
                    inlineEl.className = 'text-[11px] font-bold px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 flex items-center space-x-1';
                    inlineEl.innerHTML = `<span>✔</span> <span>${escapeHtml(engine || 'Banned')}</span>`;
                    inlineEl.classList.remove('hidden');

                    if (targetRow) {
                        setTimeout(() => {
                            targetRow.style.transition = 'opacity 0.4s ease-out';
                            targetRow.style.opacity = '0';
                            setTimeout(() => {
                                targetRow.remove();
                                const rowsRemaining = document.querySelectorAll('#threat-table-body tr').length;
                                document.getElementById('threat-count-badge').innerText = `${rowsRemaining} Actionable Threats`;
                            }, 400);
                        }, 1200);
                    }
                } else {
                    inlineEl.className = 'text-[11px] font-bold px-2 py-0.5 rounded bg-rose-500/20 text-rose-400 border border-rose-500/30 flex items-center space-x-1';
                    inlineEl.innerHTML = `<span>❌</span> <span>Error</span>`;
                    inlineEl.title = message;
                    inlineEl.classList.remove('hidden');
                    showToast(`Failed to block ${maskDemoText(targetBlock)}: ${message}`, 'error');
                }
            }
        }

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
                    <td class="px-4 py-3"><div class="flex items-center space-x-3"><div class="w-2.5 h-2.5 rounded-full ${p.State === 'running' ? 'bg-emerald-500' : 'bg-slate-500'} shrink-0 shadow-sm"></div><div><div class="font-bold text-slate-800 dark:text-slate-200">${escapeHtml(maskDemoText(p.Names))}</div><div class="text-xs opacity-70">${escapeHtml(maskDemoText(p.Status))}</div></div></div></td>
                    <td class="px-4 py-3 font-mono text-xs opacity-80">${escapeHtml(maskDemoText(p.Image))}</td>
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
            grid.querySelectorAll('.docker-btn').forEach(btn => btn.addEventListener('click', () => { const a = btn.dataset.action, c = btn.dataset.container, i = btn.dataset.image; if (a === 'console') execDocker(c); else if (a === 'logs') viewLogs(c); else if (a === 'scan') scanDocker(i); else if (a === 'remove') { socket.emit('docker-action', { action: a, container: c }); } else socket.emit('docker-action', { action: a, container: c }); }));
        }

        function viewLogs(c) { document.getElementById('diag-title').innerText = `Logs: ${maskDemoText(c)}`; document.getElementById('diagnostics-modal').classList.remove('hidden'); modalTerm.clear(); setTimeout(() => { try { modalFitAddon.fit(); } catch(e){} }, 150); socket.emit('docker-logs', { container: c }); }
        function scanDocker(i) { document.getElementById('diag-title').innerText = `Grype Scan: ${maskDemoText(i)}`; document.getElementById('diagnostics-modal').classList.remove('hidden'); modalTerm.clear(); setTimeout(() => { try { modalFitAddon.fit(); } catch(e){} }, 150); socket.emit('docker-scan', { image: i }); }
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
                    <span class="text-sm font-medium truncate pr-2 pointer-events-none">${escapeHtml(maskDemoText(s.name))}</span>
                    <div class="flex items-center space-x-2 shrink-0 pointer-events-none">
                        <span id="ind-${s.id}" class="srv-indicator hidden origin-center text-[9px] font-bold uppercase tracking-widest bg-emerald-500/10 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30 px-2 py-0.5 rounded-full shadow-sm">CONNECTED</span>
                        <button data-id="${s.id}" class="edit-server-btn pointer-events-auto opacity-0 group-hover:opacity-100 transition text-slate-400 hover:text-accent focus:outline-none"><svg class="w-3.5 h-3.5 pointer-events-none" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg></button>
                    </div>
                </div>`).join('');
            list.querySelectorAll('.server-item').forEach(el => el.addEventListener('click', () => connectServer(el.dataset.id)));
            list.querySelectorAll('.edit-server-btn').forEach(btn => btn.addEventListener('click', (e) => editServer(btn.dataset.id, e)));
        }

        function updateCloneDropdowns() {
            const h = '<option value="">-- Import From --</option>' + serversData.map(s => `<option value="${s.id}">${escapeHtml(maskDemoText(s.name))}</option>`).join('');
            document.getElementById('macro-clone-select').innerHTML = h; document.getElementById('log-clone-select').innerHTML = h;
        }

        function cloneMacros(id) { const s = serversData.find(x => x.id === id); if (s && s.macros) s.macros.forEach(m => addMacroRow(m.label, m.cmd, m.auto)); document.getElementById('macro-clone-select').value = ''; }
        function cloneLogs(id) { const s = serversData.find(x => x.id === id); if (s && s.customLogs) s.customLogs.forEach(l => addLogPathRow(l.label, l.type || 'file', l.path)); document.getElementById('log-clone-select').value = ''; }

        function connectServer(id) {
            const srv = serversData.find(s => s.id === id); activeServerId = srv.id;
            document.getElementById('telemetry-bar').classList.add('hidden'); document.getElementById('stat-cpu').innerText = '--'; document.getElementById('stat-ram').innerText = '--';
            document.getElementById('header-title').innerText = maskDemoText(srv.name); document.getElementById('tabs').classList.remove('hidden');
            
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

            switchTab('terminal'); try { fitAddon.fit(); } catch(e) {} term.clear(); term.writeln(`Connecting to ${escapeHtml(maskDemoText(srv.host))}...\r\n`);
            socket.emit('connect-ssh', { ...srv, cols: term.cols || 80, rows: term.rows || 24 });
        }

        function showAddServerForm() {
            editingServerId = null; document.getElementById('telemetry-bar').classList.add('hidden');
            ['name','host','key-custom','passphrase'].forEach(id => document.getElementById('frm-'+id).value = '');
            document.getElementById('frm-port').value = '22'; document.getElementById('frm-user').value = 'root'; document.getElementById('frm-key-type').value = '/root/.ssh/id_ed25519'; document.getElementById('frm-key-custom').classList.add('hidden');
            ['docker','logs','security'].forEach(id => document.getElementById('frm-'+id).checked = true);
            document.getElementById('frm-sudo').checked = true;
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
            document.getElementById('frm-sudo').checked = srv.isSudo !== false;
            document.getElementById('frm-auth-method').checked = srv.authMethod === 'password'; toggleAuthMethod();
            document.getElementById('macro-builder').innerHTML = ''; (srv.macros || []).forEach(m => addMacroRow(m.label, m.cmd, m.auto));
            document.getElementById('log-builder').innerHTML = ''; (srv.customLogs || []).forEach(l => addLogPathRow(l.label, l.type || 'file', l.path));
            ['terminal', 'files', 'docker', 'logs', 'security'].forEach(t => document.getElementById('view-'+t).classList.add('hidden')); document.getElementById('tabs').classList.add('hidden');
            document.getElementById('view-add-server').classList.remove('hidden'); document.getElementById('view-add-server').classList.add('flex');
            document.getElementById('form-header-title').innerText = "Edit Server"; document.getElementById('header-title').innerText = "Configuration"; document.getElementById('macro-buttons').innerHTML = '';
        }

        function deleteServer() { 
            socket.emit('delete-server', editingServerId); 
            document.getElementById('view-add-server').classList.add('hidden'); 
            showToast('Server configuration removed.');
            switchTab('terminal'); 
        }

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
        function moveMacroDown(el) { const row = el.closest ? el.closest('.macro-row') || el.closest('.log-row') : el.parentElement.parentElement.parentElement; if (row && row.nextElementSibling) row.parentElement.insertBefore(row, row.nextElementSibling); }

        function saveServer() {
            const macros = Array.from(document.querySelectorAll('.macro-row')).map(r => ({ label: r.querySelector('.m-label').value, cmd: r.querySelector('.m-cmd').value, auto: r.querySelector('.m-auto').checked })).filter(m => m.label && m.cmd);
            const customLogs = Array.from(document.querySelectorAll('.log-row')).map(r => ({ label: r.querySelector('.l-label').value, type: r.querySelector('.l-type').value, path: r.querySelector('.l-path').value })).filter(l => l.label && l.path);
            let finalKeyPath = document.getElementById('frm-key-type').value; if (finalKeyPath === 'custom') finalKeyPath = document.getElementById('frm-key-custom').value;
            const authMethod = document.getElementById('frm-auth-method').checked ? 'password' : 'key';
            const isSudo = document.getElementById('frm-sudo').checked;
            socket.emit('save-server', { id: editingServerId, name: document.getElementById('frm-name').value, host: document.getElementById('frm-host').value, port: document.getElementById('frm-port').value, username: document.getElementById('frm-user').value, privateKeyPath: finalKeyPath, passphrase: document.getElementById('frm-passphrase').value, authMethod, isSudo, dockerEnabled: document.getElementById('frm-docker').checked, logsEnabled: document.getElementById('frm-logs').checked, securityEnabled: document.getElementById('frm-security').checked, macros, customLogs });
            document.getElementById('view-add-server').classList.add('hidden'); 
            showToast('Server configuration saved.');
            switchTab('terminal'); 
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

echo "✨ BastionCC v1.8.6 Build completed successfully!"
