# Nextrole - macOS Job Matching Application
## Development Plan

## Project Overview
A native macOS application that analyzes PDF resumes and automatically searches multiple job boards (LinkedIn, Indeed, Greenhouse, Workday) for matching positions. Built with Swift/SwiftUI for the interface, Python for resume parsing and web scraping, and SwiftData for persistence.

---

## Architecture

### Technology Stack
- **Frontend**: Swift/SwiftUI (native macOS)
- **Backend Processing**: Python (embedded interpreter)
- **Data Persistence**: SwiftData
- **PDF Processing**: Python libraries (PyPDF2, pdfminer.six, or pypdf)
- **Web Scraping**: Python (requests, BeautifulSoup4, Selenium for dynamic content)
- **Python Integration**: PythonKit or embedded Python framework

### System Architecture
```
┌─────────────────────────────────────────┐
│         SwiftUI Interface               │
│  (File picker, Filters, Results List)  │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Swift Application Layer            │
│  - SwiftData Models                     │
│  - Python Bridge Manager                │
│  - State Management                     │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│    Embedded Python Runtime              │
│  ┌────────────────────────────────────┐ │
│  │  Resume Parser Module              │ │
│  │  - PDF text extraction             │ │
│  │  - Skills/keywords extraction      │ │
│  │  - Experience parsing              │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │  Job Scraper Module                │ │
│  │  - LinkedIn scraper                │ │
│  │  - Indeed scraper                  │ │
│  │  - Greenhouse scraper              │ │
│  │  - Workday scraper                 │ │
│  └────────────────────────────────────┘ │
│  ┌────────────────────────────────────┐ │
│  │  Matching Engine                   │ │
│  │  - Keyword matching                │ │
│  │  - Relevance scoring               │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Data Models (SwiftData)

### ResumeProfile
```swift
- id: UUID
- fileName: String
- uploadDate: Date
- parsedText: String
- skills: [String]
- experience: [ExperienceItem]
- keywords: [String]
- location: String?
- yearsOfExperience: Int?
```

### JobPosting
```swift
- id: UUID
- title: String
- company: String
- location: String
- description: String
- url: String
- source: String (LinkedIn/Indeed/Greenhouse/Workday)
- postedDate: Date
- isRemote: Bool
- offersRelocation: Bool
- matchScore: Double
- scrapedDate: Date
- searchQuery: SearchQuery (relationship)
```

### SearchQuery
```swift
- id: UUID
- resume: ResumeProfile (relationship)
- keywords: [String]
- location: String?
- postedWithinDays: Int?
- requiresRelocation: Bool?
- remoteOnly: Bool?
- executedDate: Date
- jobPostings: [JobPosting] (relationship)
```

### UserPreferences
```swift
- id: UUID
- defaultLocation: String?
- defaultRemotePreference: Bool
- autoSaveSearches: Bool
- notificationsEnabled: Bool
```

---

## Implementation Phases

### Phase 1: Project Setup & Foundation
**Estimated Scope**: Core infrastructure

#### 1.1 Xcode Project Setup
- Create new macOS App project with SwiftUI
- Configure deployment target (macOS 14.0+)
- Set up project structure:
  ```
  Nextrole/
  ├── App/
  │   └── NextroleApp.swift
  ├── Views/
  │   ├── ContentView.swift
  │   ├── ResumeUploadView.swift
  │   ├── SearchFiltersView.swift
  │   ├── JobResultsView.swift
  │   └── JobDetailView.swift
  ├── Models/
  │   ├── ResumeProfile.swift
  │   ├── JobPosting.swift
  │   ├── SearchQuery.swift
  │   └── UserPreferences.swift
  ├── Services/
  │   ├── PythonBridge.swift
  │   ├── ResumeService.swift
  │   └── JobSearchService.swift
  ├── ViewModels/
  │   ├── ResumeViewModel.swift
  │   └── SearchViewModel.swift
  └── Python/
      ├── requirements.txt
      ├── resume_parser.py
      ├── scrapers/
      │   ├── __init__.py
      │   ├── base_scraper.py
      │   ├── linkedin_scraper.py
      │   ├── indeed_scraper.py
      │   ├── greenhouse_scraper.py
      │   └── workday_scraper.py
      └── matching/
          ├── __init__.py
          └── matcher.py
  ```

#### 1.2 Python Environment Setup
- Embed Python framework in macOS bundle
- Options:
  - Use python.org framework distribution
  - Or use miniforge/conda-forge Python
- Create `setup_python.sh` script to bundle Python
- Configure `Info.plist` for Python runtime
- Test Python execution from Swift

#### 1.3 Python Bridge Implementation
- Install PythonKit via SPM or implement custom bridge
- Create `PythonBridge.swift`:
  - Initialize Python interpreter
  - Set up module search paths
  - Handle Python-Swift data conversion
  - Error handling and logging
- Test basic Python script execution from Swift

#### 1.4 SwiftData Setup
- Define data models with @Model macro
- Create ModelContainer configuration
- Set up ModelContext injection
- Implement basic CRUD operations

**Deliverables**:
- Working Xcode project
- Python embedded and executable from Swift
- SwiftData persistence functional
- Basic app launches and can execute Python code

---

### Phase 2: Resume Processing Module (Python)

#### 2.1 PDF Text Extraction
**File**: `Python/resume_parser.py`

```python
# Core functionality:
- Extract text from PDF using pypdf or pdfminer.six
- Handle multi-page resumes
- Preserve some formatting context
- Handle various PDF encodings
```

**Key Libraries**:
- `pypdf` (formerly PyPDF2) - simple PDF reading
- `pdfminer.six` - more robust text extraction
- `regex` - advanced pattern matching

#### 2.2 Skills & Keywords Extraction
```python
# Functionality:
- Identify technical skills (programming languages, frameworks, tools)
- Extract soft skills (leadership, communication, etc.)
- Identify certifications and education
- Extract industry-specific keywords
```

**Approach**:
- Use predefined skill dictionaries
- Pattern matching for common skill formats
- NLP-based extraction (spaCy or NLTK) for context
- Custom rules for common resume structures

#### 2.3 Experience Parsing
```python
# Extract:
- Job titles and companies
- Employment dates and duration
- Key responsibilities and achievements
- Industry sectors
```

**Challenges**:
- Various date formats
- Inconsistent resume structures
- Distinguishing between sections

#### 2.4 Contact & Location Info
```python
# Extract:
- Location (city, state for search targeting)
- Years of experience (calculated from dates)
- Education level
- Current/desired role
```

**Python API Design**:
```python
# resume_parser.py
def parse_resume(pdf_path: str) -> dict:
    """
    Parse a PDF resume and extract structured data.

    Returns:
    {
        'text': str,
        'skills': List[str],
        'keywords': List[str],
        'experience': List[dict],
        'location': str,
        'years_experience': int,
        'education': List[dict]
    }
    """
    pass
