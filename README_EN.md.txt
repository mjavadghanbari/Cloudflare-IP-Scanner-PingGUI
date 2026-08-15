
---

## ۲) فایل `README_EN.md` (انگلیسی)

این محتوا را با اسم دقیق `README_EN.md` ذخیره کن:

`
```markdown
<p align="center">
  <a href="README.md"><kbd>🇮🇷 فارسی</kbd></a> &nbsp; <kbd>🇬🇧 English</kbd>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Language-PowerShell-5391FE?logo=powershell&logoColor=white" alt="Language">
  <img src="https://img.shields.io/badge/GUI-Windows%20Forms-2E77BC" alt="GUI">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

# Cloudflare IP Scanner — Ping GUI

A lightweight **Windows desktop utility** for testing TCP latency and quickly finding the best-performing Cloudflare IPs.

Instead of relying on a single IP, this tool scans IPv4 addresses and CIDR ranges, measures connection latency to a configurable port, and ranks results by response quality — all from a clean Windows GUI.

## ✨ Features

- 🖥️ Simple Windows Forms interface
- 🌐 Supports single IPs and CIDR ranges
- 🎯 Automatic sampling of hosts from large subnets
- ⚡ Parallel scanning with configurable worker count
- 📊 Best / median latency scoring
- 📉 Connection loss and timeout detection
- 📁 Export results to CSV
- 📋 Copy the best IP to clipboard with one click
- 🛑 Stop a scan safely at any time

## 🚀 How It Works

The application tests TCP connectivity against a target port and records:

- **Best latency** (ms)
- **Median latency** (ms)
- **Loss percentage** (%)
- **Connection status**

Results are sorted so the most responsive IPs appear first.

## 🎯 Default Use Case

The app ships preloaded with common **Cloudflare IPv4 ranges**, but it also works with any valid IPv4 address or CIDR range.

## ⚙️ Requirements

- Windows
- Windows PowerShell
- .NET / Windows Forms (available in Windows PowerShell by default)

## ▶️ Launch

Run:
```bat
Start-CloudflarePingGui.bat
