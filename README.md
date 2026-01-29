Cybersecurity Home Assignment - Full Portfolio 🛡️
This repository contains the complete implementation of three cybersecurity assignments, focusing on threat detection, malware analysis, and web security.

📂 Project Overview
1. Email Phishing Detector
A tool that analyzes email content for phishing indicators using heuristic rules and string similarity.

Features: Detects suspicious links (IPs, risky TLDs), spoofed senders (Levenshtein Distance), and urgent language.

Bonus - Streamlit UI: A web dashboard for easy file analysis.

Bonus - Gmail Add-on: Real-time scanning integrated directly into the Gmail sidebar using Google Apps Script.

2. Malware Analysis Sandbox
A controlled environment (Virtual Machine) designed to execute and monitor malicious activity safely.

Setup: Isolated Ubuntu VM with Host-only Adapter network isolation.

Monitoring: Tracking file system changes, network traffic, and process activity using Python, inotify, and psutil.

Reporting: Automated generation of a malware_report.json summarizing the sample's behavior.

3. SQL Injection Simulation & Mitigation
A web application demonstration of authentication bypass attacks and security best practices.

Vulnerability: A login form susceptible to ' OR '1'='1 attacks.

Attack Demonstration: Bypassing authentication without a valid password.

Mitigation: Implementing Parameterized Queries to neutralize SQL injection attempts.

Bonus - UI: A visual interface to toggle between the "Vulnerable" and "Secure" versions of the app.
