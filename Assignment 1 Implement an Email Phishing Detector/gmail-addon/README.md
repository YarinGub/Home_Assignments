# Gmail Phishing Detector Add-on 🛡️

A Google Apps Script-based Gmail add-on that analyzes incoming emails for phishing indicators in real-time.

## Features
- **Whitelist Protection**: Automatically marks emails from trusted domains (Google, Microsoft, etc.) as safe to prevent false positives.
- **Urgent Language Detection**: Scans for high-pressure keywords like "Urgent", "Account Locked", or "Verify".
- **Typosquatting Analysis**: Uses a string similarity algorithm (Levenshtein Distance) to detect domains mimicking popular brands (e.g., `paypa1.com`).
- **Technical Indicator Scan**: Identifies suspicious IP addresses and high-risk TLDs (e.g., `.zip`, `.xyz`).

## How it Works
The add-on triggers when an email is opened. It extracts the sender's info and message body, runs them through a weighted scoring engine, and displays a security card in the Gmail sidebar with the risk verdict.

## Installation for Testing
1. Go to [script.google.com](https://script.google.com).
2. Create a new project and paste the contents of `Code.gs`.
3. Enable the manifest file in Project Settings and paste the content of `appsscript.json`.
4. Click **Deploy** -> **Test deployments**.
5. Click **Install** and refresh your Gmail.