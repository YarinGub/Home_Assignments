# Assignment 1: Email Phishing Detector 🛡️

## Objective
Create a script that scans email content for common phishing indicators and alerts the user to potential phishing attempts.

## Features & Implementation
The detector analyzes email content based on the following requirements:
* **Suspicious Links**: Detects IP addresses in URLs and uncommon domains using Regex patterns.
* **Spoofed Senders**: Identifies sender addresses that mimic legitimate brands using string similarity algorithms (Levenshtein Distance).
* **Urgent Language**: Scans for pressure-inducing keywords such as "urgent," "immediately," and "action required."

## Components
1. **Core Script (`detector.py`)**: A CLI tool that accepts a text file and prints a phishing summary with detected indicators.
2. **Web UI (`gui_detector.py`)**: A Streamlit interface for easy file upload and visual result display (Bonus).
3. **Gmail Add-on**: A Google Apps Script integration for real-time inbox scanning (Bonus).

## How to Run
### CLI Version:
```bash
python detector.py