```

**Deliverables**:
- `resume_parser.py` with complete parsing logic
- Unit tests for various resume formats
- Sample resumes for testing
- Python requirements.txt updated

---

### Phase 3: Web Scraping Module (Python)

#### 3.1 Base Scraper Framework
**File**: `Python/scrapers/base_scraper.py`

```python
class BaseScraper:
    """
    Abstract base class for job board scrapers.
    Handles common functionality:
    - Rate limiting
    - User-agent rotation
    - Error handling and retries
    - Response parsing helpers
    """

    def __init__(self):
        self.session = requests.Session()
        self.rate_limiter = RateLimiter()

    def search(self, keywords, location, filters) -> List[dict]:
        """To be implemented by subclasses"""
        raise NotImplementedError
```

**Common Features**:
- Exponential backoff for retries
- Respect robots.txt (but aggressive where needed)
- Random delays between requests
- Session management with cookies
- Proxy support (optional, for future)

**Advanced Anti-Bot Measures** (for bypassing rate limits):
1. **Request Throttling**:
   - Random delays: 2-8 seconds between requests (configurable)
   - Exponential backoff on errors (1s, 2s, 4s, 8s, 16s)
   - Per-domain rate limiting (max N requests per minute)
   - Jitter in timing to appear more human-like

2. **User-Agent Rotation**:
   - Pool of 20+ real browser user-agents
   - Rotate on each request or session
   - Match user-agent with appropriate headers (Accept-Language, etc.)

3. **Header Spoofing**:
   - Full browser-like headers (Accept, Accept-Encoding, Accept-Language, DNT)
   - Realistic Referer headers (simulate navigation)
   - Connection: keep-alive
   - Upgrade-Insecure-Requests: 1

4. **Session Persistence**:
   - Maintain cookies across requests
   - Respect Set-Cookie headers
   - Session pooling (multiple concurrent sessions)

5. **Browser Automation** (for JavaScript-heavy sites):
   - Selenium with undetected-chromedriver
   - Playwright in stealth mode
   - Browser fingerprint randomization
   - Disable automation flags (navigator.webdriver = false)

6. **IP Rotation** (optional, for future):
   - Proxy rotation (residential proxies preferred)
   - VPN integration
   - Tor network (slow but effective)

7. **Request Distribution**:
   - Distribute requests across multiple sessions
   - Parallel scraping with different IPs/sessions
   - Cache results to minimize repeat requests

8. **CAPTCHA Handling**:
   - Detect CAPTCHA challenges
   - Notify user for manual solving
   - Optional: CAPTCHA solving service integration (2Captcha, Anti-Captcha)

9. **Cloudflare Bypass**:
   - cloudscraper library for Python
   - Browser automation with fingerprint spoofing
   - Wait for Cloudflare challenge completion

10. **Monitoring & Adaptation**:
    - Log blocked requests
    - Automatically increase delays on 429/403 responses
    - Circuit breaker pattern (stop scraping if too many failures)
    - User-configurable aggressiveness levels

#### 3.2 LinkedIn Scraper
**File**: `Python/scrapers/linkedin_scraper.py`

**Challenges**:
- Requires authentication for many features
- Heavy anti-scraping measures (Cloudflare, rate limits)
- Dynamic content loading (JavaScript)

**Approach**:
- Use Selenium or Playwright for browser automation
- Implement careful rate limiting (1-2 requests per 5-10 seconds)
- Parse job search results page
- Extract: title, company, location, link, posting date
- Consider using LinkedIn's public job search (no login) initially

**Important**: LinkedIn Terms of Service are strict. Consider:
- Using only publicly available data
- Implementing user consent/awareness
- Rate limiting aggressively
- Having fallback to manual browsing

#### 3.3 Indeed Scraper
**File**: `Python/scrapers/indeed_scraper.py`

**Characteristics**:
- More scraping-friendly than LinkedIn
- Clean HTML structure
- Public job search API-like structure

**Implementation**:
- Simple requests-based scraping initially
- Parse search results HTML
- Extract job cards with BeautifulSoup
- Handle pagination
- Extract: title, company, location, description snippet, URL

**URL Pattern**:
```
https://www.indeed.com/jobs?q={keywords}&l={location}&fromage={days}&remotejob={remote}
```

#### 3.4 Greenhouse Scraper
**File**: `Python/scrapers/greenhouse_scraper.py`

**Challenges**:
- Each company has separate Greenhouse board
- URL pattern: `https://{company}.greenhouse.io/`
- Need list of target companies

