import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"
import "../../components/buttons"
import "../../components/style"

ColumnLayout {
    id: root
    spacing: 10
    
    property var calculator
    signal configChanged()
    
    GridLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        columns: 2
        rowSpacing: 10
        columnSpacing: 10
        
        Label {
            text: "Customer Name:"
            Layout.preferredWidth: 120
        }
        
        TextFieldRound {
            id: customerNameField
            Layout.fillWidth: true
            placeholderText: "Enter customer name"
            selectByMouse: true
            text: calculator ? calculator.customerName : ""
            
            onTextChanged: {
                if (calculator && calculator.customerName !== text) {
                    calculator.customerName = text
                    configChanged()
                }
            }
        }
        
        Label {
            text: "Customer Email:"
            Layout.preferredWidth: 120
        }
        
        TextFieldRound {
            id: customerEmailField
            Layout.fillWidth: true
            placeholderText: "Enter customer email"
            selectByMouse: true
            text: calculator ? calculator.customerEmail : ""
            
            onTextChanged: {
                if (calculator && calculator.customerEmail !== text) {
                    calculator.customerEmail = text
                    configChanged()
                }
            }
        }
        
        Label {
            text: "Project Name:"
            Layout.preferredWidth: 120
        }
        
        TextFieldRound {
            id: projectNameField
            Layout.fillWidth: true
            placeholderText: "Enter project name"
            selectByMouse: true
            text: calculator ? calculator.projectName : ""
            
            onTextChanged: {
                if (calculator && calculator.projectName !== text) {
                    calculator.projectName = text
                    configChanged()
                }
            }
        }
        
        Label {
            text: "ORN:"
            Layout.preferredWidth: 120
        }
        
        TextFieldRound {
            id: ornField
            Layout.fillWidth: true
            placeholderText: "Enter ORN"
            selectByMouse: true
            text: calculator ? calculator.orn : ""
            
            onTextChanged: {
                if (calculator && calculator.orn !== text) {
                    calculator.orn = text
                    configChanged()
                }
            }
        }
    }
}
