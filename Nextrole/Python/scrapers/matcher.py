#!/usr/bin/env python3
"""
Job Matching Engine
Calculates match scores between resumes and job postings

Scoring methodology inspired by comprehensive job-resume analysis:
- Technical Skills & Requirements (40%)
- Architecture & Code Quality indicators (20%)
- Collaboration & Soft Skills (15%)
- Experience Level Match (15%)
- Location Match (10%)
"""

import re
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
    'graphql': ['graph ql'],
    'postgresql': ['postgres', 'psql'],
    'mongodb': ['mongo'],
    'kubernetes': ['k8s'],
    'amazon web services': ['aws'],
    'google cloud platform': ['gcp'],
    'continuous integration': ['ci/cd', 'ci cd'],
}

# Architecture and quality indicators
ARCHITECTURE_KEYWORDS = [
    'clean architecture', 'mvvm', 'mvc', 'viper', 'vip',
    'solid', 'design patterns', 'dependency injection',
    'modular', 'modularization', 'microservices',
    'tdd', 'test driven', 'unit test', 'xctest', 'xctestcase',
    'code review', 'pull request', 'pr review',
    'refactor', 'technical debt', 'best practices',
]

# Collaboration and leadership indicators
COLLABORATION_KEYWORDS = [
    'cross-functional', 'cross functional', 'collaborate', 'collaboration',
    'partner', 'stakeholder', 'product manager', 'designer',
    'mentor', 'mentoring', 'lead', 'leadership', 'team',
    'agile', 'scrum', 'sprint', 'standup',
    'communicate', 'communication', 'presentation',
]

# Scale and impact indicators
SCALE_INDICATORS = [
    r'\d+[km]?\+?\s*users',  # "1M users", "100K+ users"
    r'\d+%\s*(improvement|reduction|increase|decrease)',  # "30% improvement"
    r'(millions?|thousands?)\s*(of\s+)?(users|customers|downloads)',
    r'high.?traffic', r'large.?scale', r'enterprise',
    r'performance\s+optimi[sz]', r'crash\s+rate',
]


def normalize_skill(skill: str) -> str:
    """Normalize a skill name for matching"""
    skill_lower = skill.lower().strip()

    for main_skill, synonyms in SKILL_SYNONYMS.items():
        if skill_lower in synonyms or skill_lower == main_skill:
            return main_skill

    return skill_lower


def get_skill_set(skills: List[str]) -> Set[str]:
    """Convert a list of skills to a normalized set"""
    return {normalize_skill(skill) for skill in skills}


def calculate_technical_skills_score(resume_skills: List[str], resume_text: str, job_text: str) -> float:
    """
    Calculate technical skills match score.

    Evaluates:
    1. How many resume skills appear in job requirements
    2. How many job-required skills appear in resume
    3. Depth indicators (not just presence)

    Returns:
        Score between 0.0 and 1.0
    """
    if not resume_skills:
        return 0.3  # Low score if no skills parsed

    resume_skill_set = get_skill_set(resume_skills)
    job_text_lower = job_text.lower()
    resume_text_lower = (resume_text or '').lower()

    # 1. Resume skills found in job (forward match)
    forward_matches = 0
    for skill in resume_skill_set:
        if skill in job_text_lower:
            forward_matches += 1
        else:
            # Fuzzy match
            for word in job_text_lower.split():
                if len(word) > 3 and fuzz.ratio(skill, word) > 85:
                    forward_matches += 1
                    break

    forward_ratio = forward_matches / len(resume_skill_set) if resume_skill_set else 0

    # 2. Extract likely required skills from job and check resume
    job_skill_indicators = extract_job_requirements(job_text_lower)
    reverse_matches = 0
    for req in job_skill_indicators:
        req_normalized = normalize_skill(req)
        if req_normalized in resume_skill_set:
            reverse_matches += 1
        elif req.lower() in resume_text_lower:
            reverse_matches += 0.7  # Partial credit for mention in resume text

    reverse_ratio = reverse_matches / len(job_skill_indicators) if job_skill_indicators else 0.5

    # 3. Depth bonus - look for quantified experience
    depth_bonus = 0.0
    for pattern in SCALE_INDICATORS:
        if re.search(pattern, resume_text_lower, re.IGNORECASE):
            depth_bonus += 0.05
    depth_bonus = min(depth_bonus, 0.15)  # Cap at 15% bonus

    # Combine: 50% forward, 40% reverse, 10% depth
    score = (forward_ratio * 0.5) + (reverse_ratio * 0.4) + depth_bonus

    return min(1.0, max(0.0, score))


