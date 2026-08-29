@echo off
chcp 65001 >nul
title Minetest Copy

net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Эту программу нужно запускать от имени администратора.
    echo Нажмите правой кнопкой мыши на файл и выберите "Запуск от имени администратора".
    pause
    exit /b 1
)

where scp >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Не найдена программа scp.
    echo В Windows 10/11 она встроена по умолчанию. Если её нет, включите
    echo компонент "OpenSSH Client" в Параметры - Приложения - Дополнительные компоненты.
    pause
    exit /b 1
)

echo.
echo  ███╗   ███╗██╗███╗   ██╗███████╗████████╗███████╗███████╗████████╗
echo  ████╗ ████║██║████╗  ██║██╔════╝╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
echo  ██╔████╔██║██║██╔██╗ ██║█████╗     ██║   █████╗  ███████╗   ██║
echo  ██║╚██╔╝██║██║██║╚██╗██║██╔══╝     ██║   ██╔══╝  ╚════██║   ██║
echo  ██║ ╚═╝ ██║██║██║ ╚████║███████╗   ██║   ███████╗███████║   ██║
echo  ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚══════╝╚══════╝   ╚═╝
echo.
echo   ██████╗ ██████╗ ██████╗ ██╗   ██╗
echo  ██╔════╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
echo  ██║     ██║   ██║██████╔╝ ╚████╔╝
echo  ██║     ██║   ██║██╔═══╝   ╚██╔╝
echo  ╚██████╗╚██████╔╝██║        ██║
echo   ╚═════╝ ╚═════╝ ╚═╝        ╚═╝
echo.
echo  Утилита для скачивания всех файлов проекта с сервера
echo.

set /p SERVER_IP="IP-адрес сервера: "
set /p SERVER_USER="Логин (обычно root): "

echo.
echo Сейчас будут скачаны ВСЕ файлы проекта с %SERVER_USER%@%SERVER_IP%
echo в папку C:\minetest
echo Пароль сервера будет запрошен отдельно для каждой папки.
echo.
set /p CONFIRM="Продолжить? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Отменено.
    pause
    exit /b 0
)

mkdir C:\minetest 2>nul

echo.
echo Скачивание /root ...
scp -r %SERVER_USER%@%SERVER_IP%:/root C:\minetest\root

echo Скачивание /opt ...
scp -r %SERVER_USER%@%SERVER_IP%:/opt C:\minetest\opt

echo Скачивание /home ...
scp -r %SERVER_USER%@%SERVER_IP%:/home C:\minetest\home

echo Скачивание /etc/minetest ...
scp -r %SERVER_USER%@%SERVER_IP%:/etc/minetest C:\minetest\etc-minetest

echo Скачивание /etc/systemd/system ...
scp -r %SERVER_USER%@%SERVER_IP%:/etc/systemd/system C:\minetest\etc-systemd

echo Скачивание /var/www ...
scp -r %SERVER_USER%@%SERVER_IP%:/var/www C:\minetest\var-www

echo.
echo Готово. Все файлы находятся в папке C:\minetest
pause
