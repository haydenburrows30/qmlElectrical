import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts
import QtCore

import QtQuick.Studio.DesignEffects

import '../components'

Page {
    id: phasor

    background: Rectangle {
        color: toolBar.toggle ? "#1a1a1a" : "#f5f5f5"
    }

    Connections {
        target: seriesRLCChart
        function onFormattedDataChanged(data) {
            var gainSeries = rlcChartView.series(0)
            var resonantSeries = rlcChartView.series(1)
            
            gainSeries.clear()
            resonantSeries.clear()
            
            // Use Python fill_series for gain data
            seriesRLCChart.fill_series(gainSeries)
            
            // Fill resonant line directly since it's just 2 points
            resonantSeries.append(data[1][0].x, data[1][0].y)
            resonantSeries.append(data[1][1].x, data[1][1].y)
        }

        function onAxisRangeChanged() {
            axisX.min = seriesRLCChart.axisXMin
            axisX.max = seriesRLCChart.axisXMax
            axisY.min = seriesRLCChart.axisYMin
            axisY.max = seriesRLCChart.axisYMax
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentHeight: mainLayout.height
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                anchors.fill: parent
                spacing: 5

                WaveCard {
                    title: 'Series RLC Frequency Response'
                    Layout.minimumHeight: 700
                    Layout.minimumWidth: 330
                    Layout.fillHeight: true

                    showInfo: false
                    
                    GridLayout {
                        columns: 2

                        Label {
                            text: "Resistance (Ω):"
                            Layout.preferredWidth: 150
                        }

                        TextField {
                            id: resistanceInput
                            placeholderText: "Enter Resistance"
                            text: "10"  // Default value
                            onTextChanged: seriesRLCChart.setResistance(parseFloat(text))
                            Layout.preferredWidth: 150
                            Layout.alignment: Qt.AlignRight
                        }

                        Label {
                            text: "Inductance (H):"
                            Layout.preferredWidth: 150
                        }

                        TextField {
                            id: inductanceInput1
                            placeholderText: "Enter Inductance"
                            text: "0.1"  // Default value
                            onTextChanged: seriesRLCChart.setInductance(parseFloat(text))
                            Layout.preferredWidth: 150
                            Layout.alignment: Qt.AlignRight
                        }

                        Label {
                            text: "Capacitance (F):"
                            Layout.preferredWidth: 150
                        }

                        TextField {
                            id: capacitanceInput1
                            placeholderText: "Enter Capacitance"
                            text: "0.0001013"  // 101.3µF
                            onTextChanged: seriesRLCChart.setCapacitance(parseFloat(text))
                            Layout.preferredWidth: 150
                            Layout.alignment: Qt.AlignRight
                        }

                        Label {
                            text: "Frequency (Hz):"
                            Layout.preferredWidth: 150
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            TextField {
                                id: minFreqInput
                                placeholderText: "Min"
                                text: "0"
                                onTextChanged: {
                                    var min = Number(text);
                                    var max = Number(maxFreqInput.text);
                                    if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                                        seriesRLCChart.setFrequencyRange(min, max);
                                    }
                                }
                                validator: DoubleValidator {
                                    bottom: 0
                                    decimals: 1
                                }
                            }

                            Label {
                                text: "to"
                            }

                            TextField {
                                id: maxFreqInput
                                placeholderText: "Max"
                                text: "100"
                                onTextChanged: {
                                    var min = Number(minFreqInput.text);
                                    var max = Number(text);
                                    if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                                        seriesRLCChart.setFrequencyRange(min, max);
                                    }
                                }
                                validator: DoubleValidator {
                                    bottom: 0
                                    decimals: 1
                                }
                            }
                        }

                        Label {
                            text: "Resonant Frequency:"
                            Layout.preferredWidth: 150
                            Layout.fillWidth:  true
                            
                        }
                        Label {
                            text: seriesRLCChart.resonantFreq.toFixed(2) + " Hz"
                            Layout.preferredWidth: 150
                            Layout.alignment: Qt.AlignHCenter
                            color: "red"
                        }

                        Button {
                            text: "Reset All Values"
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            onClicked: {
                                seriesRLCChart.resetValues()
                                resistanceInput.text = "10"
                                inductanceInput1.text = "0.1"
                                capacitanceInput1.text = "0.0001013"
                                minFreqInput.text = "0"
                                maxFreqInput.text = "100"
                            }
                        }
                    }
                }

                WaveCard {
                    title: 'Series RLC Chart'
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    showInfo: false

                    ColumnLayout {
                        anchors.fill: parent

                        ChartView {
                            id: rlcChartView
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            antialiasing: true

                            theme: Universal.theme

                            MouseArea {
                                anchors.fill: parent
                                drag.target: dragTarget
                                drag.axis: Drag.XAxis
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                hoverEnabled: true

                                onDoubleClicked: {
                                    rlcChartView.zoomReset()
                                }

                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        contextMenu.popup()
                                    }
                                }

                                onWheel: (wheel)=> {
                                    if (wheel.angleDelta.y > 0) {
                                        rlcChartView.zoom(0.9)
                                    } else {
                                        rlcChartView.zoom(1.1)
                                    }
                                }
                            }

                            Menu {
                                id: contextMenu
                                title: "Chart Options"
                                
                                Menu {
                                    id: resolutionMenu
                                    title: "Resolution"
                                    
                                    MenuItem {
                                        text: "1x"
                                        checkable: true
                                        checked: resolutionComboBox.currentIndex === 0
                                        onTriggered: resolutionComboBox.currentIndex = 0
                                    }
                                    
                                    MenuItem {
                                        text: "2x"
                                        checkable: true
                                        checked: resolutionComboBox.currentIndex === 1
                                        onTriggered: resolutionComboBox.currentIndex = 1
                                    }
                                    
                                    MenuItem {
                                        text: "4x"
                                        checkable: true
                                        checked: resolutionComboBox.currentIndex === 2
                                        onTriggered: resolutionComboBox.currentIndex = 2
                                    }
                                }
                                
                                MenuItem {
                                    text: "Save Chart (" + resolutionComboBox.model[resolutionComboBox.currentIndex] + ")"
                                    onTriggered: saveDialog.open()
                                }
                                
                                MenuSeparator {}
                                
                                MenuItem {
                                    text: "Reset Zoom"
                                    onTriggered: rlcChartView.zoomReset()
                                }
                            }

                            Item {
                                id: dragTarget

                                property real oldX : x
                                property real oldY : y

                                onXChanged: {
                                    rlcChartView.scrollLeft( x - oldX );
                                    oldX = x;
                                }
                                onYChanged: {
                                    rlcChartView.scrollUp( y - oldY );
                                    oldY = y;
                                }
                            }

                            Component.onCompleted: {
                                var gainSeries = createSeries(ChartView.SeriesTypeLine, "Gain", axisX, axisY)

                                gainSeries.color = "blue"
                                gainSeries.width = 2
                                
                                var resonantSeries = createSeries(ChartView.SeriesTypeLine, "Resonant Frequency", axisX, axisY)
                                resonantSeries.color = "red"
                                resonantSeries.width = 2
                                resonantSeries.style = Qt.DashLine

                                // Initialize with default values
                                seriesRLCChart.setResistance(10.0)
                                seriesRLCChart.setInductance(0.1)
                                seriesRLCChart.setCapacitance(0.0001013)
                                seriesRLCChart.setFrequencyRange(0, 100)
                            }

                            ValueAxis {
                                id: axisX
                                min: 0
                                max: 1000
                                tickCount: 10
                                labelFormat: "%.1f"
                                titleText: "Frequency (Hz)"
                            }

                            ValueAxis {
                                id: axisY
                                min: 0
                                max: 100
                                tickCount: 10
                                labelFormat: "%.3f"
                                titleText: "Gain (ratio)"
                            }
                        }
                    }
                }
            }
        }
    }

    // Hide the bottom controls since we now have context menu
    RowLayout {
        id: saveControls
        visible: false  // Hide these controls, using context menu instead
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        spacing: 10
        
        ComboBox {
            id: resolutionComboBox
            model: ["1x", "2x", "4x"]
            property var scaleValues: [1.0, 2.0, 4.0]
            property real scaleFactor: scaleValues[currentIndex]
            Layout.preferredWidth: 100
        }
        
        Button {
            text: "Save Chart"
            icon.name: "document-save"
            onClicked: saveDialog.open()
        }
    }

    FileDialog {
        id: saveDialog
        title: "Save Chart"
        nameFilters: ["PNG files (*.png)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "png"
        currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
        
        // Generate default filename with timestamp
        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "rlc_chart_" + timestamp + ".png"
        }
        
        onAccepted: {
            seriesRLCChart.saveChart(selectedFile, resolutionComboBox.scaleFactor)  // Update to use scaleFactor
        }
    }

    Connections {
        target: seriesRLCChart
        function onGrabRequested(filepath, scale) {
            console.log("Grabbing image to:", filepath, "with scale:", scale)
            rlcChartView.grabToImage(function(result) {
                if (result) {
                    result.saveToFile(filepath)
                }
            }, Qt.size(rlcChartView.width * scale, rlcChartView.height * scale))
        }
    }
}