**Approach**:
- Maintain list of known Greenhouse companies
- Or scrape from Greenhouse's company directory
- Each board has JSON API endpoint
- Example: `https://boards-api.greenhouse.io/v1/boards/{company}/jobs`
- Parse JSON responses (easier than HTML)

**Strategy**:
- Start with top tech companies using Greenhouse
- Allow user to add custom company boards
- Aggregate results across multiple boards

#### 3.5 Workday Scraper
**File**: `Python/scrapers/workday_scraper.py`

**Challenges**:
- Similar to Greenhouse, each company separate instance
- Heavy JavaScript rendering
- URL pattern: `https://{company}.wd5.myworkdayjobs.com/`

**Approach**:
- Use Selenium or Playwright for JavaScript rendering
- Each instance has search functionality
- Parse search results after JS execution
- Maintain list of major companies on Workday

**Companies List Strategy**:
- Pre-populate with Fortune 500 companies known to use Workday
- Allow users to add custom company career pages

#### 3.6 Scraper Orchestration
**File**: `Python/scrapers/__init__.py`

```python
def search_all_boards(resume_data: dict, filters: dict) -> List[dict]:
    """
    Orchestrate scraping across all job boards.
    Run scrapers in parallel where possible.
    Aggregate and deduplicate results.
    """
    scrapers = [
        LinkedInScraper(),
        IndeedScraper(),
        GreenhouseScraper(),
        WorkdayScraper()
    ]

    # Run in parallel with threading
    results = []
    for scraper in scrapers:
        try:
            jobs = scraper.search(
                keywords=filters['keywords'],
                location=filters.get('location'),
                remote=filters.get('remote_only'),
                days_ago=filters.get('posted_within_days')
            )
            results.extend(jobs)
        except Exception as e:
            log_error(scraper, e)

    return deduplicate_jobs(results)
```

**Deliverables**:
- Working scrapers for all 4 job boards
- Rate limiting and error handling
- Deduplication logic
- Test scripts for each scraper
- Documentation on robots.txt compliance

---

### Phase 4: Matching Engine (Python)

#### 4.1 Keyword Matching
**File**: `Python/matching/matcher.py`

