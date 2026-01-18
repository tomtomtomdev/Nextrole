#!/usr/bin/env python3
"""
Resume Parser Module
Extracts structured data from PDF resumes
"""

import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Optional

try:
    from pypdf import PdfReader
except ImportError:
    from PyPDF2 import PdfReader  # Fallback

# Common tech skills for developers
TECH_SKILLS = {
    # Programming Languages
    'python', 'javascript', 'java', 'c++', 'c#', 'swift', 'kotlin', 'go', 'rust', 'ruby',
    'php', 'typescript', 'scala', 'r', 'matlab', 'perl', 'objective-c', 'dart', 'elixir',

    # Frameworks & Libraries
    'react', 'angular', 'vue', 'svelte', 'django', 'flask', 'fastapi', 'spring', 'rails',
    'express', 'nextjs', 'nuxt', 'gatsby', 'node.js', 'nodejs', 'jquery', 'bootstrap',
    'tailwind', 'swiftui', 'uikit', 'jetpack compose', 'flutter', 'react native',

    # Databases
    'postgresql', 'mysql', 'mongodb', 'redis', 'elasticsearch', 'cassandra', 'dynamodb',
    'sqlite', 'oracle', 'sql server', 'mariadb', 'neo4j', 'couchdb', 'firebase',

    # Cloud & DevOps
    'aws', 'azure', 'gcp', 'docker', 'kubernetes', 'jenkins', 'gitlab ci', 'github actions',
    'terraform', 'ansible', 'chef', 'puppet', 'circleci', 'travis ci', 'heroku', 'vercel',

    # Tools & Technologies
    'git', 'linux', 'bash', 'vim', 'vscode', 'xcode', 'android studio', 'intellij',
    'webpack', 'vite', 'babel', 'eslint', 'prettier', 'jest', 'pytest', 'junit',
    'graphql', 'rest api', 'grpc', 'websockets', 'oauth', 'jwt', 'ssl', 'tls',

    # Data Science & ML
    'tensorflow', 'pytorch', 'keras', 'scikit-learn', 'pandas', 'numpy', 'matplotlib',
    'jupyter', 'spark', 'hadoop', 'airflow', 'mlflow', 'kubeflow',

    # Mobile
    'ios', 'android', 'cocoa', 'cocoa touch', 'core data', 'realm', 'rxswift', 'combine',

    # Testing
    'unit testing', 'integration testing', 'e2e testing', 'selenium', 'cypress', 'puppeteer',
    'xctest', 'espresso', 'appium',

    # Methodologies
    'agile', 'scrum', 'kanban', 'tdd', 'bdd', 'ci/cd', 'microservices', 'serverless',
}


