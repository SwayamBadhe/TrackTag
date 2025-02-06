import os
import re

def summarize_dart_code(directory):
    summary = []
    
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                file_path = os.path.join(root, file)
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Extract class names
                classes = re.findall(r'class (\w+)', content)
                if classes:
                    summary.append(f"\n📌 File: {file_path}\nClasses: {', '.join(classes)}")

                # Extract function/method definitions
                functions = re.findall(r'(\w+)\s+(\w+)\(.*?\)', content)
                if functions:
                    summary.append(f"Functions: {', '.join(f[1] for f in functions)}")
    
    # Save summary
    output_file = "flutter_code_summary.txt"
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(summary))
    
    print(f"✅ Code summary saved to {output_file}")

# Run script in current directory
summarize_dart_code(".")
