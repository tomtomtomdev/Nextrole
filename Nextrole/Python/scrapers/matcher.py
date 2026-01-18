#!/usr/bin/env python3
"""
Job Matching Engine
Calculates match scores between resumes and job postings
"""

from typing import Dict, List, Set
from fuzzywuzzy import fuzz


# Synonym mapping for tech skills
SKILL_SYNONYMS = {
    'javascript': ['js', 'ecmascript', 'node', 'nodejs', 'node.js'],
    'typescript': ['ts'],
    'python': ['py'],
    'objective-c': ['objective c', 'objc'],
    'c++': ['cpp', 'cplusplus'],
    'c#': ['csharp'],
    'swiftui': ['swift ui'],
    'uikit': ['ui kit'],
    'react': ['reactjs', 'react.js'],
    'vue': ['vuejs', 'vue.js'],
    'angular': ['angularjs', 'angular.js'],
}


def normalize_skill(skill: str) -> str:
    """Normalize a skill name for matching"""
    skill_lower = skill.lower().strip()

    # Check if it's a synonym
    for main_skill, synonyms in SKILL_SYNONYMS.items():
        if skill_lower in synonyms or skill_lower == main_skill:
            return main_skill

    return skill_lower


def get_skill_set(skills: List[str]) -> Set[str]:
    """Convert a list of skills to a normalized set"""
    return {normalize_skill(skill) for skill in skills}


def calculate_skill_overlap(resume_skills: List[str], job_text: str) -> float:
    """
    Calculate skill overlap between resume and job description

    Returns:
        Score between 0.0 and 1.0
    """
    if not resume_skills:
        return 0.0

    resume_skill_set = get_skill_set(resume_skills)
    job_text_lower = job_text.lower()

    matches = 0
    total = len(resume_skill_set)

    for skill in resume_skill_set:
        # Check for exact match
        if skill in job_text_lower:
            matches += 1
            continue

        # Check for fuzzy match
        for word in job_text_lower.split():
            if fuzz.ratio(skill, word) > 85:  # 85% similarity
                matches += 1
                break

    return matches / total if total > 0 else 0.0


def calculate_keyword_match(resume_keywords: List[str], job_text: str) -> float:
    """
    Calculate keyword match between resume and job description

    Returns:
        Score between 0.0 and 1.0
    """
    if not resume_keywords:
        return 0.5  # Neutral score if no keywords

    job_text_lower = job_text.lower()
    matches = 0
    total = len(resume_keywords)

    for keyword in resume_keywords:
        if keyword.lower() in job_text_lower:
            matches += 1

    return matches / total if total > 0 else 0.0


def calculate_location_match(resume_location: str, job_location: str) -> float:
    """
    Calculate location match score

    Returns:
        Score between 0.0 and 1.0
    """
    if not resume_location or not job_location:
        return 0.5  # Neutral if location not specified

    resume_loc_lower = resume_location.lower()
    job_loc_lower = job_location.lower()

    # Remote jobs match everyone
    if 'remote' in job_loc_lower:
        return 1.0

    # Exact match (city or state)
    if resume_loc_lower in job_loc_lower or job_loc_lower in resume_loc_lower:
        return 1.0

    # Same state (extract 2-letter state codes)
    import re
    resume_state = re.search(r'\b([A-Z]{2})\b', resume_location)
    job_state = re.search(r'\b([A-Z]{2})\b', job_location)

    if resume_state and job_state and resume_state.group(1) == job_state.group(1):
        return 0.7  # Same state, different city

    return 0.3  # Different locations


def calculate_experience_match(resume_years: int, job_text: str) -> float:
    """
    Calculate experience level match

    Returns:
        Score between 0.0 and 1.0
    """
    if resume_years == 0:
        return 0.5  # Neutral if not specified

    job_text_lower = job_text.lower()

    # Look for experience requirements in job description
    import re
    exp_patterns = [
        r'(\d+)\+?\s*years?\s+(?:of\s+)?experience',
        r'(\d+)-(\d+)\s*years?\s+(?:of\s+)?experience',
        r'(\d+)\s*to\s*(\d+)\s*years',
    ]

    required_years = None

    for pattern in exp_patterns:
        match = re.search(pattern, job_text_lower)
        if match:
            try:
                required_years = int(match.group(1))
                break
            except:
                continue

    if required_years is None:
        # Try to determine from title
        if 'senior' in job_text_lower or 'lead' in job_text_lower:
            required_years = 5
        elif 'junior' in job_text_lower or 'entry' in job_text_lower:
            required_years = 0
        else:
            required_years = 2  # Default for mid-level

    # Calculate match based on difference
    if resume_years >= required_years:
        # Overqualified? Slight penalty for being too experienced
        if resume_years > required_years + 5:
            return 0.8
        return 1.0
    else:
        # Underqualified - proportional penalty
        gap = required_years - resume_years
        if gap <= 1:
            return 0.8  # Slight shortage is okay
        elif gap <= 2:
            return 0.6
        else:
            return 0.4


def calculate_match_score(resume_data: Dict, job: Dict) -> float:
    """
    Calculate overall match score between resume and job posting

    Scoring factors:
    - Skills overlap (40%)
    - Keyword match (30%)
    - Experience level match (15%)
    - Location match (10%)
    - Title match (5%)

    Returns:
        Score between 0.0 and 1.0
    """
    # Extract data
    resume_skills = resume_data.get('skills', [])
    resume_keywords = resume_data.get('keywords', [])
    resume_location = resume_data.get('location', '')
    resume_years = resume_data.get('yearsExperience', 0)

    job_text = f"{job.get('title', '')} {job.get('description', '')}".lower()
    job_location = job.get('location', '')
    job_title = job.get('title', '').lower()

    # Calculate component scores
    skills_score = calculate_skill_overlap(resume_skills, job_text)
    keywords_score = calculate_keyword_match(resume_keywords, job_text)
    experience_score = calculate_experience_match(resume_years, job_text)
    location_score = calculate_location_match(resume_location, job_location)

    # Title match (simple keyword match)
    title_score = 0.5  # Default
    if resume_keywords:
        for keyword in resume_keywords:
            if keyword.lower() in job_title:
                title_score = 1.0
                break

    # Weighted average
    total_score = (
        skills_score * 0.40 +
        keywords_score * 0.30 +
        experience_score * 0.15 +
        location_score * 0.10 +
        title_score * 0.05
    )

    # Ensure score is between 0 and 1
    return max(0.0, min(1.0, total_score))
