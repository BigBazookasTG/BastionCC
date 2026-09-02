
![picture](/images/BastionCCsmall.png)


## If you do not like AI assisted code then please pass on by, we get it you don't think it's real code just like how my dad stated digital photography is not real photography and look how that turned out (;o)

### This is a simple tool that i built for myself utilising both Google Gemini Pro and Claude AI Agents.

### The tool is perfect if you manage many VM's, LXC, cloud compute etc and would like to consolidate them all into one place with lightweight yet powerful features built in.

### Full documentation can be found here > https://docs.bastioncc.cloud

![picture](/images/xterm.png)

## Features

### Add multiple servers via a simple user interface 
    * Add SSH Keys and authenticate in the backend once when adding the server (password is not stored in file and is hashed using your master password

 ![picture](/images/addserver.png)
 
### Xterm.js terminal with copy / paste functionality

![picture](/images/xterm.png)

### Docker management per server (like portainer but simple and lightweight no plugin required)
  ![picture](/images/dockermanager.png)
  
### Create "Macros" i.e command shortcuts you may use often, these will appear above the xterm terminal window and import Macro templates from your other servers to save having to recreate
  ![picture](/images/quickcommandsbcc.png)
  
### Add logs you would like to monitor, these appear as buttons in the log viewer page and you can add 3 types:
    * Files (direct links to files)
    * Folders (system scans folder and displays the button as a drop down list to select)
    * Systemd / Journalctl (Enter the term you would like to isolate i.e UFW)
    * Clone preset logs to other servers
    
  ![picture](/images/quickcommandsbcc.png)
  
### Log viewer

  ![picture](/images/logviewer.png)

  Includes the following security audits:

  * WHOIS Lookup
  * Threat Detection Score (Local or via AbuseIPDB)
  * Ban Actions (Single IP or /24) Via Crowdsec > Fail2ban > Firewall
  
### SFTP file management with drag and drop ability to transfer files.
    
 ![picture](/images/filebrowser.png)
    
### Emergency lock out button for the paranoid aka me, click this and the system kills all sessions, removes pubkey salted hashes and logs you out.
### Dark and Light theme of course.
    
![picture](/images/Changelog.png)

## Installation

**Pull the latest docker image**

~~~
Save the docker-compose.yml file to your preferred location. Double check the file points to the latest version shown in packages.
Edit your PubKey SSH Path
Docker Compose up
visit localhost:3000 or 127.0.0.1:3000
~~~


## Security Approach

### The code is here for all to see, I am no code or security expert and do not pretend to be, so cast your eye over the code and judge for yourself

The build.SH file is audited by both Claude and Gemini AI  each major version for weaknesses, then the measures to circumvent are implemented to mitigate possible risks, however it should be noted i am deploying on my laptop locally, i would not recommend deploying as a cloud based tool.


Summary Claude - 2nd September 2026 - V1.9.x

I reviewed the full diff (the new pasted-private-key feature, the deep-scan report generation, and re-checked all the previously fixed spots to make sure nothing regressed under the new code). Everything holds up:

mode allowlist in block-threat — still enforced, still correct.
Key-path validation — actually improved this round. It's now consolidated into one resolvePrivateKey() helper used identically by connect-ssh, the security-scan pivot, and the run-deep-scan pivot, so there's no longer three copies of the logic to keep in sync — just one. That's a better structural fix than what I asked for.

New pasted-key feature (encryptedPrivateKey) — the raw key content is encrypted with the PIN immediately in the save-server handler and delete serverData.privateKey happens before the write to disk, so plaintext key material never touches servers.json. Same careful handling as the existing passphrase encryption.

Deep-scan report — all dynamic values (nmapOut, fwResult, ban history entries, domain audit output) go through escapeHtmlForReport() before being embedded in the generated HTML, and it's rendered in ordinary element content, not inline event handlers, so no XSS class issue there.
Docker/nmap/curl/ssl sanitization — unchanged, still correctly allowlisted.

One very minor (non-security) note, not worth blocking on: connect-ssh re-registers the sftp-list/sftp-download/sftp-upload-* listeners on the socket every time it runs, without removing prior ones first. If a single browser session connects to multiple servers in sequence without a page reload, you'll accumulate duplicate listeners and each SFTP action could fire multiple times. Worth a socket.removeAllListeners('sftp-list') etc. at the top of the sshClient.sftp() callback if you ever notice duplicate SFTP events, but it's a correctness nit, not a vulnerability.

Nothing else stood out. This is in good shape — the security posture across all the rounds we've done has held together well as the feature set grew.



