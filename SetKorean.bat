@echo off
title 한 번에 한국어(ko-KR)로 변경 - 관리자 권한 필요
color 0A

:: ─────────────────────────────────────────────
:: 1) 관리자 권한 확인 & 없으면 승격
:: ─────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo [!] 관리자 권한이 필요합니다. 권한 승격 중...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo [1/4] 한국어 언어팩(ko-KR) 확인/설치 중... (인터넷 필요, 몇 분 걸릴 수 있음)

:: 이미 설치 여부 간단 확인
for /f "tokens=*" %%a in ('dism /online /Get-Capabilities ^| findstr /i "Language.Basic~~~ko-KR"') do set FOUND_KO=1

if not defined FOUND_KO (
  :: 기본 언어팩
  dism /online /Add-Capability /CapabilityName:Language.Basic~~~ko-KR~0.0.1.0
  :: (선택) OCR / 필기 / 음성 / TTS 필요하면 주석 해제
  dism /online /Add-Capability /CapabilityName:Language.OCR~~~ko-KR~0.0.1.0
  dism /online /Add-Capability /CapabilityName:Language.Handwriting~~~ko-KR~0.0.1.0
  :: dism /online /Add-Capability /CapabilityName:Speech~~~ko-KR~0.0.1.0
  :: dism /online /Add-Capability /CapabilityName:TextToSpeech~~~ko-KR~0.0.1.0
) else (
  echo - 이미 한국어 기본 언어팩이 감지됨.
)

echo.
echo [2/4] 사용자 표시 언어/입력기 한국어로 설정 중...

:: 사용자 언어 목록을 ko-KR + 한국어 키보드(0412:00000412)로 강제 설정
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$list = New-WinUserLanguageList 'ko-KR';" ^
  "$tip = '0412:00000412';" ^
  "if (-not ($list[0].InputMethodTips -contains $tip)) { $list[0].InputMethodTips.Add($tip) }" ^
  "Set-WinUserLanguageList $list -Force;"

:: 기본 입력기/표시 언어 고정
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Set-WinDefaultInputMethodOverride -InputTip '0412:00000412';" ^
  "Set-WinUILanguageOverride -Language 'ko-KR';" ^
  "Set-Culture -CultureInfo 'ko-KR';"

echo.
echo [3/4] 시스템 로캘(비유니코드 프로그램 언어) 한국어로 설정 중...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-WinSystemLocale -SystemLocale 'ko-KR'"

echo.
echo [4/4] 잠금화면/웰컴 화면까지 완전 적용하려면 재부팅이 필요합니다.
echo       (표시 언어 변경은 보통 로그아웃/재부팅 후 적용됩니다.)
echo.

choice /M "지금 바로 재부팅할까요?"
if errorlevel 2 (
  echo 재부팅을 건너뜁니다. 나중에 직접 재부팅하세요.
  pause
  exit /b 0
) else (
  echo 5초 후 자동 재부팅합니다...
  shutdown /r /t 5
)