```python
def calculate_match_score(resume_data: dict, job_posting: dict) -> float:
    """
    Calculate match score between resume and job posting.
    Returns score between 0.0 and 1.0.
    """

    # Scoring factors:
    # - Skills overlap (40%)
    # - Keyword match (30%)
    # - Experience level match (15%)
    # - Location match (10%)
    # - Industry match (5%)
```

**Algorithm**:
1. Extract skills/keywords from job description
2. Compare with resume skills using:
   - Exact matches
   - Fuzzy matching (similar terms)
   - Synonym matching (e.g., "JS" = "JavaScript")
3. Weight by importance (required vs. preferred skills)
4. Calculate percentage overlap
5. Adjust score based on other factors

#### 4.2 Filtering Logic
```python
def apply_filters(jobs: List[dict], filters: dict) -> List[dict]:
    """
    Filter jobs based on user criteria.
    """

    # Filters:
    # - Location match (exact or within radius)
    # - Remote status (remote_only, hybrid_ok, onsite_only)
    # - Posted date (within last N days)
    # - Relocation support (if required)
    # - Keywords (must contain specific terms)
```

#### 4.3 Ranking & Sorting
```python
def rank_jobs(jobs: List[dict], resume_data: dict) -> List[dict]:
    """
    Rank jobs by match score and other factors.
    """

    # Ranking factors:
    # 1. Match score (primary)
    # 2. Posting date (newer = better)
    # 3. Company reputation (optional)
    # 4. Location preference
```

**Deliverables**:
- Matching algorithm implementation
- Filtering logic
- Ranking system
- Unit tests with sample data
- Tuning parameters for match scoring

---

### Phase 5: Swift UI Implementation

#### 5.1 Main Window Structure
**File**: `Views/ContentView.swift`

```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationSplitView {
            // Sidebar: Resume + Filters
            VStack {
                ResumeUploadView()
                Divider()
                SearchFiltersView()
                SearchButton()
            }
        } detail: {
            // Main content: Results list
            JobResultsView()
        }
    }
}
```

#### 5.2 Resume Upload View
**File**: `Views/ResumeUploadView.swift`

**Features**:
- Drag-and-drop PDF file
- File picker button
- Display selected resume info (filename, upload date)
- Show parsed skills/keywords preview
- Delete/replace resume option

**UI Elements**:
```swift
- FileImporter for PDF selection
- Drop delegate for drag-and-drop
- Progress indicator during parsing
- Skills/keywords tag cloud display
```

#### 5.3 Search Filters View
**File**: `Views/SearchFiltersView.swift`

**Filter Controls**:
```swift
- TextField: Keywords (comma-separated)
- TextField: Location (city, state, or "Remote")
- Picker: Posted within (Today, 3 days, Week, Month, Any time)
- Toggle: Remote only
- Toggle: Offers relocation support
- Stepper: Minimum match score (50%-95%)
```

**Layout**:
- Form or List style for native macOS feel
- Collapsible sections for advanced filters
- Save filter presets functionality

#### 5.4 Job Results View
**File**: `Views/JobResultsView.swift`

**Features**:
- Table or List of job postings
- Columns: Match Score, Title, Company, Location, Posted Date
- Sorting by any column
- Search/filter within results
- Loading state with progress indicator
- Empty state with helpful message

**Design**:
```swift
Table(viewModel.jobPostings) {
    TableColumn("Match", value: \.matchScore)
    TableColumn("Title", value: \.title)
    TableColumn("Company", value: \.company)
    TableColumn("Location", value: \.location)
    TableColumn("Posted", value: \.postedDate)
}
.onTapGesture { job in
    viewModel.selectedJob = job
}
```

#### 5.5 Job Detail View
**File**: `Views/JobDetailView.swift`

**Content**:
- Job title and company (large header)
- Match score with visual indicator (progress bar or stars)
- Location, remote status, relocation support badges
- Full job description
- Matched skills highlighted
- "Open in Browser" button
- "Save for later" / "Not interested" buttons
- Application date if applied

**Features**:
- Markdown rendering for job description
- Syntax highlighting for matched keywords
- Share job link
- Copy job details

#### 5.6 Search Button & Progress
**Implementation**:
- Large primary button: "Search Jobs"
- Disabled when no resume uploaded
- Shows progress during scraping:
  - "Analyzing resume..."
  - "Searching LinkedIn..."
  - "Searching Indeed..."
  - etc.
- Displays result count when complete
- Cancel button during search

**Deliverables**:
- Complete SwiftUI interface
- Responsive layout for various window sizes
- Dark mode support
- Keyboard shortcuts (Cmd+O for open, Cmd+R for search)
- Menu bar integration

