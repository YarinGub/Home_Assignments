Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ---------------- Configuration ----------------
$BaseOut = "C:\Sandbox\out"
$Scripts = "C:\Sandbox\scripts"
$Sample  = "C:\Sandbox\in\fake_malware.ps1"

$FsSnap    = Join-Path $Scripts "fs_snapshot.ps1"
$ReportGen = Join-Path $Scripts "generate_report.ps1"

# ---------------- Helpers ----------------
function Log([System.Windows.Forms.TextBox]$box, [string]$msg) {
  $ts = (Get-Date).ToString("HH:mm:ss")
  $box.AppendText("[$ts] $msg`r`n")
}

function Ensure-Paths {
  foreach ($p in @("C:\Sandbox\in","C:\Sandbox\out","C:\Sandbox\scripts")) {
    if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
  }
  foreach ($p in @($FsSnap,$ReportGen,$Sample)) {
    if (!(Test-Path $p)) { throw "Missing required file: $p" }
  }
}

function New-RunDir {
  $runId = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss")
  $outDir = Join-Path $BaseOut $runId
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
  return $outDir
}

function Refresh-Runs([System.Windows.Forms.ListBox]$listBox) {
  $listBox.Items.Clear()
  if (!(Test-Path $BaseOut)) { return }
  Get-ChildItem $BaseOut -Directory | Sort-Object Name -Descending | ForEach-Object {
    $report = Join-Path $_.FullName "report.md"
    $tag = if (Test-Path $report) { "✅" } else { "…" }
    [void]$listBox.Items.Add("$tag  $($_.Name)")
  }
}

function Get-SelectedRunName([System.Windows.Forms.ListBox]$listRuns) {
  $sel = $listRuns.SelectedItem
  if (-not $sel) { return $null }
  return ($sel -replace '^[^0-9]*\s+','').Trim()
}

function Load-ReportIntoViewer([string]$runDir, [System.Windows.Forms.TextBox]$viewer, [System.Windows.Forms.Label]$lbl) {
  $rp = Join-Path $runDir "report.md"
  if (Test-Path $rp) {
    $viewer.Text = Get-Content $rp -Raw
    $lbl.Text = "Report: $rp"
  } else {
    $viewer.Text = ""
    $lbl.Text = "Report: (not found)"
  }
}

function Cleanup-RunningStuff {
  try {
    if ($script:sampleProc -ne $null -and -not $script:sampleProc.HasExited) {
      $script:sampleProc.Kill()
    }
  } catch {}
  $script:sampleProc = $null

  # best-effort cleanup
  try { Get-Process notepad -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue } catch {}
}

# ---------------- UI ----------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "Malware Sandbox UI"
$form.Size = New-Object System.Drawing.Size(1120, 610)
$form.StartPosition = "CenterScreen"

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Analysis"
$btnStart.Location = New-Object System.Drawing.Point(20, 20)
$btnStart.Size = New-Object System.Drawing.Size(140, 35)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "Stop"
$btnStop.Location = New-Object System.Drawing.Point(170, 20)
$btnStop.Size = New-Object System.Drawing.Size(90, 35)
$btnStop.Enabled = $false

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh Runs"
$btnRefresh.Location = New-Object System.Drawing.Point(270, 20)
$btnRefresh.Size = New-Object System.Drawing.Size(120, 35)

$btnLoadReport = New-Object System.Windows.Forms.Button
$btnLoadReport.Text = "Load Report"
$btnLoadReport.Location = New-Object System.Drawing.Point(400, 20)
$btnLoadReport.Size = New-Object System.Drawing.Size(120, 35)

$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = "Open Run Folder"
$btnOpenFolder.Location = New-Object System.Drawing.Point(530, 20)
$btnOpenFolder.Size = New-Object System.Drawing.Size(140, 35)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Status: Idle"
$lblStatus.Location = New-Object System.Drawing.Point(20, 70)
$lblStatus.Size = New-Object System.Drawing.Size(1060, 20)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 100)
$txtLog.Size = New-Object System.Drawing.Size(580, 450)
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true

