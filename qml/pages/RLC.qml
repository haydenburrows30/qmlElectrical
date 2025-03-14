import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts
import QtCore

import '../components'

Page {
    id: phasor

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
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
                            validator: DoubleValidator {
                                bottom: 0.0001
                                decimals: 4
                                notation: DoubleValidator.ScientificNotation
                            }
                            onTextChanged: {
                                if (!acceptableInput) {
                                    messagePopup.showError("Invalid resistance value")
                                    return
                                }
                                seriesRLCChart.setResistance(parseFloat(text))
                            }
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
                            validator: DoubleValidator {
                                bottom: 0.0001
                                decimals: 4
                                notation: DoubleValidator.ScientificNotation
                            }
                            onTextChanged: {
                                if (!acceptableInput) {
                                    messagePopup.showError("Invalid inductance value")
                                    return
                                }
                                seriesRLCChart.setInductance(parseFloat(text))
                            }
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
                            validator: DoubleValidator {
                                bottom: 0.0001
                                decimals: 6
                                notation: DoubleValidator.ScientificNotation
                            }
                            onTextChanged: {
                                if (!acceptableInput) {
                                    messagePopup.showError("Invalid capacitance value")
                                    return
                                }
                                seriesRLCChart.setCapacitance(parseFloat(text))
                            }
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
                                    if (!acceptableInput) {
                                        messagePopup.showError("Invalid minimum frequency")
                                        return
                                    }
                                    var min = Number(text)
                                    var max = Number(maxFreqInput.text)
                                    if (!isNaN(min) && !isNaN(max)) {
                                        if (min < 0) {
                                            messagePopup.showError("Minimum frequency cannot be negative")
                                            return
                                        }
                                        if (max <= min) {
                                            messagePopup.showError("Maximum frequency must be greater than minimum")
                                            return
                                        }
                                        seriesRLCChart.setFrequencyRange(min, max)
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
                                    var min = Number(minFreqInput.text)
                                    var max = Number(text)
                                    if (!isNaN(min) && !isNaN(max) && min >= 0 && max > min) {
                                        seriesRLCChart.setFrequencyRange(min, max)
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
                                    title: "Save Chart"
                                    
                                    MenuItem {
                                        text: "Standard Quality (1x)"
                                        onTriggered: {
                                            saveDialog.currentScale = 1.0
                                            saveDialog.open()
                                        }
                                    }
                                    
                                    MenuItem {
                                        text: "High Quality (2x)"
                                        onTriggered: {
                                            saveDialog.currentScale = 2.0
                                            saveDialog.open()
                                        }
                                    }
                                    
                                    MenuItem {
                                        text: "Ultra Quality (4x)"
                                        onTriggered: {
                                            saveDialog.currentScale = 4.0
                                            saveDialog.open()
                                        }
                                    }
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

    FileDialog {
        id: saveDialog
        title: "Save Chart"
        nameFilters: ["PNG files (*.png)", "All files (*)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "png"
        currentFolder: Qt.platform.os === "windows" ? "file:///C:" : "file:///home"
        
        // Add property to track the selected scale
        property real currentScale: 2.0
        
        // Generate default filename with timestamp
        currentFile: {
            let timestamp = new Date().toISOString().replace(/[:.]/g, '-')
            return "rlc_chart_" + timestamp + ".png"
        }
        
        onAccepted: {
            // Use the selected scale factor
            seriesRLCChart.saveChart(selectedFile, currentScale)
        }
    }

    Connections {
        target: seriesRLCChart
        function onGrabRequested(filepath, scale) {
            loadingIndicator.visible = true
            console.log("Grabbing image to:", filepath, "with scale:", scale)
            rlcChartView.grabToImage(function(result) {
                loadingIndicator.visible = false
                if (result) {
                    var saved = result.saveToFile(filepath)
                    if (saved) {
                        messagePopup.showSuccess("Chart saved successfully")
                    } else {
                        messagePopup.showError("Failed to save chart")
                    }
                } else {
                    messagePopup.showError("Failed to grab chart image")
                }
            }, Qt.size(rlcChartView.width * scale, rlcChartView.height * scale))
        }
    }

    // Add message popup for feedback
    Popup {
        id: messagePopup
        modal: true
        focus: true
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 200
        
        property string messageText: ""
        property bool isError: false
        
        function showSuccess(message) {
            messageText = message
            isError = false
            open()
        }
        
        function showError(message) {
            messageText = message
            isError = true
            open()
        }

        contentItem: ColumnLayout {
            Label {
                text: messagePopup.messageText
                wrapMode: Text.WordWrap
                color: messagePopup.isError ? "red" : (sideBar.toggle1 ? "#ffffff" : "#000000")
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: messagePopup.close()
            }
        }
    }

    // Add loading indicator
    BusyIndicator {
        id: loadingIndicator
        anchors.centerIn: parent
        visible: false
        running: visible
        z: 999
        
        Rectangle {
            anchors.fill: parent
            color: "#80000000"
            visible: parent.visible
        }
    }
}

