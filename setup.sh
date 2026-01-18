#!/bin/bash
# Setup script for Nextrole development environment

set -e

echo "============================================"
echo "  Nextrole Development Environment Setup"
echo "============================================"
echo ""

# Check macOS version
echo "1. Checking macOS version..."
sw_vers
echo ""

# Check Python
echo "2. Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✓ $PYTHON_VERSION found"
else
    echo "✗ Python 3 not found!"
    echo "Please install Python 3.11+ from https://www.python.org/"
    exit 1
fi
echo ""

# Check Xcode
echo "3. Checking Xcode..."
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo "✓ $XCODE_VERSION found"
else
    echo "✗ Xcode not found!"
    echo "Please install Xcode 15.0+ from the Mac App Store"
    exit 1
fi
echo ""

# Install Python dependencies
echo "4. Installing Python dependencies..."
cd Nextrole/Python

if [ -f "requirements.txt" ]; then
    echo "Installing packages from requirements.txt..."
    pip3 install -r requirements.txt
    echo "✓ Python dependencies installed"
else
    echo "✗ requirements.txt not found!"
    exit 1
fi
cd ../..
echo ""

# Test Python environment
echo "5. Testing Python environment..."
./test_python.sh
echo ""

# Create Resumes directory
echo "6. Creating directories..."
mkdir -p ~/Documents/Nextrole/Resumes
echo "✓ Created ~/Documents/Nextrole/Resumes"
echo ""

# Git setup
echo "7. Checking Git repository..."
if [ -d ".git" ]; then
    echo "✓ Git repository initialized"
    git status
else
    echo "Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit"
    echo "✓ Git repository initialized"
fi
echo ""

echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  1. Open the project in Xcode"
echo "  2. Create a new macOS App project"
echo "  3. Add all Swift files from Nextrole/ directory"
echo "  4. Build and run (Cmd+R)"
echo ""
echo "See README.md for detailed instructions."
echo ""
