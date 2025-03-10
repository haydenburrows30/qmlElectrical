# Application Architecture

## Overview
This application is designed for performing electrical calculations, particularly voltage drop calculations for cable sizing. It follows a modular architecture with clear separation between UI components and calculation logic.

## Core Components
1. **User Interface Layer**
   - Modular QML components
   - Responsive layouts
   - Theme support (light/dark)

2. **Calculation Logic**
   - Python-based calculation models
   - Data binding to UI through QML properties and signals

3. **Data Management**
   - Persistence of user preferences
   - Saving and loading results

## Directory Structure
```
/home/hayden/Documents/qmltest/
├── qml/
│   ├── main.qml               # Application entry point
│   ├── pages/                 # Application pages
│   │   ├── VoltageDrop.qml    # Main calculator page
│   │   └── ...
│   └── components/            # Reusable UI components
│       ├── WaveCard.qml       # Card container
│       ├── ResultsPanel.qml   # Results display
│       ├── ComparisonTable.qml # Table component
│       ├── ChartPopup.qml     # Chart popup
│       ├── MessagePopup.qml   # Message dialog
│       ├── LoadingIndicator.qml # Loading indicator
│       ├── ExportFileDialog.qml # File export dialog
│       ├── ExportFormatMenu.qml # Export format menu
│       └── ...
├── src/                       # Python source code
├── docs/                      # Documentation
└── resources/                 # Images and icons
```

## Key Features
- **Component-Based UI**: Modular components for better maintenance
- **Responsive Design**: Adapts to different screen sizes
- **Dark/Light Theme**: Customizable appearance
- **Export Options**: Multiple formats (PDF, CSV, PNG)
- **Visual Feedback**: Charts and tables for data visualization
- **Input Validation**: Prevents invalid calculations
- **Error Handling**: Informative error messages

## Data Flow
1. **User Input**
   - CableSelectionSettings captures user input
   - Input validation occurs at the UI level

2. **Calculation**
   - Validated data is passed to Python voltageDrop model
   - Calculations performed and results returned via properties/signals

3. **Display**
   - ResultsPanel shows calculation results
   - ComparisonTable shows cable size comparisons
   - Charts visualize the voltage drop

4. **Persistence**
   - ResultsManager handles saving calculations
   - Settings stored in application config

## Design Patterns
- **MVVM Architecture**: Separation of UI (View) from calculations (ViewModel)
- **Component Pattern**: Reusable, self-contained UI elements
- **Observer Pattern**: Signal/slot connections for updates
- **Factory Pattern**: Component creation standardization
- **Command Pattern**: For export operations

## Component Interaction
1. **Parent-Child Communication**
   - Direct property binding
   - Method calls on child objects
   - Signal connections

2. **Sibling Communication**
   - Through parent as mediator
   - Through shared model objects

3. **Model-View Communication**
   - Property bindings
   - Signal/handler connections
   - Direct method calls

## Technical Details

### UI Components
All UI components have been extracted into independent files for better maintainability:
- **MessagePopup**: Unified message display
- **LoadingIndicator**: Application-wide loading state
- **ExportFileDialog**: File export dialog with multiple format support
- **ExportFormatMenu**: Menu for selecting export format
- **ComparisonTable**: Table display with export capabilities
- **ResultsPanel**: Results display with action buttons
- **ChartPopup**: Chart display with save capabilities
- **CableSelectionSettings**: Input form with reset functionality

### Signal Flow
The application uses a signal-based approach for updating UI elements:
1. User input changes trigger model updates via direct method calls
2. Model emits signals when calculations are complete
3. UI components respond to signals to update their display
4. Action buttons emit signals handled by the parent page

### Export System
The export system uses a unified approach:
1. User requests export via UI
2. ExportFileDialog configures based on export type
3. Selected path passed to appropriate handler
4. Process feedback shown through LoadingIndicator and MessagePopup
