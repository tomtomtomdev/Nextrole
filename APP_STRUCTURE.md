# Nextrole App Structure

## Entry Point

**File**: `Nextrole/NextroleApp.swift`

This is the main entry point with the `@main` attribute. It:
- Initializes SwiftData ModelContainer with all 4 data models
- Loads **ContentView** as the first screen
- Configures Settings window (Cmd+,)
- Sets up window commands

## First Screen

**File**: `Nextrole/ContentView.swift`

This is the first screen that loads when the app starts. It displays:

### Left Sidebar (300-400px)
1. **Resume Upload Section**
   - Drag & drop PDF file
   - File picker button
   - Shows parsed skills when resume loaded

2. **Search Filters Section** (scrollable)
   - Keywords input
   - Location input
   - Tech stack filter
   - Remote/Relocation toggles
   - Visa sponsorship toggle
   - Posted date picker
   - Company type filters
   - Match score slider

3. **Search Button**
   - Primary action button
   - Shows progress during search
   - Displays result count
   - Cancel option while searching

### Main Content Area (600-800px)
- **Job Results Table**
  - Sortable columns: Match %, Title, Company, Location, Posted, Source
  - Filter bar at top
  - Context menu on jobs (Open in Browser, Copy Link, Save)
  - Double-click to open job URL
  - Color-coded match scores
  - Tech stack tags
  - Remote badges

## App Flow

```
App Launch
    ↓
NextroleApp (@main)
    ↓
ContentView (first screen)
    ↓
    ├─→ SidebarView
    │     ├─→ ResumeUploadView
    │     ├─→ SearchFiltersView
    │     └─→ SearchButtonView
    │
    └─→ JobResultsView (detail)
```

## Settings Window

**File**: `Nextrole/Views/SettingsView.swift`

Accessible via:
- Menu: Nextrole → Settings
- Keyboard: Cmd+,

Tabs:
1. **General**: Default location, remote preference, auto-save
2. **Scraping**: Aggressiveness level, max results, disclaimer
3. **About**: Version info, links, credits

## State Management

**ViewModel**: `SearchViewModel`

Manages all app state:
- Current resume
- Search filters (15+ options)
- Job postings list
- Selected job
- Search progress
- Error messages

## Data Persistence

**SwiftData Models** (stored locally):
- `ResumeProfile` - Uploaded resumes
- `JobPosting` - Job search results
- `SearchQuery` - Search history
- `UserPreferences` - App settings

## Current Status

✅ **Ready to Build**
- All views implemented
- All models configured
- SwiftData setup complete
- Python backend ready

⚠️ **Note**: Type resolution warnings are expected until Xcode project is created and all files are properly linked.

## Building the App

1. Open Xcode
2. The project should automatically recognize:
   - `NextroleApp.swift` as entry point
   - `ContentView.swift` as first screen
   - All other views, models, and services
3. Build (Cmd+B)
4. Run (Cmd+R)

The app will launch with ContentView showing the complete job search interface.
