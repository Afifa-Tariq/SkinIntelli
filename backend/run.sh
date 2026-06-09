#!/usr/bin/env bash
if [ -f "venv/bin/activate" ]; then
  source "venv/bin/activate"
else
  echo "Virtual environment not found. Create one with: python -m venv venv"
fi
python main.py
