#!/bin/bash
# Run export functionality tests script

# Set the base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$BASE_DIR/scripts"
EXPORTS_DIR="$BASE_DIR/exports"

# Output colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create exports directory if it doesn't exist
mkdir -p "$EXPORTS_DIR"

# Print header
echo -e "${YELLOW}=================================================${NC}"
echo -e "${YELLOW}      QML Export Functionality Test Script       ${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo

# Step 1: Scan codebase for export functions
echo -e "${GREEN}Step 1: Scanning codebase for export functions...${NC}"
if python3 "$SCRIPTS_DIR/export_functionality_scanner.py"; then
    echo -e "${GREEN}✓ Scan completed successfully${NC}"
else
    echo -e "${RED}✗ Scan failed${NC}"
    exit 1
fi
echo

# Step 2: Explain testing approaches
echo -e "${YELLOW}Export Testing Options:${NC}"
echo "1. Manual testing with GUI tool"
echo "2. Automated testing (requires application integration)"
echo
read -p "Choose testing approach (1 or 2): " approach

case $approach in
    1)
        # Manual testing with GUI
        echo -e "\n${GREEN}Starting manual export testing tool...${NC}"
        python3 "$SCRIPTS_DIR/manual_export_tester.py"
        ;;
    2)
        # Automated testing
        echo -e "\n${YELLOW}Automated testing requires application integration.${NC}"
        echo "Please provide the path to your main QML file:"
        read -p "QML path: " qml_path
        
        if [ -f "$qml_path" ]; then
            echo -e "\n${GREEN}Starting automated tests with $qml_path...${NC}"
            python3 "$SCRIPTS_DIR/test_exports.py" "$qml_path"
        else
            echo -e "${RED}Error: File not found - $qml_path${NC}"
            exit 1
        fi
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting.${NC}"
        exit 1
        ;;
esac

echo
echo -e "${YELLOW}=================================================${NC}"
echo -e "${YELLOW}        Export Testing Session Complete          ${NC}"
echo -e "${YELLOW}=================================================${NC}"
echo
echo "Reports can be found in the project directory."
echo

# Check for test report
if [ -f "$BASE_DIR/export_test_report.md" ]; then
    echo -e "${GREEN}Test report generated: $BASE_DIR/export_test_report.md${NC}"
fi

# Check for test plan
if [ -f "$BASE_DIR/export_test_plan.md" ]; then
    echo -e "${GREEN}Test plan generated: $BASE_DIR/export_test_plan.md${NC}"
fi

exit 0

#!/bin/bash
# Simple script to run export tests

# Set default paths
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$BASE_DIR/scripts"
EXPORTS_DIR="$BASE_DIR/exports"
DEFAULT_QML="$BASE_DIR/views/MainView.qml"

# Help function
function show_help {
    echo "QML Export Test Runner"
    echo "====================="
    echo "Usage: $0 [options] [QML_FILE]"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message"
    echo "  -a, --all          Test all documented calculators"
    echo "  -c, --calculator NAME  Test a specific calculator"
    echo "  -t, --type TYPE    Test a specific export type (pdf, csv, json, png)"
    echo ""
    echo "Examples:"
    echo "  $0                 Run with default QML file"
    echo "  $0 path/to/main.qml     Run with specified QML file"
    echo "  $0 -c VoltageDropCalculator   Test VoltageDropCalculator"
    echo "  $0 -t pdf          Test all PDF exporters"
    echo ""
}

# Check for help
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Create exports directory
mkdir -p "$EXPORTS_DIR"

# Process arguments
QML_FILE="$DEFAULT_QML"
CALCULATOR=""
EXPORT_TYPE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            ALL=true
            shift
            ;;
        -c|--calculator)
            CALCULATOR="$2"
            shift 2
            ;;
        -t|--type)
            EXPORT_TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            # If argument doesn't match any option, assume it's a QML file
            if [[ -f "$1" ]]; then
                QML_FILE="$1"
            else
                echo "Error: File not found - $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# Prepare additional arguments for the Python script
EXTRA_ARGS=""
if [[ -n "$CALCULATOR" ]]; then
    EXTRA_ARGS="$EXTRA_ARGS --calculator $CALCULATOR"
fi
if [[ -n "$EXPORT_TYPE" ]]; then
    EXTRA_ARGS="$EXTRA_ARGS --type $EXPORT_TYPE"
fi
if [[ "$ALL" == true ]]; then
    EXTRA_ARGS="$EXTRA_ARGS --all"
fi

# Run the test script
echo "Running export tests with: $QML_FILE"
echo "Additional arguments: $EXTRA_ARGS"
python3 "$SCRIPT_DIR/test_exports.py" "$QML_FILE" $EXTRA_ARGS

# Check if test was successful
if [ $? -eq 0 ]; then
    echo -e "\nTests completed successfully!"
    echo "Check export_test_report.md for detailed results"
else
    echo -e "\nTests failed. Check console output for errors."
fi
