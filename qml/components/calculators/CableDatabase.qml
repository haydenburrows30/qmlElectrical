import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../components"
import "../buttons"

import components 1.0

Page {
    id: root
    padding: 0
    
    background: Rectangle {
        color: window.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        ColumnLayout {
            width: scrollView.width
            
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: window.modeToggled ? "#2d2d2d" : "#e0e0e0"
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    
                    
                    Label {
                        text: "Cable Database"
                        font.pixelSize: 22
                        font.bold: true
                        color: window.modeToggled ? "#ffffff" : "#000000"
                    }
                    
                    Label {
                        text: "Manage cable data, import and export cables, and view cable properties."
                        Layout.fillWidth: true
                        color: window.modeToggled ? "#cccccc" : "#444444"
                    }
                }
            }
            
            // Main content
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 10
                
                // Cable data editor
                CableDataEditor {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 600
                }
                
                // Side panel for reference data
                ColumnLayout {
                    Layout.preferredWidth: 350
                    Layout.fillHeight: true
                    
                    // Cable reference data
                    WaveCard {
                        title: "Cable Standards"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 250
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            
                            Label {
                                text: "Cable Types and Standards"
                                font.bold: true
                                font.pixelSize: 14
                            }
                            
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                
                                Text {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: "Common standards for cables include:\n\n" +
                                          "• AS/NZS 3008 - Selection of cables\n" +
                                          "• AS/NZS 5000 - Electric cables\n" +
                                          "• IEC 60502 - Power cables\n" +
                                          "• IEC 60364 - Electrical installations\n\n" +
                                          "Common insulation types:\n\n" +
                                          "• PVC - Polyvinyl Chloride\n" +
                                          "• XLPE - Cross-linked Polyethylene\n" +
                                          "• EPR - Ethylene Propylene Rubber\n" +
                                          "• LSF - Low Smoke & Fume\n" +
                                          "• LSZH - Low Smoke Zero Halogen"
                                }
                            }
                        }
                    }
                    
                    // Material properties
                    WaveCard {
                        title: "Material Properties"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            
                            Label {
                                text: "Conductor Material Properties"
                                font.bold: true
                                font.pixelSize: 14
                            }
                            
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 3
                                
                                Label { text: "Property"; font.bold: true }
                                Label { text: "Copper"; font.bold: true }
                                Label { text: "Aluminum"; font.bold: true }
                                
                                Label { text: "Resistivity (Ω·m)" }
                                Label { text: "1.68 × 10⁻⁸" }
                                Label { text: "2.82 × 10⁻⁸" }
                                
                                Label { text: "Density (kg/m³)" }
                                Label { text: "8,960" }
                                Label { text: "2,700" }
                                
                                Label { text: "Thermal Conductivity (W/m·K)" }
                                Label { text: "401" }
                                Label { text: "237" }
                                
                                Label { text: "Melting Point (°C)" }
                                Label { text: "1,085" }
                                Label { text: "660" }
                                
                                Label { text: "Specific Heat (J/kg·K)" }
                                Label { text: "385" }
                                Label { text: "900" }
                            }
                            
                            Label {
                                text: "Temperature Considerations"
                                font.bold: true
                                font.pixelSize: 14
                                Layout.topMargin: 10
                            }
                            
                            Text {
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                text: "Cable ratings typically specify maximum continuous operating temperatures:\n\n" +
                                      "• PVC: 70°C to 90°C\n" +
                                      "• XLPE: 90°C\n" +
                                      "• EPR: 90°C\n\n" +
                                      "Short-circuit temperature limits:\n" +
                                      "• Cu with PVC insulation: 160°C\n" +
                                      "• Cu with XLPE insulation: 250°C\n" +
                                      "• Al with PVC insulation: 160°C\n" +
                                      "• Al with XLPE insulation: 250°C"
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Message popup
    Popup {
        id: messagePopup
        width: 400
        height: 200
        anchors.centerIn: Overlay.overlay
        modal: true
        
        property bool isError: false
        property string messageText: ""
        
        function showError(message) {
            messageText = message
            isError = true
            open()
        }
        
        function showSuccess(message) {
            messageText = message
            isError = false
            open()
        }
        
        ColumnLayout {
            anchors.fill: parent
            
            
            Label {
                text: messagePopup.isError ? "Error" : "Success"
                font.pixelSize: 18
                font.bold: true
                color: messagePopup.isError ? "#cc0000" : "#007acc"
                Layout.alignment: Qt.AlignHCenter
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Text {
                    width: parent.width
                    text: messagePopup.messageText
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            StyledButton {
                text: "Close"
                Layout.alignment: Qt.AlignHCenter
                onClicked: messagePopup.close()
                icon.source "../../icons/rounded/close.svg"
            }
        }
    }
    
    // Connect signals from cable manager
    Connections {
        target: cableManager
        function onSaveError(message) {
            messagePopup.showError(message)
        }
        function onSaveSuccess(message) {
            messagePopup.showSuccess(message)
        }
    }
}