def extract_job_requirements(job_text: str) -> List[str]:
    """Extract likely required skills/technologies from job description"""
    requirements = []

    # Common tech terms to look for
    tech_terms = [
        'swift', 'objective-c', 'swiftui', 'uikit', 'combine', 'rxswift',
        'graphql', 'rest', 'api', 'websocket',
        'python', 'javascript', 'typescript', 'java', 'kotlin', 'go', 'rust',
        'react', 'vue', 'angular', 'django', 'flask', 'spring',
        'aws', 'azure', 'gcp', 'docker', 'kubernetes',
        'postgresql', 'mongodb', 'redis', 'mysql', 'sqlite',
        'git', 'ci/cd', 'jenkins', 'github actions',
        'agile', 'scrum', 'jira',
    ]

    job_lower = job_text.lower()
    for term in tech_terms:
        if term in job_lower:
            requirements.append(term)

    return requirements


def calculate_architecture_quality_score(resume_text: str, job_text: str) -> float:
    """
    Calculate architecture and code quality match.

    Evaluates:
    - Architecture patterns mentioned
    - Testing practices
    - Code quality indicators

    Returns:
        Score between 0.0 and 1.0
    """
    resume_lower = (resume_text or '').lower()
    job_lower = job_text.lower()

    # Find architecture keywords in both
    resume_arch_count = 0
    job_arch_count = 0
    matches = 0

    for keyword in ARCHITECTURE_KEYWORDS:
        in_resume = keyword in resume_lower
        in_job = keyword in job_lower

        if in_resume:
            resume_arch_count += 1
        if in_job:
            job_arch_count += 1
        if in_resume and in_job:
            matches += 1

    # Score based on coverage of job requirements
    if job_arch_count > 0:
        coverage = matches / job_arch_count
    else:
        # Job doesn't emphasize architecture, give neutral-to-good score based on resume
        coverage = min(resume_arch_count / 5, 1.0) * 0.7 + 0.3

    # Bonus for having strong architecture background regardless
    arch_bonus = min(resume_arch_count / 8, 0.2)

    return min(1.0, coverage + arch_bonus)


def calculate_collaboration_score(resume_text: str, job_text: str) -> float:
    """
    Calculate collaboration and soft skills match.

    Evaluates:
    - Cross-functional collaboration indicators
    - Leadership and mentoring
    - Communication skills

    Returns:
        Score between 0.0 and 1.0
    """
    resume_lower = (resume_text or '').lower()
    job_lower = job_text.lower()

    resume_collab_count = 0
    job_collab_count = 0
    matches = 0

    for keyword in COLLABORATION_KEYWORDS:
        in_resume = keyword in resume_lower
        in_job = keyword in job_lower

        if in_resume:
            resume_collab_count += 1
        if in_job:
            job_collab_count += 1
        if in_resume and in_job:
            matches += 1

    # Score based on coverage of job requirements
    if job_collab_count > 0:
        coverage = matches / job_collab_count
    else:
        # Job doesn't emphasize collaboration, give neutral score
        coverage = 0.6

    # Bonus for strong collaboration signals in resume
    collab_bonus = min(resume_collab_count / 6, 0.15)

    return min(1.0, coverage + collab_bonus)


def calculate_experience_match(resume_years: int, job_text: str) -> float:
    """
    Calculate experience level match.

    Returns:
        Score between 0.0 and 1.0
    """
    if resume_years == 0:
        resume_years = 3  # Assume some experience if not specified

    job_text_lower = job_text.lower()

    # Look for experience requirements
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
        # Infer from title
        if 'principal' in job_text_lower or 'staff' in job_text_lower:
            required_years = 8
        elif 'senior' in job_text_lower or 'sr.' in job_text_lower:
            required_years = 5
        elif 'lead' in job_text_lower:
            required_years = 6
        elif 'junior' in job_text_lower or 'entry' in job_text_lower:
            required_years = 0
        else:
            required_years = 3  # Default mid-level

    # Calculate match
    if resume_years >= required_years:
        # Meeting or exceeding requirements
        overage = resume_years - required_years
        if overage > 7:
            return 0.75  # Significantly overqualified
        elif overage > 4:
            return 0.85  # Somewhat overqualified
        else:
            return 1.0  # Good match
    else:
        # Under requirements
        gap = required_years - resume_years
        if gap <= 1:
            return 0.85  # Close enough
        elif gap <= 2:
            return 0.65
        elif gap <= 3:
            return 0.45
        else:
            return 0.25


