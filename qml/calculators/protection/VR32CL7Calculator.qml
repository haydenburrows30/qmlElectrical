import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCharts
import Qt.labs.platform

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

import VR32CL7Calculator 1.0

Item {
    id: root

    property VR32CL7Calculator calculator: VR32CL7Calculator {}

    MessagePopup {
        id: messagePopup
    }

    ColumnLayout {
        id: mainLayout
        anchors.centerIn: parent

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Voltage Regulator Calculator"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                ToolTip.text: "Export results to PDF"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                Layout.alignment: Qt.AlignRight
                icon.source: "../../../icons/rounded/download.svg"

                onClicked: {
                    if (calculator) {
                        calculator.exportPlot()
                    }
                }
            }
        }

        // Input parameters section
        RowLayout {

            WaveCard {
                id: inputPara
                Layout.minimumWidth: 400
                Layout.minimumHeight: 280
                title: "Input Parameters"
                
                GridLayout {
                    anchors.fill: parent
                    columns: 3

                    // Generation capacity
                    Label { 
                        text: "Wind Generation:" 
                        Layout.fillWidth: true
                    }

                    SpinBoxRound {
                        id: generationInput
                        from: 1
                        to: 10000
                        value: calculator ? calculator.generation_capacity_kw : 500
                        stepSize: 10
                        editable: true
                        Layout.fillWidth: true
                        
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
                        Layout.fillWidth: true
                    }

                    // Cable length
                    Label { 
                        text: "Cable Length:" 
                        Layout.fillWidth: true
                    }

                    SpinBoxRound {
                        id: cableLengthInput
                        from: 1  // Changed from 0.1 to 1 as SpinBox expects integers
                        to: 1000  // Changed from 100.0 to 1000
                        value: calculator ? Math.round(calculator.cable_length_km * 10) : 80  // Multiply by 10 to convert to int
                        stepSize: 1
                        editable: true
                        Layout.fillWidth: true
                        
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
                        Layout.fillWidth: true
                    }

                    // Cable R value
                    Label { 
                        text: "Cable R:" 
                        Layout.fillWidth: true
                    }

                    SpinBoxRound {
                        id: cableRInput
                        from: 1  // Changed from 0.01
                        to: 1000  // Changed from 10.0
                        value: calculator ? Math.round(calculator.cable_r_per_km * 100) : 115
                        stepSize: 1
                        editable: true
                        Layout.fillWidth: true
                        
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
                        Layout.fillWidth: true
                    }

                    // Cable X value
                    Label { 
                        text: "Cable X:" 
                        Layout.fillWidth: true
                    }

                    SpinBoxRound {
                        id: cableXInput
                        from: 1  // Changed from 0.01
                        to: 1000  // Changed from 10.0
                        value: calculator ? Math.round(calculator.cable_x_per_km * 1000) : 126
                        stepSize: 1
                        editable: true
                        Layout.fillWidth: true
                        
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
                        Layout.fillWidth: true
                    }

                    // Load distance
                    Label { 
                        text: "Load Distance:" 
                        Layout.fillWidth: true
                    }

                    SpinBoxRound {
                        id: loadDistanceInput
                        from: 1  // Changed from 0.1
                        to: 500  // Changed from 50.0
                        value: calculator ? Math.round(calculator.load_distance_km * 10) : 30
                        stepSize: 1
                        editable: true
                        Layout.fillWidth: true
                        
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
                        Layout.fillWidth: true
                    }
                }
            }

            // Results section
            WaveCard {
                Layout.minimumWidth: 400
                Layout.minimumHeight: inputPara.height
                title: "Results"
                
                ColumnLayout {
                    anchors.fill: parent
                    
                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        uniformCellWidths: true
                        
                        // Labels and Values
                        Label { 
                            text: "Resistance (R):" 
                            Layout.fillWidth: true
                        }

                        TextFieldBlue { 
                            text: calculator ? calculator.resistance.toFixed(2) + " Ω" : "0.0000 Ω"
                            Layout.fillWidth: true
                        }
                        
                        Label { 
                            text: "Reactance (X):" 
                        }

                        TextFieldBlue { 
                            text: calculator ? calculator.reactance.toFixed(2) + " Ω" : "0.0000 Ω"
                        }
                        
                        Label { 
                            text: "Impedance (Z):" 
                        }

                        TextFieldBlue { 
                            text: calculator ? calculator.impedance.toFixed(2) + " Ω" : "0.0000 Ω"
                        }
                        
                        Label { 
                            text: "Impedance Angle:" 
                        }

                        TextFieldBlue { 
                            text: calculator ? calculator.impedance_angle.toFixed(2) + "°" : "0.00°"
                        }

                        Label {
                            text: "Total Resistance (R)"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        TextFieldBlue {
                            text: calculator ? calculator.resistance.toFixed(2) + " Ω" : "0.0000 Ω"
                        }

                        Label {
                            text: "Total Reactance (X)"
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        TextFieldBlue {
                            text: calculator ? calculator.reactance.toFixed(2) + " Ω" : "0.0000 Ω"
                        }
                    }
                }
            }
        }

        // Formulas section
        WaveCard {
            Layout.fillWidth: true
            Layout.minimumHeight: 330
            title: "Formulas"

            GridLayout {
                width: parent.width
                columns: 4

                // Formula for total length
                Label {
                    text: "Total Length:"
                    font.bold: true
                }

                Rectangle {
                    id: lengthImageContainer
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        id: lengthImage
                        source: "../../../assets/formulas/vr32cl7_total_length.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent
                        
                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    lengthImageContainer.scale = 1.5
                                    lengthImageContainer.z = 2

                                }
                                else{
                                    lengthImageContainer.scale = 1.0
                                    lengthImageContainer.z = 1
                                }
                            }
                        }
                    }
                }

                // Formula for power factor
                Label {
                    text: "Power Factor:"
                    font.bold: true
                }

                Rectangle {
                    id: powerFactorImageContainer
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        source: "../../../assets/formulas/vr32cl7_power_factor.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent

                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    powerFactorImageContainer.scale = 1.5
                                    powerFactorImageContainer.z = 2
                                }
                                else{
                                    powerFactorImageContainer.scale = 1.0
                                    powerFactorImageContainer.z = 1
                                }
                            }
                        }
                    }
                }

                // Formula for adjusted resistance
                Label {
                    text: "Adjusted Resistance:"
                    font.bold: true
                }

                Rectangle {
                    id: resistanceImageContainer
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        source: "../../../assets/formulas/vr32cl7_adjusted_resistance.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent

                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    resistanceImageContainer.scale = 1.5
                                    resistanceImageContainer.z = 2

                                }
                                else{
                                    resistanceImageContainer.scale = 1.0
                                    resistanceImageContainer.z = 1
                                }
                            }

                        }
                    }
                }

                // Formula for adjusted reactance
                Label {
                    text: "Adjusted Reactance:"
                    font.bold: true
                }

                Rectangle {
                    id: reactanceImage
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        source: "../../../assets/formulas/vr32cl7_adjusted_reactance.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent

                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    reactanceImage.scale = 1.5
                                    reactanceImage.z = 2

                                }
                                else{
                                    reactanceImage.scale = 1.0
                                    reactanceImage.z = 1
                                }
                            }
                        }
                    }
                }

                // Formula for impedance
                Label {
                    text: "Impedance Magnitude:"
                    font.bold: true
                }

                Rectangle {
                    id: impedanceImage
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        source: "../../../assets/formulas/vr32cl7_impedance.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent

                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    impedanceImage.scale = 1.5
                                    impedanceImage.z = 2

                                }
                                else{
                                    impedanceImage.scale = 1.0
                                    impedanceImage.z = 1
                                }
                            }

                        }
                    }
                }

                // Formula for impedance angle
                Label {
                    text: "Impedance Angle:"
                    font.bold: true
                }

                Rectangle {
                    id: angleImage
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        source: "../../../assets/formulas/vr32cl7_impedance_angle.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent

                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    angleImage.scale = 1.5
                                    angleImage.z = 2

                                }
                                else{
                                    angleImage.scale = 1.0
                                    angleImage.z = 1
                                }
                            }
                        }
                    }
                }

                // Overall impedance formula
                Label {
                    text: "Complete Impedance:"
                    font.bold: true
                }

                Rectangle {
                    id: overallImage
                    color: "white"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 10

                    Image {
                        source: "../../../assets/formulas/vr32cl7_overall.svg"
                        fillMode: Image.PreserveAspectFit
                        anchors.fill: parent

                        HoverHandler{
                            onHoveredChanged: {
                                if(hovered){
                                    overallImage.scale = 2
                                    overallImage.z = 2

                                }
                                else{
                                    overallImage.scale = 1.0
                                    overallImage.z = 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    Connections {
        target: calculator
        
        function onExportComplete(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
    }
}