---

### Phase 6: Services Layer (Swift)

#### 6.1 Python Bridge Service
**File**: `Services/PythonBridge.swift`

```swift
class PythonBridge {
    static let shared = PythonBridge()

    func parseResume(at url: URL) async throws -> ResumeData {
        // 1. Call Python resume_parser.py
        // 2. Convert Python dict to Swift struct
        // 3. Handle errors
    }

    func searchJobs(
        resumeData: ResumeData,
        filters: SearchFilters
    ) async throws -> [JobPostingData] {
        // 1. Convert Swift data to Python-compatible format
        // 2. Call Python scraper orchestration
        // 3. Receive and parse job results
        // 4. Convert to Swift models
    }
}
```

**Implementation Details**:
- Use Process to execute Python scripts
- Pass data via JSON stdin/stdout
- Handle process timeouts
- Parse JSON responses
- Error mapping (Python exceptions → Swift errors)

#### 6.2 Resume Service
**File**: `Services/ResumeService.swift`

```swift
@Observable
class ResumeService {
    private let modelContext: ModelContext
    private let pythonBridge = PythonBridge.shared

    func importResume(from url: URL) async throws -> ResumeProfile {
        // 1. Copy PDF to app's document directory
        // 2. Call Python parser
        // 3. Create ResumeProfile model
        // 4. Save to SwiftData
        // 5. Return profile
    }

    func deleteResume(_ profile: ResumeProfile) throws {
        // Delete from SwiftData and filesystem
    }
}
```

#### 6.3 Job Search Service
**File**: `Services/JobSearchService.swift`

```swift
@Observable
class JobSearchService {
    private let modelContext: ModelContext
    private let pythonBridge = PythonBridge.shared

    var searchProgress: SearchProgress = .idle

    func searchJobs(
        resume: ResumeProfile,
        filters: SearchFilters
    ) async throws -> [JobPosting] {
        // 1. Update progress state
        // 2. Call Python scrapers via bridge
        // 3. Create JobPosting models
        // 4. Calculate match scores
        // 5. Apply filters
        // 6. Save to SwiftData
        // 7. Return sorted results
    }

    func cancelSearch() {
        // Kill Python process
    }
}

enum SearchProgress {
    case idle
    case parsing
    case searching(board: String)
    case matching
    case complete(count: Int)
    case failed(Error)
}
```

**Deliverables**:
- Complete service layer implementation
- Error handling and logging
- Progress reporting
- Unit tests for services

---

### Phase 7: ViewModels & State Management

#### 7.1 Search ViewModel
**File**: `ViewModels/SearchViewModel.swift`

```swift
@MainActor
@Observable
class SearchViewModel {
    private let resumeService: ResumeService
    private let searchService: JobSearchService

    var currentResume: ResumeProfile?
    var searchFilters = SearchFilters()
    var jobPostings: [JobPosting] = []
    var selectedJob: JobPosting?
    var isSearching = false
    var searchProgress: SearchProgress = .idle
    var errorMessage: String?

    func uploadResume(from url: URL) async {
        // Handle resume import
    }

    func executeSearch() async {
        // Validate resume exists
        // Call search service
        // Update jobPostings
        // Handle errors
    }

    func cancelSearch() {
        // Cancel ongoing search
    }

    func applyFilter(_ filter: SearchFilters) {
        // Filter existing results locally
    }
}
```

#### 7.2 Data Models
**Files**: `Models/*.swift`

SwiftData models as defined in Phase 1.4 with additional computed properties:

```swift
@Model
class JobPosting {
    // Stored properties...

    var matchScoreFormatted: String {
        String(format: "%.0f%%", matchScore * 100)
    }

    var postedDateRelative: String {
        // "2 days ago", "1 week ago", etc.
    }

    var isNew: Bool {
        // Posted within 24 hours
    }
}
```

**Deliverables**:
- Complete ViewModels with business logic
- SwiftData models with relationships
- Computed properties for UI display
- Unit tests for ViewModels

---

### Phase 8: Python Dependencies & Packaging

#### 8.1 Python Requirements
**File**: `Python/requirements.txt`

