@echo off
cd /d "%~dp0frontend"
"C:\Users\jesus\Desktop\src\flutter\bin\flutter.bat" run -d chrome --dart-define=API_URL=http://127.0.0.1:8000
pause
