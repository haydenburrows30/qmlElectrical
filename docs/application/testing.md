How to Use These Scripts
First, run the scanner script to analyze your codebase and create a test plan:

Review the test plan in /home/hayden/Documents/qmltest/export_test_plan.md. This document will list all the export functionality found in your application and provide a structured approach for testing.

Use the testing tools:

For manual testing with a GUI: python manual_export_tester.py
For automated testing (requires further customization): python test_exports.py /path/to/main.qml
Or use the shell script to execute all steps in sequence:

Key Features of This Solution
Comprehensive Scanning: Automatically identifies all export functions in your codebase
Structured Test Plan: Creates a detailed test plan with specific test cases for each calculator
Manual Testing Tool: Provides a GUI to systematically test and document export functionality
Automation Framework: Includes a framework for automated testing that can be customized
Report Generation: Creates detailed test reports in Markdown format
Customization Points
You'll need to customize a few aspects of the automated testing script:

QML Object Access: The find_calculator method in test_exports.py will need modification to match your application's object hierarchy
Function Calling: The approach for calling export functions may need adjustment based on your application's architecture
File Path Handling: Output paths may need to be adjusted based on your application's file handling logic
These scripts provide a solid foundation for systematically testing all export functionality in your application. The manual testing tool in particular offers an immediate way to start testing without requiring deep integration with your application.