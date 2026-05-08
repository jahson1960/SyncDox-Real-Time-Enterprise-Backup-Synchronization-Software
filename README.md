# SyncDox: Real-Time Enterprise Backup & Synchronization Software

**SyncDox: Enterprise Backup & Synchronization Software**

A real-time (near real-time) enterprise-grade backup and file synchronization solution designed to continuously monitor user directories and securely replicate changes to a central file server using Robocopy automation.

---

## Features

- **Real-time style folder synchronization** (continuous polling)
- **Centralized server backup** for enterprise environments
- **Dynamic user profile detection** (GPO-ready)
- **Automatic exclusion** of media files (audio/video)
- **Robust logging system** (daily logs per user)
- **Server availability checks**
- **Lock-file protection** to prevent duplicate execution
- **Lightweight and Windows-native** (VBScript + Robocopy)

---

## Architecture

```text
[User Workstation]
       │
       ▼
[VBScript Sync Agent]
(Monitors folders + runs Robocopy)
       │
       ▼
[File Server Share]
       │
       ├── User Backups
       └── Central Logs
```
---

## Folder Sync Scope

SyncDox monitors and syncs the following user directories:

- Desktop
- Documents
- Downloads
- Pictures
- Music
- Videos *(Metadata/folder structure only; large media files excluded)*

---

## Requirements

- **Windows OS:** 7, 10, 11, or Server
- **Network Access:** Permissions to a network file share
- **Dependencies:** Robocopy (built into Windows)
- **Environment:** Domain environment recommended (Active Directory / GPO)

---

## Installation

### 1. Deploy Script
Place the script in a shared, read-only location for users:

```batch
\\domain.com\NETLOGON\SyncDox\
```

### 2. Group Policy Setup
Configure via Group Policy:

- **User Configuration → Windows Settings → Scripts (Logon)**
- **Add:**
```text
    wscript.exe \\domaincontroller\NETLOGON\SyncDox.vbs  
```

**OR** use a **Scheduled Task** (Recommended):
- **Trigger:** At logon
- **Settings:** Run hidden, run with user privileges

---

## How It Works

1. **Dynamic Detection:** Detects logged-in user via `%USERNAME%` and `%USERPROFILE%`.
2. **Path Construction:** Builds the destination path: `\\fileserver\Backups\<DOMAIN>\<USERNAME>\`
3. **Continuous Scan:** Scans folders based on a defined polling interval.
4. **Robocopy Execution:**
   - Copies only changed files.
   - Skips older versions.
   - Avoids duplicate transfers.
   - Logs all operations.

---

## Logging

Logs are stored centrally for administrator review:

```text
\\fileserver\logs\<username>_YYYY-MM-DD.log
```

---

## Security Considerations

- **Permissions:** Restrict share permissions so users can only see their own folders.
- **ACLs:** Use NTFS ACLs to isolate user data.
- **Integrity:** Monitor central logs for abnormal activity or failed syncs.

---

## Performance Tuning

The following variables can be adjusted within the script:

- **Sync interval:** Default is 5 seconds.
- **Robocopy threads:** Adjust using `/MT:8` (for Windows 10/Server 2012+).
- **Retry behavior:** Default `/R:1 /W:1` to prevent hanging on open files.

---

## Limitations

- **Polling-based:** Uses a loop rather than true event-driven file system triggers.
- **Connectivity:** Requires a stable LAN/VPN connection to the file server.
- **OS Restricted:** Windows-only solution.

---

## Future Improvements

- `FileSystemWatcher` integration for true event-based syncing.
- Transition to a **.NET Windows Service**.
- Web-based monitoring dashboard for IT Admins.
- Client-side encryption before transfer.

---

## Author

**Victor Oguanobi**

Full-Stack Software Developer specializing in fintech and enterprise systems, workflow automation, backend APIs, and scalable web applications using PHP, MySQL, Node.js, NestJS, Next.js, and TypeScript.

