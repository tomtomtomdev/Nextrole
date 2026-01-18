# Quick Build Fix - Remove Python Files from Xcode

## The Problem
Xcode is trying to copy both `__init__.py` files to the same flat location, causing a conflict.

## Quick Solution (2 minutes)

### Step 1: Remove Python Files from Build
1. Open **Nextrole.xcodeproj** in Xcode
2. Select the **Nextrole** target (top left, click on project name)
3. Go to **Build Phases** tab
4. Expand **Copy Bundle Resources**
5. Find and remove ALL Python files (.py files):
   - Look for `__init__.py` entries
   - Look for any `.py` files
   - Select them and click the **-** (minus) button
6. Also check if there's a Python folder - remove it too

### Step 2: Clean and Build
1. Clean build folder: **Shift + Cmd + K**
2. Build: **Cmd + B**

## What Changed

The app now uses **development mode** which:
- ✅ Uses system Python (`/usr/bin/python3`)
- ✅ Reads Python scripts directly from source folder
- ✅ No need to bundle Python files during development
- ✅ Faster build times

## Verify It Works

After building successfully:
1. Run the app (Cmd+R)
2. The app should launch without errors
3. Python scripts are read from: `/Users/tomtomtom/Documents/Nextrole/Nextrole/Python`

## For Production Build Later

When ready to ship the app:
1. Add Python folder as **folder reference** (blue folder)
2. Change `#if DEBUG` to `#if false` in PythonBridge.swift
3. Bundle Python with the app

## Still Having Issues?

If Python files keep appearing in Copy Bundle Resources:
1. Right-click on any Python file in Xcode project navigator
2. Select "Delete" → "Remove References" (NOT "Move to Trash")
3. Repeat for all Python files
4. Clean and rebuild

---

**Updated File**: `Nextrole/Services/PythonBridge.swift`
- Now uses system Python in DEBUG mode
- Uses bundled Python in RELEASE mode
