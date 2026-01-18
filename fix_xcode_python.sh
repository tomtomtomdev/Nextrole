#!/bin/bash
# Fix Xcode project to handle Python folder structure correctly

set -e

echo "============================================"
echo "  Fixing Xcode Python Folder Configuration"
echo "============================================"
echo ""

# Check if project exists
if [ ! -f "Nextrole.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Nextrole.xcodeproj not found!"
    exit 1
fi

echo "1. Creating backup of project file..."
cp Nextrole.xcodeproj/project.pbxproj Nextrole.xcodeproj/project.pbxproj.backup
echo "✓ Backup created: project.pbxproj.backup"
echo ""

echo "2. Current issue: Both __init__.py files copy to same location"
echo "   - matching/__init__.py → Resources/__init__.py"
echo "   - scrapers/__init__.py → Resources/__init__.py (CONFLICT!)"
echo ""

echo "3. Solution options:"
echo ""
echo "   Option A: Manual Fix in Xcode (RECOMMENDED)"
echo "   ------------------------------------------"
echo "   1. Open Nextrole.xcodeproj in Xcode"
echo "   2. Select 'Nextrole' target → 'Build Phases'"
echo "   3. Expand 'Copy Bundle Resources'"
echo "   4. Remove ALL individual Python files"
echo "   5. Right-click project → 'Add Files to Nextrole...'"
echo "   6. Select 'Nextrole/Python' folder"
echo "   7. IMPORTANT: Choose 'Create folder references' (blue folder)"
echo "   8. Click 'Add'"
echo "   9. Clean and rebuild (Shift+Cmd+K, then Cmd+B)"
echo ""

echo "   Option B: Exclude Python from Copy Phase"
echo "   -----------------------------------------"
echo "   We can exclude Python files and use system Python instead"
echo ""

read -p "Do you want to exclude Python files from the build? (y/n): " choice

if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo ""
    echo "Excluding Python files from Xcode build..."

    # This is a simplified approach - remove Python files from Copy Bundle Resources
    # Note: This means you'll need to use system Python instead of bundled Python

    echo ""
    echo "✓ To complete this:"
    echo "  1. Open Xcode"
    echo "  2. Select target → Build Phases → Copy Bundle Resources"
    echo "  3. Remove all .py files"
    echo "  4. Update PythonBridge.swift to use system Python:"
    echo "     self.pythonExecutable = \"/usr/local/bin/python3\""
    echo "     self.scriptsPath = \"$(pwd)/Nextrole/Python\""
    echo ""
    echo "This approach uses Python from your system instead of bundling it."

else
    echo ""
    echo "Please follow Option A above to fix the project manually."
fi

echo ""
echo "============================================"
echo "Restore backup if needed:"
echo "  cp Nextrole.xcodeproj/project.pbxproj.backup Nextrole.xcodeproj/project.pbxproj"
echo "============================================"
