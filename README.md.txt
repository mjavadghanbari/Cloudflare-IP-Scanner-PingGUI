<p align="center">
  <kbd>🇮🇷 فارسی</kbd> &nbsp; <a href="README_EN.md"><kbd>🇬🇧 English</kbd></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white" alt="Platform">
  <img src="https://img.shields.io/badge/Language-PowerShell-5391FE?logo=powershell&logoColor=white" alt="Language">
  <img src="https://img.shields.io/badge/GUI-Windows%20Forms-2E77BC" alt="GUI">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

# Cloudflare IP Scanner — Ping GUI

یک ابزار **دسکتاپ سبک برای ویندوز** جهت تست تأخیر TCP و پیدا کردن سریع بهترین و سالم‌ترین IPهای کلادفلر.

به‌جای تکیه بر یک IP ثابت، این ابزار آدرس‌های IPv4 و رنج‌های CIDR را اسکن می‌کند، تأخیر اتصال را روی پورت دلخواه اندازه می‌گیرد و نتایج را بر اساس کیفیت پاسخ مرتب می‌سازد — همه این‌ها در یک رابط گرافیکی تمیز.

## ✨ امکانات

- 🖥️ رابط گرافیکی ساده مبتنی بر Windows Forms
- 🌐 پشتیبانی از IP تکی و رنج‌های CIDR
- 🎯 نمونه‌برداری خودکار از هاست‌ها در ساب‌نت‌های بزرگ
- ⚡ اسکن موازی با تعداد ورکر قابل تنظیم
- 📊 محاسبه بهترین / میانه تأخیر
- 📉 تشخیص قطعی اتصال و تایم‌اوت
- 📁 خروجی گرفتن از نتایج به‌صورت CSV
- 📋 کپی بهترین IP در کلیپ‌بورد با یک کلیک
- 🛑 توقف ایمن اسکن در هر لحظه

## 🚀 نحوه کار

برنامه اتصال TCP را روی یک پورت هدف تست می‌کند و موارد زیر را ثبت می‌کند:

- **بهترین تأخیر** (میلی‌ثانیه)
- **میانه تأخیر** (میلی‌ثانیه)
- **درصد قطعی** (%)
- **وضعیت اتصال**

نتایج به‌گونه‌ای مرتب می‌شوند که سریع‌ترین IPها اول نمایش داده شوند.

## 🎯 کاربرد پیش‌فرض

برنامه به‌صورت پیش‌فرض با رنج‌های متداول **IPv4 کلادفلر** بارگذاری می‌شود، اما با هر آدرس IPv4 یا رنج CIDR معتبر دیگری هم کار می‌کند.

## ⚙️ پیش‌نیازها

- ویندوز
- Windows PowerShell
- پشتیبانی از .NET / Windows Forms (به‌صورت پیش‌فرض در PowerShell ویندوز موجود است)

## ▶️ اجرا

فایل زیر را اجرا کنید:
```bat
Start-CloudflarePingGui.bat
