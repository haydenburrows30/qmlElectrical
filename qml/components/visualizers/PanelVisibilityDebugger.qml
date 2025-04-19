import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// A small utility to help debug panel visibility issues
Rectangle {
    width: 300
    height: 150
    color: "lightgray"
    opacity: 0.9
    radius: 8
    
    property var calculator
    property var diagram
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5
        
        Label {
            text: "Panel Visibility Debug:"
            font.bold: true
        }
        
        Label {
            text: calculator ? 
                "Calculator SL: " + calculator.showStreetlightingPanel + 
                ", SP: " + calculator.showServicePanel :
                "No calculator connected"
            Layout.fillWidth: true
        }
        
        Label {
            text: diagram ? 
                "Diagram SL: " + diagram.showStreetlightingPanel + 
                ", SP: " + diagram.showServicePanel :
                "No diagram connected"
            Layout.fillWidth: true
        }
        
        RowLayout {
            Button {
                text: "Force Diagram Update"
                onClicked: {
                    if (diagram) {
                        diagram.updatePanelVisibility()
                        diagram.forceRefresh()
                    }
                }
            }
            
            Button {
                text: "Direct Set True"
                onClicked: {
                    if (diagram) {
                        diagram.showStreetlightingPanel = true
                        diagram.showServicePanel = true
                        diagram.forceRefresh()
                    }
                }
            }
            
            Button {
                text: "Direct Set False"
                onClicked: {
                    if (diagram) {
                        diagram.showStreetlightingPanel = false
                        diagram.showServicePanel = false
                        diagram.forceRefresh()
                    }
                }
            }
        }
    }
}
