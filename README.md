# File Backup + Cleanup + Google Chat Notification (PowerShell)

A PowerShell automation script that performs **file synchronization, cleanup of old files, and Google Chat notifications** using a webhook.

## 🚀 Features

- Copies new and updated files from source to destination
- Deletes files older than a configured retention period (default: 24 hours)
- Uses `Robocopy` for fast and reliable transfers
- Generates execution report (copied + deleted files)
- Sends summary notification to Google Chat
- Maintains execution logs for auditing

## 📌 Use Cases

- Daily backup between drives or servers
- Temporary file staging cleanup
- Log or archive rotation
- Automated data pipeline folder sync
- IT backup and replication jobs

## ⚙️ Prerequisites

- Windows OS
- PowerShell 5.1+
- Robocopy (built-in)
- Internet access (for Google Chat webhook)
- Read/Write/Delete permissions on folders

## 🔧 Configuration

Update the script variables:

```powershell
$SOURCE_FOLDER = "D:\Source-folder"
$DEST_FOLDER   = "F:\Dest-folder"

$DELETE_OLDER_THAN_HOURS = 24

$WEBHOOK_URL = "YOUR_GOOGLE_CHAT_WEBHOOK"
$TOPIC       = "File Backup Report"
```

## 🔄 How It Works

1. Capture start time
2. Scan source and destination folders
3. Compare files (name, size, modified time)
4. Copy changed/new files using Robocopy
5. Delete files older than retention period
6. Generate execution summary
7. Send Google Chat notification

## 🧰 Robocopy Options Used

```text
/E     Copy subdirectories (including empty)
/MT:32 Multi-threaded copy
/R:2   Retry failed copies twice
/W:2   Wait 2 seconds between retries
/FFT   FAT file time compatibility
/Z     Restartable mode
/LOG   Generate log file
```

## ▶️ Run the Script

### Manual Execution

```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\Scripts\backup.ps1"
```

### Scheduled Execution (Recommended)

Use Windows Task Scheduler:

```text
Program: powershell.exe

Arguments:
-ExecutionPolicy Bypass -File "C:\Scripts\backup.ps1"
```

## 📊 Output

### 📁 File Behavior
- Syncs new/updated files
- Deletes old files based on retention policy

### 📄 Log File
```text
%TEMP%\24hr-transbackup.log
```

### 📢 Google Chat Notification Includes
- Job status (SUCCESS / FAILED)
- Files copied
- Files deleted
- Execution duration
- Source & destination paths
- Up to 20 file names

## 🔚 Exit Codes

| Code | Status |
|------|--------|
| 0–7  | SUCCESS |
| >7   | FAILURE |
