# Calculators with Export Functions

This document lists all calculators that have export functionality.

## PDF
1. TransformerLineSection
2. ProtectionRequirementsSection
3. WindTurbineSection
4. NetworkCabinetCalculator
5. DiscriminationAnalyzer
6. VoltageDropCalculator
7. SolkorRf
8. VoltageDropOrion

## CSV
1. MotorStartingCalculator
2. HarmonicsAnalyzer

## JSON
1. CalculatorSettings

## PNG
1. VR32CL7Calculator


# Export Testing Documentation

This document provides instructions for testing the export functionality in your QML application.

## How to Use These Scripts

### Step 1: Run the Scanner

First, run the scanner script to analyze your codebase and create a test plan:

```bash
python scan_exports.py /path/to/your/project
```

### Step 2: Review Test Plan

Review the test plan in `/home/hayden/Documents/qmltest/export_test_plan.md`. This document will list all the export functionality found in your application and provide a structured approach for testing.

### Step 3: Use the Testing Tools

Choose the appropriate testing method:

* For manual testing with a GUI: 
  ```bash
  python manual_export_tester.py
  ```