```txt
# PDF Processing
pypdf==4.0.0
pdfminer.six==20231228

# Web Scraping
requests==2.31.0
beautifulsoup4==4.12.3
lxml==5.1.0
selenium==4.16.0
webdriver-manager==4.0.1
playwright==1.40.0

# Anti-Bot Measures
undetected-chromedriver==3.5.4
cloudscraper==1.2.71
fake-useragent==1.4.0
requests-html==0.10.0

# Text Processing & NLP
spacy==3.7.2
nltk==3.8.1
python-dateutil==2.8.2
fuzzywuzzy==0.18.0
python-Levenshtein==0.23.0

# Rate Limiting & Async
ratelimit==2.2.1
tenacity==8.2.3

# Utilities
python-dotenv==1.0.0
pydantic==2.5.0
```

#### 8.2 Embedding Python in App Bundle
**Build Script**: `scripts/embed_python.sh`

```bash
#!/bin/bash
# Download and embed Python framework in app bundle

# 1. Download Python framework (python.org or miniforge)
# 2. Copy to app's Frameworks directory
# 3. Install pip packages to embedded site-packages
# 4. Code sign Python framework
# 5. Set up RPATH and library paths
```

**Xcode Build Phase**:
- Add "Run Script" phase to embed Python
- Ensure Python copied to .app/Contents/Frameworks
- Set up environment variables for Python paths

#### 8.3 Testing Python Integration
- Verify Python can be launched from app
- Test all Python modules can be imported
- Verify scrapers work with embedded Python
- Test on clean macOS without Python installed

**Deliverables**:
- Complete Python requirements specification
- Build scripts to embed Python
- Xcode project configuration for embedding
- Testing checklist for Python integration

---

### Phase 9: Testing & Quality Assurance

#### 9.1 Unit Tests
**Swift Tests** (`NextroleTests/`):
- Model tests (SwiftData)
- ViewModel tests (search logic, state management)
- Service tests (with mocked Python bridge)
- Utility function tests

**Python Tests** (`Python/tests/`):
- Resume parser tests with sample PDFs
- Scraper tests (with mock responses)
- Matching algorithm tests
- Filter logic tests

#### 9.2 Integration Tests
- End-to-end resume upload and parsing
- Full search workflow (Swift → Python → Results)
- SwiftData persistence and retrieval
- Error handling scenarios

#### 9.3 UI Tests
- Resume upload flow
- Filter configuration
- Search execution and results display
- Job detail view interaction
- Keyboard shortcuts

#### 9.4 Scraper Validation
- Test each scraper against live websites
- Verify robots.txt compliance
- Confirm rate limiting works
- Test error recovery (network failures, timeouts)
- Validate parsed data accuracy

#### 9.5 Performance Testing
- Large resume parsing (10+ pages)
- Searching with 100+ results
- SwiftData query performance
- Memory usage during scraping
- App launch time

**Deliverables**:
- Comprehensive test suite (>70% coverage)
- Test documentation
- Performance benchmarks
- Bug tracking and resolution

---

### Phase 10: Polish & Deployment

#### 10.1 UI/UX Polish
- App icon design
- Launch screen
- Empty states with helpful guidance
- Error messages user-friendly
- Loading animations smooth
- Keyboard navigation complete
- VoiceOver accessibility

#### 10.2 Documentation
- User guide (How to use the app)
- Technical documentation (Architecture, extending scrapers)
- README.md for repository
- Privacy policy (data handling)
- Terms of use

#### 10.3 Settings & Preferences
- Preferences window (Cmd+,)
- User preferences:
  - Default search filters
  - Save search history (on/off)
  - Scraping rate limits (conservative/normal/aggressive)
  - Python logging level
  - Data retention period

#### 10.4 Additional Features

**Core Features**:
- Export results to CSV/JSON
- Save searches and re-run
- Job posting notifications (new matches)
- Application tracking (mark as applied)
- Notes on job postings

**Developer-Specific Features** (since target audience is developers):
- **Tech Stack Filtering**: Filter by programming languages, frameworks, tools
- **Company Tech Stack Display**: Show known tech stack for each company
- **GitHub Integration**: Optionally link GitHub profile to showcase projects
- **Remote-First Filter**: Highlight fully remote and remote-first companies
- **Startup vs. Enterprise Tags**: Categorize companies by size/stage
- **Salary Range Display**: Show salary data when available (from job posts or Levels.fyi)
- **Visa Sponsorship Filter**: Critical for international developers
- **Engineering Blog Links**: Show company engineering blogs for culture research
- **Stack Overflow Jobs Integration**: If available via API or scraping
- **Hacker News "Who's Hiring" Parser**: Monthly HN threads are goldmine for dev jobs
- **YC Companies Filter**: Focus on Y Combinator portfolio companies

