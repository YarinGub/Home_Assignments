param(
  [Parameter(Mandatory=$true)][string]$OutFile,
  [Parameter(Mandatory=$true)][string]$SinceUtcIso
)

$ErrorActionPreference = "Stop"

function Write-Err([string]$msg) {
  $errFile = [System.IO.Path]::ChangeExtension($OutFile, ".error.txt")
  $msg | Out-File -Encoding UTF8 $errFile
}

try {
  $since = [DateTime]::Parse($SinceUtcIso).ToUniversalTime()

  # Try filtered export first
  $events = @()
  try {
    $events = Get-WinEvent -FilterHashtable @{
      LogName   = "Microsoft-Windows-Sysmon/Operational"
      StartTime = $since
    } -ErrorAction Stop
  } catch {
    # We'll fall back below
    $events = @()
  }

  # Fallback if filter returns nothing
  if ($events.Count -eq 0) {
    $events = Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 200 -ErrorAction Stop
  }

  $events | ForEach-Object {
    [PSCustomObject]@{
      timeCreated = $_.TimeCreated.ToUniversalTime().ToString("o")
      id          = $_.Id
      message     = $_.Message
    }
  } | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 $OutFile

} catch {
  Write-Err ("Sysmon export failed: " + $_.Exception.Message + "`r`n" +
             "Tip: Run PowerShell as Administrator to read Sysmon logs.")
  # still create an empty json to keep pipeline consistent
  "[]" | Out-File -Encoding UTF8 $OutFile
  exit 1
}
