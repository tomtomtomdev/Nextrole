#!/usr/bin/env python3
"""
Base Scraper Framework
Common functionality for all job board scrapers
"""

import time
import random
import sys
from abc import ABC, abstractmethod
from typing import List, Dict, Optional
from datetime import datetime, timedelta

import requests
from fake_useragent import UserAgent
from ratelimit import limits, sleep_and_retry
from tenacity import retry, stop_after_attempt, wait_exponential


class RateLimiter:
    """Rate limiter for HTTP requests"""

    def __init__(self, level: str = "normal"):
        self.level = level
        self.delays = {
            "conservative": (10.0, 15.0),
            "normal": (5.0, 8.0),
            "aggressive": (2.0, 5.0)
        }

    def delay(self):
        """Sleep for a random amount of time based on level"""
        min_delay, max_delay = self.delays.get(self.level, self.delays["normal"])
        delay_time = random.uniform(min_delay, max_delay)
        time.sleep(delay_time)


class BaseScraper(ABC):
    """
    Abstract base class for job board scrapers.
    Handles common functionality like rate limiting, retries, and headers.
    """

    def __init__(self, scraping_level: str = "normal"):
        self.scraping_level = scraping_level
        self.rate_limiter = RateLimiter(scraping_level)
        self.session = requests.Session()
        self.user_agent = UserAgent()

        # Track statistics
        self.requests_made = 0
        self.errors_encountered = 0

    def get_headers(self) -> Dict[str, str]:
        """Generate realistic browser headers"""
        return {
            'User-Agent': self.user_agent.random,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1',
            'Sec-Fetch-Dest': 'document',
            'Sec-Fetch-Mode': 'navigate',
            'Sec-Fetch-Site': 'none',
            'Cache-Control': 'max-age=0',
        }

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=2, max=16))
    def make_request(self, url: str, method: str = "GET", **kwargs) -> requests.Response:
        """Make HTTP request with retry logic and rate limiting"""
        self.rate_limiter.delay()

        headers = kwargs.pop('headers', {})
        headers.update(self.get_headers())

        try:
            if method == "GET":
                response = self.session.get(url, headers=headers, timeout=30, **kwargs)
            elif method == "POST":
                response = self.session.post(url, headers=headers, timeout=30, **kwargs)
            else:
                raise ValueError(f"Unsupported method: {method}")

            response.raise_for_status()
            self.requests_made += 1
            return response

        except requests.exceptions.HTTPError as e:
            self.errors_encountered += 1
            if e.response.status_code == 429:  # Rate limited
                self.log_progress(f"Rate limited, waiting longer...")
                time.sleep(30)  # Wait 30 seconds before retry
            raise

        except requests.exceptions.RequestException as e:
            self.errors_encountered += 1
            raise

    def log_progress(self, message: str, progress: float = 0.0):
        """Log progress to stderr for Swift to parse"""
        sys.stderr.write(f"PROGRESS: {message} | {progress:.2f}\n")
        sys.stderr.flush()

    def parse_relative_date(self, date_str: str) -> str:
        """
        Convert relative date strings to ISO format.
        Examples: "2 days ago", "1 week ago", "Just posted"
        """
        date_str_lower = date_str.lower()
        now = datetime.now()

        if 'just' in date_str_lower or 'today' in date_str_lower:
            return now.isoformat()
        elif 'yesterday' in date_str_lower:
            return (now - timedelta(days=1)).isoformat()
        elif 'hour' in date_str_lower:
            hours = int(''.join(filter(str.isdigit, date_str))) or 1
            return (now - timedelta(hours=hours)).isoformat()
        elif 'day' in date_str_lower:
            days = int(''.join(filter(str.isdigit, date_str))) or 1
            return (now - timedelta(days=days)).isoformat()
        elif 'week' in date_str_lower:
            weeks = int(''.join(filter(str.isdigit, date_str))) or 1
            return (now - timedelta(weeks=weeks)).isoformat()
        elif 'month' in date_str_lower:
            months = int(''.join(filter(str.isdigit, date_str))) or 1
            return (now - timedelta(days=months*30)).isoformat()
        else:
            return now.isoformat()

    def extract_tech_stack(self, text: str) -> List[str]:
        """Extract tech stack from job description"""
        tech_keywords = [
            'python', 'javascript', 'java', 'swift', 'kotlin', 'go', 'rust',
            'react', 'vue', 'angular', 'django', 'flask', 'spring',
            'aws', 'azure', 'gcp', 'docker', 'kubernetes',
            'postgresql', 'mongodb', 'redis', 'mysql',
            'swiftui', 'uikit', 'combine', 'rxswift'
        ]

        text_lower = text.lower()
        found_stack = []

        for tech in tech_keywords:
            if tech in text_lower:
                found_stack.append(tech.title())

        return found_stack

    @abstractmethod
    def search(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        max_results: int
    ) -> List[Dict]:
        """
        Search for jobs on this board.
        Must be implemented by subclasses.

        Returns:
            List of job dictionaries with keys:
            - title, company, location, description, url, source, postedDate,
              isRemote, offersRelocation, matchScore, techStack, etc.
        """
        pass

    @abstractmethod
    def get_source_name(self) -> str:
        """Return the name of this job board"""
        pass
