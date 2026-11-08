
# =====================================================
# ANDROID ROOT CHECKER For - WINDOWS 11
# Android 11 and newer
# ADB / Magisk / KernelSU / APatch
# Bootloader / Verified Boot / SU detection
# =====================================================

$ErrorActionPreference = "SilentlyContinue"

Clear-Host

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       ANDROID ROOT CHECKER SCRIPT" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Locate ADB
$ADB = Join-Path $PSScriptRoot "adb.exe"

if (!(Test-Path $ADB)) {
    $ADBCommand = Get-Command adb.exe -ErrorAction SilentlyContinue

    if ($ADBCommand) {
        $ADB = $ADBCommand.Source
    }
    else {
        Write-Host "[ERROR] ADB not found!" -ForegroundColor Red
        Write-Host "Install Android Platform Tools."
        Read-Host "Press Enter to exit"
        exit
    }
}

function Get-DeviceProperty {
    param([string]$Name)

    return ((& $ADB shell getprop $Name 2>$null) -join "").Trim()
}

function Show-Result {
    param(
        [string]$Name,
        [string]$Value,
        [string]$Status
    )

    Write-Host ("{0,-35}: {1}" -f $Name, $Value) -NoNewline

    switch ($Status) {
        "GOOD" {
            Write-Host " [OK]" -ForegroundColor Green
        }
        "BAD" {
            Write-Host " [WARNING]" -ForegroundColor Red
        }
        default {
            Write-Host " [INFO]" -ForegroundColor Yellow
        }
    }
}

# -----------------------------------------------------
# 1. ADB CONNECTION
# -----------------------------------------------------

Write-Host "`n[1] ADB CONNECTION" -ForegroundColor Cyan

& $ADB start-server | Out-Null

$Devices = @(& $ADB devices)

$Authorized = @(
    $Devices | Where-Object { $_ -match "^\S+\s+device$" }
)

if ($Authorized.Count -eq 0) {
    Write-Host "[ERROR] No authorized device connected!" -ForegroundColor Red
    Write-Host "Check USB debugging and authorization."
    Read-Host "Press Enter to exit"
    exit
}

Show-Result "ADB Connection" "Connected" "GOOD"

# -----------------------------------------------------
# 2. DEVICE INFORMATION
# -----------------------------------------------------

Write-Host "`n[2] DEVICE INFORMATION" -ForegroundColor Cyan

$Brand = Get-DeviceProperty "ro.product.brand"
$Model = Get-DeviceProperty "ro.product.model"
$Manufacturer = Get-DeviceProperty "ro.product.manufacturer"
$Android = Get-DeviceProperty "ro.build.version.release"
$SDK = Get-DeviceProperty "ro.build.version.sdk"
$Build = Get-DeviceProperty "ro.build.display.id"

Show-Result "Brand" $Brand "INFO"
Show-Result "Manufacturer" $Manufacturer "INFO"
Show-Result "Model" $Model "INFO"
Show-Result "Android Version" $Android "INFO"
Show-Result "SDK Version" $SDK "INFO"
Show-Result "Build Number" $Build "INFO"

# -----------------------------------------------------
# 3. ROOT ACCESS CHECK
# -----------------------------------------------------

Write-Host "`n[3] ROOT ACCESS CHECK" -ForegroundColor Cyan

$RootOutput = (& $ADB shell su -c id 2>&1 | Out-String).Trim()

if ($RootOutput -match "uid=0") {
    $RootStatus = "ROOT ACCESS CONFIRMED"
    Show-Result "Root Access" $RootStatus "GOOD"
}
else {
    $RootStatus = "ROOT ACCESS NOT DETECTED"
    Show-Result "Root Access" $RootStatus "BAD"
}

Write-Host "SU Response: $RootOutput" -ForegroundColor Gray

# -----------------------------------------------------
# 4. ROOT MANAGER DETECTION
# -----------------------------------------------------

Write-Host "`n[4] ROOT MANAGER DETECTION" -ForegroundColor Cyan

$Packages = (& $ADB shell pm list packages 2>$null) -join "`n"

$Managers = @{
    "Magisk"   = "com.topjohnwu.magisk"
    "KernelSU" = "me.weishu.kernelsu"
    "APatch"   = "me.bmax.apatch"
}

foreach ($Manager in $Managers.Keys) {

    $Package = $Managers[$Manager]

    if ($Packages -match [regex]::Escape($Package)) {
        Show-Result $Manager "Package installed" "GOOD"
    }
    else {
        Show-Result $Manager "Package not found" "INFO"
    }
}

# -----------------------------------------------------
# 5. SU BINARY CHECK
# -----------------------------------------------------

Write-Host "`n[5] SU BINARY CHECK" -ForegroundColor Cyan

