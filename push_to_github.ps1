# ==============================================================================
# GitHub ga bitta buyruq bilan yuklash skripti
# Joylashuv: D:\FPGA_projects\Day03_FIFO\push_to_github.ps1
# ==============================================================================
param (
    [string]$RepoUrl = ""
)

Write-Host "`n🚀 [Day03_FIFO] Loyihani GitHub'ga joylash boshlandi..." -ForegroundColor Cyan

# 1. Manzilni tekshirish
$ProjectDir = "D:\FPGA_projects\Day03_FIFO"
Set-Location -Path $ProjectDir

# 2. Git foydalanuvchi ma'lumotlarini tekshirish
$gitUser = git config user.name
$gitEmail = git config user.email

if ([string]::IsNullOrWhiteSpace($gitUser)) {
    $defaultUser = "FPGA-Developer"
    git config user.name $defaultUser
    Write-Host "ℹ️ Git user.name o'rnatildi: $defaultUser" -ForegroundColor Yellow
}

if ([string]::IsNullOrWhiteSpace($gitEmail)) {
    $defaultEmail = "developer@fpga.local"
    git config user.email $defaultEmail
    Write-Host "ℹ️ Git user.email o'rnatildi: $defaultEmail" -ForegroundColor Yellow
}

# 3. Git omborini tekshirish yoki initsializatsiya qilish
if (!(Test-Path ".git")) {
    git init
    Write-Host "✅ Git repository initsializatsiya qilindi." -ForegroundColor Green
}

# 4. GitHub Repo URL ni olish
if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
    $existingRemote = git remote get-url origin 2>$null
    if (![string]::IsNullOrWhiteSpace($existingRemote)) {
        Write-Host "ℹ️ Mavjud masofaviy ombor (remote origin) topildi: $existingRemote" -ForegroundColor Green
        $RepoUrl = $existingRemote
    } else {
        $RepoUrl = Read-Host "`nIltimos, GitHub repository URL manzilini kiriting (masalan: https://github.com/USERNAME/Day03_FIFO.git)"
    }
}

if ([string]::IsNullOrWhiteSpace($RepoUrl)) {
    Write-Host "❌ Xatolik: GitHub repository URL kiritilmadi!" -ForegroundColor Red
    exit 1
}

# 5. Remote origin sozlash
$currentRemote = git remote get-url origin 2>$null
if ([string]::IsNullOrWhiteSpace($currentRemote)) {
    git remote add origin $RepoUrl
    Write-Host "✅ Masofaviy ombor qo'shildi: $RepoUrl" -ForegroundColor Green
} else {
    git remote set-url origin $RepoUrl
    Write-Host "✅ Masofaviy ombor yangilandi: $RepoUrl" -ForegroundColor Green
}

# 6. Fayllarni sahnaga qo'shish (stage)
Write-Host "`n📦 Fayllar qo'shilmoqda..." -ForegroundColor Cyan
git add .

# 7. Commit yaratish
$status = git status --porcelain
if (![string]::IsNullOrWhiteSpace($status)) {
    $commitMsg = "Day 03: Synchronous FIFO & UART Command Processor on Zynq UltraScale+ FPGA"
    git commit -m $commitMsg
    Write-Host "✅ Commit yaratildi: '$commitMsg'" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Yangi o'zgarishlar yo'q, avvalgi commit mavjud." -ForegroundColor Yellow
}

# 8. Asosiy tarmoqni 'main' ga o'tkazish
git branch -M main

# 9. GitHub ga push qilish
Write-Host "`n🚀 GitHub ga yuklanmoqda (git push -u origin main)..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n🎉 Tabriklaymiz! Loyiha GitHub ga muvaffaqiyatli yuklandi!" -ForegroundColor Green
    Write-Host "🔗 Manzil: $RepoUrl`n" -ForegroundColor Cyan
} else {
    Write-Host "`n⚠️ Yuklashda xatolik yuz berdi. Iltimos, GitHub ruxsatlari (PAT yoki SSH key) to'g'riligini tekshiring." -ForegroundColor Yellow
}
