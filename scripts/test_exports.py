#!/usr/bin/env python3
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
import argparse
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


# Export function mapping based on static analysis
EXPORT_FUNCTIONS = {
    'other': {
        'ProtectionRequirementsSection': 'exportProtectionSettings',
        'WindTurbineSection': 'exportWindTurbineReport',
        'TransformerLineSection': 'exportReport',
        'ThreePhase': 'exports',
        'ThreePhaseCalculator': 'exports',
        'DiscriminationAnalyzer': 'exportButton',
        'DiscriminationAnalyzerCalculator': 'exportButton',
        'SolkorRf': 'exports',
        'SolkorRfCalculator': 'exports',
        'HarmonicsAnalyzer': 'exportDataToCSV',
        'HarmonicsAnalyzerCalculator': 'exportDataToCSV',
        'MotorStartingCalculator': 'exports',
        'RLC': 'exports',
        'RLCCalculator': 'exports',
        'VoltageDropOrion': 'exportType',
        'VoltageDropOrionCalculator': 'exportType',
        'ResultsPanel': 'saveResultsClicked',
        'ResultsPanelCalculator': 'saveResultsClicked',
        'NetworkCabinetCalculator': 'exportToPdf',
        'SwitchboardPanel': 'exportPDF',
        'SwitchboardPanelCalculator': 'exportPDF',
        'VoltageDropChart': 'exportChartData',
        'VoltageDropChartCalculator': 'exportChartData',
        'DiscriminationChart': 'export',
        'DiscriminationChartCalculator': 'export',
        'LogViewer': 'exportAllLogs',
        'LogViewerCalculator': 'exportAllLogs',
        'ExportFileDialog': 'setup',
        'ExportFileDialogCalculator': 'setup',
        'FileSaveHandler': 'exported_data',
        'FileSaveHandlerCalculator': 'exported_data',
        'LogExporter': 'exportLogs',
        'LogExporterCalculator': 'exportLogs',
        'TestCase': 'printed',
        'TestCaseCalculator': 'printed',
        'Config': 'export',
        'ConfigCalculator': 'export',
        'StyleImage': 'print',
        'StyleImageCalculator': 'print',
        'FocusFrame': 'print',
        'FocusFrameCalculator': 'print',
        'Component': 'export',
        'ComponentCalculator': 'export',
        'Helper': 'exports',
        'HelperCalculator': 'exports',
    },
    'png': {
        'WindTurbineSection': 'saveChartImage',
        'DiscriminationAnalyzer': 'saveChartImage',
        'DiscriminationAnalyzerCalculator': 'saveChartImage',
        'VR32CL7Calculator': 'generate_plot_with_url',
        'RLC': 'saveChart',
        'RLCCalculator': 'saveChart',
        'VoltageDropOrion': 'saveChart',
        'VoltageDropOrionCalculator': 'saveChart',
        'NetworkCabinetCalculator': 'captureImage',
        'NetworkCabinetDiagram': 'captureImage',
        'NetworkCabinetDiagramCalculator': 'captureImage',
        'VoltageDropChart': 'saveChart',
        'VoltageDropChartCalculator': 'saveChart',
        'DiscriminationChart': 'saveChartAsSVG',
        'DiscriminationChartCalculator': 'saveChartAsSVG',
    },
    'pdf': {
        'DiscriminationAnalyzer': 'exportResults',
        'DiscriminationAnalyzerCalculator': 'exportResults',
        'SolkorRf': 'saveToPdf',
        'SolkorRfCalculator': 'saveToPdf',
        'VR32CL7Calculator': 'generate_plot_with_url',
        'MotorStartingCalculator': 'exportResults',
        'VoltageDropDetails': 'saveToPdfRequested',
        'VoltageDropDetailsCalculator': 'saveToPdfRequested',
        'NetworkCabinetCalculator': 'exportToPdf',
    },
    'csv': {
        'HarmonicsAnalyzer': 'exportDataToCSV',
        'HarmonicsAnalyzerCalculator': 'exportDataToCSV',
        'SwitchboardPanel': 'exportCSV',
        'SwitchboardPanelCalculator': 'exportCSV',
    },
    'json': {
        'RealTime': 'saveConfiguration',
        'RealTimeCalculator': 'saveConfiguration',
        'NetworkCabinetCalculator': 'saveConfig',
        'SwitchboardPanel': 'saveToJSON',
        'SwitchboardPanelCalculator': 'saveToJSON',
    },
}

# Documented exporters from export_calculators.md
DOCUMENTED_EXPORTERS = {
    'pdf': ['TransformerLineSection', 'ProtectionRequirementsSection', 'WindTurbineSection', 'NetworkCabinetCalculator', 'DiscriminationAnalyzer', 'VoltageDropCalculator', 'SolkorRf', 'VoltageDropOrion'],
    'csv': ['MotorStartingCalculator', 'HarmonicsAnalyzer'],
    'json': ['CalculatorSettings'],
    'png': ['VR32CL7Calculator'],
}


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
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
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
    # Set up argument parser
    parser = argparse.ArgumentParser(description='Test QML export functionality')
    parser.add_argument('qml_file', help='Path to the main QML file')
    parser.add_argument('--calculator', '-c', help='Test a specific calculator')
    parser.add_argument('--type', '-t', choices=['pdf', 'csv', 'json', 'png'], 
                        help='Test a specific export type')
    parser.add_argument('--all', '-a', action='store_true', 
                        help='Test all documented calculators')
    parser.add_argument('--output', '-o', default='export_test_report.md',
                        help='Path for the output report file')
    
    args = parser.parse_args()
    
    print("QML Export Functionality Tester")
    print("-------------------------------")
    
    main_qml = args.qml_file
    print(f"Loading QML file: {main_qml}")
    
    tester = ExportTester()
    if not tester.initialize_app(main_qml):
        print("Failed to initialize the application")
        sys.exit(1)
    
    print("Application initialized successfully")
    
    print("\nConfigured exporters:")
    for export_type, calculators in DOCUMENTED_EXPORTERS.items():
        if not args.type or args.type == export_type:
            print(f"{export_type.upper()} Exporters: {calculators}")
    
    # Filter by export type if specified
    export_types = [args.type] if args.type else DOCUMENTED_EXPORTERS.keys()
    
    # Process each export type
    for export_type in export_types:
        if export_type not in DOCUMENTED_EXPORTERS:
            continue
            
        calculators = DOCUMENTED_EXPORTERS[export_type]
        
        # Filter by calculator if specified
        if args.calculator:
            calculators = [calc for calc in calculators if calc == args.calculator]
            if not calculators:
                print(f"Note: Calculator '{args.calculator}' not found for {export_type} export type")
        
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
    
    # Generate report
    if args.output.startswith('/'):
        report_path = args.output
    else:
        report_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), args.output)
    
    tester.generate_report(report_path)
    print(f"\nReport generated: {report_path}")

if __name__ == "__main__":
    main()