def calculate_location_match(resume_location: str, job_location: str) -> float:
    """
    Calculate location match score.

    Returns:
        Score between 0.0 and 1.0
    """
    if not job_location:
        return 0.7  # No location specified, neutral-positive

    job_loc_lower = job_location.lower()

    # Remote jobs are universal match
    if 'remote' in job_loc_lower:
        return 1.0

    if not resume_location:
        return 0.5  # Can't determine match

    resume_loc_lower = resume_location.lower()

    # Exact or partial match
    if resume_loc_lower in job_loc_lower or job_loc_lower in resume_loc_lower:
        return 1.0

    # Same country/region check
    countries = ['usa', 'us', 'united states', 'uk', 'canada', 'japan', 'germany', 'australia']
    for country in countries:
        if country in resume_loc_lower and country in job_loc_lower:
            return 0.8

    # State code match
    resume_state = re.search(r'\b([A-Z]{2})\b', resume_location)
    job_state = re.search(r'\b([A-Z]{2})\b', job_location)
    if resume_state and job_state and resume_state.group(1) == job_state.group(1):
        return 0.85

    return 0.3  # Different locations


def calculate_match_score(resume_data: Dict, job: Dict) -> float:
    """
    Calculate overall match score between resume and job posting.

    Returns:
        Score between 0.0 and 1.0
    """
    breakdown = calculate_match_breakdown(resume_data, job)
    return breakdown['totalScore']


def calculate_match_breakdown(resume_data: Dict, job: Dict) -> Dict:
    """
    Calculate match score with detailed breakdown for each factor.

    Scoring weights (aligned with comprehensive job analysis):
    - Technical Skills: 40%
    - Architecture & Quality: 20%
    - Collaboration: 15%
    - Experience: 15%
    - Location: 10%

    Returns:
        Dictionary with totalScore and breakdown of each factor
    """
    # Extract data
    resume_skills = resume_data.get('skills', [])
    resume_text = resume_data.get('text', '')  # Full resume text if available
    resume_location = resume_data.get('location', '')
    resume_years = resume_data.get('yearsExperience', 0) or 0

    job_text = f"{job.get('title', '')} {job.get('description', '')}"
    job_location = job.get('location', '')

    # If no full resume text, construct from available data
    if not resume_text:
        resume_text = ' '.join(resume_skills + resume_data.get('keywords', []))

    # Calculate component scores
    skills_score = calculate_technical_skills_score(resume_skills, resume_text, job_text)
    architecture_score = calculate_architecture_quality_score(resume_text, job_text)
    collaboration_score = calculate_collaboration_score(resume_text, job_text)
    experience_score = calculate_experience_match(resume_years, job_text)
    location_score = calculate_location_match(resume_location, job_location)

    # Weights aligned with comprehensive analysis
    weights = {
        'skills': 0.40,
        'architecture': 0.20,
        'collaboration': 0.15,
        'experience': 0.15,
        'location': 0.10
    }

    # Weighted average
    total_score = (
        skills_score * weights['skills'] +
        architecture_score * weights['architecture'] +
        collaboration_score * weights['collaboration'] +
        experience_score * weights['experience'] +
        location_score * weights['location']
    )

    # Ensure score is between 0 and 1
    total_score = max(0.0, min(1.0, total_score))

    # Build breakdown (keep backward compatible field names for UI)
    return {
        'totalScore': total_score,
        'skillsScore': skills_score,
        'skillsWeight': weights['skills'],
        'keywordsScore': architecture_score,  # Renamed but keeping field for UI
        'keywordsWeight': weights['architecture'],
        'experienceScore': experience_score,
        'experienceWeight': weights['experience'],
        'locationScore': location_score,
        'locationWeight': weights['location'],
        'titleScore': collaboration_score,  # Renamed but keeping field for UI
        'titleWeight': weights['collaboration'],
    }
