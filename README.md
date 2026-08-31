
![picture](/images/BastionCCsmall.png)


## If you do not like AI assisted code then please pass on by, we get it you don't think it's real code just like how my dad stated digital photography is not real photography and look how that turned out (;o)

### This is a simple tool that i built for myself utilising both Google Gemini Pro and Claude AI Agents.

### The tool is perfect if you manage many VM's, LXC, cloud compute etc and would like to consolidate them all into one place with lightweight yet powerful features built in.

![picture](/images/xterm.png)

## Features

### Add multiple servers via a simple user interface 
    * Add path to SSH Keys and authenticate in the backend once when adding the server (password is not stored in file and is hashed using your master password

 ![picture](/images/addserver.png)
 
### Xterm.js terminal with copy / paste functionality

![picture](/images/xterm.png)

### Docker management per server (like portainer but simple and lightweight no plugin required)
  ![picture](/images/dockermanager.png)
  
### Create "Macros" i.e command shortcuts you may use often, these will appear above the xterm terminal window and import Macro templates from your other servers to save having to recreate
  ![picture](/images/quickcommands.png)
  
### Add logs you would like to monitor, these appear as buttons in the log viewer page and you can add 3 types:
    * Files (direct links to files)
    * Folders (system scans folder and displays the button as a drop down list to select)
    * Systemd / Journalctl (Enter the term you would like to isolate i.e UFW)
    * Clone preset logs to other servers
    
  ![picture](/images/addlogs.png)
  
### Log viewer

  ![picture](/images/logviewer.png)
  
### SFTP file management with drag and drop ability to transfer files.
    
 ![picture](/images/filebrowser.png)
    
### Emergency lock out button for the paranoid aka me, click this and the system kills all sessions, removes pubkey salted hashes and logs you out.
### Dark and Light theme of course.
    
![picture](/images/Changelog.png)

## Installation

### There are several options for installation:

### **Clone the .sh file**

The following will create the whole application structure in a folder called server-management. You can then build the docker locally and deploy on your laptop

~~~
Save the .sh file to your desired location
chmod +x servermon.sh
cd server-dashboard 
Build your docker locally or push to your repo i.e docker buildx build --platform linux/amd64,linux/arm64 -t my.repo.uk/username/servermonitor:v4.4 --push .
Create the docker compose file based on example here
Change the version number to the latest release in the compose file
Docker compose up
visit localhost:3000 / 127.0.0.1:3000

On first install you will set a master password.
~~~

### **Pull the latest docker image**

~~~
Save the dockerfile to your preffered location. Double check the file points to the latest version.
Docker Compose up
~~~

### **Download the binary file**

Prebuilt binaries will be avaliable for Linux only.
* Arch Based Distros
* Rhel Based Distros
* Debian Based Distros
* Appimage 


## Security Approach

### The .SH file is being audited by both Claude and Gemini AI Pro each major version for weaknesses, then the measures to circumvent are implemented to mitigate possible risks, however it should be noted i am deploying on my laptop locally, i would not recommend deploying as a cloud based tool.

~~~
Version 4+ Security review and patch implementation

1) Command Injection: Right now, if the frontend sends container = "ubuntu && rm -rf /", the backend blindly executes it on your remote server via SSH. Even though you are the only user, it's best practice to sanitize this so a stray typo or a compromised browser tab can't accidentally nuke your server.

2) Arbitrary File Read: Because the backend reads whatever path the frontend sends in config.privateKeyPath, a manipulated socket message could force the backend to read your auth.json or /etc/passwd file.

3) Timing-unsafe PIN comparison: While network jitter usually makes timing attacks nearly impossible over a standard network, since you are running this locally (where latency is basically zero), a script could theoretically measure the nanosecond differences in how long the backend takes to reject a PIN. Switching to crypto.timingSafeEqual is a one-line fix and perfect cryptographic hygiene.

4) Brute-force protection: Since your dashboard isn't exposed to the internet, a remote botnet isn't going to hammer it. However, a malicious script running locally on your laptop could try to guess a 4-digit PIN in seconds. Adding a simple in-memory rate limiter (e.g., locking out for 5 minutes after 5 failed attempts) completely kills this vector.

5) Stored XSS (Cross-Site Scripting): Because you are the only user, you would technically have to XSS yourself by typing malicious JavaScript into a server name or macro label. That said, if you ever copy-pasted a weird string by accident, it could break your UI. Writing a tiny helper function to sanitize those HTML strings is standard practice and will make the UI bulletproof.

6) Plaintext over HTTP: Claude is absolutely right for a normal deployment, but because you are running Nginx Proxy Manager, your TLS (HTTPS/WSS) is already handled at the proxy level. The traffic is encrypted before it ever leaves your laptop/network. We don't need to change the app code for this, you already built the right architecture!

7) JWT_SECRET Regeneration: This is actually a great catch. Right now, if you restart the Docker container, it generates a new JWT secret in memory, which immediately logs you out of any open tabs. We should absolutely save the JWT_SECRET into auth.json so your sessions survive container restarts.

8) Emergency Lock doesn't revoke sessions: This is the best catch in the entire audit. Because JWTs are stateless, kicking the WebSocket disconnects the live terminal, but the browser still holds a valid token. If we rotate the JWT_SECRET when you hit Emergency Lock, every single active token instantly becomes worthless. That makes the lock truly absolute.

9) Exposing /node_modules: Sloppy on my part! Exposing the whole directory gives away unnecessary info. We will lock the static routing down so it only serves the specific xterm files the frontend actually needs.

~~~




~~~
docker buildx build --platform linux/amd64,linux/arm64 -t repo.mb-assist.uk/bigbazookas/servermonitor:v4.4 --push .
~~~
