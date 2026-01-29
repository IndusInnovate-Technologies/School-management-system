import re
import os

file_path = r'c:\Users\Admin\Desktop\testing_main\backend\management_admin\models.py'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
i = 0
replaced_count = 0

while i < len(lines):
    line = lines[i]
    
    # Target line: clean_class_name = self.applying_class.replace("Class ", "").strip()
    if 'clean_class_name = self.applying_class.replace("Class ", "").strip()' in line:
        # Get indentation
        indent = line[:line.find('clean_class_name')]
        
        # We found the block. Let's look ahead for the target_class assignment
        # It should be within the next 10 lines
        found_target_class = False
        for j in range(i + 1, min(i + 10, len(lines))):
            if 'target_class = Class.objects.filter(' in lines[j]:
                # Found the start of the filter block
                # We want to replace everything from the original "Clean the class name" comment
                # which is usually the line before
                start_index = i - 1 if i > 0 and '# Clean the class name' in lines[i-1] else i
                
                # Now find the end of the first() call
                end_index = j
                while end_index < len(lines) and ').first()' not in lines[end_index]:
                    end_index += 1
                
                if end_index < len(lines):
                    # We have the range [start_index, end_index]
                    new_block = [
                        f"{indent}# Robust class name matching\n",
                        f"{indent}clean_class_name = self.applying_class.replace(\"Class \", \"\").replace(\"Grade \", \"\").strip()\n",
                        f"{indent}\n",
                        f"{indent}# Look for the class in the teacher app for the current academic year\n",
                        f"{indent}from django.db.models import Q\n",
                        f"{indent}target_class = Class.objects.filter(\n",
                        f"{indent}    Q(name=self.applying_class) | Q(name=clean_class_name) | Q(name=f\"Class {{clean_class_name}}\"),\n",
                        f"{indent}    section=self.section,\n",
                        f"{indent}    academic_year='2025-2026'\n",
                        f"{indent}).first()\n"
                    ]
                    
                    # Skip the old lines and add the new block
                    i = end_index + 1
                    new_lines.extend(new_block)
                    replaced_count += 1
                    found_target_class = True
                    break
        
        if not found_target_class:
            new_lines.append(line)
            i += 1
    else:
        new_lines.append(line)
        i += 1

if replaced_count > 0:
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print(f"Successfully replaced {replaced_count} blocks.")
else:
    print("Could not find blocks to replace.")
