<#
.SYNOPSIS
Complete Windows 10/11 PowerShell bootstrap script for DevOps, Dev, and content creation.
Includes debloat, privacy, essential apps, Node.js, Postman, Minikube, Ansible, Prometheus, Grafana, Oh My Posh, WSL+Fedora.
#>

Set-ExecutionPolicy Bypass -Scope Process -Force

$LogPath = "$env:USERPROFILE\SetupBootstrap.log"
Start-Transcript -Path $LogPath -Force

Write-Host "=== Starting Full Windows Bootstrap ===" -ForegroundColor Cyan

# =============================
# UTILITY FUNCTIONS
# =============================
function Install-IfMissing {
    param($pkgId)
    if (-not (winget list --id $pkgId --disable-interactivity | Select-String $pkgId)) {
        Write-Host "Installing $pkgId..." -ForegroundColor Yellow
        winget install --id $pkgId --accept-source-agreements --accept-package-agreements --silent
    } else {
        Write-Host "$pkgId is already installed." -ForegroundColor DarkGray
    }
}

function Debloat-System {
    Write-Host "=== Debloating Windows ===" -ForegroundColor Cyan
    $packagesToRemove = @(
        "Microsoft.3DViewer","Microsoft.XboxApp","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider",
        "Microsoft.GamingApp","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.MSPaint","Microsoft.OneNote",
        "Microsoft.WindowsFeedbackHub","Microsoft.Clipchamp","MicrosoftTeams","Microsoft.BingNews"
    )
    foreach ($p in $packagesToRemove) {
        Get-AppxPackage -Name $p -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $p } |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }

    # Privacy & telemetry
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableConsumerFeatures /t REG_DWORD /d 1 /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSyncProviderNotifications /t REG_DWORD /d 0 /f
}

function Configure-Shell {
    Write-Host "=== Configuring Start Menu and Context Menu ===" -ForegroundColor Cyan
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f
    reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAl /t REG_DWORD /d 0 /f
}

function Install-Apps {
    Write-Host "=== Installing Apps ===" -ForegroundColor Cyan
    $apps = @(
        "7zip.7zip","Git.Git","Microsoft.VisualStudioCode","Google.Chrome","Brave.Brave",
        "Mozilla.Thunderbird","Notepad++.Notepad++","Docker.DockerDesktop","Microsoft.Office",
        "Bitwarden.Bitwarden","Nextcloud.NextcloudDesktop","Python.Python.3","MullvadVPN.MullvadVPN",
        "Safing.Portmaster","Google.AndroidStudio","Microsoft.PowerShell",
        "OpenJS.NodeJS","Postman.Postman","Minikube.Minikube","Grafana.Grafana"
    )
    foreach ($app in $apps) { Install-IfMissing $app }
}

function Setup-WSL {
    Write-Host "=== Installing WSL and Fedora Remix ===" -ForegroundColor Cyan
    wsl --install --no-distribution
    Install-IfMissing "WhitewaterFoundry.FedoraRemixforWSL"
    wsl --install -d fedoraremix 2>$null
    # Install Ansible inside WSL
    wsl -d fedoraremix -- sudo dnf install ansible -y
}

function Setup-OhMyPosh {
    Write-Host "=== Installing Oh My Posh ===" -ForegroundColor Cyan
    Install-Module oh-my-posh -Scope AllUsers -Force
    Install-Module PSReadLine -Force
    oh-my-posh font install CascadiaCode -q
}

function Configure-Profile {
    Write-Host "=== Configuring PowerShell Profile ===" -ForegroundColor Cyan
    $profileContent = @'
# Alias and functions
function psa { Start-Process powershell -Verb RunAs }
function upg { winget upgrade --all --silent --accept-source-agreements --accept-package-agreements }

# Winget autocomplete
winget completion powershell | Out-String | Invoke-Expression

# Git completions
Register-ArgumentCompleter -CommandName git -ScriptBlock {
    param($wordToComplete,$commandAst,$cursorPosition)
    $completions = git help -a 2>$null | Select-String "^[ ]{2}\w" | ForEach-Object { $_.ToString().Trim() }
    $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_,$_, 'ParameterValue',$_)
    }
}

# Oh My Posh
oh-my-posh init pwsh --config "$(oh-my-posh config export --stdout)" | Invoke-Expression
'@
    New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force | Out-Null
    Set-Content -Path $PROFILE -Value $profileContent -Force
}

function Install-Pipx {
    Write-Host "=== Installing pipx ===" -ForegroundColor Cyan
    python -m pip install --upgrade pip
    python -m pip install pipx
    pipx ensurepath
}

function Install-Prometheus {
    Write-Host "=== Installing Prometheus CLI ===" -ForegroundColor Cyan
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'AMD64') {'windows-amd64'} else {'windows-386'}
    $promUrl = "https://github.com/prometheus/prometheus/releases/latest/download/prometheus-$arch.zip"
    $promZip = "$env:TEMP\prometheus.zip"
    Invoke-WebRequest -Uri $promUrl -OutFile $promZip -UseBasicParsing
    Expand-Archive $promZip -DestinationPath "C:\Prometheus" -Force
    [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Prometheus", [EnvironmentVariableTarget]::Machine)
}

function Restart-Explorer {
    Write-Host "=== Restarting Explorer ===" -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
    Start-Process explorer.exe
}

# =============================
# RUN ALL STEPS
# =============================
Debloat-System
Configure-Shell
Install-Apps
Setup-WSL
Setup-OhMyPosh
Configure-Profile
Install-Pipx
Install-Prometheus
Restart-Explorer

Write-Host "=== Full Windows Bootstrap Finished ===" -ForegroundColor Green
Stop-Transcript
