import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal
import QtQuick.Dialogs

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"

import LightningProtectionCalculator 1.0

Item {
    id: root

    property LightningProtectionCalculator calculator: LightningProtectionCalculator {}
    
    // Structure type models
    property var structureTypes: [
        "Common structure",
        "Metal structure",
        "Structure with flammable contents",
        "Structure with explosive/chemical contents",
        "Hospital or school"
    ]
    
    // Protection level models
    property var protectionLevels: ["I", "II", "III", "IV"]
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableMain
            contentWidth: parent.width
            contentHeight: mainLayout.height + 20
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5
        
            ColumnLayout {
                id: mainLayout
                width: flickableMain.width -20
                
                // Header
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5
                    
                    Label {
                        text: "Lightning Protection System Designer"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    
                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: methodInfoDialog.open()
                    }
                }
                
                // Main content
                RowLayout {
                    
                    // Left column - inputs
                    ColumnLayout {
                        Layout.maximumWidth: 350
                        Layout.minimumWidth: 350
                        Layout.alignment: Qt.AlignTop
                        
                        WaveCard {
                            title: "Structure Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 220
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                Label { text: "Height (m):" }
                                SpinBox {
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 200
                                    stepSize: 1
                                    value: calculator ? calculator.structureHeight : 10
                                    onValueChanged: {
                                        if (calculator) calculator.structureHeight = value
                                    }
                                    editable: true
                                }
                                
                                Label { text: "Length (m):" }
                                SpinBox {
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 1000
                                    stepSize: 1
                                    value: calculator ? calculator.structureLength : 20
                                    onValueChanged: {
                                        if (calculator) calculator.structureLength = value
                                    }
                                    editable: true
                                }
                                
                                Label { text: "Width (m):" }
                                SpinBox {
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 1000
                                    stepSize: 1
                                    value: calculator ? calculator.structureWidth : 15
                                    onValueChanged: {
                                        if (calculator) calculator.structureWidth = value
                                    }
                                    editable: true
                                }
                                
                                Label { text: "Structure Type:" }
                                ComboBox {
                                    Layout.fillWidth: true
                                    model: structureTypes
                                    currentIndex: calculator ? calculator.structureType : 0
                                    onCurrentIndexChanged: {
                                        if (calculator) calculator.structureType = currentIndex
                                    }
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "Location Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 180
                            
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                
                                Label { text: "Thunderdays per year:" }
                                SpinBox {
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 200
                                    stepSize: 1
                                    value: calculator ? calculator.locationThunderdays : 25
                                    onValueChanged: {
                                        if (calculator) calculator.locationThunderdays = value
                                    }
                                    editable: true
                                }
                                
                                Label { text: "Ground resistivity (Ω·m):" }
                                SpinBox {
                                    Layout.fillWidth: true
                                    from: 10
                                    to: 10000
                                    stepSize: 10
                                    value: calculator ? calculator.locationGroundResistivity : 100
                                    onValueChanged: {
                                        if (calculator) calculator.locationGroundResistivity = value
                                    }
                                    editable: true
                                }
                                
                                Label { text: "Terrain coefficient:" }
                                SpinBox {
                                    Layout.fillWidth: true
                                    from: 1
                                    to: 200
                                    stepSize: 10
                                    value: calculator ? calculator.locationTerrainCoefficient * 100 : 100
                                    onValueChanged: {
                                        if (calculator) calculator.locationTerrainCoefficient = value / 100.0
                                    }
                                    textFromValue: function(value) {
                                        return (value / 100.0).toFixed(2)
                                    }
                                    valueFromText: function(text) {
                                        return Number(text) * 100
                                    }
                                    editable: true
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "Protection System"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 300
                            
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                
                                Label { text: "Protection Level:" }
                                ComboBox {
                                    Layout.fillWidth: true
                                    model: protectionLevels
                                    currentIndex: {
                                        if (calculator) {
                                            var lvl = calculator.protectionLevel
                                            return protectionLevels.indexOf(lvl)
                                        }
                                        return 1 // Default to Level II
                                    }
                                    onCurrentIndexChanged: {
                                        if (calculator) calculator.protectionLevel = protectionLevels[currentIndex]
                                    }
                                }
                                
                                Label { 
                                    text: "Use mesh method:" 
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        ToolTip.text: "Grid of conductors on the roof to intercept lightning strikes"
                                        ToolTip.visible: containsMouse
                                        ToolTip.delay: 500
                                    }
                                }
                                CheckBox {
                                    checked: calculator ? calculator.useMeshMethod : true
                                    onCheckedChanged: {
                                        if (calculator) {
                                            calculator.useMeshMethod = checked
                                            // Make the mesh size label visible/invisible based on checkbox
                                            meshSizeRow.visible = checked
                                        }
                                    }
                                }
                                
                                Label { 
                                    text: "Use rolling sphere:" 
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        ToolTip.text: "Method to determine protected zones using an imaginary rolling sphere"
                                        ToolTip.visible: containsMouse
                                        ToolTip.delay: 500
                                    }
                                }
                                CheckBox {
                                    checked: calculator ? calculator.useRollingSphere : true
                                    onCheckedChanged: {
                                        if (calculator) {
                                            calculator.useRollingSphere = checked
                                            // Make the rolling sphere radius label visible/invisible based on checkbox
                                            rollingSphereRow.visible = checked
                                        }
                                    }
                                }
                                
                                // Add visualization button
                                Item { width: 1; height: 10 } // Spacer
                                Item { width: 1; height: 10 } // Spacer
                                
                                Button {
                                    text: "Show 3D Visualization"
                                    icon.source: "../../../icons/rounded/visibility.svg"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    onClicked: visualizationLoader.active = true
                                }
                                
                                Item { width: 1; height: 5 } // Small spacer
                                Item { width: 1; height: 5 } // Small spacer
                                
                                Button {
                                    text: "Learn More About Methods"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    onClicked: methodInfoDialog.open()
                                }
                            }
                        }
                    }
                    
                    // Right column - Results
                    ColumnLayout {
                        Layout.maximumWidth: 600
                        Layout.minimumWidth: 600
                        Layout.alignment: Qt.AlignTop

                        WaveCard {
                            title: "Strike Probability Analysis"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 200
                            
                            GridLayout {
                                anchors.fill: parent
                                columns: 2
                                
                                Label { text: "Ground flash density:" }
                                Label { 
                                    text: calculator ? calculator.groundFlashDensity.toFixed(4) + " flashes/km²/year" : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Collection area:" }
                                Label { 
                                    text: calculator ? Math.round(calculator.collectionArea) + " m²" : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Annual strikes:" }
                                Label { 
                                    text: calculator ? calculator.annualStrikes.toFixed(4) + " strikes/year" : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Required efficiency:" }
                                Label { 
                                    text: calculator ? calculator.requiredEfficiency.toFixed(2) : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Recommended level:" }
                                Label { 
                                    text: calculator ? calculator.recommendedLevel : "IV"
                                    font.bold: true
                                    color: {
                                        if (calculator) {
                                            var current = calculator.protectionLevel;
                                            var recommended = calculator.recommendedLevel;
                                            
                                            // Check if current level is less protective than recommended
                                            var currentIndex = protectionLevels.indexOf(current);
                                            var recommendedIndex = protectionLevels.indexOf(recommended);
                                            
                                            return currentIndex > recommendedIndex ? "red" : "black";
                                        }
                                        return "black";
                                    }
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "Protection System Parameters"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 240
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                
                                // Rolling sphere radius row
                                Label { 
                                    id: rollingSphereLabel
                                    text: "Rolling sphere radius:" 
                                    visible: calculator ? calculator.useRollingSphere : true
                                }
                                Label { 
                                    id: rollingSphereValue
                                    text: calculator ? calculator.rollingSphereRadius + " m" : "0"
                                    font.bold: true
                                    visible: calculator ? calculator.useRollingSphere : true
                                }
                                
                                // Mesh size row
                                Label { 
                                    id: meshSizeLabel
                                    text: "Mesh size:" 
                                    visible: calculator ? calculator.useMeshMethod : true
                                }
                                Label { 
                                    id: meshSizeValue
                                    text: calculator ? calculator.meshSize + " m × " + calculator.meshSize + " m" : "0"
                                    font.bold: true
                                    visible: calculator ? calculator.useMeshMethod : true
                                }
                                
                                // Row separators that can be controlled by visibility
                                Row {
                                    id: rollingSphereRow
                                    visible: calculator ? calculator.useRollingSphere : true
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    height: visible ? implicitHeight : 0
                                    
                                    Rectangle {
                                        width: parent.width
                                        height: 0.5
                                        color: "lightgray"
                                        visible: rollingSphereRow.visible
                                    }
                                }
                                
                                Row {
                                    id: meshSizeRow
                                    visible: calculator ? calculator.useMeshMethod : true
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    height: visible ? implicitHeight : 0
                                    
                                    Rectangle {
                                        width: parent.width
                                        height: 0.5
                                        color: "lightgray"
                                        visible: meshSizeRow.visible
                                    }
                                }
                                
                                Label { text: "Down conductor spacing:" }
                                Label { 
                                    text: calculator ? calculator.downConductorSpacing + " m" : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Required down conductors:" }
                                Label { 
                                    text: calculator ? calculator.downConductorCount.toString() : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Minimum ground rods:" }
                                Label { 
                                    text: calculator ? calculator.groundRodCount.toString() : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Separation distance:" }
                                Label { 
                                    text: calculator ? calculator.separationDistance.toFixed(2) + " m" : "0"
                                    font.bold: true
                                }
                                
                                Label { text: "Target ground resistance:" }
                                Label { 
                                    text: calculator ? calculator.groundResistanceTarget.toFixed(1) + " Ω" : "0"
                                    font.bold: true
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "Protection Assessment"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 150
                            
                            ColumnLayout {
                                anchors.fill: parent
                                
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Label { text: "Protection probability:" }
                                    Label { 
                                        text: {
                                            if (calculator) {
                                                if (!calculator.useMeshMethod && !calculator.useRollingSphere) {
                                                    return "No protection methods active"
                                                } else {
                                                    return calculator.protectionProbability.toFixed(1) + "%"
                                                }
                                            }
                                            return "0%"
                                        }
                                        font.bold: true
                                        color: (!calculator || (!calculator.useMeshMethod && !calculator.useRollingSphere)) 
                                               ? "red" : "black"
                                    }
                                }
                                
                                ProgressBar {
                                    Layout.fillWidth: true
                                    from: 0
                                    to: 100
                                    value: (calculator && (calculator.useMeshMethod || calculator.useRollingSphere)) 
                                           ? calculator.protectionProbability : 0
                                }
                                
                                Label {
                                    Layout.fillWidth: true
                                    text: {
                                        if (!calculator || (!calculator.useMeshMethod && !calculator.useRollingSphere)) {
                                            return "Warning: No protection methods are active. Enable at least one method."
                                        } else if (calculator) {
                                            var prob = calculator.protectionProbability;
                                            if (prob >= 98) return "Highest level of protection";
                                            else if (prob >= 95) return "Very high level of protection";
                                            else if (prob >= 90) return "High level of protection";
                                            else return "Standard level of protection";
                                        }
                                        return "";
                                    }
                                    wrapMode: Text.WordWrap
                                    color: (!calculator || (!calculator.useMeshMethod && !calculator.useRollingSphere)) 
                                           ? "red" : "black"
                                }
                            }
                        }
                        
                        WaveCard {
                            title: "System Design Notes"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 150
                            
                            Label {
                                anchors.fill: parent
                                wrapMode: Text.WordWrap
                                text: "The lightning protection system should include air termination, down conductors, and earthing system. " +
                                    "Ensure all metal parts are bonded to the lightning protection system with appropriate separation distances. " +
                                    "Consider surge protection devices for electrical and communication systems."
                            }
                        }
                    }
                }
            }
        }
    }
    
    Loader {
        id: visualizationLoader
        active: false
        sourceComponent: visualizationComponent
        
        onLoaded: item.open()
        
        Connections {
            target: visualizationLoader.item
            function onVisualizerClosed() {
                visualizationLoader.active = false
            }
        }
    }
    
    Component {
        id: visualizationComponent
        LightningProtectionVisualizer {
            calculator: root.calculator
        }
    }
    
    Dialog {
        id: methodInfoDialog
        title: "Lightning Protection Methods"
        width: 600
        height: 500
        modal: true
        standardButtons: Dialog.Close
        anchors.centerIn: parent
        
        ScrollView {
            anchors.fill: parent
            clip: true
            
            ColumnLayout {
                width: parent.width
                spacing: 15
                
                Label {
                    text: "Rolling Sphere Method"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "The Rolling Sphere Method is a technique used to determine where lightning protection is needed on a structure. It works on the principle that lightning strikes will attach to objects that the sphere touches as it rolls over and around a structure."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "Key characteristics of the Rolling Sphere Method:"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.bold: true
                }
                
                Label {
                    text: "• The sphere radius represents the striking distance of lightning, which varies by protection level.\n\n" +
                          "• For Protection Level I: 20m radius\n" +
                          "• For Protection Level II: 30m radius\n" +
                          "• For Protection Level III: 45m radius\n" +
                          "• For Protection Level IV: 60m radius\n\n" +
                          "• Areas where the sphere touches the structure need air termination devices (lightning rods).\n\n" +
                          "• Areas that the sphere cannot touch are considered protected zones.\n\n" +
                          "• The smaller the sphere radius, the more protection is required and the more air terminals needed."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "lightgray"
                }
                
                Label {
                    text: "Mesh Method"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "The Mesh Method involves installing a grid of conductors on the roof of a structure to intercept lightning strikes. This method is particularly effective for flat or gently sloping roofs."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "Key characteristics of the Mesh Method:"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.bold: true
                }
                
                Label {
                    text: "• The mesh size (grid spacing) varies based on the protection level:\n\n" +
                          "• For Protection Level I: 5m × 5m\n" +
                          "• For Protection Level II: 10m × 10m\n" +
                          "• For Protection Level III: 15m × 15m\n" +
                          "• For Protection Level IV: 20m × 20m\n\n" +
                          "• The grid creates a Faraday cage effect, providing distributed interception points.\n\n" +
                          "• All metallic objects on the roof should be bonded to the mesh.\n\n" +
                          "• The mesh should be connected to down conductors that run to the grounding system.\n\n" +
                          "• A smaller mesh size provides better protection but requires more conductor material."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "lightgray"
                }
                
                Label {
                    text: "Combined Application"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
                
                Label {
                    text: "In practice, both methods are often used together to design a comprehensive lightning protection system:\n\n" +
                          "• The Rolling Sphere Method determines where air terminals are needed, especially on irregular structures or buildings with multiple height levels.\n\n" +
                          "• The Mesh Method provides a well-distributed interception network for flat roof areas.\n\n" +
                          "• Both methods should be implemented according to the same protection level to ensure consistent protection.\n\n" +
                          "• The more critical the structure or its contents, the higher the protection level should be and the more comprehensive the implementation of both methods."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }
}
