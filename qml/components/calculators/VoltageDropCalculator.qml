import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"

WaveCard {
    id: voltageDropCard
    title: 'Voltage Drop Calculator'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 250
    
    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop

            RowLayout {
                spacing: 10
                Label {
                    text: "Cable Length (m):"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: cableLength
                    placeholderText: "Enter Length"
                    onTextChanged: voltageDropCalc.setLength(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Current (A):"
                    Layout.preferredWidth: 120
                }
                TextField {
                    id: loadCurrent
                    placeholderText: "Enter Current"
                    onTextChanged: voltageDropCalc.setCurrent(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Cable Size (mm²):"
                    Layout.preferredWidth: 120
                }
                ComboBox {
                    id: cableSize
                    model: ["1.5", "2.5", "4", "6", "10", "16", "25", "35", "50", "70", "95", "120"]
                    onCurrentTextChanged: {
                        if (currentText) {
                            // Call the slot method correctly
                            voltageDropCalc.setCableSize(parseFloat(currentText))
                        }
                    }
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Material:"
                    Layout.preferredWidth: 120
                }
                ComboBox {
                    id: conductorMaterial
                    model: ["Copper", "Aluminum"]
                    onCurrentTextChanged: {
                        if (currentText) {
                            // Call the slot method correctly
                            voltageDropCalc.setConductorMaterial(currentText)
                        }
                    }
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                }
            }

            RowLayout {
                spacing: 10
                Layout.topMargin: 5
                Label {
                    text: "Voltage Drop:"
                    Layout.preferredWidth: 120
                    font.bold: true
                }
                Text {
                    id: voltageDropResult
                    text: voltageDropCalc && !isNaN(voltageDropCalc.voltageDrop) ? 
                          voltageDropCalc.voltageDrop.toFixed(2) + "V" : "0.00V"
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    font.bold: true
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Drop Percentage:"
                    Layout.preferredWidth: 120
                }
                Text {
                    id: dropPercentage
                    text: voltageDropCalc && !isNaN(voltageDropCalc.dropPercentage) ? 
                          voltageDropCalc.dropPercentage.toFixed(2) + "%" : "0.00%"
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    color: voltageDropCalc && voltageDropCalc.dropPercentage > 3 ? "red" : "black"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: 200
            color: "transparent"
            
            Canvas {
                id: voltageDropCanvas
                anchors.fill: parent
                
                property real dropPercent: voltageDropCalc && !isNaN(voltageDropCalc.dropPercentage) ? 
                                         voltageDropCalc.dropPercentage : 0.0
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var width = voltageDropCanvas.width;
                    var height = voltageDropCanvas.height;
                    
                    // Draw cable
                    ctx.beginPath();
                    ctx.rect(50, height/2 - 15, width - 100, 30);
                    ctx.fillStyle = "#aaaaaa";
                    ctx.fill();
                    
                    // Draw source voltage
                    ctx.beginPath();
                    ctx.moveTo(30, height/2 - 40);
                    ctx.lineTo(30, height/2 + 40);
                    ctx.moveTo(10, height/2 - 20);
                    ctx.lineTo(30, height/2 - 20);
                    ctx.moveTo(10, height/2 + 20);
                    ctx.lineTo(30, height/2 + 20);
                    ctx.strokeStyle = "black";
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    
                    // Draw load
                    ctx.beginPath();
                    ctx.rect(width - 40, height/2 - 30, 20, 60);
                    ctx.fillStyle = "#dddddd";
                    ctx.fill();
                    ctx.strokeStyle = "black";
                    ctx.stroke();
                    
                    // Draw voltage levels
                    var startVoltage = height/2 - 50;
                    var endVoltage = startVoltage + (height/5 * dropPercent/100);
                    
                    // Voltage profile line
                    ctx.beginPath();
                    ctx.moveTo(50, startVoltage);
                    ctx.lineTo(width - 50, endVoltage);
                    ctx.strokeStyle = "blue";
                    ctx.lineWidth = 2;
                    ctx.stroke();
                    
                    // Add labels
                    ctx.font = "12px sans-serif";
                    ctx.fillStyle = "black";
                    ctx.fillText("Source", 20, height - 20);
                    ctx.fillText("Load", width - 40, height - 20);
                    ctx.fillText("100%", 55, startVoltage - 5);
                    ctx.fillText((100 - dropPercent).toFixed(1) + "%", width - 70, endVoltage - 5);
                }
            }
            
            // Fix the connections to use the right signal
            Connections {
                target: voltageDropCalc
                function onDropPercentageChanged() {
                    voltageDropCanvas.requestPaint()
                }
            }
        }
    }
}
