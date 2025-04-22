#!/usr/bin/env python3
"""
Export Functionality Scanner

This script scans QML files for export-related functions and creates a test plan document.
"""

import os
import re
import json
from collections import defaultdict

class ExportScanner:
    def __init__(self, base_dir='/home/hayden/Documents/qmltest'):
        self.base_dir = base_dir
        self.export_functions = {
            'pdf': [
                r'exportToPdf', r'exportPdf', r'saveToPdf', r'exportResults',
                r'exportDataToFolder', r'pdfSaved', r'generate_plot_with_url'
            ],
            'csv': [
                r'exportDataToCSV', r'exportToCSV', r'exportCSV', r'saveToCSV'
            ],
            'json': [
                r'saveToJSON', r'loadFromJSON', r'saveConfig', r'loadConfig'
            ],
            'png': [
                r'saveChart', r'captureImage', r'exportChartImage', r'generate_plot',
                r'exportToPng', r'saveToPng'
            ],
            'other': [
                r'export', r'save.*Result', r'print'
            ]
        }
        self.file_extensions = ['.qml']
        self.export_findings = defaultdict(list)
        self.calculator_mapping = self._load_calculator_mapping()

    def _load_calculator_mapping(self):
        """Load or create calculator mapping from the export_calculators.md file"""
        mapping = defaultdict(list)
        md_path = os.path.join(self.base_dir, 'docs/application/export_calculators.md')
        
        if os.path.exists(md_path):
            current_format = None
            with open(md_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('## '):
                        current_format = line[3:].lower().strip()
                    elif line and current_format:
                        if re.match(r'^\d+\.', line):
                            calculator = line.split('.', 1)[1].strip()
                            if calculator:
                                mapping[current_format].append(calculator)
                        elif not line.startswith('#') and line:
                            mapping[current_format].append(line)
        
        return mapping

    def find_export_functions(self):
        """Recursively scan all QML files for export functions"""
        for root, _, files in os.walk(self.base_dir):
            for file in files:
                if any(file.endswith(ext) for ext in self.file_extensions):
                    self._scan_file(os.path.join(root, file))
                    
    def _scan_file(self, file_path):
        """Scan a single file for export functions"""
        rel_path = os.path.relpath(file_path, self.base_dir)
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                
                calculator_name = os.path.basename(file_path).replace('.qml', '')
                
                if calculator_name.endswith('Section'):
                    calculator_variants = [calculator_name]
                elif calculator_name.endswith('Calculator'):
                    calculator_variants = [calculator_name]
                else:
                    calculator_variants = [calculator_name, f"{calculator_name}Calculator"]
                
                for export_type, patterns in self.export_functions.items():
                    for pattern in patterns:
                        if re.search(pattern, content):
                            matches = re.findall(r'(function\s+' + pattern + r'[^{]*{[^}]*})', content, re.DOTALL)
                            if not matches:
                                matches = re.findall(r'(' + pattern + r'[^;(]*\([^)]*\))', content)
                            if not matches:
                                matches = re.findall(r'(signal\s+' + pattern + r'[^;(]*)', content)
                            
                            if matches:
                                for match in matches:
                                    for calculator in calculator_variants:
                                        self.export_findings[export_type].append({
                                            'file': rel_path,
                                            'calculator': calculator,
                                            'function': match.split('{')[0].strip() if '{' in match else match.strip(),
                                            'content': match
                                        })
                            else:
                                for calculator in calculator_variants:
                                    self.export_findings[export_type].append({
                                        'file': rel_path,
                                        'calculator': calculator,
                                        'function': pattern,
                                        'content': f"Pattern '{pattern}' found but function definition not extracted"
                                    })
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    def generate_test_plan(self, output_file='export_test_plan.md'):
        """Generate a markdown test plan file"""
        test_plan_path = os.path.join(self.base_dir, 'scripts','tests',output_file)
        
        with open(test_plan_path, 'w') as f:
            f.write("# Export Functionality Test Plan\n\n")
            f.write("This document outlines a plan for testing export functionality in the application.\n\n")
            
            f.write("## Export Types Documented in MD\n\n")
            for export_type, calculators in self.calculator_mapping.items():
                f.write(f"### {export_type.upper()} Export\n\n")
                if calculators:
                    for i, calculator in enumerate(calculators, 1):
                        f.write(f"{i}. {calculator}\n")
                else:
                    f.write("No calculators documented for this export type.\n")
                f.write("\n")
            
            f.write("## Export Functions Found in Code\n\n")
            for export_type, findings in self.export_findings.items():
                f.write(f"### {export_type.upper()} Export Functions\n\n")
                
                if findings:
                    f.write("| Calculator | File | Function |\n")
                    f.write("|------------|------|----------|\n")
                    
                    for entry in findings:
                        function_name = entry['function'].replace('\n', ' ').strip()
                        f.write(f"| {entry['calculator']} | {entry['file']} | `{function_name}` |\n")
                else:
                    f.write("No functions found for this export type.\n")
                f.write("\n")
            
            f.write("## Test Procedures\n\n")
            
            for export_type in set(list(self.calculator_mapping.keys()) + list(self.export_findings.keys())):
                f.write(f"### Testing {export_type.upper()} Export\n\n")
                
                f.write("#### Manual Test Steps:\n\n")
                f.write("1. Launch the application\n")
                f.write("2. Navigate to each calculator with export functionality\n")
                f.write("3. Configure inputs with valid test data\n")
                f.write("4. Trigger the export function\n")
                f.write("5. Verify the exported file is created and contains the expected data\n")
                f.write("6. Check file formatting and content validity\n\n")
                
                f.write("#### Test Cases:\n\n")
                
                calculators_from_code = set([entry['calculator'] for entry in self.export_findings.get(export_type, [])])
                calculators_from_md = set(self.calculator_mapping.get(export_type, []))
                
                all_calculators = calculators_from_code.union(calculators_from_md)
                
                if all_calculators:
                    for i, calculator in enumerate(all_calculators, 1):
                        f.write(f"**{i}. {calculator}**\n\n")
                        f.write("- [ ] Export completes without errors\n")
                        f.write("- [ ] File is created in the expected location\n")
                        f.write("- [ ] File content is correct and well-formatted\n")
                        f.write("- [ ] Error handling works appropriately for invalid inputs\n\n")
                else:
                    f.write("No specific calculators identified for this export type.\n\n")
            
            f.write("## Automation Opportunities\n\n")
            f.write("The following export functions could be candidates for automated testing:\n\n")
            
            export_patterns = defaultdict(int)
            for findings in self.export_findings.values():
                for entry in findings:
                    function_name = entry['function']
                    if isinstance(function_name, str) and '(' in function_name:
                        function_name = function_name.split('(')[0].strip()
                    export_patterns[function_name] += 1
            
            common_patterns = sorted(export_patterns.items(), key=lambda x: x[1], reverse=True)
            
            if common_patterns:
                f.write("| Function Pattern | Occurrence Count |\n")
                f.write("|-----------------|------------------|\n")
                
                for pattern, count in common_patterns:
                    if count > 1:
                        f.write(f"| `{pattern}` | {count} |\n")
            else:
                f.write("No common export patterns identified for automation.\n")
                
            f.write("\n")
            f.write("## Notes on Testing Approach\n\n")
            f.write("1. For PDF exports, validate the content using a PDF reader or parser\n")
            f.write("2. For CSV exports, validate structure and data integrity\n")
            f.write("3. For JSON exports, validate against expected schema\n")
            f.write("4. For image exports, validate dimensions and basic image properties\n")
            
        print(f"Test plan generated: {test_plan_path}")
        
    def generate_json_data(self, output_file='export_functions.json'):
        """Generate JSON data with all findings"""
        json_path = os.path.join(self.base_dir, 'scripts','tests',output_file)
        
        data = {
            'documented_calculators': dict(self.calculator_mapping),
            'export_functions': dict(self.export_findings)
        }
        
        with open(json_path, 'w') as f:
            json.dump(data, f, indent=2)
            
        print(f"JSON data generated: {json_path}")


if __name__ == "__main__":
    scanner = ExportScanner()
    scanner.find_export_functions()
    scanner.generate_test_plan()
    scanner.generate_json_data()
    
    print("Scan complete!")
    print(f"Found export functions: {sum(len(findings) for findings in scanner.export_findings.values())}")
