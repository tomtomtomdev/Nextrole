# Contributing to Nextrole

Thank you for your interest in contributing to Nextrole! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and constructive in all interactions. We want to maintain a welcoming community for all contributors.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in [Issues](https://github.com/yourusername/nextrole/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs. actual behavior
   - Screenshots if applicable
   - Your macOS version and app version

### Suggesting Features

1. Check [Issues](https://github.com/yourusername/nextrole/issues) for existing suggestions
2. Create a new issue with:
   - Clear description of the feature
   - Use case / motivation
   - Proposed implementation (optional)

### Contributing Code

#### Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/yourusername/nextrole.git
   cd nextrole
   ```

3. Set up your development environment:
   ```bash
   # Install Python dependencies
   cd Nextrole/Python
   pip3 install -r requirements.txt

   # Open project in Xcode
   # (You'll need to create the Xcode project first)
   ```

4. Create a branch for your changes:
   ```bash
   git checkout -b feature/my-new-feature
   ```

#### Development Guidelines

**Swift Code Style**
- Follow Swift API Design Guidelines
- Use SwiftLint for code formatting
- Write meaningful variable and function names
- Add documentation comments for public APIs
- Keep functions focused and small

**Python Code Style**
- Follow PEP 8 style guide
- Use type hints where possible
- Add docstrings for functions and classes
- Keep functions under 50 lines when possible
- Use meaningful variable names

**Testing**
- Write unit tests for new functionality
- Ensure all tests pass before submitting PR
- Test on a clean macOS installation if possible
- Test with various resume formats

**Scraper Guidelines**
- **IMPORTANT**: All scrapers must respect rate limits
- Use the `BaseScraper` class for common functionality
- Implement exponential backoff for retries
- Log progress for user feedback
- Handle errors gracefully
- Test thoroughly to avoid overwhelming job boards
- Document any special requirements (auth, browser automation)

#### Commit Messages

Follow conventional commits format:
- `feat: Add LinkedIn authentication support`
- `fix: Resolve PDF parsing error for multi-page resumes`
- `docs: Update README with installation instructions`
- `refactor: Simplify job matching algorithm`
- `test: Add tests for Greenhouse scraper`

#### Pull Request Process

1. Update documentation if needed (README, code comments)
2. Add tests for new functionality
3. Ensure all tests pass
4. Update CHANGELOG.md (if exists)
5. Create a Pull Request with:
   - Clear title and description
   - Reference any related issues
   - Screenshots/videos for UI changes
   - List of changes made

6. Wait for review and address feedback
7. Once approved, your PR will be merged

### Adding a New Job Board Scraper

Want to add support for a new job board? Great! Follow these steps:

1. **Create a new scraper file**
   ```python
   # Nextrole/Python/scrapers/newboard_scraper.py
   from .base_scraper import BaseScraper

   class NewBoardScraper(BaseScraper):
       def get_source_name(self) -> str:
           return "NewBoard"

       def search(self, keywords, location, remote_only, posted_within_days, max_results):
           # Implementation here
           pass
   ```

2. **Implement the scraper**
   - Use `self.make_request()` for HTTP requests (handles rate limiting)
   - Use `self.log_progress()` to report progress
   - Extract: title, company, location, description, url, posted date
   - Handle pagination if needed
   - Return list of job dictionaries

3. **Add to orchestrator**
   ```python
   # Nextrole/Python/scrapers/__init__.py
   from .newboard_scraper import NewBoardScraper

   # Add to scrapers list in search_all_boards()
   ```

4. **Test thoroughly**
   - Test with various search queries
   - Verify rate limiting works
   - Check for edge cases (no results, errors, etc.)
   - Ensure it doesn't overwhelm the job board

5. **Document**
   - Add scraper to README
   - Note any special requirements
   - Document rate limits and best practices

### Areas Needing Help

We especially welcome contributions in these areas:

- **LinkedIn Scraper**: Implement Selenium/Playwright-based scraping
- **Workday Scraper**: Browser automation for Workday sites
- **Resume Parser**: Improve accuracy for various resume formats
- **UI/UX**: Design improvements, dark mode polish, animations
- **Testing**: More comprehensive test coverage
- **Documentation**: Tutorials, examples, better docs
- **Localization**: Support for non-English job boards
- **Accessibility**: VoiceOver support, keyboard navigation

## Development Setup

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- Python 3.11+
- Git

### Environment Setup

```bash
# Clone repo
git clone https://github.com/yourusername/nextrole.git
cd nextrole

# Install Python dependencies
cd Nextrole/Python
pip3 install -r requirements.txt

# Run tests
cd ../..
./test_python.sh

# Open in Xcode
# (Create Xcode project and add Swift files)
```

### Running Tests

**Python Tests**
```bash
cd Nextrole/Python
python3 -m pytest tests/
```

**Swift Tests**
```bash
# In Xcode: Cmd+U
# Or via command line:
xcodebuild test -scheme Nextrole
```

## Project Structure

See [README.md](README.md#project-structure) for detailed project structure.

## Release Process

(For maintainers)

1. Update version number in app
2. Update CHANGELOG.md
3. Create release branch: `release/v1.x.x`
4. Test thoroughly
5. Create GitHub release with notes
6. Build and notarize app
7. Publish DMG

## Questions?

- Open a [Discussion](https://github.com/yourusername/nextrole/discussions)
- Check the [Wiki](https://github.com/yourusername/nextrole/wiki)
- Review existing [Issues](https://github.com/yourusername/nextrole/issues)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Nextrole! 🎉
