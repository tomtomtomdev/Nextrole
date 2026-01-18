# Nextrole

A native macOS application that analyzes your resume and automatically searches multiple job boards for matching positions. Built specifically for developers.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Python](https://img.shields.io/badge/Python-3.11-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

### Core Features
- 📄 **Resume Parsing**: Extract skills, keywords, and experience from PDF resumes
- 🔍 **Multi-Board Search**: Search across LinkedIn, Indeed, Greenhouse, and Workday
- 🎯 **Smart Matching**: AI-powered job matching based on your resume
- ⚡ **Fast & Native**: Built with SwiftUI for optimal macOS performance
- 💾 **Local Storage**: All data stored locally using SwiftData

### Developer-Specific Features
- 💻 **Tech Stack Filtering**: Filter by programming languages, frameworks, and tools
- 🌍 **Remote-First**: Highlight fully remote and remote-first companies
- 🛂 **Visa Sponsorship**: Filter jobs offering visa sponsorship
- 🏢 **Company Type Tags**: Categorize by startup, mid-size, or enterprise
- 📊 **Salary Estimates**: Display salary data when available
- 🔗 **Engineering Blogs**: Links to company engineering blogs

### Advanced Scraping
- 🤖 **Anti-Bot Measures**: Request throttling, user-agent rotation, and rate limiting
- ⚙️ **Configurable Aggressiveness**: Conservative, normal, or aggressive scraping modes
- 🔄 **Auto-Retry**: Exponential backoff and error recovery
- 📈 **Progress Tracking**: Real-time progress updates during searches

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Python 3.11 or later

## Installation

### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/nextrole.git
   cd nextrole
   ```

2. **Install Python dependencies**
   ```bash
   ./setup_python.sh
   ```

   This will install required packages to your system Python:
   - pypdf (PDF parsing)
   - beautifulsoup4 (HTML parsing)
   - requests (HTTP client)
   - fake-useragent (User agent rotation)
   - python-dateutil (Date parsing)
   - fuzzywuzzy (Fuzzy string matching)

3. **Open in Xcode**
   ```bash
   open Nextrole.xcodeproj
   ```

4. **Build and Run**
   - Build the project in Xcode (Cmd+B)
   - Run the app (Cmd+R)

   **Note**: The app runs without App Sandbox in development mode to allow Python script execution and network access.

## Usage

1. **Upload Resume**: Click or drag & drop your resume PDF
2. **Set Filters**: Configure search parameters (location, remote status, tech stack)
3. **Search Jobs**: Click "Search Jobs" to scan all job boards
4. **Review Results**: Sort by match score, filter by tech stack, save favorites
5. **Apply**: Click to open job postings in your browser

## Architecture

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
│  - Resume Parser                        │
│  - Job Scrapers (LinkedIn, Indeed, etc.)│
│  - Matching Engine                      │
└─────────────────────────────────────────┘
```

## Project Structure

```
Nextrole/
├── App/
│   └── NextroleApp.swift           # App entry point
├── Views/
│   ├── ContentView.swift           # Main layout
│   ├── ResumeUploadView.swift     # Resume upload UI
│   ├── SearchFiltersView.swift    # Filter controls
│   ├── JobResultsView.swift       # Results table
│   └── SettingsView.swift         # App settings
├── Models/
│   ├── ResumeProfile.swift        # SwiftData model
│   ├── JobPosting.swift           # SwiftData model
│   ├── SearchQuery.swift          # SwiftData model
│   └── UserPreferences.swift      # SwiftData model
├── Services/
│   ├── PythonBridge.swift         # Python integration
│   ├── ResumeService.swift        # Resume management
│   └── JobSearchService.swift     # Search orchestration
├── ViewModels/
│   └── SearchViewModel.swift      # State management
└── Python/
    ├── requirements.txt            # Python dependencies
    ├── resume_parser.py           # PDF parsing
    ├── scrapers/
    │   ├── base_scraper.py        # Base scraper class
    │   ├── linkedin_scraper.py    # LinkedIn scraper
    │   ├── indeed_scraper.py      # Indeed scraper
    │   ├── greenhouse_scraper.py  # Greenhouse scraper
    │   └── workday_scraper.py     # Workday scraper
    └── matching/
        └── matcher.py             # Matching algorithm
```

## Configuration

### Scraping Settings

In Settings (Cmd+,), you can configure:
- **Aggressiveness Level**: How fast to scrape (affects delays between requests)
  - Conservative: 10-15s delays (most respectful)
  - Normal: 5-8s delays (balanced)
  - Aggressive: 2-5s delays (faster but riskier)
- **Max Results**: Maximum jobs per board (10-500)

### Anti-Bot Measures

The app implements several anti-bot techniques:
- Random delays between requests
- User-agent rotation
- Browser-like headers
- Session persistence
- Exponential backoff on errors
- Circuit breaker pattern

## Ethical Usage & Disclaimer

⚠️ **Important**: This tool scrapes public job postings for personal use. Users are responsible for compliance with each website's Terms of Service. Use respectfully and at your own risk.

- Respect robots.txt
- Use conservative scraping by default
- Don't overwhelm servers
- Only scrape public data
- Be aware of rate limits

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Adding a New Job Board

1. Create a new scraper class inheriting from `BaseScraper`
2. Implement the `search()` and `get_source_name()` methods
3. Add the scraper to `scrapers/__init__.py`
4. Test thoroughly with rate limiting
5. Submit a pull request

## Known Limitations

- **LinkedIn**: Requires authentication and has strict anti-scraping measures (placeholder implementation)
- **Workday**: Requires browser automation for JavaScript-heavy sites (placeholder implementation)
- **Rate Limits**: Aggressive scraping may trigger rate limits or bans
- **Job Board Changes**: Scrapers may break if job boards change their HTML structure

## Future Enhancements

- [ ] Full LinkedIn integration with Selenium/Playwright
- [ ] Workday scraper with browser automation
- [ ] Hacker News "Who's Hiring" parser
- [ ] Stack Overflow Jobs integration
- [ ] Application tracking (track where you've applied)
- [ ] Email notifications for new matching jobs
- [ ] Cover letter generation with AI
- [ ] Interview preparation based on job descriptions
- [ ] Chrome extension for saving jobs while browsing

## Development Roadmap

See [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) for the complete development roadmap.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Swift](https://swift.org/) and [SwiftUI](https://developer.apple.com/swiftui/)
- Resume parsing with [PyPDF](https://pypdf2.readthedocs.io/)
- Web scraping with [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/) and [Selenium](https://www.selenium.dev/)
- Inspired by the need for better developer job search tools

## Support

- 📖 [Documentation](https://github.com/yourusername/nextrole/wiki)
- 🐛 [Report Bug](https://github.com/yourusername/nextrole/issues)
- 💡 [Request Feature](https://github.com/yourusername/nextrole/issues)
- 💬 [Discussions](https://github.com/yourusername/nextrole/discussions)

## Author

Made with ❤️ for developers

---

⭐ Star this repo if you find it useful!
