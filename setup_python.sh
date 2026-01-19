#!/bin/bash

# Python Dependencies Setup Script for Nextrole
# This script installs required Python packages for the app

echo "Setting up Python dependencies for Nextrole..."

# Use system Python (required by the app)
PYTHON="/usr/bin/python3"

# Check if Python exists
if [ ! -f "$PYTHON" ]; then
    echo "Error: System Python not found at $PYTHON"
    exit 1
fi

echo "Using Python: $PYTHON"
$PYTHON --version

# Install packages to user site-packages
echo "Installing Python packages..."
$PYTHON -m pip install --user \
    pypdf \
    beautifulsoup4 \
    lxml \
    requests \
    fake-useragent \
    python-dateutil \
    fuzzywuzzy \
    ratelimit \
    tenacity \
    playwright

# Verify installation
echo ""
echo "Verifying installation..."
$PYTHON -c "
import pypdf
from bs4 import BeautifulSoup
import lxml
import requests
from fake_useragent import UserAgent
import dateutil
from fuzzywuzzy import fuzz
from ratelimit import limits
from tenacity import retry
from playwright.sync_api import sync_playwright
print('✓ All packages installed successfully!')
"

if [ $? -eq 0 ]; then
    echo ""
    echo "Installing Playwright browsers (Chromium)..."
    $PYTHON -m playwright install chromium

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Setup complete! You can now run the Nextrole app."
    else
        echo ""
        echo "Warning: Playwright browser installation failed. LinkedIn scraper may not work."
        echo "You can manually install later with: $PYTHON -m playwright install chromium"
    fi
else
    echo ""
    echo "Error: Package verification failed. Please check the installation."
    exit 1
fi