$listRuns = New-Object System.Windows.Forms.ListBox
$listRuns.Location = New-Object System.Drawing.Point(620, 100)
$listRuns.Size = New-Object System.Drawing.Size(470, 180)

$lblReport = New-Object System.Windows.Forms.Label
$lblReport.Text = "Report: (select a run)"
$lblReport.Location = New-Object System.Drawing.Point(620, 290)
$lblReport.Size = New-Object System.Drawing.Size(470, 20)

$txtReport = New-Object System.Windows.Forms.TextBox
$txtReport.Location = New-Object System.Drawing.Point(620, 315)
$txtReport.Size = New-Object System.Drawing.Size(470, 235)
$txtReport.Multiline = $true
$txtReport.ScrollBars = "Vertical"
$txtReport.ReadOnly = $true
$txtReport.Font = New-Object System.Drawing.Font("Consolas", 9)

$form.Controls.AddRange(@(
  $btnStart,$btnStop,$btnRefresh,$btnLoadReport,$btnOpenFolder,
  $lblStatus,$txtLog,$listRuns,$lblReport,$txtReport
))

# ---------------- State machine ----------------
$script:cancel = $false
$script:currentRunDir = $null
$script:sampleProc = $null
$script:step = 0
$script:paths = $null

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 250

function Fail([string]$where, [string]$msg) {
  Log $txtLog "ERROR ($where): $msg"
  $timer.Stop()
  $script:step = 0
  $btnStart.Enabled = $true
  $btnStop.Enabled = $false
  $lblStatus.Text = "Status: Failed"
  Refresh-Runs $listRuns
}

function Finish([string]$status) {
  $timer.Stop()
  $script:step = 0
  $btnStart.Enabled = $true
  $btnStop.Enabled = $false
  $lblStatus.Text = "Status: $status"
  Refresh-Runs $listRuns

  if ($script:currentRunDir) {
    Load-ReportIntoViewer $script:currentRunDir $txtReport $lblReport
  }
}

