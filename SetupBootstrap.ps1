# ============================================================
# WINDOWS BOOTSTRAP – COMPLETE SETUP
# Aggressive debloat + privacy + developer tools
# ============================================================

Set-ExecutionPolicy Bypass -Scope Process -Force

Write-Host "=== Starting Bootstrap ===" -ForegroundColor Cyan

# ------------------------------------------------------------
# UTILITY FUNCTIONS
# ------------------------------------------------------------
function Install-IfMissing {
    param($pkgId)
    if (-not (winget list --id $pkgId --disable-interactivity | Select-String $pkgId)) {
        Write-Host "Installing $pkgId..." -ForegroundColor Yellow
        winget install --id $pkgId --accept-source-agreements --accept-package-agreements --silent
    } else {
        Write-Host "$pkgId is already installed." -ForegroundColor DarkGray
    }
}

function Disable-ServiceSafe {
    param($name)
    if (Get-Service -Name $name -ErrorAction SilentlyContinue) {
        Stop-Service $name -Force -ErrorAction SilentlyContinue
        Set-Service $name -StartupType Disabled
    }
}

# ------------------------------------------------------------
# DEBLOAT – LEVEL B (AGGRESSIVE)
# ------------------------------------------------------------
Write-Host "=== Removing bloatware (aggressive) ===" -ForegroundColor Cyan

$packagesToRemove = @(
    "Microsoft.3DViewer",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MixedReality.Portal",
    "Microsoft.People",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.OneNote",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.Clipchamp",
    "MicrosoftTeams",
    "Microsoft.BingNews",
    "Microsoft.MSPaint"
)

foreach ($p in $packagesToRemove) {
    Get-AppxPackage -Name $p -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $p } |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

Write-Host "=== Configuring privacy settings ===" -ForegroundColor Cyan

# Minimal telemetry
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f

# Disable consumer features
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableConsumerFeatures /t REG_DWORD /d 1 /f

# Disable Start menu suggestions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSyncProviderNotifications /t REG_DWORD /d 0 /f

# Disable other privacy-intrusive keys
$privacyKeys = @{
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" = @(
        "TailoredExperiencesWithDiagnosticDataEnabled",
        "AdvertisingId",
        "LetAppsAccessMotion",
        "LetAppsAccessLocation",
        "LetAppsAccessContacts"
    )
}

foreach ($path in $privacyKeys.Keys) {
    foreach ($value in $privacyKeys[$path]) {
        reg add $path /v $value /t REG_DWORD /d 0 /f
    }
}

# ------------------------------------------------------------
# CLASSIC CONTEXT MENU + START LEFT
# ------------------------------------------------------------
Write-Host "=== Adjusting shell appearance ===" -ForegroundColor Cyan

# Classic context menu
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f

# Start menu left alignment
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f

# ------------------------------------------------------------
# INSTALL APPLICATIONS
# ------------------------------------------------------------
Write-Host "=== Installing applications ===" -ForegroundColor Cyan

$apps = @(
    "7zip.7zip",
    "Git.Git",
    "Microsoft.VisualStudioCode",
    "Google.Chrome",
    "Brave.Brave",
    "Mozilla.Thunderbird",
    "Notepad++.Notepad++",
    "Docker.DockerDesktop",
    "Microsoft.Office",
    "Bitwarden.Bitwarden",
    "Nextcloud.NextcloudDesktop",
    "Python.Python.3",
    "MullvadVPN.MullvadVPN",
    "Safing.Portmaster",
    "Google.AndroidStudio",
    "Microsoft.Powershell"
)

foreach ($app in $apps) { Install-IfMissing $app }

# ------------------------------------------------------------
# PIPX
# ------------------------------------------------------------
Write-Host "=== Installing pipx ===" -ForegroundColor Cyan
python -m pip install --upgrade pip
python -m pip install pipx
pipx ensurepath

# ------------------------------------------------------------
# WSL + FEDORA REMIX
# ------------------------------------------------------------
Write-Host "=== Installing WSL + Fedora Remix ===" -ForegroundColor Cyan
wsl --install
Install-IfMissing "WhitewaterFoundry.FedoraRemixforWSL"
wsl --install -d fedoraremix 2>$null

# ------------------------------------------------------------
# OH MY POSH + NERD FONTS
# ------------------------------------------------------------
Write-Host "=== Configuring Oh My Posh ===" -ForegroundColor Cyan
Install-Module oh-my-posh -Scope AllUsers -Force
Install-Module PSReadLine -Force
oh-my-posh font install CascadiaCode -q

# ------------------------------------------------------------
# POWERSHELL PROFILE
# ------------------------------------------------------------
Write-Host "=== Setting up PowerShell profile ===" -ForegroundColor Cyan

$profileContent = @"
# ----- PowerShell Profile -----

Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History

# Oh My Posh
oh-my-posh init pwsh --config `$(oh-my-posh config export --stdout)` | Invoke-Expression

# Winget autocomplete
winget completion powershell | Out-String | Add-Content \$PROFILE

# Aliases
Set-Alias psa "Start-Process powershell -Verb RunAs"
function upg { winget upgrade --all --silent --accept-source-agreements --accept-package-agreements }
"@

New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force | Out-Null
Set-Content -Path $PROFILE -Value $profileContent -Force

# ------------------------------------------------------------
# RESTART EXPLORER
# ------------------------------------------------------------
Write-Host "Restarting Explorer..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force

Write-Host "=== Bootstrap finished ===" -ForegroundColor Green
