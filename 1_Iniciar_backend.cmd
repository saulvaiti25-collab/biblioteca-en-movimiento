@echo off
cd /d "%~dp0backend"
"C:\Users\jesus\AppData\Local\Programs\Python\Python314\python.exe" -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
