import os
import re

def migrate_with_opacity(directory):
    pattern = re.compile(r'\.withOpacity\((.*?)\)')
    replacement = r'.withValues(alpha: \1)'
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if '.withOpacity(' in content:
                    new_content = pattern.sub(replacement, content)
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Migrated: {path}")

if __name__ == "__main__":
    migrate_with_opacity('lib')
