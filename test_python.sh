#!/bin/bash
# Simple test script to verify Python environment

echo "Testing Python environment..."
echo ""

# Check Python version
echo "1. Checking Python version:"
python3 --version
echo ""

# Check if required packages can be imported
echo "2. Testing Python imports:"
python3 << EOF
import sys
import json

try:
    import pypdf
    print("✓ pypdf installed")
except ImportError:
    print("✗ pypdf not installed - run: pip3 install pypdf")

try:
    import bs4
    print("✓ beautifulsoup4 installed")
except ImportError:
    print("✗ beautifulsoup4 not installed - run: pip3 install beautifulsoup4")

try:
    import requests
    print("✓ requests installed")
except ImportError:
    print("✗ requests not installed - run: pip3 install requests")

try:
    from fake_useragent import UserAgent
    print("✓ fake-useragent installed")
except ImportError:
    print("✗ fake-useragent not installed - run: pip3 install fake-useragent")

print("")
print("If any packages are missing, run:")
print("  cd Nextrole/Python && pip3 install -r requirements.txt")
EOF

echo ""
echo "3. Testing resume parser:"
cd Nextrole/Python
echo '{"action": "parse", "pdf_path": "/nonexistent.pdf"}' | python3 resume_parser.py
echo ""

echo "✓ Python environment test complete!"
