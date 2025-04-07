import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtCharts
import QtQuick.Window

import "../components"
import "../components/charts/"
import "../components/style"
import "../components/popups"
import "../components/buttons"

import RealTime 1.0

Page {
    id: realTime

    property RealTimeChart calculator: RealTimeChart {}
    property color textColor: sideBar.modeToggled ? "#ffffff" : "#000000"

    background: Rectangle {
        color: sideBar.modeToggled ? "#1a1a1a" : "#f5f5f5"
    }

    PopUpText {
        widthFactor: 0.8
        heightFactor: 0.8
        parentCard: results
        popupText: "<h1>Real Time Chart</h1><br>\
            This example demonstrates a real-time chart that displays three waveforms \
            with different frequencies, amplitudes, offsets, and phases. The chart updates \
            every 100ms and shows the last 30 seconds of data. You can adjust the wave \
            parameters and wave types in the sidebar. The chart also includes a tracker \
            line that displays the values of the three waveforms at the current time. \
            You can hover over the chart to see the values at a specific time. \
            <br><br>\
            <b>Wave Types:</b><br>\
            The wave types are Sine, Square, Sawtooth, and Triangle. You can select the \
            wave type for each waveform.\
            <br><br>\
            <b>Parameters:</b><br>\
            You can adjust the frequency, amplitude, offset, and phase for each waveform. \
            The frequency is in Hz, the amplitude is in units, the offset is in units, and \
            the phase is in radians.\
            <br><br>\
            <b>Controls:</b><br>\
            You can pause or resume the chart, restart the chart, and save or load the \
            configuration.\
            <br><br>\
            <b>Configuration:</b><br>\
            You can save the current configuration to a file and load a configuration from \
            a file. The configuration includes the wave types, frequencies, amplitudes, \
            offsets, and phases.\
            <br><br>\
            <b>Real Time Chart:</b><br>\
            The real-time chart displays the three waveforms over the last 30 seconds. \
            The chart updates every 100ms. You can hover over the chart to see the values \
            of the waveforms at a specific time. The chart also includes a tracker line that \
            displays the values of the waveforms at the current time.\
            <br><br>\
            <b>Chart Controls:</b><br>\
            You can pause or resume the chart, restart the chart, and save or load the \
            configuration. The chart also includes a tracker line that displays the values \
            of the waveforms at the current time. You can hover over the chart to see the \
            values of the waveforms at a specific time."
    }

    onVisibleChanged: {
        if (rtChart && rtChart.visible) {
            rtChart.isActive = visible
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 10
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            RowLayout {
                id: mainLayout
                width: scrollView.width
                anchors.left: parent.left
                
                //Settings
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.minimumWidth: 350
                    Layout.maximumWidth: 350

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        Layout.minimumHeight: 50

                        StyledButton {
                            id: pauseButton
                            
                            ToolTip.text: "Pause/Run"
                            ToolTip.visible: pauseButton.hovered
                            ToolTip.delay: 500

                            icon.source: calculator.isRunning ? "../../icons/svg/pause/baseline.svg" : "../../icons/svg/play_arrow/baseline.svg"

                            onClicked: {
                                calculator.toggleRunning()
                            }
                        }

                        StyledButton {
                            id: resetButton

                            ToolTip.text: "Reset"
                            ToolTip.visible: resetButton.hovered
                            ToolTip.delay: 500
                            icon.source: "../../icons/svg/restart_alt/baseline.svg"
                            
                            onClicked: {
                                calculator.restart()
                            }
                        }

                        StyledButton {
                            id: saveButton

                            ToolTip.text: "Save parameters"
                            ToolTip.visible: saveButton.hovered
                            ToolTip.delay: 500
                            icon.source: "../../icons/svg/save/baseline.svg"

                            onClicked: {
                                calculator.saveConfiguration()
                            }
                        }

                        StyledButton {
                            id: loadButton

                            ToolTip.text: "Load parameters"
                            ToolTip.visible: loadButton.hovered
                            ToolTip.delay: 500
                            icon.source: "../../icons/svg/folder_open/baseline.svg"

                            onClicked: {
                                calculator.loadConfiguration()
                            }
                        }
                    }
                    
                    // Wave type controls
                    WaveCard {
                        title: "Wave Types"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 180
                        id: results
                        showSettings: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            
                            Repeater {
                                model: [{name: "Alpha", color: "#ff0000"}, 
                                    {name: "Beta", color: "#00cc00"}, 
                                    {name: "Gamma", color: "#0000ff"}]
                                RowLayout {
                                    Layout.minimumWidth: 300
                                    
                                    Label { 
                                        text: modelData.name
                                        color: modelData.color
                                        Layout.minimumWidth: 80
                                        font.bold: true
                                    }
                                    ComboBoxRound {
                                        id: waveTypeCombo
                                        model: ["Sine", "Square", "Sawtooth", "Triangle"]
                                        Layout.fillWidth: true
                                        onCurrentIndexChanged: calculator.setWaveType(index, currentIndex)
                                    }
                                }
                            }
                        }
                    }

                    // Wave parameters
                    WaveCard {
                        title: "Parameters"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 650
                        
                        ColumnLayout {
                            Layout.fillWidth: true

                            Repeater {
                                model: ["Alpha", "Beta", "Gamma"]
                                Column {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 300
                                    property int index: modelData === "Alpha" ? 0 : modelData === "Beta" ? 1 : 2
                                    property color waveColor: index === 0 ? "#ff0000" : index === 1 ? "#00cc00" : "#0000ff"
                                    
                                    Label { 
                                        text: modelData
                                        color: parent.waveColor 
                                        font.bold: true
                                        bottomPadding: 10
                                    }
                                    
                                    Grid {
                                        columns: 2
                                        
                                        width: parent.width

                                        Label { text: "Frequency:" }
                                        Slider {
                                            id: freqSlider
                                            width: parent.width - 70
                                            from: 0.1; to: 2.0
                                            Component.onCompleted: value = calculator.frequencies[index]
                                            onMoved: calculator.setFrequency(index, value)
                                        }
                                        
                                        Label { text: "Amplitude:" }
                                        Slider {
                                            id: ampSlider
                                            width: parent.width - 70
                                            from: 10; to: 100
                                            Component.onCompleted: value = calculator.amplitudes[index]
                                            onMoved: calculator.setAmplitude(index, value)
                                        }
                                        
                                        Label { text: "Offset:" }
                                        Slider {
                                            id: offsetSlider
                                            width: parent.width - 70
                                            from: 50; to: 250
                                            Component.onCompleted: value = calculator.offsets[index]
                                            onMoved: calculator.setOffset(index, value)
                                        }
                                        
                                        Label { text: "Phase:" }
                                        Slider {
                                            id: phaseSlider
                                            width: parent.width - 70
                                            from: -Math.PI; to: Math.PI
                                            Component.onCompleted: value = calculator.phases[index]
                                            onMoved: calculator.setPhase(index, value)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Chart
                WaveCard {
                    title: "Real Time Chart"
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    color: sideBar.modeToggled ? "black" : "white"

                    RealChart {
                        id: rtChart
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        isActive: realTime.visible
                        calculator: realTime.calculator //pass calculator to chart
                    }
                }
            }
        }
    }
}