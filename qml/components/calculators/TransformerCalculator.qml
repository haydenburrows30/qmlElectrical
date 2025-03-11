import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../../components"

WaveCard {
    id: transformerCalculator
    title: 'Transformer Calculator'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 250
    info: "../../media/transformer_formula.png"

    RowLayout {
        anchors.fill: parent

        ColumnLayout {
            Layout.alignment: Qt.AlignTop

            RowLayout {
                spacing: 10
                Label {
                    text: "Primary V:"
                    Layout.preferredWidth: 100
                }
                TextField {
                    id: primaryVoltage
                    placeholderText: "Primary Voltage"
                    onTextChanged: transformerCalc.setPrimaryVoltage(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    validator: DoubleValidator { bottom: 0 }
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Secondary V:"
                    Layout.preferredWidth: 100
                }
                TextField {
                    id: secondaryVoltage
                    placeholderText: "Secondary Voltage"
                    onTextChanged: transformerCalc.setSecondaryVoltage(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    validator: DoubleValidator { bottom: 0 }
                }
            }

            RowLayout {
                spacing: 10
                Label {
                    text: "Primary I:"
                    Layout.preferredWidth: 100
                }
                TextField {
                    id: primaryCurrent
                    placeholderText: "Primary Current"
                    onTextChanged: transformerCalc.setPrimaryCurrent(parseFloat(text))
                    Layout.preferredWidth: 120
                    Layout.alignment: Qt.AlignRight
                    validator: DoubleValidator { bottom: 0 }
                }
            }

            GroupBox {
                title: "Results"
                Layout.fillWidth: true
                Layout.topMargin: 10

                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    RowLayout {
                        Label {
                            text: "Secondary I:"
                            Layout.preferredWidth: 100
                        }
                        Text {
                            text: transformerCalc.secondaryCurrent.toFixed(2) + " A"
                            Layout.preferredWidth: 120
                            font.bold: true
                        }
                    }

                    RowLayout {
                        Label {
                            text: "Turns Ratio:"
                            Layout.preferredWidth: 100
                        }
                        Text {
                            text: transformerCalc.turnsRatio.toFixed(2)
                            Layout.preferredWidth: 120
                            font.bold: true
                        }
                    }
                }
            }
        }

        // Transformer Visualization
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            
            Image {
                source: "../../media/transformer_diagram.png"
                anchors.centerIn: parent
                width: parent.width * 0.7
                height: parent.height * 0.7
                fillMode: Image.PreserveAspectFit
            }
            
            // Ratio visualization
            Canvas {
                id: ratioCanvas
                anchors.fill: parent
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var ratio = transformerCalc.turnsRatio;
                    if (isNaN(ratio) || !isFinite(ratio)) return;
                    
                    // Draw arrows indicating transformation ratio
                    ctx.strokeStyle = "blue";
                    ctx.fillStyle = "blue";
                    ctx.lineWidth = 2;
                    
                    // Primary side arrow
                    var startX = width * 0.2;
                    var endX = width * 0.4;
                    var y = height * 0.5;
                    
                    ctx.beginPath();
                    ctx.moveTo(startX, y);
                    ctx.lineTo(endX, y);
                    ctx.stroke();
                    
                    // Secondary side arrow
                    startX = width * 0.6;
                    endX = width * 0.8;
                    
                    ctx.beginPath();
                    ctx.moveTo(startX, y);
                    ctx.lineTo(endX, y);
                    ctx.stroke();
                    
                    // Add ratio labels
                    ctx.font = "12px sans-serif";
                    ctx.textAlign = "center";
                    ctx.fillText(primaryVoltage.text + "V", width * 0.3, y - 10);
                    ctx.fillText(secondaryVoltage.text + "V", width * 0.7, y - 10);
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turns Ratio: " + transformerCalc.turnsRatio.toFixed(2)
                font.bold: true
            }
        }
    }

    // Update visualization when values change
    Connections {
        target: transformerCalc
        function onTurnsRatioChanged() {
            ratioCanvas.requestPaint()
        }
    }
}