def extract_text_from_pdf(pdf_path: str) -> str:
    """Extract text content from PDF file"""
    try:
        reader = PdfReader(pdf_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text.strip()
    except Exception as e:
        return f"Error extracting text: {str(e)}"


def extract_skills(text: str) -> List[str]:
    """Extract technical skills from resume text"""
    text_lower = text.lower()
    found_skills = set()

    # Look for exact matches and common variations
    for skill in TECH_SKILLS:
        # Create pattern that matches whole words
        pattern = r'\b' + re.escape(skill) + r'\b'
        if re.search(pattern, text_lower):
            found_skills.add(skill.title())

    # Look for version patterns (e.g., "Python 3.9", "iOS 15")
    version_patterns = [
        r'\b(Python|Java|Swift|Kotlin|Go|Rust|Ruby|PHP|Node\.js)\s+\d+',
        r'\b(iOS|Android)\s+\d+',
        r'\b(React|Angular|Vue)\s+\d+',
    ]

    for pattern in version_patterns:
        matches = re.finditer(pattern, text, re.IGNORECASE)
        for match in matches:
            found_skills.add(match.group(0))

    return sorted(list(found_skills))


def extract_keywords(text: str) -> List[str]:
    """Extract important keywords beyond just tech skills"""
    keywords = set()

    # Common developer-related terms
    keyword_patterns = [
        r'\b(full-stack|full stack|frontend|front-end|backend|back-end|devops)\b',
        r'\b(senior|lead|principal|staff|architect)\b',
        r'\b(engineer|developer|programmer|architect)\b',
        r'\b(open source|open-source)\b',
        r'\b(distributed systems|scalability|performance|security)\b',
        r'\b(api design|system design|database design)\b',
    ]

    text_lower = text.lower()
    for pattern in keyword_patterns:
        matches = re.finditer(pattern, text_lower, re.IGNORECASE)
        for match in matches:
            keywords.add(match.group(0).lower())

    return sorted(list(keywords))


def extract_experience(text: str) -> List[Dict[str, str]]:
    """Extract work experience from resume"""
    experiences = []

    # Look for common job title patterns
    job_title_pattern = r'(Senior|Lead|Principal|Staff|Junior)?\s*(Software|iOS|Android|Full[- ]Stack|Frontend|Backend|DevOps)?\s*(Engineer|Developer|Architect|Programmer)'

    # Look for company names (uppercase words, possibly with Inc, LLC, etc.)
    company_pattern = r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*(?:\s+(?:Inc|LLC|Corp|Corporation|Ltd))?)'

    # Look for date ranges
    date_pattern = r'(\d{4})\s*[-–—]\s*(\d{4}|Present|Current)'

    lines = text.split('\n')
    for i, line in enumerate(lines):
        title_match = re.search(job_title_pattern, line, re.IGNORECASE)
        date_match = re.search(date_pattern, line)

        if title_match and date_match:
            title = title_match.group(0).strip()
            duration = date_match.group(0).strip()

            # Look for company in nearby lines
            company = "Unknown Company"
            for j in range(max(0, i-2), min(len(lines), i+3)):
                company_match = re.search(company_pattern, lines[j])
                if company_match and company_match.group(0) != title:
                    company = company_match.group(0).strip()
                    break

            experiences.append({
                "title": title,
                "company": company,
                "duration": duration
            })

    return experiences[:5]  # Return max 5 experiences


def extract_location(text: str) -> Optional[str]:
    """Extract location from resume"""
    # Look for city, state patterns
    location_pattern = r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*),\s*([A-Z]{2})\b'
    match = re.search(location_pattern, text)

    if match:
        return f"{match.group(1)}, {match.group(2)}"

    # Look for just state
    state_pattern = r'\b([A-Z]{2})\b'
    match = re.search(state_pattern, text)
    if match:
        return match.group(1)

    return None


def calculate_years_of_experience(experiences: List[Dict[str, str]]) -> int:
    """Calculate total years of experience"""
    total_years = 0
    current_year = 2026

    for exp in experiences:
        duration = exp.get('duration', '')
        # Extract start and end years
        years = re.findall(r'\d{4}', duration)
        if len(years) >= 2:
            start_year = int(years[0])
            end_year = int(years[1]) if years[1].isdigit() else current_year
            total_years += (end_year - start_year)
        elif 'Present' in duration or 'Current' in duration:
            if years:
                start_year = int(years[0])
                total_years += (current_year - start_year)

    return total_years


def parse_resume(pdf_path: str) -> Dict:
    """
    Main function to parse resume and return structured data

    Returns:
        Dictionary with parsed resume data
    """
    # Extract text from PDF
    text = extract_text_from_pdf(pdf_path)

    if text.startswith("Error"):
        return {
            "error": text,
            "text": "",
            "skills": [],
            "keywords": [],
            "experience": [],
            "location": None,
            "yearsExperience": 0
        }

    # Extract structured data
    skills = extract_skills(text)
    keywords = extract_keywords(text)
    experiences = extract_experience(text)
    location = extract_location(text)
    years_exp = calculate_years_of_experience(experiences)

    return {
        "text": text[:5000],  # First 5000 chars for preview
        "skills": skills,
        "keywords": keywords,
        "experience": experiences,
        "location": location,
        "yearsExperience": years_exp
    }


def main():
    """Main entry point when called from Swift"""
    try:
        # Read input from stdin (JSON)
        input_data = json.loads(sys.stdin.read())

        action = input_data.get('action')

        if action == 'parse':
            pdf_path = input_data.get('pdf_path')
            if not pdf_path or not Path(pdf_path).exists():
                result = {"error": "PDF file not found"}
            else:
                result = parse_resume(pdf_path)
        else:
            result = {"error": f"Unknown action: {action}"}

        # Write output to stdout (JSON)
        print(json.dumps(result))

    except Exception as e:
        error_result = {"error": str(e)}
        print(json.dumps(error_result))
        sys.exit(1)


if __name__ == "__main__":
    main()
