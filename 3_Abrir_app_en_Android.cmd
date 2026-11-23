@echo off
cd /d "%~dp0frontend"
"C:\Users\jesus\Desktop\src\flutter\bin\flutter.bat" run --dart-define=API_URL=http://10.0.2.2:8000
pause
