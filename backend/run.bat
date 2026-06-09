@echo off
if exist venv\Scripts\activate.bat (
  call venv\Scripts\activate.bat
) else (
  echo Virtual environment not found. Create one with: python -m venv venv
)
python main.py
pause