#### 10.5 App Signing & Distribution
- Apple Developer account setup
- Code signing certificate
- Hardened Runtime enabled
- Notarization for Gatekeeper
- Create DMG installer
- Distribution options:
  - Direct download
  - Mac App Store (requires review)
  - TestFlight beta testing

**Deliverables**:
- Polished, production-ready application
- Complete documentation
- Signed and notarized app bundle
- DMG installer
- Beta testing completed

---

## Technical Challenges & Solutions

### Challenge 1: Embedding Python in macOS App
**Problem**: Distributing Python runtime with app without requiring user installation.

**Solution**:
- Use python.org's framework build
- Copy to .app/Contents/Frameworks/
- Set PYTHONHOME and PYTHONPATH environment variables
- Install dependencies to embedded site-packages
- Code sign the Python framework

**Alternative**: Use PyInstaller to create standalone Python executables.

### Challenge 2: Web Scraping Anti-Bot Measures
**Problem**: LinkedIn, Indeed have bot detection (Cloudflare, rate limits, CAPTCHAs).

**Solutions**:
- **Rate Limiting**: Add delays, randomize request timing
- **User-Agent Rotation**: Mimic real browsers
- **Session Management**: Maintain cookies, realistic behavior
- **Selenium**: Use real browser automation for JavaScript sites
- **Proxy Rotation**: Optional, for future if needed
- **Fallback**: If scraping fails, provide "Open in Browser" option

**Ethical Considerations**:
- Only scrape public data
- Respect robots.txt
- Implement conservative rate limits by default
- Don't overwhelm servers
- Consider ToS implications

### Challenge 3: Greenhouse & Workday Company Lists
**Problem**: Each company has separate board; need comprehensive list.

