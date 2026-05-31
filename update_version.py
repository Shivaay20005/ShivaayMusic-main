import re
import os
import sys
from datetime import datetime

# Enable UTF-8 output on Windows terminals to prevent UnicodeEncodeError for emojis
if sys.platform == 'win32':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except AttributeError:
        pass

#py update_version.py 1.0.1+1     using technique 
# === CONFIGURATION ===
FILES = {
    'pubspec': 'pubspec.yaml',
    'runner_rc': 'windows/runner/Runner.rc',
    'inno_iss': 'windows/packaging/exe/inno_setup.iss',
    'settings': 'lib/ui/screens/Settings/settings_screen_controller.dart',
    'license': 'LICENSE'
}

def validate_version(version_str):
    """Matches format 1.0.0+1"""
    pattern = r'^(\d+)\.(\d+)\.(\d+)\+(\d+)$'
    match = re.match(pattern, version_str)
    if not match:
        print(f"❌ Error: Invalid version format '{version_str}'. expected format: '1.0.4+4'")
        return None
    return {
        'full': version_str,
        'major': match.group(1),
        'minor': match.group(2),
        'patch': match.group(3),
        'build': match.group(4),
        'short': f"{match.group(1)}.{match.group(2)}.{match.group(3)}"
    }

def update_file(path, regex_pattern, replacement, description):
    if not os.path.exists(path):
        print(f"⚠️  Skipping {description}: File not found ({path})")
        return False
    
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if re.search(regex_pattern, content, re.MULTILINE):
        new_content = re.sub(regex_pattern, replacement, content, count=1, flags=re.MULTILINE)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"✅ Updated {description}")
        return True
    else:
        print(f"⚠️  Could not find pattern in {description}")
        return False

def main():
    print("🚀 ShivaayMusic Version bumper")
    
    # 1. Get arguments
    if len(sys.argv) > 1:
        raw_version = sys.argv[1]
    else:
        raw_version = input("Enter new version (e.g., 1.0.4+4): ").strip()
    
    # 2. Parse version
    v = validate_version(raw_version)
    if not v:
        sys.exit(1)
        
    print(f"\n📦 Applying version: {v['full']} (Build: {v['build']})")
    print("-" * 50)

    # 3. Update pubspec.yaml
    # pattern: version: 1.0.0+1
    update_file(
        FILES['pubspec'], 
        r'^version: .+$', 
        f'version: {v["full"]}', 
        'pubspec.yaml'
    )

    # 4. Update Runner.rc (Windows)
    # pattern: #define VERSION_AS_NUMBER 1,0,0,1
    # pattern: #define VERSION_AS_STRING "1.0.0.1"
    
    win_num = f"{v['major']},{v['minor']},{v['patch']},{v['build']}"
    win_str = f'"{v["major"]}.{v["minor"]}.{v["patch"]}.{v["build"]}"'
    
    update_file(
        FILES['runner_rc'], 
        r'#define VERSION_AS_NUMBER [\d,]+', 
        f'#define VERSION_AS_NUMBER {win_num}', 
        'Runner.rc (Number)'
    )
    update_file(
        FILES['runner_rc'], 
        r'#define VERSION_AS_STRING "[^"]+"', 
        f'#define VERSION_AS_STRING {win_str}', 
        'Runner.rc (String)'
    )

    # 5. Update Inno Setup (.iss)
    # pattern: AppVersion=1.0.0
    update_file(
        FILES['inno_iss'],
        r'^AppVersion=.+$',
        f'AppVersion={v["short"]}',
        'Inno Setup (iss)'
    )

    # 6. Update Dart Settings Controller (Fallback)
    # pattern: currentVersion.value = "V1.0.0";
    # pattern: final currentVersion = "V1.0.0".obs;
    update_file(
        FILES['settings'],
        r'currentVersion\.value = "V[\d\.]+";',
        f'currentVersion.value = "V{v["short"]}";',
        'Dart Settings (Value)'
    )
    # Try updating valid constant if it exists differently
    update_file(
        FILES['settings'],
        r'final currentVersion = "V[\d\.]+"\.obs',
        f'final currentVersion = "V{v["short"]}".obs',
        'Dart Settings (Obs)'
    )

    # 7. Update LICENSE
    # pattern: VERSION 1.0.4 | LAST UPDATED: MAY 04, 2026
    current_date = datetime.now().strftime("%B %d, %Y").upper()
    update_file(
        FILES['license'],
        r'VERSION [\d\.]+ \| LAST UPDATED: .+$',
        f'VERSION {v["short"]} | LAST UPDATED: {current_date}',
        'LICENSE File'
    )

    print("-" * 50)
    print("✨  Done! Run 'flutter build apk' or 'flutter build windows' now.")

if __name__ == "__main__":
    main()
