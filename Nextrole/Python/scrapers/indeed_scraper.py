#!/usr/bin/env python3
"""
Indeed Job Scraper
Scrapes job postings from Indeed.com
"""

from typing import List, Dict, Optional
from bs4 import BeautifulSoup
from urllib.parse import quote_plus
from .base_scraper import BaseScraper


class IndeedScraper(BaseScraper):
    """Scraper for Indeed job board"""

    BASE_URL = "https://www.indeed.com"

    def get_source_name(self) -> str:
        return "Indeed"

    def search(
        self,
        keywords: List[str],
        location: Optional[str],
        remote_only: bool,
        posted_within_days: Optional[int],
        max_results: int
    ) -> List[Dict]:
        """Search Indeed for job postings"""
        jobs = []

        try:
            # Build search query
            query = " ".join(keywords) if keywords else "developer"
            location_query = location if location else "Remote"

            # Build URL parameters
            params = {
                'q': query,
                'l': location_query,
            }

            if remote_only:
                params['sc'] = '0kf:attr(DSQF7)remotejob;'

            if posted_within_days:
                params['fromage'] = str(posted_within_days)

            # Construct search URL
            search_url = f"{self.BASE_URL}/jobs?q={quote_plus(query)}&l={quote_plus(location_query)}"

            if remote_only:
                search_url += "&remotejob=032b3046-06a3-4876-8dfd-474eb5e7ed11"

            if posted_within_days:
                search_url += f"&fromage={posted_within_days}"

            self.log_progress(f"Searching Indeed for '{query}'...", 0.1)

            # Make request
            response = self.make_request(search_url)
            soup = BeautifulSoup(response.text, 'lxml')

            # Find job cards
            job_cards = soup.find_all('div', class_='job_seen_beacon') or \
                       soup.find_all('div', class_='jobsearch-SerpJobCard') or \
                       soup.find_all('a', class_='jcs-JobTitle')

            self.log_progress(f"Found {len(job_cards)} job cards", 0.3)

            for idx, card in enumerate(job_cards[:max_results]):
                try:
                    job = self.parse_job_card(card)
                    if job:
                        jobs.append(job)

                    # Update progress
                    progress = 0.3 + (idx / min(len(job_cards), max_results)) * 0.6
                    self.log_progress(f"Parsed {idx+1}/{len(job_cards)} jobs", progress)

                except Exception as e:
                    self.log_progress(f"Error parsing job card: {str(e)}", 0.0)
                    continue

            self.log_progress(f"Completed Indeed search: {len(jobs)} jobs", 0.9)

        except Exception as e:
            self.log_progress(f"Indeed search failed: {str(e)}", 0.0)
            raise

        return jobs

    def parse_job_card(self, card) -> Optional[Dict]:
        """Parse a single job card"""
        try:
            # Extract title
            title_elem = card.find('h2', class_='jobTitle') or \
                        card.find('a', class_='jcs-JobTitle')

            if not title_elem:
                return None

            title = title_elem.get_text(strip=True)

            # Extract company
            company_elem = card.find('span', class_='companyName')
            company = company_elem.get_text(strip=True) if company_elem else "Unknown Company"

            # Extract location
            location_elem = card.find('div', class_='companyLocation')
            location = location_elem.get_text(strip=True) if location_elem else "Unknown Location"

            # Determine if remote
            is_remote = 'remote' in location.lower()

            # Extract job URL
            link_elem = title_elem.find('a') if title_elem.name != 'a' else title_elem
            job_id = link_elem.get('data-jk', '') if link_elem else ''
            job_url = f"{self.BASE_URL}/viewjob?jk={job_id}" if job_id else f"{self.BASE_URL}/jobs"

            # Extract snippet/description
            snippet_elem = card.find('div', class_='job-snippet')
            description = snippet_elem.get_text(strip=True) if snippet_elem else ""

            # Extract posted date
            date_elem = card.find('span', class_='date')
            posted_date_str = date_elem.get_text(strip=True) if date_elem else "Unknown"
            posted_date = self.parse_relative_date(posted_date_str)

            # Extract tech stack from description
            tech_stack = self.extract_tech_stack(description + " " + title)

            return {
                "title": title,
                "company": company,
                "location": location,
                "description": description,
                "url": job_url,
                "source": self.get_source_name(),
                "postedDate": posted_date,
                "isRemote": is_remote,
                "offersRelocation": False,  # Indeed doesn't always show this
                "matchScore": 0.0,  # Will be calculated later
                "techStack": tech_stack,
                "salaryRange": None,
                "visaSponsorship": None,
                "companySize": None
            }

        except Exception as e:
            return None
