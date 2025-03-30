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

import RealTime 1.0

Page {
    id: realTime

    property RealTimeChart calculator: RealTimeChart {}
    property color textColor: sideBar.toggle1 ? "#ffffff" : "#000000"

    background: Rectangle {
        color: sideBar.toggle1 ? "#1a1a1a" : "#f5f5f5"
    }

    FontLoader {
        id: iconFont
        source: "../../icons/MaterialIcons-Regular.ttf"
    }

    RealTimePopup {
        id: tipsPopup
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
                spacing: Style.spacing

                //Settings
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.minimumWidth: 350
                    Layout.maximumWidth: 350
                    spacing: Style.spacing

                    ButtonCard {
                        Layout.fillWidth: true
                        Layout.minimumHeight: 80

                        RowLayout {
                            anchors.centerIn: parent

                            ShadowRectangle {
                                Layout.alignment: Qt.AlignLeft
                                implicitHeight: 52
                                implicitWidth: 52
                                radius: implicitHeight / 2

                                ImageButton {
                                    id: pauseButton
                                    anchors.centerIn: parent
                                    iconName: calculator.isRunning ? '\ue034' : '\ue037'
                                    iconWidth: 24
                                    iconHeight: 24
                                    color: calculator.isRunning ? Style.red : Style.green
                                    backgroundColor: Style.alphaColor(color,0.1)

                                    ToolTip.text: "Pause/Run"
                                    ToolTip.visible: pauseButton.hovered
                                    ToolTip.delay: 500

                                    onClicked: {
                                        calculator.toggleRunning()
                                    }
                                }
                            }
                            ShadowRectangle {
                                Layout.alignment: Qt.AlignLeft
                                implicitHeight: 52
                                implicitWidth: 52
                                radius: implicitHeight / 2

                                ImageButton {
                                    id: resetButton
                                    anchors.centerIn: parent
                                    iconName: '\uf053'
                                    iconWidth: 24
                                    iconHeight: 24
                                    color: Style.blueGreen
                                    backgroundColor: Style.alphaColor(color,0.1)

                                    ToolTip.text: "Reset"
                                    ToolTip.visible: resetButton.hovered
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        calculator.restart()
                                    }
                                }
                            }

                            ShadowRectangle {
                                Layout.alignment: Qt.AlignRight
                                implicitHeight: 52
                                implicitWidth: 52
                                radius: implicitHeight / 2

                                ImageButton {
                                    id: saveButton
                                    anchors.centerIn: parent
                                    iconName: '\ue161'
                                    iconWidth: 24
                                    iconHeight: 24
                                    color: Style.black
                                    backgroundColor: Style.alphaColor(color,0.1)

                                    ToolTip.text: "Save parameters"
                                    ToolTip.visible: saveButton.hovered
                                    ToolTip.delay: 500

                                    onClicked: {
                                        calculator.saveConfiguration()
                                    }
                                }
                            }
                            ShadowRectangle {
                                id: loadButton
                                Layout.alignment: Qt.AlignRight
                                implicitHeight: 52
                                implicitWidth: 52
                                radius: implicitHeight / 2

                                ImageButton {
                                    anchors.centerIn: parent
                                    iconName: '\ue2c6'
                                    iconWidth: 24
                                    iconHeight: 24
                                    color: Style.charcoalGrey
                                    backgroundColor: Style.alphaColor(color,0.1)

                                    ToolTip.text: "Load parameters"
                                    ToolTip.visible: loadButton.hovered
                                    ToolTip.delay: 500

                                    onClicked: {
                                        calculator.loadConfiguration()
                                    }
                                }
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
                            spacing: Style.spacing
                            Layout.fillWidth: true
                            
                            Repeater {
                                model: [{name: "Alpha", color: "#ff0000"}, 
                                    {name: "Beta", color: "#00cc00"}, 
                                    {name: "Gamma", color: "#0000ff"}]
                                RowLayout {
                                    Layout.minimumWidth: 300
                                    spacing: Style.spacing
                                    Label { 
                                        text: modelData.name
                                        color: modelData.color
                                        Layout.minimumWidth: 80
                                        font.bold: true
                                    }
                                    ComboBox {
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
                                        spacing: Style.spacing
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

                    color: sideBar.toggle1 ? "black" : "white"

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