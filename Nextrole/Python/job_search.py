#!/usr/bin/env python3
"""
Job Search Entry Point
Main script for job scraping orchestration
"""

import json
import sys
import os
from typing import Dict

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scrapers.linkedin_scraper import LinkedInScraper
from scrapers.indeed_scraper import IndeedScraper
from scrapers.greenhouse_scraper import GreenhouseScraper
from scrapers.workday_scraper import WorkdayScraper
from scrapers.matcher import calculate_match_score

from concurrent.futures import ThreadPoolExecutor, as_completed


def search_all_boards(resume_data: Dict, filters: Dict) -> Dict:
    """
    Orchestrate scraping across all job boards.
    Run scrapers in parallel and aggregate results.

    Args:
        resume_data: Parsed resume data (skills, keywords, etc.)
        filters: Search filters (location, remote, etc.)

    Returns:
        Dictionary with 'jobs' list and 'errors' list
    """
    scrapers = [
        LinkedInScraper(filters.get('scrapingLevel', 'normal')),
        IndeedScraper(filters.get('scrapingLevel', 'normal')),
        GreenhouseScraper(filters.get('scrapingLevel', 'normal')),
        WorkdayScraper(filters.get('scrapingLevel', 'normal')),
    ]

    all_jobs = []
    errors = []
    max_results = filters.get('maxResults', 100)

    # Progress tracking
    total_scrapers = len(scrapers)
    completed_scrapers = 0

    # Run scrapers in parallel
    with ThreadPoolExecutor(max_workers=4) as executor:
        # Submit all scraper tasks
        future_to_scraper = {
            executor.submit(
                run_scraper,
                scraper,
                filters.get('keywords', []),
                filters.get('location'),
                filters.get('remoteOnly', False),
                filters.get('postedWithinDays'),
                max_results
            ): scraper for scraper in scrapers
        }

        # Collect results as they complete
        for future in as_completed(future_to_scraper):
            scraper = future_to_scraper[future]
            source_name = scraper.get_source_name()

            try:
                jobs = future.result()
                all_jobs.extend(jobs)

                completed_scrapers += 1
                progress = 0.2 + (completed_scrapers / total_scrapers) * 0.6  # 20% to 80%
                log_progress(f"Completed {source_name}", progress)

            except Exception as e:
                error_msg = f"{source_name}: {str(e)}"
                errors.append(error_msg)
                log_progress(f"Error in {source_name}", 0.0)

                completed_scrapers += 1

    # Calculate match scores
    log_progress("Calculating match scores...", 0.85)
    for job in all_jobs:
        score = calculate_match_score(resume_data, job)
        job['matchScore'] = score

    # Deduplicate jobs (same URL or title+company)
    log_progress("Deduplicating results...", 0.90)
    unique_jobs = deduplicate_jobs(all_jobs)

    # Sort by match score
    unique_jobs.sort(key=lambda j: j.get('matchScore', 0.0), reverse=True)

    # Apply filters
    log_progress("Applying filters...", 0.95)
    filtered_jobs = apply_filters(unique_jobs, filters, resume_data)

    return {
        "jobs": filtered_jobs,
        "errors": errors
    }


def run_scraper(
    scraper,
    keywords: list,
    location: str,
    remote_only: bool,
    posted_within_days: int,
    max_results: int
) -> list:
    """Run a single scraper and return results"""
    source_name = scraper.get_source_name()
    log_progress(f"Searching {source_name}...", 0.0)

    jobs = scraper.search(
        keywords=keywords,
        location=location,
        remote_only=remote_only,
        posted_within_days=posted_within_days,
        max_results=max_results
    )

    return jobs


def deduplicate_jobs(jobs: list) -> list:
    """Remove duplicate job postings"""
    seen_urls = set()
    seen_title_company = set()
    unique_jobs = []

    for job in jobs:
        url = job.get('url', '')
        title_company = (job.get('title', '').lower(), job.get('company', '').lower())

        if url and url not in seen_urls:
            seen_urls.add(url)
            seen_title_company.add(title_company)
            unique_jobs.append(job)
        elif title_company not in seen_title_company:
            seen_title_company.add(title_company)
            unique_jobs.append(job)

    return unique_jobs


def apply_filters(jobs: list, filters: Dict, resume_data: Dict) -> list:
    """Apply user filters to job results"""
    filtered = jobs

    # Filter by minimum match score
    min_score = filters.get('minimumMatchScore', 0.5)
    filtered = [j for j in filtered if j.get('matchScore', 0.0) >= min_score]

    # Filter by tech stack
    tech_filter = filters.get('techStack', [])
    if tech_filter:
        filtered = [
            j for j in filtered
            if any(tech.lower() in j.get('description', '').lower() for tech in tech_filter)
        ]

    # Filter by visa sponsorship
    if filters.get('visaSponsorship'):
        filtered = [j for j in filtered if j.get('visaSponsorship') == True]

    # Filter by company type
    company_types = filters.get('companyTypes', [])
    if company_types and company_types != []:
        filtered = [
            j for j in filtered
            if j.get('companySize') in company_types or not j.get('companySize')
        ]

    return filtered


def log_progress(message: str, progress: float):
    """Log progress to stderr for Swift to parse"""
    sys.stderr.write(f"PROGRESS: {message} | {progress:.2f}\n")
    sys.stderr.flush()


def main():
    """Main entry point when called from Swift"""
    try:
        # Read input from stdin (JSON)
        input_data = json.loads(sys.stdin.read())

        action = input_data.get('action')

        if action == 'search':
            resume_data = input_data.get('resumeData', {})
            filters = input_data.get('filters', {})

            result = search_all_boards(resume_data, filters)
        else:
            result = {"jobs": [], "errors": [f"Unknown action: {action}"]}

        # Write output to stdout (JSON)
        print(json.dumps(result))

    except Exception as e:
        import traceback
        error_result = {
            "jobs": [],
            "errors": [f"{str(e)}\n{traceback.format_exc()}"]
        }
        print(json.dumps(error_result))
        sys.exit(1)


if __name__ == "__main__":
    main()
