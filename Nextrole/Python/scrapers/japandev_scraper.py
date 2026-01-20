#!/usr/bin/env python3
"""
Japan Dev Job Scraper
Scrapes job postings from japan-dev.com for tech jobs in Japan.

Uses Playwright for browser automation since Japan Dev uses
Algolia InstantSearch for client-side rendering.
"""

import asyncio
import random
import sys
from typing import List, Dict, Optional
from datetime import datetime

from playwright.async_api import async_playwright, Browser, BrowserContext, Page, TimeoutError as PlaywrightTimeoutError
from bs4 import BeautifulSoup
from fake_useragent import UserAgent

from .base_scraper import BaseScraper, RateLimiter


class JapanDevScraper(BaseScraper):
    """
    Scraper for Japan Dev job board using Playwright.

    Japan Dev focuses on tech jobs in Japan for English speakers.
    Uses Algolia for search which requires JavaScript rendering.
    """

    BASE_URL = "https://japan-dev.com/jobs"

    # Maximum pages to scrape
    MAX_PAGES = 3

    # Jobs per page (approximate)
    JOBS_PER_PAGE = 20

    def __init__(self, scraping_level: str = "normal"):
        """Initialize Japan Dev scraper."""
        super().__init__(scraping_level)
        self.rate_limiter = RateLimiter("normal")
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None

    def get_source_name(self) -> str:
        """Return the name of this job board"""
        return "JapanDev"

    def search(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        max_results: int
    ) -> List[Dict]:
        """
        Search Japan Dev for job postings.

        Args:
            keywords: List of search keywords
            location: Job location (ignored - Japan Dev is Japan-focused)
            remote_only: Filter for remote jobs only
            posted_within_days: Filter for jobs posted within N days
            max_results: Maximum number of results to return

        Returns:
            List of job dictionaries
        """
        try:
            if sys.platform == 'win32':
                asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

            try:
                jobs = loop.run_until_complete(
                    self._async_search(keywords, remote_only, max_results)
                )
                return jobs
            finally:
                loop.close()

        except Exception as e:
            self.log_progress(f"JapanDev error: {str(e)}", 0.0)
            return []

    async def _async_search(
        self,
        keywords: List[str],
        remote_only: bool,
        max_results: int
    ) -> List[Dict]:
        """Main async search orchestration."""
        jobs = []

        try:
            self.log_progress("Initializing JapanDev scraper...", 0.05)

            async with async_playwright() as playwright:
                self.browser = await self._init_browser(playwright)
                self.context = await self._create_context()
                page = await self.context.new_page()

                try:
                    # Build search URL
                    search_url = self._build_search_url(keywords, remote_only)

                    self.log_progress(f"Searching JapanDev...", 0.1)

                    # Navigate and scrape
                    page_jobs = await self._scrape_page(page, search_url)

                    if page_jobs:
                        jobs.extend(page_jobs)
                        self.log_progress(f"JapanDev: Found {len(page_jobs)} jobs", 0.8)

                    self.log_progress(f"JapanDev scraping complete: {len(jobs)} jobs", 0.9)

                finally:
                    await page.close()
                    await self.context.close()
                    await self.browser.close()

        except Exception as e:
            self.log_progress(f"JapanDev fatal error: {str(e)}", 0.0)
            import traceback
            sys.stderr.write(f"JapanDev traceback: {traceback.format_exc()}\n")
            sys.stderr.flush()

        return jobs[:max_results]

    async def _init_browser(self, playwright) -> Browser:
        """Initialize browser with anti-detection settings."""
        browser = await playwright.chromium.launch(
            headless=True,
            args=[
                '--disable-blink-features=AutomationControlled',
                '--disable-dev-shm-usage',
                '--disable-gpu',
                '--no-sandbox',
            ]
        )
        return browser

    async def _create_context(self) -> BrowserContext:
        """Create browser context with realistic fingerprint."""
        ua = UserAgent()

        context = await self.browser.new_context(
            user_agent=ua.random,
            viewport={'width': 1920, 'height': 1080},
            locale='en-US',
            timezone_id='Asia/Tokyo',
            extra_http_headers={
                'Accept-Language': 'en-US,en;q=0.9,ja;q=0.8',
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            }
        )

        return context

    def _build_search_url(self, keywords: List[str], remote_only: bool) -> str:
        """Build Japan Dev search URL with filters."""
        url = self.BASE_URL

        params = []

        # Add keyword search
        if keywords:
            keyword_str = " ".join(keywords)
            params.append(f"search={keyword_str}")

        # Add remote filter
        if remote_only:
            params.append("remote=true")

        if params:
            url += "?" + "&".join(params)

        return url

    async def _scrape_page(self, page: Page, url: str) -> List[Dict]:
        """Scrape job listings from page."""
        jobs = []

        try:
            # Navigate to page
            await page.goto(url, wait_until='networkidle', timeout=30000)

            # Wait for job listings to load (Algolia renders client-side)
            try:
                await page.wait_for_selector('.job-item, .ais-Hits-item', timeout=15000)
            except PlaywrightTimeoutError:
                self.log_progress("JapanDev: No job items found", 0.0)
                return []

            # Scroll to load more content
            await self._scroll_page(page)

            # Get page HTML
            html = await page.content()

            # Parse with BeautifulSoup
            soup = BeautifulSoup(html, 'lxml')

            # Find job cards (try multiple selectors)
            job_cards = soup.select('.job-item') or soup.select('.ais-Hits-item') or soup.select('[class*="job"]')

            self.log_progress(f"JapanDev: Parsing {len(job_cards)} job cards...", 0.5)

            for card in job_cards:
                try:
                    job = self._parse_job_card(card)
                    if job:
                        jobs.append(job)
                except Exception as e:
                    sys.stderr.write(f"JapanDev: Error parsing card: {str(e)}\n")
                    continue

        except Exception as e:
            self.log_progress(f"JapanDev page error: {str(e)}", 0.0)

        return jobs

    async def _scroll_page(self, page: Page):
        """Scroll page to trigger lazy loading."""
        try:
            for _ in range(3):
                await page.evaluate('window.scrollBy(0, 500)')
                await asyncio.sleep(0.5)
        except Exception:
            pass

    def _parse_job_card(self, card) -> Optional[Dict]:
        """Parse a job card element into a job dictionary."""
        try:
            # Title
            title_elem = (
                card.select_one('h2') or
                card.select_one('h3') or
                card.select_one('[class*="title"]') or
                card.select_one('a')
            )
            title = title_elem.get_text(strip=True) if title_elem else None

            if not title:
                return None

            # Company
            company_elem = (
                card.select_one('[class*="company"]') or
                card.select_one('.text-gray-600') or
                card.select_one('span')
            )
            company = company_elem.get_text(strip=True) if company_elem else "Unknown Company"

            # Location (usually Tokyo, Japan for Japan Dev)
            location_elem = card.select_one('[class*="location"]')
            location = location_elem.get_text(strip=True) if location_elem else "Japan"

            # URL
            link_elem = card.select_one('a[href*="/jobs/"]') or card.select_one('a')
            url = None
            if link_elem and link_elem.get('href'):
                url = link_elem['href']
                if not url.startswith('http'):
                    url = f"https://japan-dev.com{url}"

            if not url:
                return None

            # Check for remote
            card_text = card.get_text().lower()
            is_remote = 'remote' in card_text

            # Description snippet
            desc_elem = card.select_one('[class*="description"]') or card.select_one('p')
            description = desc_elem.get_text(strip=True) if desc_elem else ""

            # Tags/tech stack
            tags = []
            tag_elems = card.select('.bubble, .tag, [class*="badge"]')
            for tag in tag_elems:
                tags.append(tag.get_text(strip=True))

            # Build job dictionary
            job = {
                'title': title,
                'company': company,
                'location': location,
                'description': description,
                'url': url,
                'source': 'JapanDev',
                'postedDate': datetime.now().isoformat(),  # Japan Dev doesn't show dates on cards
                'isRemote': is_remote,
                'offersRelocation': 'relocation' in card_text or 'visa' in card_text,
                'matchScore': 0.0,
                'techStack': tags if tags else self.extract_tech_stack(description + " " + title),
                'salaryRange': None,
                'visaSponsorship': 'visa' in card_text or 'sponsorship' in card_text,
                'companySize': None,
            }

            return job

        except Exception as e:
            sys.stderr.write(f"JapanDev: Error parsing job card: {str(e)}\n")
            return None
