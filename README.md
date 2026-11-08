
# Android Root Checker

A simple PowerShell script for checking Android device root status using official platform tools (ADB and Fastboot, Powershell etc) on Windows 11.



## Features

- Detect connected Android devices.
- Check Android root status.
- Detect available `su` binaries.
- Verify root privileges (UID 0).
- Detect ADB authorization status.
- Identify Fastboot mode.
- Display device information.

## Requirements

- Windows 10 / 11
- PowerShell 5.1 or later
- Android SDK Platform-Tools
- USB data cable 
- Android USB Debugging enabled

## 1\. Download ADB & Fastboot

Download the official Google Platform-Tools package:

**Windows ZIP:**\
https://dl.google.com/android/repository/platform-tools-latest-windows.zip

**Official Documentation:**\
[https://developer.android.com/tools/releases/platform-tools](https://developer.android.com/tools/releases/platform-tools)

Extract the ZIP file to:

text

```text
C:\platform-tools
```

## 2\. Connect Android Device

1. Enable Developer Options on Android.
2. Enable USB Debugging.
3. Connect your device to Windows 11.
4. Accept the USB Debugging authorization prompt.

Open PowerShell:

powershell

```powershell
cd C:\platform-tools
```

Check ADB connection:

powershell

```powershell
.\adb.exe devices
```

Your device should appear with the status `device`.

## 3\. Check Fastboot Connection

Reboot into Fastboot mode:

powershell

```powershell
.\adb.exe reboot bootloader
```

Check connection:

powershell

```powershell
.\fastboot.exe devices
```

Return to Android:

powershell

```powershell
.\fastboot.exe reboot
```

**Note:** Root status must be checked from Android through ADB, not directly through Fastboot.

## 4\. Run Android Root Checker

Place `Android-Root-Checker.ps1` in your same path where you unzip "platform tools" directory.

Execute:

powershell

```powershell
.\Android-Root-Checker.ps1
```

If execution policy blocks the script then use:

powershell

```powershell
Set-ExecutionPolicy -Scope Process Bypass
```

Then run the script again.

## 5\. Root Status Results

| Status       | Description                       |
| ------------ | --------------------------------- |
| ROOTED       | Root privileges (UID 0) verified  |
| NOT ROOTED   | Root access not detected          |
| UNKNOWN      | Root status could not be verified |
| UNAUTHORIZED | ADB authorization required        |
| FASTBOOT     | Device detected in Fastboot mode  |

_Root detection is diagnostic and may not identify every root-management configuration._

## 6\. Troubleshooting

**ADB device not detected:**

powershell

```powershell
.\adb.exe kill-server
.\adb.exe start-server
.\adb.exe devices
```

**Fastboot device not detected:**

- Install the appropriate USB driver.
- Try another USB port or data cable.
- Verify that the device is in Fastboot mode.
- Make sure USB debugging on & File Transfer Mode.

**ADB unauthorized:**

- Unlock your Android device.
- Accept the USB Debugging authorization prompt.

## Additional Information

- Uses Google's official Android SDK Platform-Tools.
- Does not automatically root or modify devices.
- Does not unlock the bootloader or flash firmware.
- No external server or data upload is required.
- Root detection depends on device configuration and root-manager permissions.

## Official Resources

- [Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools)
- [ADB Documentation](https://developer.android.com/tools/adb)
- [Fastboot Documentation](https://developer.android.com/tools/fastboot)

## Disclaimer

This project is intended for educational and diagnostic purposes only. The developer is not responsible for device damage or data loss.

