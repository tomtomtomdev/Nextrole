#!/usr/bin/env python3
"""
LinkedIn Job Scraper
Scrapes job postings from LinkedIn's public job search using Playwright.

NOTE: This scraper uses LinkedIn's public job search API without authentication.
Uses conservative rate limiting to respect LinkedIn's ToS and avoid detection.
"""

import asyncio
import random
import time
import sys
from typing import List, Dict, Optional
from urllib.parse import urlencode, quote_plus

from playwright.async_api import async_playwright, Browser, BrowserContext, Page, TimeoutError as PlaywrightTimeoutError
from bs4 import BeautifulSoup
from fake_useragent import UserAgent

from .base_scraper import BaseScraper, RateLimiter


class LinkedInScraper(BaseScraper):
    """
    Scraper for LinkedIn job board using Playwright.

    Uses public job search without authentication. Implements aggressive
    rate limiting and anti-detection measures to avoid CAPTCHAs and bans.
    """

    # LinkedIn public job search base URL
    BASE_URL = "https://www.linkedin.com/jobs/search"

    # Maximum pages to scrape (25 jobs per page = 125 jobs max)
    MAX_PAGES = 5

    # Jobs per page on LinkedIn
    JOBS_PER_PAGE = 25

    def __init__(self, scraping_level: str = "normal"):
        """
        Initialize LinkedIn scraper with conservative rate limiting.

        Args:
            scraping_level: Scraping speed level (always uses 'conservative' for LinkedIn)
        """
        super().__init__(scraping_level)

        # Override with conservative rate limiting for LinkedIn
        self.rate_limiter = RateLimiter("conservative")

        # Track browser state
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None

        # Page counter for progressive backoff
        self.pages_scraped = 0

    def get_source_name(self) -> str:
        """Return the name of this job board"""
        return "LinkedIn"

    def search(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        max_results: int
    ) -> List[Dict]:
        """
        Search LinkedIn for job postings.

        Synchronous wrapper around async implementation.

        Args:
            keywords: List of search keywords
            location: Job location (or "Remote")
            remote_only: Filter for remote jobs only
            posted_within_days: Filter for jobs posted within N days
            max_results: Maximum number of results to return

        Returns:
            List of job dictionaries
        """
        try:
            # Run async search in event loop
            if sys.platform == 'win32':
                # Windows requires specific event loop policy
                asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

            try:
                jobs = loop.run_until_complete(
                    self._async_search(keywords, location, remote_only, posted_within_days, max_results)
                )
                return jobs
            finally:
                loop.close()

        except Exception as e:
            self.log_progress(f"LinkedIn error: {str(e)}", 0.0)
            return []

    async def _async_search(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        max_results: int
    ) -> List[Dict]:
        """
        Main async search orchestration.

        Coordinates browser initialization, pagination, and job scraping.
        """
        jobs = []

        try:
            self.log_progress("Initializing LinkedIn scraper...", 0.05)

            # Initialize browser
            async with async_playwright() as playwright:
                self.browser = await self._init_browser(playwright)
                self.context = await self._create_context()
                page = await self.context.new_page()

                try:
                    # Apply stealth mode
                    await self._apply_stealth(page)

                    # Calculate max pages to scrape
                    max_pages = min(self.MAX_PAGES, (max_results + self.JOBS_PER_PAGE - 1) // self.JOBS_PER_PAGE)

                    self.log_progress(f"Searching LinkedIn (up to {max_pages} pages)...", 0.1)

                    # Scrape pages
                    for page_num in range(max_pages):
                        try:
                            # Build search URL for this page
                            search_url = self._build_search_url(
                                keywords, location, remote_only, posted_within_days, page_num
                            )

                            self.log_progress(f"LinkedIn page {page_num}: Loading...", 0.1 + (page_num / max_pages) * 0.6)

                            # Navigate to search page
                            page_jobs = await self._scrape_page(page, search_url, page_num)

                            if page_jobs:
                                jobs.extend(page_jobs)
                                self.log_progress(
                                    f"LinkedIn page {page_num}: Found {len(page_jobs)} job cards",
                                    0.1 + ((page_num + 0.5) / max_pages) * 0.6
                                )
                            else:
                                self.log_progress(f"LinkedIn page {page_num}: No jobs found, stopping", 0.7)
                                break

                            # Stop if we have enough results
                            if len(jobs) >= max_results:
                                break

                            # Rate limiting between pages (progressive backoff)
                            if page_num < max_pages - 1:
                                await self._delay_between_pages(page_num)

                        except PlaywrightTimeoutError:
                            self.log_progress(f"LinkedIn page {page_num}: Timeout, skipping", 0.0)
                            break
                        except Exception as e:
                            self.log_progress(f"LinkedIn page {page_num}: Error - {str(e)}", 0.0)
                            break

                    self.log_progress(f"LinkedIn scraping complete: {len(jobs)} jobs found", 0.8)

                finally:
                    # Cleanup
                    await page.close()
                    await self.context.close()
                    await self.browser.close()

        except Exception as e:
            self.log_progress(f"LinkedIn fatal error: {str(e)}", 0.0)
            import traceback
            sys.stderr.write(f"LinkedIn traceback: {traceback.format_exc()}\n")
            sys.stderr.flush()

        # Truncate to max_results
        return jobs[:max_results]

    async def _init_browser(self, playwright) -> Browser:
        """
        Initialize browser with anti-detection settings.

        Args:
            playwright: Playwright instance

        Returns:
            Browser instance
        """
        browser = await playwright.chromium.launch(
            headless=True,
            args=[
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--disable-gpu',
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-web-security',
                '--disable-features=IsolateOrigins,site-per-process',
            ]
        )
        return browser

    async def _create_context(self) -> BrowserContext:
        """
        Create browser context with realistic fingerprint.

        Returns:
            BrowserContext instance
        """
        ua = UserAgent()

        context = await self.browser.new_context(
            user_agent=ua.random,
            viewport={'width': 1920, 'height': 1080},
            locale='en-US',
            timezone_id='America/New_York',
            extra_http_headers={
                'Accept-Language': 'en-US,en;q=0.9',
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'DNT': '1',
                'Connection': 'keep-alive',
                'Upgrade-Insecure-Requests': '1',
            }
        )

        return context

    async def _apply_stealth(self, page: Page):
        """
        Apply JavaScript to hide automation indicators.

        Args:
            page: Page instance
        """
        await page.add_init_script("""
            // Override navigator.webdriver
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            });

            // Override permissions
            const originalQuery = window.navigator.permissions.query;
            window.navigator.permissions.query = (parameters) => (
                parameters.name === 'notifications' ?
                    Promise.resolve({ state: Notification.permission }) :
                    originalQuery(parameters)
            );

            // Override plugins
            Object.defineProperty(navigator, 'plugins', {
                get: () => [1, 2, 3, 4, 5]
            });

            // Override languages
            Object.defineProperty(navigator, 'languages', {
                get: () => ['en-US', 'en']
            });
        """)

    def _build_search_url(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        page_num: int
    ) -> str:
        """
        Build LinkedIn job search URL with filters.

        Args:
            keywords: Search keywords
            location: Job location
            remote_only: Filter for remote jobs
            posted_within_days: Date filter
            page_num: Page number (0-indexed)

        Returns:
            Full search URL
        """
        params = {}

        # Keywords
        if keywords:
            params['keywords'] = ' '.join(keywords)

        # Location
        if location:
            params['location'] = location

        # Remote filter
        if remote_only:
            params['f_WT'] = '2'  # 2 = Remote

        # Date posted filter
        if posted_within_days:
            # LinkedIn time filter codes:
            # r86400 = Past 24 hours
            # r604800 = Past week
            # r2592000 = Past month
            if posted_within_days <= 1:
                params['f_TPR'] = 'r86400'
            elif posted_within_days <= 7:
                params['f_TPR'] = 'r604800'
            elif posted_within_days <= 30:
                params['f_TPR'] = 'r2592000'

        # Pagination (25 jobs per page)
        if page_num > 0:
            params['start'] = page_num * self.JOBS_PER_PAGE

        # Build URL
        query_string = urlencode(params, quote_via=quote_plus)
        return f"{self.BASE_URL}?{query_string}"

    async def _scrape_page(self, page: Page, url: str, page_num: int) -> List[Dict]:
        """
        Scrape a single search results page.

        Args:
            page: Page instance
            url: Search URL
            page_num: Page number for logging

        Returns:
            List of job dictionaries
        """
        jobs = []

        try:
            # Navigate to page
            await self._navigate_with_retry(page, url)

            # Wait for job cards to load
            try:
                await page.wait_for_selector('.jobs-search__results-list', timeout=15000)
            except PlaywrightTimeoutError:
                # Check if we hit a CAPTCHA or rate limit
                if await self._check_for_rate_limit(page):
                    self.log_progress("LinkedIn: Rate limit or CAPTCHA detected", 0.0)
                    return []
                raise

            # Simulate human behavior
            await self._simulate_human_behavior(page)

            # Get page HTML
            html = await page.content()

            # Parse with BeautifulSoup
            soup = BeautifulSoup(html, 'lxml')

            # Find job cards
            job_cards = soup.select('.jobs-search__results-list li')

            if not job_cards:
                # Try alternative selector
                job_cards = soup.select('.base-card')

            self.log_progress(f"LinkedIn page {page_num}: Parsing {len(job_cards)} job cards...", 0.0)

            # Parse each job card
            for card in job_cards:
                try:
                    job = self._parse_job_card(card)
                    if job:
                        jobs.append(job)
                except Exception as e:
                    # Skip individual card errors
                    sys.stderr.write(f"LinkedIn: Error parsing job card: {str(e)}\n")
                    sys.stderr.flush()
                    continue

        except PlaywrightTimeoutError:
            self.log_progress(f"LinkedIn page {page_num}: Timeout loading page", 0.0)
        except Exception as e:
            self.log_progress(f"LinkedIn page {page_num}: Error - {str(e)}", 0.0)

        return jobs

    def _parse_job_card(self, card) -> Optional[Dict]:
        """
        Parse a job card element into a job dictionary.

        Args:
            card: BeautifulSoup element

        Returns:
            Job dictionary or None if parsing fails
        """
        try:
            # Title (multiple selector fallbacks)
            title_elem = (
                card.select_one('.base-search-card__title') or
                card.select_one('.job-search-card__title') or
                card.select_one('[class*="title"]')
            )
            title = title_elem.get_text(strip=True) if title_elem else None

            if not title:
                return None

            # Company
            company_elem = (
                card.select_one('.base-search-card__subtitle') or
                card.select_one('.job-search-card__company-name') or
                card.select_one('[class*="company"]')
            )
            company = company_elem.get_text(strip=True) if company_elem else "Unknown Company"

            # Location
            location_elem = (
                card.select_one('.job-search-card__location') or
                card.select_one('.base-search-card__metadata') or
                card.select_one('[class*="location"]')
            )
            location = location_elem.get_text(strip=True) if location_elem else "Unknown Location"

            # URL
            link_elem = card.select_one('a[href*="/jobs/view/"]')
            if not link_elem:
                link_elem = card.select_one('a')

            url = None
            if link_elem and link_elem.get('href'):
                url = link_elem['href']
                if not url.startswith('http'):
                    url = f"https://www.linkedin.com{url}"
                # Clean tracking parameters
                if '?' in url:
                    url = url.split('?')[0]

            if not url:
                return None

            # Posted date
            date_elem = card.select_one('time[datetime]')
            posted_date = None
            if date_elem and date_elem.get('datetime'):
                posted_date = date_elem['datetime']
            else:
                # Try to parse relative date
                date_text_elem = card.select_one('.job-search-card__listdate')
                if date_text_elem:
                    date_text = date_text_elem.get_text(strip=True)
                    posted_date = self.parse_relative_date(date_text)

            # Description snippet
            desc_elem = (
                card.select_one('.base-search-card__snippet') or
                card.select_one('.job-search-card__snippet') or
                card.select_one('[class*="snippet"]')
            )
            description = desc_elem.get_text(strip=True) if desc_elem else ""

            # Extract additional info from text
            card_text = card.get_text().lower()

            is_remote = any(keyword in card_text for keyword in ['remote', 'work from home', 'wfh'])
            offers_relocation = any(keyword in card_text for keyword in ['relocation', 'visa', 'sponsorship'])
            visa_sponsorship = 'visa' in card_text or 'sponsorship' in card_text

            # Build job dictionary
            job = {
                'title': title,
                'company': company,
                'location': location,
                'description': description,
                'url': url,
                'source': 'LinkedIn',
                'postedDate': posted_date,
                'isRemote': is_remote,
                'offersRelocation': offers_relocation,
                'matchScore': 0.0,  # Calculated later
                'techStack': self.extract_tech_stack(description),
                'salaryRange': None,  # Not typically visible in public search
                'visaSponsorship': visa_sponsorship,
                'companySize': None,  # Not available in job card
            }

            return job

        except Exception as e:
            sys.stderr.write(f"LinkedIn: Error parsing job card: {str(e)}\n")
            sys.stderr.flush()
            return None

    async def _navigate_with_retry(self, page: Page, url: str, max_retries: int = 3):
        """
        Navigate to URL with retry logic.

        Args:
            page: Page instance
            url: Target URL
            max_retries: Maximum retry attempts
        """
        for attempt in range(max_retries):
            try:
                await page.goto(url, wait_until='domcontentloaded', timeout=30000)
                return
            except PlaywrightTimeoutError:
                if attempt < max_retries - 1:
                    wait_time = 2 ** attempt  # Exponential backoff
                    self.log_progress(f"LinkedIn: Navigation timeout, retrying in {wait_time}s...", 0.0)
                    await asyncio.sleep(wait_time)
                else:
                    raise

    async def _simulate_human_behavior(self, page: Page):
        """
        Simulate human browsing behavior.

        Args:
            page: Page instance
        """
        try:
            # Random scrolling
            for _ in range(random.randint(1, 3)):
                await page.evaluate(f'window.scrollBy(0, {random.randint(200, 500)})')
                await asyncio.sleep(random.uniform(0.2, 0.5))

            # Random mouse movement
            await page.mouse.move(
                random.randint(100, 800),
                random.randint(100, 600)
            )

        except Exception:
            # Ignore errors in behavior simulation
            pass

    async def _delay_between_pages(self, page_num: int):
        """
        Add delay between pages with progressive backoff.

        Args:
            page_num: Current page number
        """
        # Base delay from rate limiter (10-15 seconds)
        base_min, base_max = self.rate_limiter.delays['conservative']

        # Progressive backoff (add more delay after each page)
        backoff = page_num * 2

        delay = random.uniform(base_min + backoff, base_max + backoff)

        self.log_progress(f"LinkedIn: Waiting {delay:.1f}s before next page...", 0.0)
        await asyncio.sleep(delay)

    async def _check_for_rate_limit(self, page: Page) -> bool:
        """
        Check if page shows rate limiting or CAPTCHA.

        Args:
            page: Page instance

        Returns:
            True if rate limited, False otherwise
        """
        try:
            html = await page.content()
            html_lower = html.lower()

            # Check for CAPTCHA or rate limit indicators
            indicators = [
                'captcha',
                'unusual activity',
                'verify you\'re human',
                'authwall',
                'too many requests',
            ]

            return any(indicator in html_lower for indicator in indicators)

        except Exception:
            return False
