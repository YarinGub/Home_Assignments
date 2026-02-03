# Malware Analysis Sandbox – Assignment 2

## Overview
This project implements a **Windows-based malware analysis sandbox** for dynamic analysis of suspicious samples.  
The sandbox executes a sample in an isolated environment, monitors its behavior, and generates a structured analysis report.

The focus is on **behavioral observation**, not detection.

Features:
- Automated execution and monitoring pipeline
- File system snapshots (before / after execution)
- Sysmon-based process and system event collection
- Automatic report generation
- *(Bonus)* Graphical user interface (UI) for managing runs and viewing reports

---

## Environment
- Windows Virtual Machine
- PowerShell 5+
- Sysmon installed and enabled
- Administrator privileges required
- Network isolation recommended

---

## Project Structure

sandbox/
├─ scripts/
│  ├─ fs_snapshot.ps1
│  ├─ export_sysmon.ps1
│  ├─ generate_report.ps1
│  └─ sandbox_ui.ps1   # Bonus UI
└─ in/
   └─ fake_malware.ps1

Each execution produces a run directory under:
C:\Sandbox\out\<runId>\

---

## Analysis Pipeline
Each run follows these steps:

1. Initialization – create run directory and record start time  
2. Pre-execution snapshot – capture filesystem state (fs_before.json)  
3. Sample execution – run the sample with a time limit  
4. Post-execution snapshot – capture filesystem changes (fs_after.json)  
5. Sysmon collection – export relevant system events (sysmon.json)  
6. Report generation – generate report.md summarizing behavior  

---

## Output Artifacts

Each run directory contains:

- since_utc.txt – execution start time
- fs_before.json – filesystem snapshot before execution
- fs_after.json – filesystem snapshot after execution
- sysmon.json – Sysmon event log
- report.md – final behavioral analysis report

---

## Running the Sandbox (CLI)

Run PowerShell as Administrator:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$runId = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmss")
$outDir = "C:\Sandbox\out\$runId"
New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$paths = @("$env:TEMP", "C:\Sandbox\in")

& "sandbox\scripts\fs_snapshot.ps1" -Paths $paths -OutFile "$outDir\fs_before.json"

$since = (Get-Date).AddMinutes(-10).ToUniversalTime().ToString("o")
$since | Out-File "$outDir\since_utc.txt"

powershell -ExecutionPolicy Bypass -File "sandbox\in\fake_malware.ps1"
Start-Sleep -Seconds 3

& "sandbox\scripts\fs_snapshot.ps1" -Paths $paths -OutFile "$outDir\fs_after.json"

& "sandbox\scripts\export_sysmon.ps1" -OutFile "$outDir\sysmon.json" -SinceUtcIso $since

& "sandbox\scripts\generate_report.ps1" -RunDir $outDir

---

## Bonus: User Interface (UI)

A PowerShell WinForms UI is included to simplify sandbox operation.

Features:
- Start / stop analysis runs
- Automatic run management
- Live execution logs
- Integrated report viewer

Run the UI:

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
& "sandbox\scripts\sandbox_ui.ps1"

---

## Safety Notes
- All execution is performed inside a virtual machine
- The sample is a controlled simulation
- Network access can be disabled
- Sysmon access requires Administrator privileges

---

## Conclusion
This project demonstrates an end-to-end malware analysis workflow combining controlled execution, behavioral monitoring, and automated reporting.  
The solution is modular, extensible, and suitable as a foundation for more advanced sandboxing systems.
