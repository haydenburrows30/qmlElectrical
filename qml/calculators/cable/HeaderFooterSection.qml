import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"
import "../../components/buttons"
import "../../components/style"

ColumnLayout {

    property var calculator
    property int maxRevisions: 5  // Maximum number of revisions to display
    signal configChanged()

    GridLayout {
        Layout.fillWidth: true
        Layout.minimumHeight: 200
        columns: 2

        Label {
            text: "Header:"
            Layout.columnSpan: 2
            Layout.bottomMargin: 10
            font.bold: true
            font.pixelSize: 16
        }

        Label {
            text: "Customer Name:"
            Layout.minimumWidth: 150
        }
        
        TextFieldRound {
            id: customerNameField
            Layout.minimumWidth: 200
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
            Layout.minimumWidth: 150
        }
        
        TextFieldRound {
            id: customerEmailField
            Layout.minimumWidth: 200
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
            Layout.minimumWidth: 150
        }
        
        TextFieldRound {
            id: projectNameField
            Layout.minimumWidth: 200
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
            Layout.minimumWidth: 150
        }
        
        TextFieldRound {
            id: ornField
            Layout.minimumWidth: 200
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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        Label {
            text: "Revisions:"
            Layout.bottomMargin: 10
            font.bold: true
            font.pixelSize: 16
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 10
            
            Label {
                text: "Number of revisions:"
            }
            
            SpinBox {
                id: revisionCountSpinBox
                from: 1
                to: maxRevisions
                value: calculator ? (calculator.revisionCount || 1) : 1
                
                onValueChanged: {
                    if (calculator) {
                        calculator.revisionCount = value;
                        configChanged()
                    }
                }
            }
        }
        
        Repeater {
            id: revisionRepeater
            model: calculator ? calculator.revisionCount || 1 : 1
            
            delegate: Frame {
                Layout.fillWidth: true
                
                background: Rectangle {
                    color: index % 2 === 0 ? "#f0f0f0" : "#ffffff"
                    border.color: "#cccccc"
                    radius: 5
                }
                
                GridLayout {
                    columns: 2
                    columnSpacing: 10
                    rowSpacing: 10
                    anchors.fill: parent
                    
                    Label {
                        text: "Revision " + (index + 1) + ":"
                        font.bold: true
                        Layout.columnSpan: 2
                    }
                    
                    Label {
                        text: "Revision No.:"
                        Layout.minimumWidth: 150
                    }
                    
                    TextFieldRound {
                        id: revisionField
                        Layout.minimumWidth: 200
                        placeholderText: (index + 1).toString()
                        selectByMouse: true
                        text: calculator && calculator.revisions && calculator.revisions[index] ? 
                              calculator.revisions[index].number || (index + 1).toString() : 
                              (index + 1).toString()
                        
                        onTextChanged: {
                            if (calculator) {
                                if (!calculator.revisions) {
                                    calculator.revisions = [];
                                }
                                while (calculator.revisions.length <= index) {
                                    calculator.revisions.push({});
                                }
                                calculator.revisions[index].number = text;
                                configChanged();
                            }
                        }
                    }
                    
                    Label {
                        text: "Revision Description:"
                        Layout.minimumWidth: 150
                    }
                    
                    TextFieldRound {
                        id: revisionDescField
                        Layout.minimumWidth: 200
                        Layout.fillWidth: true
                        placeholderText: "Enter revision description"
                        selectByMouse: true
                        text: calculator && calculator.revisions && calculator.revisions[index] ? 
                              calculator.revisions[index].description || "" : ""
                        
                        onTextChanged: {
                            if (calculator) {
                                if (!calculator.revisions) {
                                    calculator.revisions = [];
                                }
                                while (calculator.revisions.length <= index) {
                                    calculator.revisions.push({});
                                }
                                calculator.revisions[index].description = text;
                                configChanged();
                            }
                        }
                    }
                    
                    Label {
                        text: "Designer:"
                        Layout.minimumWidth: 150
                    }
                    
                    TextFieldRound {
                        id: designerField
                        Layout.minimumWidth: 200
                        placeholderText: "Enter designer name"
                        selectByMouse: true
                        text: calculator && calculator.revisions && calculator.revisions[index] ? 
                              calculator.revisions[index].designer || calculator.designer || "" : 
                              (calculator ? calculator.designer || "" : "")
                        
                        onTextChanged: {
                            if (calculator) {
                                if (!calculator.revisions) {
                                    calculator.revisions = [];
                                }
                                while (calculator.revisions.length <= index) {
                                    calculator.revisions.push({});
                                }
                                calculator.revisions[index].designer = text;
                                if (index === 0 && (!calculator.designer || calculator.designer === "")) {
                                    calculator.designer = text;
                                }
                                configChanged();
                            }
                        }
                    }
                    
                    Label {
                        text: "Date:"
                        Layout.minimumWidth: 150
                    }
                    
                    TextFieldRound {
                        id: dateField
                        Layout.minimumWidth: 200
                        placeholderText: Qt.formatDate(new Date(), "dd/MM/yyyy")
                        selectByMouse: true
                        text: calculator && calculator.revisions && calculator.revisions[index] ? 
                              calculator.revisions[index].date || "" : ""
                        
                        onTextChanged: {
                            if (calculator) {
                                if (!calculator.revisions) {
                                    calculator.revisions = [];
                                }
                                while (calculator.revisions.length <= index) {
                                    calculator.revisions.push({});
                                }
                                calculator.revisions[index].date = text;
                                configChanged();
                            }
                        }
                    }
                    
                    Label {
                        text: "Checked by:"
                        Layout.minimumWidth: 150
                    }
                    
                    TextFieldRound {
                        id: checkedByField
                        Layout.minimumWidth: 200
                        placeholderText: "Enter checker name"
                        selectByMouse: true
                        text: calculator && calculator.revisions && calculator.revisions[index] ? 
                              calculator.revisions[index].checkedBy || calculator.checkedBy || "" : 
                              (calculator ? calculator.checkedBy || "" : "")
                        
                        onTextChanged: {
                            if (calculator) {
                                if (!calculator.revisions) {
                                    calculator.revisions = [];
                                }
                                while (calculator.revisions.length <= index) {
                                    calculator.revisions.push({});
                                }
                                calculator.revisions[index].checkedBy = text;
                                if (index === 0 && (!calculator.checkedBy || calculator.checkedBy === "")) {
                                    calculator.checkedBy = text;
                                }
                                configChanged();
                            }
                        }
                    }
                }
            }
        }
    }
}