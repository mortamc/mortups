[README.md](https://github.com/user-attachments/files/26220036/README.md)
> ⚠️ **WARNING: READ THE INSTRUCTIONS AND FILES BEFORE USE**

# mortups v1.0
**Minecraft 1.12.2 Server Manager for Windows**  
*by mortamc*

A PowerShell-based manager that runs alongside your Minecraft server and handles automatic backups, in-game commands, and post-restore restarts — no GUI needed.

---

## What it does

- Starts the server with configurable RAM
- Creates automatic `.7z` backups on a timer
- Deletes backups older than a configurable number of days
- Listens to in-game chat for commands (all players or ops-only, configurable)
- Automatically restarts the server after a restore

---

## Requirements

```
Java 8 JRE in the system PATH     → https://adoptium.net
7-Zip installed                    → https://7-zip.org
RCON enabled in server.properties:
    enable-rcon=true
    rcon.port=25575
    rcon.password=yourpassword
```

> When installing Java, make sure to check **"Add to PATH"** during setup.

---

## Installation

1. Copy both files (`mortups.ps1` and `start.bat`) into the **same folder** as your `server.jar`.
2. Open `mortups.ps1` with a text editor (Notepad++, VS Code, etc.).
3. Edit **only** the `CONFIGURATION` section at the top of the file (see below).
4. Save your changes.
5. Double-click `start.bat` to launch everything.

---

## Configuration

All configurable parameters are at the top of `mortups.ps1`, between the `CONFIGURATION` and `END OF CONFIGURATION` markers. **Do not edit anything outside that section.**

### Server

| Parameter | Description | Example |
|-----------|-------------|---------|
| `$ServerDir` | Full path to the server folder (not the .jar file) | `"C:\MinecraftServer"` |
| `$ServerJar` | Name of the server .jar file | `"server.jar"` |
| `$JavaExe` | Path to Java. If Java is in the system PATH, `"java"` is enough | `"java"` |
| `$MaxRamGB` | Maximum RAM assigned to the server (in GB) | `4` |
| `$MinRamGB` | Minimum RAM on startup — keeping it equal to `$MaxRamGB` is more stable | `4` |
| `$ServerStartupWaitSec` | Seconds the manager waits after launch before starting to monitor | `40` |

> **Tip:** If you use Forge with many mods, increase `$ServerStartupWaitSec` to `60`–`120`.

### Backups

| Parameter | Description | Default |
|-----------|-------------|---------|
| `$BackupDir` | Folder where backup files are stored | `$ServerDir\backups` |
| `$BackupIntervalMin` | Minutes between each automatic backup | `30` |
| `$BackupRetentionDays` | Days to keep backups before auto-deletion | `3` |
| `$BackupOnServerStart` | Create a backup when the server starts? | `$false` |
| `$CompressionLevel` | 7-Zip compression level (1 = fastest, 9 = smallest) | `5` |
| `$CompressionThreads` | CPU threads used by 7-Zip | `2` |
| `$SaveAllWaitSec` | Seconds to wait after `save-all` before compressing | `5` |

> **Tip:** You can point `$BackupDir` to a different drive, e.g. `"D:\MinecraftBackups"`.

### RCON

| Parameter | Description | Default |
|-----------|-------------|---------|
| `$RconHost` | Server IP for RCON | `"127.0.0.1"` |
| `$RconPort` | RCON port — must match `server.properties` | `25575` |
| `$RconPass` | RCON password — must match `server.properties` | `"yourpassword"` |

### Command Permissions

| Parameter | Description | Options |
|-----------|-------------|---------|
| `$CommandPermission` | Who can use in-game commands | `"everyone"` / `"ops"` / `"whitelist"` |
| `$AllowedPlayers` | Player whitelist (only used when set to `"whitelist"`) | `@("player1", "player2")` |

You can also enable or disable each command individually:

```powershell
$EnableBackupCommand  = $true   # !backup
$EnableBackupsCommand = $true   # !backups
$EnableRestoreCommand = $true   # !restore  ← stops and restarts the server
```

> ⚠️ `!restore` **stops and restarts the server.** If you don't want players triggering restores, set `$EnableRestoreCommand = $false` or restrict permissions to `"ops"`.

---

## Usage

### Starting the server

Double-click `start.bat`. It checks that PowerShell, Java, and `mortups.ps1` are all available, then launches the manager.

### Stopping the server

Type `stop` in the server console (or from in-game with op permissions). The manager shuts itself down cleanly when the server exits normally.

### Manager console output

```
[HH:MM:SS][INFO]   Manager started.
[HH:MM:SS][BACKUP] Backup created: backup_auto_2026-03-24_14-30.7z
[HH:MM:SS][CMD]    Command from 'mortamc': !backup pre-update
[HH:MM:SS][SERVER] Next automatic backup at: 15:00
```

---

## In-game commands

These commands are typed in the **in-game chat** (not the server console). Only players with permission according to `$CommandPermission` can use them.

### `!save`
Forces an immediate world save to disk.
```
!save
```

### `!backup [name]`
Creates a manual backup. The name is optional — if omitted, the timestamp is used.
```
!backup
!backup pre-update
!backup before-clearing-spawn
```
Generated filenames:
- `backup_manual_2026-03-24_14-30.7z`
- `backup_manual_pre-update_2026-03-24_14-30.7z`

### `!backups`
Lists available backups in chat (newest first), with age and size.
```
!backups
```
Example output:
```
[Backups] Available backups (newest first):
 - backup_manual_pre-update_2026-03-24_14-30.7z (0.5h ago, 142.3 MB)
 - backup_auto_2026-03-24_14-00.7z (1.0h ago, 141.8 MB)
 - backup_auto_2026-03-24_13-30.7z (1.5h ago, 141.5 MB)
[Backups] To restore: !restore <exact_filename.7z>
```

### `!restore <filename>`
Restores the server from a backup. The server **stops**, files are restored, and it **restarts automatically**.
```
!restore backup_auto_2026-03-24_14-00.7z
```
> ⚠️ A countdown is shown in chat before the restore begins (15 seconds by default) so players have time to prepare.

---

## Backup filename format

```
backup_<type>_<optional-name>_<date>_<time>.7z
```

Examples:
- `backup_auto_2026-03-24_14-30.7z` — automatic backup
- `backup_manual_2026-03-24_15-00.7z` — manual backup without a name
- `backup_manual_pre-update_2026-03-24_15-00.7z` — manual backup with a name

---

## Expected folder structure

```
📁 Your server folder
├── start.bat           ← double-click to start
├── mortups.ps1         ← the manager (configure before use)
├── server.jar
├── server.properties   ← RCON must be enabled here
├── ops.json
├── world/
├── logs/
│   └── latest.log
└── backups/            ← created automatically
    ├── backup_auto_2026-03-24_14-00.7z
    └── backup_manual_pre-update_2026-03-24_15-00.7z
```

---

## FAQ

**Commands typed in chat aren't being detected.**  
Make sure RCON is enabled and that `$RconPass` matches the password in `server.properties`. Also check that `$CommandPermission` is set correctly.

**Can I store backups on a different drive?**  
Yes. Set `$BackupDir` to any path, e.g. `"D:\MinecraftBackups"`.

**The manager starts monitoring before the server is fully loaded.**  
Increase `$ServerStartupWaitSec`. With Forge and many mods, values between `60` and `120` are normal.

**Are server logs included in backups?**  
No. Logs, crash reports, and Java lock files are excluded by default. This keeps backup sizes smaller without affecting restores.

**A backup was interrupted mid-way — what do I do?**  
Delete the incomplete `.7z` file manually, then use `!backup` to create a fresh one.

---

## License

MIT — see the `LICENSE` file for full terms.
