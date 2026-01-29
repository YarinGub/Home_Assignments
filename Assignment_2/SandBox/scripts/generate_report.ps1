param(
  [Parameter(Mandatory=$true)][string]$RunDir
)

$ErrorActionPreference = "Stop"

function Load-JsonArray($path) {
  if (!(Test-Path $path)) { return @() }
  $raw = Get-Content $path -Raw
  if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
  $obj = $raw | ConvertFrom-Json
  if ($obj -is [System.Array]) { return $obj }
  return @($obj)
}

$beforePath = Join-Path $RunDir "fs_before.json"
$afterPath  = Join-Path $RunDir "fs_after.json"
$sysmonPath = Join-Path $RunDir "sysmon.json"

$before = Load-JsonArray $beforePath
$after  = Load-JsonArray $afterPath
$sysmon = Load-JsonArray $sysmonPath

# --- FS diff ---
$b = @{}; foreach ($x in $before) { if ($x.path) { $b[$x.path] = $x } }
$a = @{}; foreach ($x in $after)  { if ($x.path) { $a[$x.path] = $x } }

$created  = @()
$deleted  = @()
$modified = @()

foreach ($p in $a.Keys) { if (-not $b.ContainsKey($p)) { $created += $a[$p] } }
foreach ($p in $b.Keys) { if (-not $a.ContainsKey($p)) { $deleted += $b[$p] } }

foreach ($p in $a.Keys) {
  if ($b.ContainsKey($p)) {
    $old = $b[$p]; $new = $a[$p]
    $oldHash = "" + $old.sha256
    $newHash = "" + $new.sha256
    if (($old.size -ne $new.size) -or ($oldHash -ne $newHash -and $newHash -ne "")) {
      $modified += [PSCustomObject]@{ path=$p; before=$old; after=$new }
    }
  }
}

# --- Sysmon summary (IDs) ---
$proc = $sysmon | Where-Object { [int]$_.id -eq 1 }
$net  = $sysmon | Where-Object { [int]$_.id -eq 3 }
$file = $sysmon | Where-Object { [int]$_.id -eq 11 }

# Extract a simple "headline" from message (first line)
function Headline($msg) {
  if ($null -eq $msg) { return "" }
  $s = "" + $msg
  $parts = $s -split "`r?`n"
  return $parts[0].Trim()
}

$reportPath = Join-Path $RunDir "report.md"

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Malware Behavior Report")
$md.Add("")
$md.Add("**RunDir:** $RunDir")
$md.Add("")
$md.Add("## Summary")
$md.Add("- Processes created (Sysmon ID 1): **$($proc.Count)**")
$md.Add("- Network events (Sysmon ID 3): **$($net.Count)**")
$md.Add("- FileCreate events (Sysmon ID 11): **$($file.Count)**")
$md.Add("- Files created (FS diff): **$($created.Count)**")
$md.Add("- Files modified (FS diff): **$($modified.Count)**")
$md.Add("- Files deleted (FS diff): **$($deleted.Count)**")
$md.Add("")

$md.Add("## Files Created (FS diff)")
if ($created.Count -eq 0) { $md.Add("_None detected in monitored paths._") }
else { $created | Select-Object -First 50 | ForEach-Object { $md.Add("- " + $_.path) } }
$md.Add("")

$md.Add("## Files Modified (FS diff)")
if ($modified.Count -eq 0) { $md.Add("_None detected in monitored paths._") }
else { $modified | Select-Object -First 50 | ForEach-Object { $md.Add("- " + $_.path) } }
$md.Add("")

$md.Add("## Processes (Sysmon ID 1) – top 30")
if ($proc.Count -eq 0) { $md.Add("_No process creation events found._") }
else { $proc | Select-Object -First 30 | ForEach-Object { $md.Add("- [" + $_.timeCreated + "] " + (Headline $_.message)) } }
$md.Add("")

$md.Add("## Network (Sysmon ID 3) – top 30")
if ($net.Count -eq 0) { $md.Add("_No network events found._") }
else { $net | Select-Object -First 30 | ForEach-Object { $md.Add("- [" + $_.timeCreated + "] " + (Headline $_.message)) } }
$md.Add("")

$md.Add("## Notes")
$md.Add("- FS diff is computed by comparing `fs_before.json` vs `fs_after.json`.")
$md.Add("- Sysmon events are exported to JSON and summarized by event IDs and first-line message headlines.")

$md -join "`r`n" | Out-File -Encoding UTF8 $reportPath

Write-Host "✅ Report generated: $reportPath"
