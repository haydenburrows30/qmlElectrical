import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts
import QtQuick.Window

import "../"
import "../style"
import "../popups"

// import RLC 1.0

Item {
    id: root
    anchors.fill: parent

    property var calculator
    property int currentMode: 0 // 0 for Gain, 1 for Impedance
    
    Connections {
        target: calculator
        function onFormattedDataChanged(data) {
            var gainSeries = rlcChartView.series(0)
            var resonantSeries = rlcChartView.series(1)
            
            gainSeries.clear()
            resonantSeries.clear()

            calculator.fill_series(gainSeries)

            resonantSeries.append(data[1][0].x, data[1][0].y)
            resonantSeries.append(data[1][1].x, data[1][1].y)
        }

        function onAxisRangeChanged() {
            axisX.min = calculator.axisXMin
            axisX.max = calculator.axisXMax
            axisY.min = calculator.axisYMin
            axisY.max = calculator.axisYMax
        }
        
        function onCircuitModeChanged(mode) {
            currentMode = mode
        }

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

    ChartView {
        id: rlcChartView
        antialiasing: true
        theme: Universal.theme
        anchors.fill: parent

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

            // Initialize with default values if calculator exists
            if (calculator) {
                calculator.setResistance(10.0)
                calculator.setInductance(0.1)
                calculator.setCapacitance(0.0001013)
                calculator.setFrequencyRange(0, 100)
            }
        }

        ValueAxis {
            id: axisX
            min: 0
            max: 1000
            tickCount: 10
            labelFormat: "\u00B0"
            titleText: "Frequency (Hz)"
        }

        ValueAxis {
            id: axisY
            min: 0
            max: 100
            tickCount: 10
            labelFormat: "%.3f"
            titleText: currentMode === 0 ? "Gain (ratio)" : "Impedance (Ω)"
        }
    }
}