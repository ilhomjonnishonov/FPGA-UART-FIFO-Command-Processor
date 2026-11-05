# ==============================================================================
# Script: push_to_github.ps1
# Description: Automated single-command Git initialization and GitHub publisher
# Location: D:\FPGA_projects\Day03_FIFO\push_to_github.ps1
# ==============================================================================
param (
    [string]$RepoUrl = ""
)

Write-Host "`n[INFO] Starting GitHub deployment..." -ForegroundColor Cyan

# 1. Verify working directory
$ProjectDir = "D:\FPGA_projects\Day03_FIFO"
Set-Location -Path $ProjectDir

# 2. Verify git user configuration
$gitUser = git config user.name
$gitEmail = git config user.email

if ([string]::IsNullOrWhiteSpace($gitUser)) {
    $defaultUser = "FPGA-Developer"
    git config user.name $defaultUser
    Write-Host "[CONFIG] Setting default git user.name: $defaultUser" -ForegroundColor Yellow
}

if ([string]::IsNullOrWhiteSpace($gitEmail)) {
    $defaultEmail = "developer@fpga.local"
    git config user.email $defaultEmail
    Write-Host "[CONFIG] Setting default git user.email: $defaultEmail" -ForegroundColor Yellow
}

# 3. Check or initialize git repository
if (!(Test-Path ".git")) {
    git init
    Write-Host "[SUCCESS] Git repository initialized." -ForegroundColor Green
}

# 4. Prompt or verify remote repository URL
if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
    $existingRemote = git remote get-url origin 2>$null
    if (![string]::IsNullOrWhiteSpace($existingRemote)) {
        Write-Host "[INFO] Using configured remote origin: $existingRemote" -ForegroundColor Green
        $RepoUrl = $existingRemote
    } else {
        $RepoUrl = Read-Host "`nPlease enter your GitHub repository URL (e.g., https://github.com/USERNAME/FPGA-UART-FIFO-Command-Processor.git)"
    }
}

if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
    Write-Host "[ERROR] No repository URL provided. Aborting." -ForegroundColor Red
    exit 1
}

# 5. Configure remote origin
$currentRemote = git remote get-url origin 2>$null
if ([string]::IsNullOrWhiteSpace($currentRemote)) {
    git remote add origin $RepoUrl
    Write-Host "[SUCCESS] Remote origin added: $RepoUrl" -ForegroundColor Green
} else {
    git remote set-url origin $RepoUrl
    Write-Host "[SUCCESS] Remote origin updated: $RepoUrl" -ForegroundColor Green
}

# 6. Stage tracked files
Write-Host "`n[STAGE] Staging modified files..." -ForegroundColor Cyan
git add .

# 7. Commit changes
$status = git status --porcelain
if (![string]::IsNullOrWhiteSpace($status)) {
    $commitMsg = "FPGA UART FIFO Command Processor: Synchronous FIFO and UART Command Engine on Zynq UltraScale+"
    git commit -m $commitMsg
    Write-Host "[SUCCESS] Commit created: '$commitMsg'" -ForegroundColor Green
} else {
    Write-Host "[INFO] Working tree clean. No new changes to commit." -ForegroundColor Yellow
}

# 8. Set default branch to main
git branch -M main

# 9. Push to GitHub
Write-Host "`n[DEPLOY] Pushing to GitHub (git push -u origin main)..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Repository successfully published to GitHub!" -ForegroundColor Green
    Write-Host "[LINK] $RepoUrl`n" -ForegroundColor Cyan
} else {
    Write-Host "`n[WARNING] Push failed. Please check your GitHub authentication (PAT / SSH key)." -ForegroundColor Yellow
}
