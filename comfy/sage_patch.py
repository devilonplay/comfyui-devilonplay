import re
import sys
import os

print("--- STARTING SAGEATTENTION PATCH ---")

target_file = 'setup.py'

if not os.path.exists(target_file):
    print(f"Error: {target_file} not found!")
    sys.exit(1)

try:
    with open(target_file, 'r') as f:
        content = f.read()
    
    print("Read setup.py successfully.")

    # 1. Force populate compute_capabilities
    # Matches: compute_capabilities = set()
    # Replaces with hardcoded set
    new_content, count1 = re.subn(
        r'compute_capabilities\s*=\s*set\(\)', 
        'compute_capabilities = { "8.0", "8.6", "8.9", "9.0" }', 
        content
    )
    print(f"Replaced compute_capabilities init: {count1} occurrence(s)")

    # 2. Kill the check that raises RuntimeError
    # Matches: "if not compute_capabilities:" and replaces with "if False:"
    new_content, count2 = re.subn(
        r'if\s+not\s+compute_capabilities:', 
        'if False:', 
        new_content
    )
    print(f"Disabled GPU check block: {count2} occurrence(s)")

    if count1 == 0 and count2 == 0:
        print("WARNING: No replacements made! Regex might depend on exact spacing.")
        # Fallback dump for debugging
        print(content[:500])
        sys.exit(1)

    with open(target_file, 'w') as f:
        f.write(new_content)
    
    print("--- PATCH APPLIED SUCCESSFULLY ---")

except Exception as e:
    print(f"EXCEPTION DURING PATCH: {e}")
    sys.exit(1)
