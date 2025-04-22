# Export Testing - Usage Guide

This guide explains how to use the `test_exports.py` script to test the export functionality in your QML application.

## Basic Usage

The basic usage pattern is to run the script with the path to your main QML file:

```bash
cd /home/hayden/Documents/qmltest/scripts
python test_exports.py /path/to/your/main.qml
```

### Example with TestView.qml

If you have a test view that contains most of your calculators, you can use it like this:

```bash
# Testing with a test view that contains multiple calculators
python test_exports.py /home/hayden/Documents/qmltest/views/TestView.qml
```

### Example with Individual Calculators

You can also test individual calculator QML files:

```bash
# Testing a specific calculator
python scripts/test_exports.py /home/hayden/Documents/qmltest/qml/calculators/VoltageDropCalculator.qml
```

## Viewing Results

After running the tests, the script will:

1. Print the results to the console
2. Generate a Markdown report at `/home/hayden/Documents/qmltest/export_test_report.md`
3. Save any successfully exported files in the `/home/hayden/Documents/qmltest/exports` directory

## Common Issues and Solutions

### Calculator Not Found

If you see "Calculator 'XYZ' not found", it might be because:

- The calculator is not directly accessible from the main QML context
- The calculator is instantiated dynamically
- The calculator has a different name than expected

Solutions:
- Create a test view that exposes the calculator objects at the root level
- Add object names to your calculators to match the expected names:
  ```qml
  // Example QML modification
  VoltageDropCalculator {
      id: voltageDropCalculator
      objectName: "VoltageDropCalculator"
  }
  ```

### Export Function Not Accessible

If you see "Function 'exportToPdf' not directly accessible", it could be because:

- The function is defined but not accessible from the QML context
- The function has a different name
- The function requires different parameters

Solutions:
- Check the actual name of the export function in the calculator
- Add a simple wrapper function to your calculator that follows the expected signature:
  ```qml
  // In your calculator QML
  function exportToPdf(filePath) {
      // Call your actual export function with the correct parameters
      yourActualExportFunction(filePath, otherParams);
  }
  ```

## Creating a Test View for Export Testing

For easier testing, you can create a dedicated test view that exposes all calculators:

```qml
// TestExportView.qml - Example
import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 1024
    height: 768
    
    // Explicitly create and expose calculator instances
    property VoltageDropCalculator voltageDropCalculator: VoltageDropCalculator {
        objectName: "VoltageDropCalculator"
    }
    
    property NetworkCabinetCalculator networkCabinetCalculator: NetworkCabinetCalculator {
        objectName: "NetworkCabinetCalculator"
    }
    
    // Add more calculators as needed
    
    // Optional: A simple UI to manually trigger exports for debugging
    Column {
        spacing: 10
        padding: 20
        
        Button {
            text: "Test VoltageDropCalculator PDF Export"
            onClicked: voltageDropCalculator.exportToPdf("/home/hayden/Documents/qmltest/exports/test_voltage_drop.pdf")
        }
        
        // More test buttons as needed
    }
}
```

## Scripting Multiple Test Runs

You can create a shell script to run tests with different QML files:

```bash
#!/bin/bash
# test_all_exports.sh

BASE_DIR="/home/hayden/Documents/qmltest"
SCRIPT_DIR="$BASE_DIR/scripts"
EXPORTS_DIR="$BASE_DIR/exports"

# Create exports directory
mkdir -p "$EXPORTS_DIR"

# Run tests with different QML files
echo "Testing with main application"
python "$SCRIPT_DIR/test_exports.py" "$BASE_DIR/views/MainView.qml"

echo "Testing with test view"
python "$SCRIPT_DIR/test_exports.py" "$BASE_DIR/views/TestView.qml"

echo "Testing individual calculators"
python "$SCRIPT_DIR/test_exports.py" "$BASE_DIR/calculators/VoltageDropCalculator.qml"
python "$SCRIPT_DIR/test_exports.py" "$BASE_DIR/calculators/NetworkCabinetCalculator.qml"

echo "All tests completed"
```

Make it executable:
```bash
chmod +x test_all_exports.sh
```

Then run it:
```bash
./test_all_exports.sh
```