**Solutions**:
- Pre-populate with Fortune 500 companies
- Allow users to add custom company URLs
- Build community-sourced company database
- Scrape company directories (e.g., Greenhouse's company listings)
- Start with tech-focused subset (YC companies, tech giants)

### Challenge 4: Resume Parsing Accuracy
**Problem**: Resumes have wildly varying formats.

**Solutions**:
- Test with diverse resume samples
- Use multiple parsing strategies (rules + NLP)
- Allow manual keyword addition by user
- Display parsed data for user verification
- Iterate based on user feedback

### Challenge 5: Job Matching Accuracy
**Problem**: Keyword matching may miss nuanced fits.

**Solutions**:
- Use synonym dictionaries (JS = JavaScript)
- Implement fuzzy matching for similar terms
- Allow users to adjust match score weights
- Let users manually add jobs to favorites
- Consider future ML-based matching

---

## Development Timeline Estimate

**Note**: Estimates assume 1 developer working full-time. Actual time may vary based on experience and unforeseen challenges.

- **Phase 1**: Project Setup - 3-5 days
- **Phase 2**: Resume Processing - 5-7 days
- **Phase 3**: Web Scraping - 10-14 days (most complex)
- **Phase 4**: Matching Engine - 3-5 days
- **Phase 5**: Swift UI - 7-10 days
- **Phase 6**: Services Layer - 5-7 days
- **Phase 7**: ViewModels - 3-5 days
- **Phase 8**: Python Packaging - 5-7 days
- **Phase 9**: Testing & QA - 7-10 days
- **Phase 10**: Polish & Deployment - 5-7 days

**Total Estimated Time**: 8-12 weeks for MVP

---

## Risks & Mitigation

### Risk 1: Scrapers Break Due to Website Changes
**Mitigation**:
- Modular scraper design (easy to update)
- Comprehensive error handling
- Fallback to manual browsing
- Regular maintenance schedule
- Version scrapers with site version detection

### Risk 2: LinkedIn/Indeed Block Scraping
**Mitigation**:
- Conservative rate limiting
- Rotate user agents and sessions
- Provide "Open in Browser" alternative
- Consider official APIs (if available/affordable)
- Focus on Indeed and smaller boards initially

### Risk 3: Python Embedding Issues
**Mitigation**:
- Thorough testing on clean macOS installs
- Document Python version requirements
- Consider fallback to requiring user Python install
- Use stable Python version (3.11)

### Risk 4: Poor Resume Parsing Accuracy
**Mitigation**:
- Extensive testing with real resumes
- User feedback mechanism
- Allow manual keyword editing
- Iterative improvement based on usage data

### Risk 5: Performance Issues with Many Results
**Mitigation**:
- Pagination in results view
- Background threading for scraping
- SwiftData query optimization
- Limit results per board (top 100)

---

## Future Enhancements (Post-MVP)

### Advanced Matching
- ML-based job matching
- Semantic similarity using embeddings
- Job recommendation engine
- Salary prediction based on experience

### Additional Job Boards
- AngelList (startups)
- Dice (tech jobs)
- ZipRecruiter
- Glassdoor
- Company career pages directly

### Application Tracking
- Track application status
- Interview scheduling
- Follow-up reminders
- Communication history with recruiters

### Browser Extension
- Save jobs while browsing
- Auto-fill applications with resume data
- Sync with desktop app

### Analytics & Insights
- Job market trends
- Salary insights by location/role
- Skills in demand
- Application success rate tracking

### Collaboration
- Share job postings with friends
- Referral tracking
- Team job search for couples/families

### AI Features
- AI-powered resume improvement suggestions
- Cover letter generation
- Interview preparation based on job description
- Skill gap analysis

---

## Privacy & Data Handling

### Data Storage
- All data stored locally in SwiftData
- No cloud sync in MVP
- User has full control over data

### Privacy Considerations
- Resume data never sent to external servers (only local Python parsing)
- Job search queries go directly to job boards (no intermediary)
- No analytics or telemetry in MVP
- User can delete all data at any time

### Future Cloud Features (Optional)
- End-to-end encrypted cloud sync
- Multi-device support
- Require explicit user consent
- GDPR/CCPA compliance

---

## Open Source & Licensing

### License Choice: MIT (Recommended)
- **Permissive license**: Allows commercial use, modification, distribution
- **Developer-friendly**: Widely adopted in dev tools
- **Maximum adoption**: No copyleft restrictions
- **Simple**: Easy to understand and comply with

**Files to Include**:
- `LICENSE` - MIT License text
- `CONTRIBUTING.md` - How to contribute (code style, PR process)
- `CODE_OF_CONDUCT.md` - Community standards
- `SECURITY.md` - How to report security issues

### Repository Structure
```
nextrole/
├── LICENSE
├── README.md (comprehensive, with screenshots)
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── DEVELOPMENT_PLAN.md
├── .gitignore
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   └── feature_request.md
│   └── workflows/
│       ├── swift-test.yml
│       └── python-test.yml
├── Nextrole/ (Xcode project)
└── Python/ (Python modules)
```

### Community Contributions
**Encourage**:
- New job board scrapers (community can add niche boards)
- Resume parser improvements
- UI/UX enhancements
- Bug fixes and documentation

**Contribution Guidelines**:
- Fork & PR workflow
- All scrapers must respect rate limits
- Code must pass CI/CD (Swift tests, Python linting)
- New scrapers need documentation and tests

### Monetization (Not Applicable for MVP)
- Keep 100% free and open source
- No premium features for MVP
- Community-driven development
- Future: Optional donations or sponsorships (GitHub Sponsors)

### Ethical Considerations
**Transparency**:
- Clearly document scraping methods
- Warn users about ToS implications
- Provide conservative defaults (slow, respectful scraping)
- Allow users to adjust aggressiveness (at their own risk)

**Disclaimer in README**:
> "This tool scrapes public job postings for personal use. Users are responsible for compliance with each website's Terms of Service. Use respectfully and at your own risk."

---

## Success Metrics

### MVP Success Criteria
1. Successfully parse 90%+ of resume formats
2. Find relevant jobs from at least 2 job boards
3. Match score accuracy validated by users
4. No crashes or data loss
5. Search completes in under 60 seconds
6. Positive user feedback from beta testers

### Key Performance Indicators
- Resume parsing accuracy (user-reported)
- Number of relevant jobs found per search
- User engagement (searches per week)
- Application success rate (tracked by users)
- App store rating (if published)
- GitHub stars (if open source)

---

## Next Steps

1. **Review this plan** - Confirm approach and priorities
2. **Set up development environment** - Xcode, Python, dependencies
3. **Create project repository** - Git, README, license
4. **Start Phase 1** - Project setup and foundation
5. **Iterative development** - Build, test, iterate
6. **User feedback** - Beta test with real job seekers
7. **Launch MVP** - Distribution and marketing

---

## Project Decisions

1. **Timeline**: No specific launch date - iterative development
2. **Target Users**: Developers (tech-focused job search)
3. **Distribution**: Open source (MIT or GPL license)
4. **Design**: Standard macOS design patterns (native look and feel)
5. **Budget**: Free/scraping approach (no paid APIs)
6. **Legal**: No ToS consultation - implementing aggressive anti-bot measures with request throttling

---

**Document Version**: 1.0
**Date**: 2026-01-18
**Author**: Claude (AI Assistant)
**Project**: Nextrole - Job Matching Application