$SUPaths = @(
    "/system/bin/su",
    "/system/xbin/su",
    "/sbin/su",
    "/system_ext/bin/su",
    "/vendor/bin/su",
    "/product/bin/su",
    "/debug_ramdisk/su"
)

foreach ($Path in $SUPaths) {

    $Output = (& $ADB shell ls -l $Path 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -eq 0 -and
        $Output -notmatch "No such file|not found") {
        Show-Result $Path "Found" "GOOD"
    }
    else {
        Show-Result $Path "Not found" "INFO"
    }
}

# -----------------------------------------------------
# 6. BOOTLOADER STATUS
# -----------------------------------------------------

Write-Host "`n[6] BOOTLOADER STATUS" -ForegroundColor Cyan

$FlashLocked = Get-DeviceProperty "ro.boot.flash.locked"
$DeviceState = Get-DeviceProperty "ro.boot.vbmeta.device_state"

if ($FlashLocked -eq "1") {
    Show-Result "Bootloader Flash Lock" "LOCKED" "GOOD"
}
elseif ($FlashLocked -eq "0") {
    Show-Result "Bootloader Flash Lock" "UNLOCKED" "BAD"
}
else {
    Show-Result "Bootloader Flash Lock" "UNKNOWN" "INFO"
}

if ($DeviceState -eq "locked") {
    Show-Result "VBMeta Device State" "LOCKED" "GOOD"
}
elseif ($DeviceState -eq "unlocked") {
    Show-Result "VBMeta Device State" "UNLOCKED" "BAD"
}
else {
    Show-Result "VBMeta Device State" $DeviceState "INFO"
}

# -----------------------------------------------------
# 7. VERIFIED BOOT STATUS
# -----------------------------------------------------

Write-Host "`n[7] VERIFIED BOOT STATUS" -ForegroundColor Cyan

$VerifiedBoot = Get-DeviceProperty "ro.boot.verifiedbootstate"

switch ($VerifiedBoot) {
    "green" {
        Show-Result "Verified Boot" "GREEN" "GOOD"
    }
    "yellow" {
        Show-Result "Verified Boot" "YELLOW" "INFO"
    }
    "orange" {
        Show-Result "Verified Boot" "ORANGE" "BAD"
    }
    "red" {
        Show-Result "Verified Boot" "RED" "BAD"
    }
    default {
        Show-Result "Verified Boot" $VerifiedBoot "INFO"
    }
}

# -----------------------------------------------------
# 8. ANDROID SECURITY PROPERTIES
# -----------------------------------------------------

Write-Host "`n[8] ANDROID SECURITY PROPERTIES" -ForegroundColor Cyan

$Properties = @(
    "ro.secure",
    "ro.debuggable",
    "ro.build.type",
    "ro.boot.veritymode",
    "ro.boot.vbmeta.avb_version",
    "ro.build.tags"
)

foreach ($Property in $Properties) {
    $Value = Get-DeviceProperty $Property
    Show-Result $Property $Value "INFO"
}

# -----------------------------------------------------
# 9. ADDITIONAL ROOT TRACES
# -----------------------------------------------------

Write-Host "`n[9] ADDITIONAL ROOT TRACES" -ForegroundColor Cyan

$TracePaths = @(
    "/data/adb/magisk",
    "/data/adb/ksu",
    "/data/adb/ap",
    "/data/adb/modules"
)

foreach ($Path in $TracePaths) {

    $Output = (& $ADB shell ls -ld $Path 2>&1 | Out-String).Trim()

    if ($LASTEXITCODE -eq 0 -and
        $Output -notmatch "No such file|not found") {
        Show-Result $Path "Present" "GOOD"
    }
    else {
        Show-Result $Path "Not accessible or absent" "INFO"
    }
}

# -----------------------------------------------------
# 10. FINAL REPORT
# -----------------------------------------------------

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "              FINAL REPORT" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host "Device       : $Brand $Model"
Write-Host "Android      : $Android"
Write-Host "Root Status  : $RootStatus"

if ($FlashLocked -eq "0" -or $DeviceState -eq "unlocked") {
    Write-Host "Bootloader   : UNLOCKED" -ForegroundColor Yellow
}
elseif ($FlashLocked -eq "1" -or $DeviceState -eq "locked") {
    Write-Host "Bootloader   : LOCKED" -ForegroundColor Green
}
else {
    Write-Host "Bootloader   : UNKNOWN" -ForegroundColor Yellow
}

Write-Host "Verified Boot: $VerifiedBoot"

Write-Host "`nIMPORTANT:"
Write-Host "- Missing SU does not prove unrooted status."
Write-Host "- Root manager apps may hide root access."
Write-Host "- Bootloader unlock does not mean rooted."
Write-Host "- Some root traces may be inaccessible to ADB."

Write-Host "`n============================================" -ForegroundColor Cyan

Read-Host "Press Enter to exit"