$timer.Add_Tick({
  try {
    if ($script:cancel) {
      Log $txtLog "Cancel requested -> cleaning up..."
      Cleanup-RunningStuff
      $script:cancel = $false
      Finish "Cancelled"
      return
    }

    switch ($script:step) {

      1 {
        try {
          Log $txtLog "Step 1/6: Before snapshot..."
          $before = Join-Path $script:currentRunDir "fs_before.json"
          & $FsSnap -Paths $script:paths -OutFile $before | Out-Null
          if (!(Test-Path $before)) { throw "fs_before.json was not created" }
          Log $txtLog "Created: $before"
          $script:step = 2
        } catch { Fail "BeforeSnapshot" $_.Exception.Message }
      }

      2 {
        try {
          Log $txtLog "Step 2/6: Execute sample..."
          $psi = New-Object System.Diagnostics.ProcessStartInfo
          $psi.FileName = "powershell.exe"
          $psi.Arguments = "-ExecutionPolicy Bypass -File `"$Sample`""
          $psi.UseShellExecute = $false
          $psi.CreateNoWindow = $true
          $script:sampleProc = [System.Diagnostics.Process]::Start($psi)
          Log $txtLog "Sample PID: $($script:sampleProc.Id)"
          $script:step = 3
        } catch { Fail "ExecuteSample" $_.Exception.Message }
      }

      3 {
        # Wait for sample to exit
        if ($script:sampleProc -ne $null -and -not $script:sampleProc.HasExited) { return }
        Start-Sleep -Milliseconds 150
        $script:step = 4
      }

      4 {
        try {
          Log $txtLog "Step 3/6: After snapshot..."
          $after = Join-Path $script:currentRunDir "fs_after.json"
          & $FsSnap -Paths $script:paths -OutFile $after | Out-Null
          if (!(Test-Path $after)) { throw "fs_after.json was not created" }
          Log $txtLog "Created: $after"
          $script:step = 5
        } catch { Fail "AfterSnapshot" $_.Exception.Message }
      }

      5 {
        try {
          Log $txtLog "Step 4/6: Export Sysmon (200 latest events)..."
          $sys = Join-Path $script:currentRunDir "sysmon.json"
          Get-WinEvent -LogName "Microsoft-Windows-Sysmon/Operational" -MaxEvents 200 |
            ForEach-Object {
              [PSCustomObject]@{
                timeCreated = $_.TimeCreated.ToUniversalTime().ToString("o")
                id          = $_.Id
                message     = $_.Message
              }
            } | ConvertTo-Json -Depth 4 | Out-File -Encoding UTF8 $sys

          if (!(Test-Path $sys)) { throw "sysmon.json was not created" }
          $len = (Get-Item $sys).Length
          Log $txtLog "Created: $sys (bytes=$len)"
          if ($len -eq 0) { Log $txtLog "WARNING: sysmon.json is empty. (Are you running the UI as Administrator?)" }
          $script:step = 6
        } catch { Fail "ExportSysmon" $_.Exception.Message }
      }

      6 {
        try {
          Log $txtLog "Step 5/6: Generate report..."
          & $ReportGen -RunDir $script:currentRunDir | Out-Null
          $rp = Join-Path $script:currentRunDir "report.md"
          if (!(Test-Path $rp)) { throw "report.md was not created" }
          Log $txtLog "Created: $rp"
          Finish "Idle (Done)"
        } catch { Fail "GenerateReport" $_.Exception.Message }
      }
    }
  } catch {
    Fail "Timer" $_.Exception.Message
  }
})

# ---------------- Buttons ----------------
$btnStart.Add_Click({
  try {
    Ensure-Paths
    $script:cancel = $false

    $script:currentRunDir = New-RunDir
    $lblStatus.Text = "Status: Running ($script:currentRunDir)"
    $btnStart.Enabled = $false
    $btnStop.Enabled = $true

    # keep scope small to avoid huge snapshots
    $script:paths = @("$env:TEMP","C:\Sandbox\in")

    $since = (Get-Date).ToUniversalTime().ToString("o")
    $since | Out-File (Join-Path $script:currentRunDir "since_utc.txt")
    Log $txtLog "RunDir: $script:currentRunDir"
    Log $txtLog "Created: $(Join-Path $script:currentRunDir "since_utc.txt")"

    Log $txtLog "Starting pipeline..."
    $script:step = 1
    $timer.Start()
  } catch {
    Fail "Start" $_.Exception.Message
  }
})

$btnStop.Add_Click({
  Log $txtLog "Stop clicked."
  $script:cancel = $true
})

$btnRefresh.Add_Click({ Refresh-Runs $listRuns })

$btnLoadReport.Add_Click({
  $name = Get-SelectedRunName $listRuns
  if (-not $name) { return }
  $rd = Join-Path $BaseOut $name
  Load-ReportIntoViewer $rd $txtReport $lblReport
})

$btnOpenFolder.Add_Click({
  if ($script:currentRunDir -and (Test-Path $script:currentRunDir)) {
    Start-Process explorer.exe $script:currentRunDir
    return
  }
  $name = Get-SelectedRunName $listRuns
  if (-not $name) { return }
  $rd = Join-Path $BaseOut $name
  if (Test-Path $rd) { Start-Process explorer.exe $rd }
})

$listRuns.Add_SelectedIndexChanged({
  $name = Get-SelectedRunName $listRuns
  if (-not $name) { return }
  $rd = Join-Path $BaseOut $name
  Load-ReportIntoViewer $rd $txtReport $lblReport
})

# ---------------- Init ----------------
Refresh-Runs $listRuns
Log $txtLog "Ready. (Run as Administrator is required to read Sysmon logs.)"
Log $txtLog "Tip: If snapshot is slow, reduce monitored paths."

[void]$form.ShowDialog()
