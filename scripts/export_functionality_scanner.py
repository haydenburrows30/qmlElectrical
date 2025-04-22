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
        test_plan_path = os.path.join(self.base_dir, output_file)
        
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
        json_path = os.path.join(self.base_dir, output_file)
        
        data = {
            'documented_calculators': dict(self.calculator_mapping),
            'export_functions': dict(self.export_findings)
        }
        
        with open(json_path, 'w') as f:
            json.dump(data, f, indent=2)
            
        print(f"JSON data generated: {json_path}")

    def generate_test_script(self, output_file='test_exports.py'):
        """Generate a Python script for testing export functionality"""
        script_path = os.path.join(self.base_dir, 'scripts', output_file)
        
        os.makedirs(os.path.dirname(script_path), exist_ok=True)
        
        function_mapping = defaultdict(dict)
        for export_type, findings in self.export_findings.items():
            for entry in findings:
                calculator = entry['calculator']
                function_name = entry['function']
                
                if 'function ' in function_name:
                    function_name = function_name.split('function ')[1].split('(')[0].strip()
                elif '(' in function_name:
                    function_name = function_name.split('(')[0].strip()
                
                if calculator not in function_mapping[export_type] or len(function_name) < len(function_mapping[export_type][calculator]):
                    function_mapping[export_type][calculator] = function_name

        export_calculators = self._load_calculator_mapping()
        
        with open(script_path, 'w') as f:
            f.write('''#!/usr/bin/env python3
"""
Export Functionality Test Script

This script provides utilities for testing export functionality in the QML application.
It prioritizes PySide6 but falls back to PyQt5/PySide2 if needed.
"""

import os
import sys
import json
import subprocess
import time
from datetime import datetime

try:
    from PySide6.QtCore import QObject, QUrl, Qt, QMetaObject, Q_ARG
    from PySide6.QtWidgets import QApplication
    from PySide6.QtQml import QQmlApplicationEngine, QJSValue
    PYSIDE6 = True
    PYQT = False
    print("Using PySide6")
except ImportError:
    PYSIDE6 = False
    try:
        from PyQt5.QtCore import QObject, QUrl
        from PyQt5.QtWidgets import QApplication
        from PyQt5.QtQml import QQmlApplicationEngine
        PYQT = True
        print("Using PyQt5")
    except ImportError:
        try:
            from PySide2.QtCore import QObject, QUrl
            from PySide2.QtWidgets import QApplication
            from PySide2.QtQml import QQmlApplicationEngine
            PYQT = False
            print("Using PySide2")
        except ImportError:
            print("Error: This script requires PySide6, PyQt5, or PySide2 to be installed.")
            sys.exit(1)

''')

            f.write("\n# Export function mapping based on static analysis\n")
            f.write("EXPORT_FUNCTIONS = {\n")
            for export_type, calculators in function_mapping.items():
                f.write(f"    '{export_type}': {{\n")
                for calculator, function_name in calculators.items():
                    f.write(f"        '{calculator}': '{function_name}',\n")
                f.write("    },\n")
            f.write("}\n\n")
            
            f.write("# Documented exporters from export_calculators.md\n")
            f.write("DOCUMENTED_EXPORTERS = {\n")
            for export_type, calculators in export_calculators.items():
                f.write(f"    '{export_type}': {repr(calculators)},\n")
            f.write("}\n\n")
            
            f.write('''
class ExportTester(QObject):
    """Helper class for testing export functionality"""
    
    def __init__(self):
        super().__init__()
        self.engine = None
        self.root_object = None
        self.test_results = {}
    
    def initialize_app(self, qml_path):
        """Initialize the application with the main QML file"""
        app = QApplication.instance() or QApplication(sys.argv)
        
        self.engine = QQmlApplicationEngine()
        self.engine.load(QUrl.fromLocalFile(qml_path))
        
        if not self.engine.rootObjects():
            print(f"Error: Failed to load {qml_path}")
            return False
            
        self.root_object = self.engine.rootObjects()[0]
        return True
    
    def find_calculator(self, calculator_name):
        """Find a calculator object by name"""
        if not self.root_object:
            return None
            
        if hasattr(self.root_object, calculator_name):
            return getattr(self.root_object, calculator_name)
            
        if hasattr(self.root_object, "findChild"):
            calculator = self.root_object.findChild(QObject, calculator_name)
            if calculator:
                return calculator
                
        if PYSIDE6:
            try:
                contentStack = self.root_object.findChild(QObject, "contentStack")
                if contentStack:
                    currentItem = contentStack.property("currentItem")
                    if currentItem:
                        calc = currentItem.findChild(QObject, calculator_name)
                        if calc:
                            return calc
                        
                        if hasattr(currentItem, "calculator") or currentItem.property("calculator"):
                            return currentItem.property("calculator")
            except Exception as e:
                print(f"Error trying to find calculator via traversal: {e}")
        
        try:
            if hasattr(self.engine, "rootObjects"):
                js_result = None
                
                if PYSIDE6:
                    context = self.engine.rootContext()
                    if context:
                        js_result = context.engine().evaluate(f"findCalculator('{calculator_name}')")
                        if isinstance(js_result, QJSValue) and not js_result.isNull() and not js_result.isUndefined():
                            return js_result.toQObject()
                
                print(f"JavaScript evaluation attempt completed, result: {js_result is not None}")
        except Exception as e:
            print(f"Error in JavaScript evaluation: {e}")
                
        print(f"Could not find calculator: {calculator_name}")
        return None
    
    def test_export(self, calculator_name, export_function, export_format="pdf"):
        """Test a specific export function for a calculator"""
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        test_id = f"{calculator_name}_{timestamp}"
        
        calculator = self.find_calculator(calculator_name)
        if not calculator:
            result = {
                "status": "FAIL",
                "message": f"Calculator '{calculator_name}' not found",
                "file_path": None
            }
            self.test_results[test_id] = result
            return result
        
        output_path = os.path.expanduser(f"~/Documents/qmltest/exports/{calculator_name}_{timestamp}.{export_format}")
        
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        try:
            if hasattr(calculator, export_function):
                print(f"Calling {export_function} directly on calculator object")
                getattr(calculator, export_function)(output_path)
            elif PYSIDE6 and hasattr(calculator, "metaObject"):
                print(f"Trying to invoke {export_function} using QMetaObject")
                QMetaObject.invokeMethod(
                    calculator, 
                    export_function,
                    Qt.ConnectionType.DirectConnection,
                    Q_ARG(str, output_path)
                )
            else:
                print(f"Warning: Function {export_function} not directly accessible")
                print(f"Available properties: {[p for p in dir(calculator) if not p.startswith('_')]}")
                
                if hasattr(calculator, "property") and callable(calculator.property):
                    func = calculator.property(export_function)
                    if callable(func):
                        print(f"Found {export_function} as a property, attempting to call")
                        func(output_path)
                    else:
                        print(f"Property {export_function} exists but is not callable")
            
            time.sleep(2)
            
            if os.path.exists(output_path):
                result = {
                    "status": "PASS",
                    "message": f"Export file created successfully",
                    "file_path": output_path
                }
            else:
                result = {
                    "status": "FAIL",
                    "message": f"Export file not created at expected path: {output_path}",
                    "file_path": None
                }
            
        except Exception as e:
            result = {
                "status": "ERROR",
                "message": f"Exception during export: {str(e)}",
                "file_path": None
            }
        
        self.test_results[test_id] = result
        return result
    
    def validate_export(self, file_path, export_format):
        """Basic validation of exported file"""
        if not file_path or not os.path.exists(file_path):
            return {"status": "FAIL", "message": "File does not exist"}
            
        try:
            if export_format.lower() == "pdf":
                if os.path.getsize(file_path) > 100:
                    return {"status": "PASS", "message": "PDF file exists and has content"}
                else:
                    return {"status": "WARN", "message": "PDF file exists but may be empty or corrupted"}
                    
            elif export_format.lower() == "csv":
                with open(file_path, 'r') as f:
                    lines = f.readlines()
                    
                if len(lines) > 1:
                    return {"status": "PASS", "message": f"CSV file has {len(lines)} lines"}
                else:
                    return {"status": "WARN", "message": "CSV file has less than 2 lines"}
                    
            elif export_format.lower() == "json":
                with open(file_path, 'r') as f:
                    data = json.load(f)
                    
                return {"status": "PASS", "message": f"JSON file is valid with {len(data)} top-level elements"}
                
            elif export_format.lower() in ["png", "jpg", "jpeg"]:
                if os.path.getsize(file_path) > 1000:
                    return {"status": "PASS", "message": "Image file exists and has content"}
                else:
                    return {"status": "WARN", "message": "Image file exists but may be empty or corrupted"}
                    
            else:
                return {"status": "INFO", "message": f"No specific validation for {export_format} format"}
                
        except Exception as e:
            return {"status": "ERROR", "message": f"Error validating file: {str(e)}"}
    
    def generate_report(self, output_file="export_test_report.md"):
        """Generate a markdown report of test results"""
        with open(output_file, 'w') as f:
            f.write("# Export Functionality Test Report\n\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')\n\n")
            
            f.write("## Test Results\n\n")
            
            f.write("| Calculator | Export Function | Status | Message | Output File |\n")
            f.write("|------------|----------------|--------|---------|-------------|\n")
            
            for test_id, result in self.test_results.items():
                calculator_name = test_id.split('_')[0]
                status_color = {
                    "PASS": "green",
                    "FAIL": "red",
                    "ERROR": "red",
                    "WARN": "orange",
                    "INFO": "blue"
                }.get(result["status"], "black")
                
                file_path = result.get("file_path", "")
                if file_path:
                    file_path = os.path.basename(file_path)
                
                f.write(f"| {calculator_name} | {test_id} | ")
                f.write(f"<span style='color: {status_color}'>{result['status']}</span> | ")
                f.write(f"{result['message']} | {file_path} |\n")
            
            f.write("\n## Summary\n\n")
            
            total = len(self.test_results)
            passed = sum(1 for r in self.test_results.values() if r["status"] == "PASS")
            failed = sum(1 for r in self.test_results.values() if r["status"] in ["FAIL", "ERROR"])
            warnings = sum(1 for r in self.test_results.values() if r["status"] == "WARN")
            
            f.write(f"- Total tests: {total}\n")
            if total > 0:
                f.write(f"- Passed: {passed} ({passed/total*100:.1f}%)\n")
                f.write(f"- Failed: {failed} ({failed/total*100:.1f}%)\n")
                f.write(f"- Warnings: {warnings} ({warnings/total*100:.1f}%)\n")
            else:
                f.write("- No tests executed\n")

def main():
    """Main function to demonstrate the export testing"""
    print("QML Export Functionality Tester")
    print("-------------------------------")
    
    if len(sys.argv) < 2:
        print("Usage: python test_exports.py <path_to_main_qml>")
        sys.exit(1)
    
    main_qml = sys.argv[1]
    print(f"Loading QML file: {main_qml}")
    
    tester = ExportTester()
    if not tester.initialize_app(main_qml):
        print("Failed to initialize the application")
        sys.exit(1)
    
    print("Application initialized successfully")
    
    print("\nConfigured exporters:")
    for export_type, calculators in DOCUMENTED_EXPORTERS.items():
        print(f"{export_type.upper()} Exporters: {calculators}")
    
    for export_type, calculators in DOCUMENTED_EXPORTERS.items():
        for calculator in calculators:
            if not calculator or calculator == "":
                continue
                
            export_function = None
            
            if calculator in EXPORT_FUNCTIONS.get(export_type, {}):
                export_function = EXPORT_FUNCTIONS[export_type][calculator]
            
            if not export_function:
                if export_type == 'pdf':
                    export_function = 'exportToPdf'
                elif export_type == 'csv':
                    export_function = 'exportDataToCSV'
                elif export_type == 'json':
                    export_function = 'saveToJSON'
                elif export_type == 'png':
                    if calculator == 'VR32CL7Calculator':
                        export_function = 'generate_plot_with_url'
                    else:
                        export_function = 'saveChart'
            
            print(f"\nTesting {export_type.upper()} export for {calculator} using {export_function}...")
            result = tester.test_export(calculator, export_function, export_type)
            print(f"Result: {result['status']} - {result['message']}")
    
    report_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'export_test_report.md')
    tester.generate_report(report_path)
    print(f"\nReport generated: {report_path}")

if __name__ == "__main__":
    main()
''')
        
        os.chmod(script_path, 0o755)
        print(f"Test script generated: {script_path}")


if __name__ == "__main__":
    scanner = ExportScanner()
    scanner.find_export_functions()
    scanner.generate_test_plan()
    scanner.generate_json_data()
    scanner.generate_test_script()
    
    print("Scan complete!")
    print(f"Found export functions: {sum(len(findings) for findings in scanner.export_findings.values())}")
