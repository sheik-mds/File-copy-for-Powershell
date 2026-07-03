# ================= USER SETTINGS =================
$SOURCE_FOLDER = "D:\Source-folder"
$DEST_FOLDER   = "F:\Desg-folder"

# Delete files in destination older than this many hours
$DELETE_OLDER_THAN_HOURS = 24

$WEBHOOK_URL   = "G_space_Webhook_URL"
$TOPIC         = "Set the Topic"
# =================================================

$StartTime = Get-Date
$TempLog = "$env:TEMP\24hr-transbackup.log"

# ================= Get files to be copied =================
$SourceFiles = Get-ChildItem $SOURCE_FOLDER -Recurse -File
$DestFilesMap = @{}

if (Test-Path $DEST_FOLDER) {
    Get-ChildItem $DEST_FOLDER -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($DEST_FOLDER.Length).TrimStart('\')
        $DestFilesMap[$rel] = $_
    }
}

$CopiedList = @()

foreach ($file in $SourceFiles) {
    $rel = $file.FullName.Substring($SOURCE_FOLDER.Length).TrimStart('\')

    if (-not $DestFilesMap.ContainsKey($rel)) {
        $CopiedList += $rel
    }
    else {
        $destFile = $DestFilesMap[$rel]
        if ($file.LastWriteTime -gt $destFile.LastWriteTime -or
            $file.Length -ne $destFile.Length) {
            $CopiedList += $rel
        }
    }
}

# ================= Copy Files (NO MIRROR) =================
robocopy $SOURCE_FOLDER $DEST_FOLDER /E /MT:32 /R:2 /W:2 /FFT /Z /NP /TEE /LOG:$TempLog

$ExitCode = $LASTEXITCODE

# ================= Delete old files from destination =================
$DeletedFiles = @()
$DeleteBefore = (Get-Date).AddHours(-$DELETE_OLDER_THAN_HOURS)

Get-ChildItem $DEST_FOLDER -Recurse -File |
Where-Object {
    $_.LastWriteTime -lt $DeleteBefore
} | ForEach-Object {

    $DeletedFiles += $_.FullName.Substring($DEST_FOLDER.Length).TrimStart('\')

    try {
        Remove-Item $_.FullName -Force
    }
    catch {
        Write-Host "Failed to delete $($_.FullName)"
    }
}

$DeletedCount = $DeletedFiles.Count

$EndTime = Get-Date

if ($ExitCode -le 7) {
    $Status = "SUCCESS"
    $StatusLabel = "[SUCCESS]"
}
else {
    $Status = "FAILED"
    $StatusLabel = "[FAILED]"
}

$CopiedCount = $CopiedList.Count

# ================= Format Copied Files =================
$FileNamesText = if ($CopiedCount -eq 0) {
    "No new or updated files."
}
elseif ($CopiedCount -le 20) {
    ($CopiedList | ForEach-Object { "• $_" }) -join "`n"
}
else {
    (($CopiedList |
        Select-Object -First 20 |
        ForEach-Object { "• $_" }) -join "`n") +
    "`n...and $($CopiedCount - 20) more files"
}

# ================= Format Deleted Files =================
$DeletedText = if ($DeletedCount -eq 0) {
    "No old files deleted."
}
elseif ($DeletedCount -le 20) {
    ($DeletedFiles | ForEach-Object { "• $_" }) -join "`n"
}
else {
    (($DeletedFiles |
        Select-Object -First 20 |
        ForEach-Object { "• $_" }) -join "`n") +
    "`n...and $($DeletedCount - 20) more files"
}

# ================= Google Chat Payload =================
$Payload = @{
    cardsV2 = @(
        @{
            cardId = "backup_report"
            card = @{
                header = @{
                    title = "$StatusLabel $TOPIC"
                }
                sections = @(
                    @{
                        header = "Summary"
                        widgets = @(
                            @{
                                decoratedText = @{
                                    topLabel = "Status"
                                    text = "<b>$Status</b>"
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Source"
                                    text = $SOURCE_FOLDER
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Destination"
                                    text = $DEST_FOLDER
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Files Copied / Updated"
                                    text = "<b>$CopiedCount</b>"
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Old Files Deleted"
                                    text = "<b>$DeletedCount</b>"
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Retention Policy"
                                    text = "Delete files older than $DELETE_OLDER_THAN_HOURS hours"
                                }
                            }
                        )
                    },
                    @{
                        header = "Copied Files"
                        widgets = @(
                            @{
                                textParagraph = @{
                                    text = $FileNamesText
                                }
                            }
                        )
                    },
                    @{
                        header = "Deleted Files"
                        widgets = @(
                            @{
                                textParagraph = @{
                                    text = $DeletedText
                                }
                            }
                        )
                    },
                    @{
                        header = "Timing"
                        widgets = @(
                            @{
                                decoratedText = @{
                                    topLabel = "Started At"
                                    text = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Completed At"
                                    text = $EndTime.ToString("yyyy-MM-dd HH:mm:ss")
                                }
                            },
                            @{
                                decoratedText = @{
                                    topLabel = "Duration"
                                    text = "$([math]::Round(($EndTime - $StartTime).TotalSeconds)) seconds"
                                }
                            }
                        )
                    },
                    @{
                        widgets = @(
                            @{
                                textParagraph = @{
                                    text = "<i>Regards, IT Team</i>"
                                }
                            }
                        )
                    }
                )
            }
        }
    )
} | ConvertTo-Json -Depth 10

Invoke-RestMethod `
    -Uri $WEBHOOK_URL `
    -Method Post `
    -ContentType "application/json" `
    -Body $Payload

exit $ExitCode
