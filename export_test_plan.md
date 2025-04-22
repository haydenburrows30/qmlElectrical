# Export Functionality Test Plan

This document outlines a plan for testing export functionality in the application.

## Export Types Documented in MD

### PDF Export

1. TransformerLineSection
2. ProtectionRequirementsSection
3. WindTurbineSection
4. NetworkCabinetCalculator
5. DiscriminationAnalyzer
6. VoltageDropCalculator
7. SolkorRf
8. VoltageDropOrion

### CSV Export

1. MotorStartingCalculator
2. HarmonicsAnalyzer

### JSON Export

1. CalculatorSettings

### PNG Export

1. VR32CL7Calculator

## Export Functions Found in Code

### OTHER Export Functions

| Calculator | File | Function |
|------------|------|----------|
| ProtectionRequirementsSection | qml/calculators/grid_wind/ProtectionRequirementsSection.qml | `function exportProtectionSettings(filePath)` |
| WindTurbineSection | qml/calculators/grid_wind/WindTurbineSection.qml | `exportWindTurbineReport(null, tempImagePath)` |
| WindTurbineSection | qml/calculators/grid_wind/WindTurbineSection.qml | `exportWindTurbineReport(null, "")` |
| TransformerLineSection | qml/calculators/grid_wind/TransformerLineSection.qml | `function exportReport()` |
| ThreePhase | qml/calculators/three_phase/ThreePhase.qml | `exports" import "../../components/charts" import "../three_phase/"  import Sine 1.0  Page` |
| ThreePhaseCalculator | qml/calculators/three_phase/ThreePhase.qml | `exports" import "../../components/charts" import "../three_phase/"  import Sine 1.0  Page` |
| DiscriminationAnalyzer | qml/calculators/protection/DiscriminationAnalyzer.qml | `exportButton                                     text: "Export Results"                                     Layout.columnSpan: 2                                      ToolTip.text: "Export results to PDF"                                     ToolTip.visible: hovered                                     ToolTip.delay: 500                                                                          visible: calculator.relayCount >= 2                                     icon.source: "../../../icons/rounded/download.svg"                                                                          onClicked:` |
| DiscriminationAnalyzerCalculator | qml/calculators/protection/DiscriminationAnalyzer.qml | `exportButton                                     text: "Export Results"                                     Layout.columnSpan: 2                                      ToolTip.text: "Export results to PDF"                                     ToolTip.visible: hovered                                     ToolTip.delay: 500                                                                          visible: calculator.relayCount >= 2                                     icon.source: "../../../icons/rounded/download.svg"                                                                          onClicked:` |
| SolkorRf | qml/calculators/protection/SolkorRf.qml | `exports"  import SolkorRfCalculator 1.0  Item` |
| SolkorRfCalculator | qml/calculators/protection/SolkorRf.qml | `exports"  import SolkorRfCalculator 1.0  Item` |
| SolkorRf | qml/calculators/protection/SolkorRf.qml | `exportToPdf with null parameter         // to let FileSaver handle the file dialog         calculator.exportToPdf(null)` |
| SolkorRfCalculator | qml/calculators/protection/SolkorRf.qml | `exportToPdf with null parameter         // to let FileSaver handle the file dialog         calculator.exportToPdf(null)` |
| HarmonicsAnalyzer | qml/calculators/theory/HarmonicsAnalyzer.qml | `exports" import "../../components/charts" import "../../components/displays" import "../../components/menus"  import HarmonicAnalysis 1.0 import SeriesHelper 1.0  Item` |
| HarmonicsAnalyzerCalculator | qml/calculators/theory/HarmonicsAnalyzer.qml | `exports" import "../../components/charts" import "../../components/displays" import "../../components/menus"  import HarmonicAnalysis 1.0 import SeriesHelper 1.0  Item` |
| HarmonicsAnalyzer | qml/calculators/theory/HarmonicsAnalyzer.qml | `export the harmonic data to a CSV file for further analysis."     }      ColumnLayout` |
| HarmonicsAnalyzerCalculator | qml/calculators/theory/HarmonicsAnalyzer.qml | `export the harmonic data to a CSV file for further analysis."     }      ColumnLayout` |
| HarmonicsAnalyzer | qml/calculators/theory/HarmonicsAnalyzer.qml | `exportDataToCSV(null)` |
| HarmonicsAnalyzerCalculator | qml/calculators/theory/HarmonicsAnalyzer.qml | `exportDataToCSV(null)` |
| HarmonicsAnalyzer | qml/calculators/theory/HarmonicsAnalyzer.qml | `exportMouseArea.containsMouse                         ToolTip.delay: 500                                                  MouseArea` |
| HarmonicsAnalyzerCalculator | qml/calculators/theory/HarmonicsAnalyzer.qml | `exportMouseArea.containsMouse                         ToolTip.delay: 500                                                  MouseArea` |
| MotorStartingCalculator | qml/calculators/theory/MotorStartingCalculator.qml | `exports" import "../../components/menus"  import MotorStarting 1.0  Item` |
| MotorStartingCalculator | qml/calculators/theory/MotorStartingCalculator.qml | `exportButton                         icon.source: "../../../icons/rounded/download.svg"                         enabled: hasValidInputs && calculator.startingCurrent > 0                         onClicked: calculator.exportResults(null)` |
| RLC | qml/calculators/theory/RLC.qml | `exports" import "../../components/charts"  import RLC 1.0  Page` |
| RLCCalculator | qml/calculators/theory/RLC.qml | `exports" import "../../components/charts"  import RLC 1.0  Page` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exports" import "../../components/charts" import "../../components/monitors" import "../voltage_drop/"  import VDrop 1.0  Page` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exports" import "../../components/charts" import "../../components/monitors" import "../voltage_drop/"  import VDrop 1.0  Page` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableData(null)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableData(null)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableToPDF(null)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableToPDF(null)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFormatMenu.popup()` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFormatMenu.popup()` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFileDialog.setup("Save Chart", "PNG files (*.png)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFileDialog.setup("Save Chart", "PNG files (*.png)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFileDialog.chartExport)             exportFileDialog.currentScale = scale             exportFileDialog.open()` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFileDialog.chartExport)             exportFileDialog.currentScale = scale             exportFileDialog.open()` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFileDialog          function handleExport(selectedFile)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFileDialog          function handleExport(selectedFile)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportType)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportType)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableData(selectedFile)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableData(selectedFile)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableToPDF(selectedFile)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableToPDF(selectedFile)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportDetailsToPDF(selectedFile, details)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportDetailsToPDF(selectedFile, details)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFormatMenu                  Component.onCompleted:` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportFormatMenu                  Component.onCompleted:` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableData(null)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableData(null)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableToPDF(null)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportTableToPDF(null)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportDetailsToPDF(null,` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `exportDetailsToPDF(null,` |
| ResultsPanel | qml/calculators/voltage_drop/ResultsPanel.qml | `saveResultsClicked()` |
| ResultsPanelCalculator | qml/calculators/voltage_drop/ResultsPanel.qml | `saveResultsClicked()` |
| ResultsPanel | qml/calculators/voltage_drop/ResultsPanel.qml | `saveResultsClicked()` |
| ResultsPanelCalculator | qml/calculators/voltage_drop/ResultsPanel.qml | `saveResultsClicked()` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `exportToPdf(folderDialog.folder, diagramImage)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `exportButton                         text: "Export PDF"                         icon.source: "../../../icons/rounded/download.svg"                         ToolTip.text: "Export configuration to PDF"                         ToolTip.visible: hovered                         ToolTip.delay: 500                         onClicked:` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `exportToPdf(null, diagramImage)` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `export of the full switchboard schedule.<br><br>" +                    "Double-click any row to edit circuit details, or use the + button to add a new circuit."         widthFactor: 0.5         heightFactor: 0.5     }      ColumnLayout` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `export of the full switchboard schedule.<br><br>" +                    "Double-click any row to edit circuit details, or use the + button to add a new circuit."         widthFactor: 0.5         heightFactor: 0.5     }      ColumnLayout` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `exportMenu.open()` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `exportMenu.open()` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `exportMenu                             MenuItem` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `exportMenu                             MenuItem` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `exportPDF()` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `exportPDF()` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `printSchedule()` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `printSchedule()` |
| VoltageDropChart | qml/components/charts/VoltageDropChart.qml | `function exportChartData(format)` |
| VoltageDropChartCalculator | qml/components/charts/VoltageDropChart.qml | `function exportChartData(format)` |
| DiscriminationChart | qml/components/charts/DiscriminationChart.qml | `export         chart.antialiasing = true                  // Calculate proper aspect ratio based on current chart dimensions         let originalWidth = chart.width         let originalHeight = chart.height         let aspectRatio = originalHeight / originalWidth                  // Use extremely high resolution for vector-like quality         let targetWidth = 8000         let targetHeight = Math.round(targetWidth * aspectRatio)` |
| DiscriminationChartCalculator | qml/components/charts/DiscriminationChart.qml | `export         chart.antialiasing = true                  // Calculate proper aspect ratio based on current chart dimensions         let originalWidth = chart.width         let originalHeight = chart.height         let aspectRatio = originalHeight / originalWidth                  // Use extremely high resolution for vector-like quality         let targetWidth = 8000         let targetHeight = Math.round(targetWidth * aspectRatio)` |
| LogViewer | qml/components/logging/LogViewer.qml | `exportFileDialog         title: "Export All Log History"         nameFilters: ["Text files (*.txt)` |
| LogViewerCalculator | qml/components/logging/LogViewer.qml | `exportFileDialog         title: "Export All Log History"         nameFilters: ["Text files (*.txt)` |
| LogViewer | qml/components/logging/LogViewer.qml | `exportAllLogs)` |
| LogViewerCalculator | qml/components/logging/LogViewer.qml | `exportAllLogs)` |
| ExportFileDialog | qml/components/exports/ExportFileDialog.qml | `exportType: chartExport     property real currentScale: 2.0     property var handler: null     property var details: null          function setup(dialogTitle, filters, suffix, baseFilename, type, callback)` |
| ExportFileDialogCalculator | qml/components/exports/ExportFileDialog.qml | `exportType: chartExport     property real currentScale: 2.0     property var handler: null     property var details: null          function setup(dialogTitle, filters, suffix, baseFilename, type, callback)` |
| ExportFileDialog | qml/components/exports/ExportFileDialog.qml | `exportType = type         handler = callback                  // Simple timestamp for filename         let now = new Date()` |
| ExportFileDialogCalculator | qml/components/exports/ExportFileDialog.qml | `exportType = type         handler = callback                  // Simple timestamp for filename         let now = new Date()` |
| FileSaveHandler | qml/components/exports/FileSaveHandler.qml | `exported_data"     property var saveHandler: null     property string lastSavedPath: ""     property bool busy: false          // File saver instance     property FileSaver fileSaver: FileSaver` |
| FileSaveHandlerCalculator | qml/components/exports/FileSaveHandler.qml | `exported_data"     property var saveHandler: null     property string lastSavedPath: ""     property bool busy: false          // File saver instance     property FileSaver fileSaver: FileSaver` |
| LogExporter | qml/components/exports/LogExporter.qml | `function exportLogs(filePath)` |
| LogExporterCalculator | qml/components/exports/LogExporter.qml | `function exportLogs(filePath)` |
| TestCase | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtTest/TestCase.qml | `printed by the test framework when a row fails, to help the reader     identify which case failed amongst a set of otherwise passing tests.      \section1 Benchmarks      Functions whose names start with "benchmark_" will be run multiple     times with the Qt benchmark framework, with an average timing value     reported for the runs.  This is equivalent to using the \c` |
| TestCaseCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtTest/TestCase.qml | `printed by the test framework when a row fails, to help the reader     identify which case failed amongst a set of otherwise passing tests.      \section1 Benchmarks      Functions whose names start with "benchmark_" will be run multiple     times with the Qt benchmark framework, with an average timing value     reported for the runs.  This is equivalent to using the \c` |
| TestCase | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtTest/TestCase.qml | `prints the optional \a message.         If this is a data-driven test, then only the current row is skipped.         Similar to \c` |
| TestCaseCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtTest/TestCase.qml | `prints the optional \a message.         If this is a data-driven test, then only the current row is skipped.         Similar to \c` |
| TestCase | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtTest/TestCase.qml | `printed and the test passes.  If the message         does not occur, then the test will fail.  Similar to         \c` |
| TestCaseCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtTest/TestCase.qml | `printed and the test passes.  If the message         does not occur, then the test will fail.  Similar to         \c` |
| Config | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/Controls/FluentWinUI3/Config.qml | `export` |
| ConfigCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/Controls/FluentWinUI3/Config.qml | `export` |
| StyleImage | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/Controls/FluentWinUI3/StyleImage.qml | `print("StyleImage has been moved to private FluentWinUI3.impl module "              + "and is no longer part of the public QML API.")` |
| StyleImageCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/Controls/FluentWinUI3/StyleImage.qml | `print("StyleImage has been moved to private FluentWinUI3.impl module "              + "and is no longer part of the public QML API.")` |
| FocusFrame | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/Controls/FluentWinUI3/FocusFrame.qml | `print("FocusFrame has been moved to private FluentWinUI3.impl module "              + "and is no longer part of the public QML API.")` |
| FocusFrameCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/Controls/FluentWinUI3/FocusFrame.qml | `print("FocusFrame has been moved to private FluentWinUI3.impl module "              + "and is no longer part of the public QML API.")` |
| Component | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/tooling/Component.qml | `export` |
| ComponentCalculator | venv/lib/python3.13/site-packages/PySide6/Qt/qml/QtQuick/tooling/Component.qml | `export` |
| Helper | docs/application/Helper.qml | `exports" import "../../components/charts" import "../../components/displays"  // copilot checks  Are you able to check the calculations in this file please? Are there any changes needed to the qml file? Can you modify this file so it looks nice please? Can you check the accuracy of the calculations in this file please and generate documentation?   // section header  // Header with title and help button RowLayout` |
| HelperCalculator | docs/application/Helper.qml | `exports" import "../../components/charts" import "../../components/displays"  // copilot checks  Are you able to check the calculations in this file please? Are there any changes needed to the qml file? Can you modify this file so it looks nice please? Can you check the accuracy of the calculations in this file please and generate documentation?   // section header  // Header with title and help button RowLayout` |

