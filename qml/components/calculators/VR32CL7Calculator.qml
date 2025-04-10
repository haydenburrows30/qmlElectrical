import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCharts
import Qt.labs.platform

import "../"
import "../style"
import "../buttons"

import VR32CL7Calculator 1.0

Item {
    id: root
    
    
    property VR32CL7Calculator calculator: VR32CL7Calculator {}
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#2c3e50"
            radius: 5
            
            Text {
                anchors.centerIn: parent
                text: "VR32 CL-7 Voltage Regulator Calculator"
                font.pixelSize: 20
                font.bold: true
                color: "white"
            }
        }
        
        // Input parameters section
        GroupBox {
            Layout.fillWidth: true
            title: "Input Parameters"
            
            GridLayout {
                anchors.fill: parent
                columns: 4
                rowSpacing: 10
                columnSpacing: 15
                
                // Generation capacity
                Label { 
                    text: "Wind Generation:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    id: generationInput
                    from: 1
                    to: 10000
                    value: calculator ? calculator.generation_capacity_kw : 500
                    stepSize: 10
                    editable: true
                    
                    onValueChanged: {
                        if (calculator) {
                            calculator.generation_capacity_kw = value
                        }
                    }
                    
                    textFromValue: function(value) {
                        return value.toFixed(0)
                    }
                }
                Label { 
                    text: "kW" 
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true } // Spacer
                
                // Cable length
                Label { 
                    text: "Cable Length:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    id: cableLengthInput
                    from: 1  // Changed from 0.1 to 1 as SpinBox expects integers
                    to: 1000  // Changed from 100.0 to 1000
                    value: calculator ? Math.round(calculator.cable_length_km * 10) : 80  // Multiply by 10 to convert to int
                    stepSize: 1
                    editable: true
                    
                    property real realValue: value / 10
                    
                    onValueChanged: {
                        if (calculator) {
                            calculator.cable_length_km = realValue
                        }
                    }
                    
                    textFromValue: function(value) {
                        return (value / 10).toFixed(1)
                    }
                    
                    valueFromText: function(text) {
                        return Math.round(parseFloat(text) * 10)
                    }
                }
                Label { 
                    text: "km" 
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true } // Spacer
                
                // Cable R value
                Label { 
                    text: "Cable R:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    id: cableRInput
                    from: 1  // Changed from 0.01
                    to: 1000  // Changed from 10.0
                    value: calculator ? Math.round(calculator.cable_r_per_km * 100) : 115
                    stepSize: 1
                    editable: true
                    
                    property real realValue: value / 100
                    
                    onValueChanged: {
                        if (calculator) {
                            calculator.cable_r_per_km = realValue
                        }
                    }
                    
                    textFromValue: function(value) {
                        return (value / 100).toFixed(2)
                    }
                    
                    valueFromText: function(text) {
                        return Math.round(parseFloat(text) * 100)
                    }
                }
                Label { 
                    text: "Ω/km" 
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true } // Spacer
                
                // Cable X value
                Label { 
                    text: "Cable X:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    id: cableXInput
                    from: 1  // Changed from 0.01
                    to: 1000  // Changed from 10.0
                    value: calculator ? Math.round(calculator.cable_x_per_km * 1000) : 126
                    stepSize: 1
                    editable: true
                    
                    property real realValue: value / 1000
                    
                    onValueChanged: {
                        if (calculator) {
                            calculator.cable_x_per_km = realValue
                        }
                    }
                    
                    textFromValue: function(value) {
                        return (value / 1000).toFixed(3)
                    }
                    
                    valueFromText: function(text) {
                        return Math.round(parseFloat(text) * 1000)
                    }
                }
                Label { 
                    text: "Ω/km" 
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true } // Spacer
                
                // Load distance
                Label { 
                    text: "Load Distance:" 
                    font.pixelSize: 14
                }
                SpinBox {
                    id: loadDistanceInput
                    from: 1  // Changed from 0.1
                    to: 500  // Changed from 50.0
                    value: calculator ? Math.round(calculator.load_distance_km * 10) : 30
                    stepSize: 1
                    editable: true
                    
                    property real realValue: value / 10
                    
                    onValueChanged: {
                        if (calculator) {
                            calculator.load_distance_km = realValue
                        }
                    }
                    
                    textFromValue: function(value) {
                        return (value / 10).toFixed(1)
                    }
                    
                    valueFromText: function(text) {
                        return Math.round(parseFloat(text) * 10)
                    }
                }
                Label { 
                    text: "km" 
                    font.pixelSize: 14
                }
                Item { Layout.fillWidth: true } // Spacer
                
                Button {
                    Layout.columnSpan: 2
                    Layout.alignment: Qt.AlignHCenter
                    text: "Calculate"
                    onClicked: {
                        if (calculator) {
                            calculator.calculate()
                        }
                    }
                }
                
                Button {
                    Layout.columnSpan: 2
                    Layout.alignment: Qt.AlignHCenter
                    text: "Generate Plot"
                    onClicked: {
                        if (calculator) {
                            folderDialog.open()
                        }
                    }
                }
            }
        }
        
        // Results section
        GroupBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Results"
            
            ColumnLayout {
                anchors.fill: parent
                spacing: 10
                
                // Simple results display - no TableView
                GridLayout {
                    columns: 2
                    Layout.fillWidth: true
                    columnSpacing: 20
                    rowSpacing: 10
                    
                    // Header
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        height: 40
                        color: "#e0e0e0"
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Calculation Results"
                            font.bold: true
                            font.pixelSize: 16
                        }
                    }
                    
                    // Labels and Values
                    Text { 
                        text: "Resistance (R):" 
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text { 
                        text: calculator ? calculator.resistance.toFixed(4) + " Ω" : "0.0000 Ω"
                        font.pixelSize: 14
                    }
                    
                    Text { 
                        text: "Reactance (X):" 
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text { 
                        text: calculator ? calculator.reactance.toFixed(4) + " Ω" : "0.0000 Ω"
                        font.pixelSize: 14
                    }
                    
                    Text { 
                        text: "Impedance (Z):" 
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text { 
                        text: calculator ? calculator.impedance.toFixed(4) + " Ω" : "0.0000 Ω"
                        font.pixelSize: 14
                    }
                    
                    Text { 
                        text: "Impedance Angle:" 
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text { 
                        text: calculator ? calculator.impedance_angle.toFixed(2) + "°" : "0.00°"
                        font.pixelSize: 14
                    }
                }
                
                // Results summary
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    height: 80
                    color: "#e8f5e9"
                    radius: 5
                    border.color: "#81c784"
                    border.width: 1
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 20
                        
                        Column {
                            Text {
                                text: "Total Resistance (R)"
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            Text {
                                text: calculator ? calculator.resistance.toFixed(4) + " Ω" : "0.0000 Ω"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        Column {
                            Text {
                                text: "Total Reactance (X)"
                                font.pixelSize: 14
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            
                            Text {
                                text: calculator ? calculator.reactance.toFixed(4) + " Ω" : "0.0000 Ω"
                                font.pixelSize: 18
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
        }
        
        // // Formulas section
        GroupBox {
            Layout.fillWidth: true
            Layout.preferredHeight: 250
            title: "Formulas"
                
            ColumnLayout {
                anchors.fill: parent
                
                Text {
                    width: parent.width
                    text: "VR32 CL-7 Voltage Regulator Formulas"
                    font.bold: true
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                }
                
                GridLayout {
                    columns: 2
                    
                    // Formula for total length
                    Text {
                        text: "Total Length:"
                        font.bold: true
                    }
                    Image {
                        source: "../../../assets/formulas/vr32cl7_total_length.png"
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    // Formula for resistance
                    Text {
                        text: "Total Resistance:"
                        font.bold: true
                    }
                    Image {
                        source: "../../../assets/formulas/vr32cl7_resistance.png"
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    // Formula for reactance
                    Text {
                        text: "Total Reactance:"
                        font.bold: true
                    }
                    Image {
                        source: "../../../assets/formulas/vr32cl7_reactance.png"
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    // Formula for impedance
                    Text {
                        text: "Impedance Magnitude:"
                        font.bold: true
                    }
                    Image {
                        source: "../../../assets/formulas/vr32cl7_impedance.png"
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    // Formula for impedance angle
                    Text {
                        text: "Impedance Angle:"
                        font.bold: true
                    }
                    Image {
                        source: "../../../assets/formulas/vr32cl7_impedance_angle.png"
                        fillMode: Image.PreserveAspectFit
                    }
                    
                    // Overall impedance formula
                    Text {
                        text: "Complete Impedance:"
                        font.bold: true
                    }
                    Image {
                        source: "../../../assets/formulas/vr32cl7_overall.png"
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }
    }
    
    // Dialog for selecting save folder
    FolderDialog {
        id: folderDialog
        title: "Select folder to save plot"
        currentFolder: StandardPaths.standardLocations(StandardPaths.DocumentsLocation)[0]
        
        onAccepted: {
            if (calculator) {
                // Get the selected folder URL
                var folderUrl = folderDialog.currentFolder.toString()
                
                // Generate the plot and update the dialog text before showing it
                calculator.generate_plot_with_url(folderUrl)
                
                // Construct a readable path for the message dialog
                var displayPath
                if (folderUrl.startsWith("file:///")) {
                    // Remove the file:/// prefix for display
                    displayPath = folderUrl.replace(/^file:\/\/\//, "")
                    if (displayPath.match(/^[A-Za-z]:/)) {
                        // Windows path
                        displayPath = displayPath + "\\vr32_cl7_plot.png"
                    } else {
                        // Linux/Unix path
                        displayPath = "/" + displayPath + "/vr32_cl7_plot.png"
                    }
                } else {
                    // Fallback
                    displayPath = folderUrl + "/vr32_cl7_plot.png"
                }
                
                plotSavedDialog.text = "The VR32 CL-7 plot has been generated and saved to:\n" + displayPath
                plotSavedDialog.open()
            }
        }
    }
    
    // Dialog for plot saved confirmation
    MessageDialog {
        id: plotSavedDialog
        title: "Plot Generated"
        text: "The VR32 CL-7 plot has been generated and saved."
        buttons: MessageDialog.Ok
    }
    
    // Connections to update UI when calculator changes
    Connections {
        target: calculator
        function onResultsChanged() {
            // The UI will automatically update through property bindings
        }
    }
}