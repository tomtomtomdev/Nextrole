#!/usr/bin/env python3
"""
Greenhouse Job Scraper
Scrapes job postings from Greenhouse boards
"""

from typing import List, Dict, Optional
import requests
from .base_scraper import BaseScraper


class GreenhouseScraper(BaseScraper):
    """Scraper for Greenhouse job boards"""

    # List of known companies using Greenhouse
    # In production, this should be a much larger list or loaded from a file
    KNOWN_COMPANIES = [
        'airbnb', 'stripe', 'gitlab', 'notion', 'figma', 'coinbase',
        'robinhood', 'dropbox', 'pinterest', 'reddit', 'twitch',
        'datadog', 'cloudflare', 'elastic', 'hashicorp', 'mongodb'
    ]

    def get_source_name(self) -> str:
        return "Greenhouse"

    def search(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        max_results: int
    ) -> List[Dict]:
        """Search Greenhouse boards for job postings"""
        all_jobs = []

        try:
            self.log_progress(f"Searching {len(self.KNOWN_COMPANIES)} Greenhouse boards...", 0.1)

            for idx, company in enumerate(self.KNOWN_COMPANIES):
                try:
                    jobs = self.scrape_company_board(
                        company,
                        keywords,
                        location,
                        remote_only
                    )
                    all_jobs.extend(jobs)

                    # Update progress
                    progress = 0.1 + (idx / len(self.KNOWN_COMPANIES)) * 0.8
                    self.log_progress(f"Scraped {company}: {len(jobs)} jobs", progress)

                    if len(all_jobs) >= max_results:
                        break

                except Exception as e:
                    self.log_progress(f"Error scraping {company}: {str(e)}", 0.0)
                    continue

            self.log_progress(f"Greenhouse search complete: {len(all_jobs)} jobs", 0.9)

        except Exception as e:
            self.log_progress(f"Greenhouse search failed: {str(e)}", 0.0)

        return all_jobs[:max_results]

    def scrape_company_board(
        self,
        company: str,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool
    ) -> List[Dict]:
        """Scrape a single company's Greenhouse board"""
        jobs = []

        try:
            # Greenhouse API endpoint (public)
            api_url = f"https://boards-api.greenhouse.io/v1/boards/{company}/jobs"

            response = self.make_request(api_url)
            data = response.json()

            # Parse jobs from API response
            for job_data in data.get('jobs', []):
                # Filter by keywords
                if keywords:
                    title = job_data.get('title', '').lower()
                    if not any(kw.lower() in title for kw in keywords):
                        continue

                # Filter by location
                job_location = job_data.get('location', {}).get('name', '')
                if remote_only and 'remote' not in job_location.lower():
                    continue

                if location and location.lower() not in job_location.lower() and 'remote' not in job_location.lower():
                    continue

                # Parse job - use updated_at if available, fallback to current time
                from datetime import datetime
                posted_date = job_data.get('updated_at') or datetime.now().isoformat()

                job = {
                    "title": job_data.get('title', ''),
                    "company": company.title(),
                    "location": job_location,
                    "description": job_data.get('content', ''),
                    "url": job_data.get('absolute_url', ''),
                    "source": self.get_source_name(),
                    "postedDate": posted_date,
                    "isRemote": 'remote' in job_location.lower(),
                    "offersRelocation": False,
                    "matchScore": 0.0,
                    "techStack": self.extract_tech_stack(job_data.get('content', '')),
                    "salaryRange": None,
                    "visaSponsorship": None,
                    "companySize": None
                }

                jobs.append(job)

        except Exception as e:
            pass  # Company board doesn't exist or API failed

        return jobs
