$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

if (-not (Get-Command scp -ErrorAction SilentlyContinue)) {
    Write-Host "Не найдена программа scp."
    Write-Host "В Windows 10/11 она встроена по умолчанию. Если её нет, включите"
    Write-Host "компонент 'OpenSSH Client' в Параметры - Приложения - Дополнительные компоненты."
    Read-Host "Нажмите Enter для выхода"
    exit
}

Write-Host ""
Write-Host "=========================================="
Write-Host "            MINETEST COPY"
Write-Host "=========================================="
Write-Host ""
Write-Host "Утилита для скачивания всех файлов проекта с сервера"
Write-Host ""

$SERVER_IP = Read-Host "IP-адрес сервера"
$SERVER_USER = Read-Host "Логин (обычно root)"

Write-Host ""
Write-Host "Сейчас будут скачаны ВСЕ файлы проекта с $SERVER_USER@$SERVER_IP"
Write-Host "в папку C:\minetest"
Write-Host "Пароль сервера будет запрошен отдельно для каждой папки."
Write-Host ""
$CONFIRM = Read-Host "Продолжить? (y/n)"
if ($CONFIRM -ne "y" -and $CONFIRM -ne "Y") {
    Write-Host "Отменено."
    Read-Host "Нажмите Enter для выхода"
    exit
}

New-Item -ItemType Directory -Force -Path C:\minetest | Out-Null

$folders = @(
    @{remote="/root"; local="C:\minetest\root"},
    @{remote="/opt"; local="C:\minetest\opt"},
    @{remote="/home"; local="C:\minetest\home"},
    @{remote="/etc/minetest"; local="C:\minetest\etc-minetest"},
    @{remote="/etc/systemd/system"; local="C:\minetest\etc-systemd"},
    @{remote="/var/www"; local="C:\minetest\var-www"}
)

foreach ($f in $folders) {
    Write-Host ""
    Write-Host "Скачивание $($f.remote) ..."
    scp -r "$SERVER_USER@$($SERVER_IP):$($f.remote)" $f.local
}

Write-Host ""
Write-Host "Готово. Все файлы находятся в папке C:\minetest"
Read-Host "Нажмите Enter для выхода"
