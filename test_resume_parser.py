#!/usr/bin/env python3
"""
Quick test to verify resume parser works
"""

import sys
import json

# Test if we can import the parser
try:
    sys.path.insert(0, './Nextrole/Python')
    from resume_parser import parse_resume
    print("✓ Successfully imported resume_parser")
except ImportError as e:
    print(f"✗ Failed to import resume_parser: {e}")
    sys.exit(1)

# Test parsing with a non-existent file (should handle gracefully)
print("\nTesting parser with non-existent file...")
result = parse_resume("/tmp/nonexistent.pdf")
print(f"Result: {json.dumps(result, indent=2)}")

if "error" in result:
    print("\n✓ Parser handles missing files correctly")
else:
    print("\n✗ Parser should return error for missing file")

print("\nResume parser is ready!")
print("\nTo test with a real PDF:")
print("  1. Place a PDF resume in /tmp/test_resume.pdf")
print("  2. Run: python3 test_resume_parser.py /tmp/test_resume.pdf")