### PNG Export Functions

| Calculator | File | Function |
|------------|------|----------|
| WindTurbineSection | qml/calculators/grid_wind/WindTurbineSection.qml | `function saveChartImage(filePath)` |
| DiscriminationAnalyzer | qml/calculators/protection/DiscriminationAnalyzer.qml | `saveChartImage(filename)` |
| DiscriminationAnalyzerCalculator | qml/calculators/protection/DiscriminationAnalyzer.qml | `saveChartImage(filename)` |
| VR32CL7Calculator | qml/calculators/protection/VR32CL7Calculator.qml | `generate_plot_with_url(folderUrl)` |
| RLC | qml/calculators/theory/RLC.qml | `saveChart(selectedFile, currentScale)` |
| RLCCalculator | qml/calculators/theory/RLC.qml | `saveChart(selectedFile, currentScale)` |
| VoltageDropOrion | qml/calculators/voltage_drop/VoltageDropOrion.qml | `saveChart(selectedFile, currentScale)` |
| VoltageDropOrionCalculator | qml/calculators/voltage_drop/VoltageDropOrion.qml | `saveChart(selectedFile, currentScale)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `captureImage()` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `captureImage()` |
| NetworkCabinetDiagram | qml/components/visualizers/NetworkCabinetDiagram.qml | `function captureImage()` |
| NetworkCabinetDiagramCalculator | qml/components/visualizers/NetworkCabinetDiagram.qml | `function captureImage()` |
| VoltageDropChart | qml/components/charts/VoltageDropChart.qml | `saveChart(null, 1.0)` |
| VoltageDropChartCalculator | qml/components/charts/VoltageDropChart.qml | `saveChart(null, 1.0)` |
| VoltageDropChart | qml/components/charts/VoltageDropChart.qml | `saveChart(null, 2.0)` |
| VoltageDropChartCalculator | qml/components/charts/VoltageDropChart.qml | `saveChart(null, 2.0)` |
| VoltageDropChart | qml/components/charts/VoltageDropChart.qml | `saveChart(null, 4.0)` |
| VoltageDropChartCalculator | qml/components/charts/VoltageDropChart.qml | `saveChart(null, 4.0)` |
| VoltageDropChart | qml/components/charts/VoltageDropChart.qml | `saveChart(null, scale)` |
| VoltageDropChartCalculator | qml/components/charts/VoltageDropChart.qml | `saveChart(null, scale)` |
| DiscriminationChart | qml/components/charts/DiscriminationChart.qml | `function saveChartAsSVG(filename)` |
| DiscriminationChartCalculator | qml/components/charts/DiscriminationChart.qml | `function saveChartAsSVG(filename)` |
| DiscriminationChart | qml/components/charts/DiscriminationChart.qml | `function saveChartImage(filename)` |
| DiscriminationChartCalculator | qml/components/charts/DiscriminationChart.qml | `function saveChartImage(filename)` |

### PDF Export Functions

| Calculator | File | Function |
|------------|------|----------|
| DiscriminationAnalyzer | qml/calculators/protection/DiscriminationAnalyzer.qml | `exportResults()` |
| DiscriminationAnalyzerCalculator | qml/calculators/protection/DiscriminationAnalyzer.qml | `exportResults()` |
| SolkorRf | qml/calculators/protection/SolkorRf.qml | `exportToPdf with null parameter         // to let FileSaver handle the file dialog         calculator.exportToPdf(null)` |
| SolkorRfCalculator | qml/calculators/protection/SolkorRf.qml | `exportToPdf with null parameter         // to let FileSaver handle the file dialog         calculator.exportToPdf(null)` |
| SolkorRf | qml/calculators/protection/SolkorRf.qml | `function saveToPdf()` |
| SolkorRfCalculator | qml/calculators/protection/SolkorRf.qml | `function saveToPdf()` |
| VR32CL7Calculator | qml/calculators/protection/VR32CL7Calculator.qml | `generate_plot_with_url(folderUrl)` |
| MotorStartingCalculator | qml/calculators/theory/MotorStartingCalculator.qml | `exportResults(null)` |
| VoltageDropDetails | qml/calculators/voltage_drop/VoltageDropDetails.qml | `saveToPdfRequested()` |
| VoltageDropDetailsCalculator | qml/calculators/voltage_drop/VoltageDropDetails.qml | `saveToPdfRequested()` |
| VoltageDropDetails | qml/calculators/voltage_drop/VoltageDropDetails.qml | `saveToPdfRequested()` |
| VoltageDropDetailsCalculator | qml/calculators/voltage_drop/VoltageDropDetails.qml | `saveToPdfRequested()` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `exportToPdf(folderDialog.folder, diagramImage)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `exportToPdf(null, diagramImage)` |

### CSV Export Functions

| Calculator | File | Function |
|------------|------|----------|
| HarmonicsAnalyzer | qml/calculators/theory/HarmonicsAnalyzer.qml | `exportDataToCSV(null)` |
| HarmonicsAnalyzerCalculator | qml/calculators/theory/HarmonicsAnalyzer.qml | `exportDataToCSV(null)` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `exportCSV()` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `exportCSV()` |

### JSON Export Functions

| Calculator | File | Function |
|------------|------|----------|
| RealTime | qml/calculators/theory/RealTime.qml | `saveConfiguration()` |
| RealTimeCalculator | qml/calculators/theory/RealTime.qml | `saveConfiguration()` |
| RealTime | qml/calculators/theory/RealTime.qml | `loadConfiguration()` |
| RealTimeCalculator | qml/calculators/theory/RealTime.qml | `loadConfiguration()` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `saveConfigDialog         title: "Save Configuration"         fileMode: FileDialog.SaveFile         nameFilters: ["JSON Files (*.json)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `saveConfig(saveConfigDialog.file)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `saveConfig(null)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `loadConfigDialog         title: "Load Configuration"         fileMode: FileDialog.OpenFile         nameFilters: ["JSON Files (*.json)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `loadConfig(loadConfigDialog.file)` |
| NetworkCabinetCalculator | qml/calculators/cable/NetworkCabinetCalculator.qml | `loadConfig(null)` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `saveToJSON()` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `saveToJSON()` |
| SwitchboardPanel | qml/calculators/cable/SwitchboardPanel.qml | `loadFromJSON(fileDialog.selectedFile.toString()` |
| SwitchboardPanelCalculator | qml/calculators/cable/SwitchboardPanel.qml | `loadFromJSON(fileDialog.selectedFile.toString()` |

## Test Procedures

### Testing CSV Export

#### Manual Test Steps:

1. Launch the application
2. Navigate to each calculator with export functionality
3. Configure inputs with valid test data
4. Trigger the export function
5. Verify the exported file is created and contains the expected data
6. Check file formatting and content validity

#### Test Cases:

**1. MotorStartingCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**2. HarmonicsAnalyzerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**3. HarmonicsAnalyzer**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**4. SwitchboardPanel**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**5. SwitchboardPanelCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

### Testing JSON Export

#### Manual Test Steps:

1. Launch the application
2. Navigate to each calculator with export functionality
3. Configure inputs with valid test data
4. Trigger the export function
5. Verify the exported file is created and contains the expected data
6. Check file formatting and content validity

#### Test Cases:

**1. CalculatorSettings**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**2. RealTime**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**3. RealTimeCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**4. SwitchboardPanel**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**5. SwitchboardPanelCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**6. NetworkCabinetCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

### Testing PNG Export

#### Manual Test Steps:

1. Launch the application
2. Navigate to each calculator with export functionality
3. Configure inputs with valid test data
4. Trigger the export function
5. Verify the exported file is created and contains the expected data
6. Check file formatting and content validity

#### Test Cases:

**1. RLC**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**2. NetworkCabinetDiagram**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**3. NetworkCabinetDiagramCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**4. VoltageDropChart**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**5. VoltageDropOrionCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**6. VoltageDropChartCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**7. VoltageDropOrion**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**8. NetworkCabinetCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**9. DiscriminationChartCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**10. DiscriminationAnalyzerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**11. RLCCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**12. WindTurbineSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**13. VR32CL7Calculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**14. DiscriminationChart**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**15. DiscriminationAnalyzer**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

### Testing PDF Export

#### Manual Test Steps:

1. Launch the application
2. Navigate to each calculator with export functionality
3. Configure inputs with valid test data
4. Trigger the export function
5. Verify the exported file is created and contains the expected data
6. Check file formatting and content validity

#### Test Cases:

**1. SolkorRfCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**2. TransformerLineSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**3. VoltageDropOrion**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**4. VoltageDropCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**5. NetworkCabinetCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**6. SolkorRf**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**7. ProtectionRequirementsSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**8. MotorStartingCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**9. DiscriminationAnalyzerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**10. WindTurbineSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**11. VoltageDropDetails**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**12. VR32CL7Calculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**13. VoltageDropDetailsCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**14. DiscriminationAnalyzer**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

### Testing OTHER Export

#### Manual Test Steps:

1. Launch the application
2. Navigate to each calculator with export functionality
3. Configure inputs with valid test data
4. Trigger the export function
5. Verify the exported file is created and contains the expected data
6. Check file formatting and content validity

#### Test Cases:

**1. VoltageDropOrionCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**2. SolkorRfCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**3. HarmonicsAnalyzer**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**4. FileSaveHandlerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**5. VoltageDropOrion**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**6. ResultsPanelCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**7. ConfigCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**8. HelperCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**9. HarmonicsAnalyzerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**10. TestCase**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**11. WindTurbineSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**12. FocusFrameCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**13. RLC**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**14. VoltageDropChart**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**15. TransformerLineSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**16. FileSaveHandler**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**17. FocusFrame**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**18. Config**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**19. Helper**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**20. ExportFileDialog**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**21. LogExporterCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**22. SwitchboardPanelCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**23. DiscriminationChart**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**24. StyleImage**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**25. ThreePhaseCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**26. LogExporter**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**27. SwitchboardPanel**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**28. ProtectionRequirementsSection**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**29. TestCaseCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**30. ResultsPanel**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**31. Component**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**32. ExportFileDialogCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**33. VoltageDropChartCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**34. LogViewerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**35. LogViewer**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**36. NetworkCabinetCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**37. SolkorRf**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**38. StyleImageCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**39. MotorStartingCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**40. DiscriminationAnalyzerCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**41. RLCCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**42. DiscriminationChartCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**43. ThreePhase**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**44. ComponentCalculator**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

**45. DiscriminationAnalyzer**

- [ ] Export completes without errors
- [ ] File is created in the expected location
- [ ] File content is correct and well-formatted
- [ ] Error handling works appropriately for invalid inputs

## Automation Opportunities

The following export functions could be candidates for automated testing:

| Function Pattern | Occurrence Count |
|-----------------|------------------|
| `saveChart` | 12 |
| `exportTableData` | 6 |
| `exportTableToPDF` | 6 |
| `exportToPdf with null parameter
        // to let FileSaver handle the file dialog
        calculator.exportToPdf` | 4 |
| `exportDataToCSV` | 4 |
| `exportDetailsToPDF` | 4 |
| `saveResultsClicked` | 4 |
| `exportToPdf` | 4 |
| `export` | 4 |
| `print` | 4 |
| `saveToPdfRequested` | 4 |
| `function saveChartImage` | 3 |
| `exportResults` | 3 |
| `exportWindTurbineReport` | 2 |
| `exports"
import "../../components/charts"
import "../three_phase/"

import Sine 1.0

Page` | 2 |
| `exportButton
                                    text: "Export Results"
                                    Layout.columnSpan: 2

                                    ToolTip.text: "Export results to PDF"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    visible: calculator.relayCount >= 2
                                    icon.source: "../../../icons/rounded/download.svg"
                                    
                                    onClicked:` | 2 |
| `exports"

import SolkorRfCalculator 1.0

Item` | 2 |
| `exports"
import "../../components/charts"
import "../../components/displays"
import "../../components/menus"

import HarmonicAnalysis 1.0
import SeriesHelper 1.0

Item` | 2 |
| `export the harmonic data to a CSV file for further analysis."
    }

    ColumnLayout` | 2 |
| `exportMouseArea.containsMouse
                        ToolTip.delay: 500
                        
                        MouseArea` | 2 |
| `exports"
import "../../components/charts"

import RLC 1.0

Page` | 2 |
| `exports"
import "../../components/charts"
import "../../components/monitors"
import "../voltage_drop/"

import VDrop 1.0

Page` | 2 |
| `exportFormatMenu.popup` | 2 |
| `exportFileDialog.setup` | 2 |
| `exportFileDialog.chartExport)
            exportFileDialog.currentScale = scale
            exportFileDialog.open` | 2 |
| `exportFileDialog

        function handleExport` | 2 |
| `exportType)` | 2 |
| `exportFormatMenu
        
        Component.onCompleted:` | 2 |
| `export of the full switchboard schedule.<br><br>" +
                   "Double-click any row to edit circuit details, or use the + button to add a new circuit."
        widthFactor: 0.5
        heightFactor: 0.5
    }

    ColumnLayout` | 2 |
| `exportMenu.open` | 2 |
| `exportMenu
                            MenuItem` | 2 |
| `exportPDF` | 2 |
| `printSchedule` | 2 |
| `function exportChartData` | 2 |
| `export
        chart.antialiasing = true
        
        // Calculate proper aspect ratio based on current chart dimensions
        let originalWidth = chart.width
        let originalHeight = chart.height
        let aspectRatio = originalHeight / originalWidth
        
        // Use extremely high resolution for vector-like quality
        let targetWidth = 8000
        let targetHeight = Math.round` | 2 |
| `exportFileDialog
        title: "Export All Log History"
        nameFilters: ["Text files` | 2 |
| `exportAllLogs)` | 2 |
| `exportType: chartExport
    property real currentScale: 2.0
    property var handler: null
    property var details: null
    
    function setup` | 2 |
| `exportType = type
        handler = callback
        
        // Simple timestamp for filename
        let now = new Date` | 2 |
| `exported_data"
    property var saveHandler: null
    property string lastSavedPath: ""
    property bool busy: false
    
    // File saver instance
    property FileSaver fileSaver: FileSaver` | 2 |
| `function exportLogs` | 2 |
| `printed by the test framework when a row fails, to help the reader
    identify which case failed amongst a set of otherwise passing tests.

    \section1 Benchmarks

    Functions whose names start with "benchmark_" will be run multiple
    times with the Qt benchmark framework, with an average timing value
    reported for the runs.  This is equivalent to using the \c` | 2 |
| `prints the optional \a message.
        If this is a data-driven test, then only the current row is skipped.
        Similar to \c` | 2 |
| `printed and the test passes.  If the message
        does not occur, then the test will fail.  Similar to
        \c` | 2 |
| `exports"
import "../../components/charts"
import "../../components/displays"

// copilot checks

Are you able to check the calculations in this file please?
Are there any changes needed to the qml file?
Can you modify this file so it looks nice please?
Can you check the accuracy of the calculations in this file please and generate documentation?


// section header

// Header with title and help button
RowLayout` | 2 |
| `saveChartImage` | 2 |
| `generate_plot_with_url` | 2 |
| `captureImage` | 2 |
| `function captureImage` | 2 |
| `function saveChartAsSVG` | 2 |
| `function saveToPdf` | 2 |
| `exportCSV` | 2 |
| `saveConfiguration` | 2 |
| `loadConfiguration` | 2 |
| `saveConfig` | 2 |
| `loadConfig` | 2 |
| `saveToJSON` | 2 |
| `loadFromJSON` | 2 |

## Notes on Testing Approach

1. For PDF exports, validate the content using a PDF reader or parser
2. For CSV exports, validate structure and data integrity
3. For JSON exports, validate against expected schema
4. For image exports, validate dimensions and basic image properties
