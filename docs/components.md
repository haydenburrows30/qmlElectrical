# Application Components Documentation

## Overview
This document describes the UI components used in the application, their responsibilities, and interactions.
The application follows a modular design pattern where components are broken down into reusable units.

## Core Components

### Pages
- **VoltageDrop**: Main page for voltage drop calculations
- **Settings**: Application settings
- **About**: Information about the application

### UI Components
- **WaveCard**: Container with title and optional info button
- **CableSelectionSettings**: Cable and installation parameter inputs
- **ResultsPanel**: Displays calculation results with actions
- **ComparisonTable**: Shows cable comparison data in table format
- **ChartPopup**: Displays voltage drop charts
- **MessagePopup**: Shows success/error messages
- **LoadingIndicator**: Shows loading state during operations
- **ExportFileDialog**: Handles file exports with various formats
- **ExportFormatMenu**: Menu for selecting export format
- **VoltageDropDetails**: Detailed calculation information popup
- **SavedResults**: Display and management of saved calculations

## Component Relationships
1. **VoltageDrop Page**
   - Contains CableSelectionSettings for input
   - Contains ResultsPanel for displaying results
   - Contains ComparisonTable for cable comparisons
   - Uses MessagePopup, LoadingIndicator for feedback
   - Uses ChartPopup for visualizations

2. **Popup Components**
   - ChartPopup: Shows voltage drop chart
   - VoltageDropDetails: Shows detailed calculation info

3. **Utility Components**
   - ExportFileDialog: File save operations
   - ExportFormatMenu: Format selection
   - MessagePopup: User feedback
   - LoadingIndicator: Operation status

## Signal Flow
1. User interacts with CableSelectionSettings
2. Changes trigger voltageDrop model updates
3. voltageDrop emits signals on calculation completion
4. UI components update based on new values
5. User can export/save via action buttons

## Component Details

### WaveCard
- **Properties**:
  - title: string
  - showInfo: bool
  - info: string
  - Layout properties

### CableSelectionSettings
- **Properties**:
  - Aliases to all input controls
- **Methods**:
  - resetAllValues(): Resets all fields to defaults
- **Signals**:
  - resetRequested(): Emitted when reset button is clicked
  - resetCompleted(): Emitted after reset is complete

### ResultsPanel
- **Properties**:
  - voltageDropValue: Current voltage drop
  - selectedVoltage: Selected voltage system
  - diversityFactor: Current diversity factor
  - combinedRatingInfo: Rating information
  - totalLoad: Total load in kVA
  - current: Current in amperes
  - darkMode: UI theme indicator
  - dropPercentage: Calculated percentage drop
- **Signals**:
  - saveResultsClicked(): Save button clicked
  - viewDetailsClicked(): Details button clicked
  - viewChartClicked(): Chart button clicked

### ComparisonTable
- **Properties**:
  - tableModel: Model with cable comparison data
  - headerLabels: Column headers
  - darkMode: UI theme indicator
- **Methods**:
  - getColumnWidth(column): Returns width for specific column
- **Signals**:
  - onExportRequest(format): Export request with format

### ChartPopup
- **Properties**:
  - percentage: Voltage drop percentage
  - cableSize: Selected cable size
  - currentValue: Current in amperes
  - chartComponent: Access to inner chart component
- **Methods**:
  - prepareChart(): Prepare chart before showing
  - grabImage(callback, scale): Grab chart image with scaling
- **Signals**:
  - saveRequested(scale): Chart save requested with scale

### MessagePopup
- **Properties**:
  - messageText: Text to display
  - isError: Error or success indicator
- **Methods**:
  - showSuccess(message): Show success message
  - showError(message): Show error message

### LoadingIndicator
- **Properties**:
  - Covers entire parent area when visible
- **Methods**:
  - show(): Show the indicator
  - hide(): Hide the indicator

### ExportFileDialog
- **Properties**:
  - exportType: Type of export (chart, CSV, PDF)
  - currentScale: Scale for image exports
  - handler: Callback handler
  - details: Additional export details
- **Methods**:
  - setup(title, filters, suffix, baseFilename, type, callback): Configure dialog

### ExportFormatMenu
- **Properties**:
  - onCsvExport: Handler for CSV export
  - onPdfExport: Handler for PDF export
- **Menu items**:
  - Export as CSV
  - Export as PDF

## Error Handling
1. **Input Validation**
   ```qml
   TextField {
       validator: DoubleValidator {
           bottom: 0.0
           top: 1000.0
           decimals: 2
       }
   }
   ```

2. **Error Messages**
   ```qml
   messagePopup.showError("Operation failed: " + errorMessage)
   ```

3. **Operation Feedback**
   ```qml
   loadingIndicator.show()
   // ...perform operation
   loadingIndicator.hide()
   ```

## Best Practices
1. **Component Encapsulation**: Components should have well-defined interfaces and responsibilities
2. **Signal-Based Communication**: Use signals and handlers for component communication
3. **Property Binding**: Use declarative bindings for reactive updates
4. **Theme Consistency**: Respect darkMode property for consistent theming
5. **Error Handling**: Use the MessagePopup for user feedback
