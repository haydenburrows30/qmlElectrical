import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal


import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"
import "../../components/charts"

import DiscriminationAnalyzer 1.0

Item {
    id: discriminationAnalyzerCard

    property DiscriminationAnalyzer calculator: DiscriminationAnalyzer {}
    
    PopUpText {
        id: tipsPopup
        parentCard: results
        popupText: "<h3>Discrimination Analyzer</h3><br>" +
                    "This tool analyzes the discrimination between relays in a protection system.<br><br>" +
                    "The user can add multiple relays with their pickup current and time dial setting (TDS).<br>" +
                    "The tool calculates the minimum margin between the primary and backup relays for different fault levels.<br><br>" +
                    "The visualization shows the margin analysis chart with the relay curves and margin points.<br><br>" +
                    "Developed by <b>Wave</b>."
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
                
                // Left Column - Controls and Results
                ColumnLayout {
                    id: leftColumn
                    Layout.maximumWidth: 400
                    Layout.minimumWidth: 400

                    RowLayout {

                        StyledButton {
                            icon.source: "../../../icons/rounded/restart_alt.svg"

                            onClicked: {
                                calculator.reset()
                                relayName.text = ""
                                pickupCurrent.text = ""
                                tds.text = ""
                                faultCurrent.text = ""
                                marginChart.scatterSeries.clear()
                            }
                        }

                        StyledButton {
                            id: results
                            icon.source: "../../../icons/rounded/info.svg"
                            onClicked: {
                                tipsPopup.open()
                            }
                        }
                    }

                    // Relay Input Section
                    WaveCard {
                        title: "Add New Relay"

                        Layout.fillWidth: true
                        Layout.minimumHeight: 240

                        RowLayout {
                            anchors.fill: parent

                            ColumnLayout {

                                Label {
                                    Layout.columnSpan: 2
                                    text: "Relays added: " + calculator.relayCount + " (minimum 2 needed)"
                                    color: calculator.relayCount < 2 ? 
                                        Universal.theme === Universal.Dark ? "#ff8080" : "red" : 
                                        Universal.theme === Universal.Dark ? "#90EE90" : "green"
                                    font.bold: true
                                }
                                
                                ComboBoxRound {
                                    id: curveType
                                    Layout.fillWidth: true
                                    Layout.columnSpan: 2
                                    model: calculator.curveTypes
                                    currentIndex: 0
                                }

                                TextFieldRound {
                                    id: relayName
                                    Layout.fillWidth: true
                                    placeholderText: "Relay Name"
                                }

                                TextFieldRound {
                                    id: pickupCurrent
                                    Layout.fillWidth: true
                                    placeholderText: "Pickup Current (A)"
                                    validator: DoubleValidator { bottom: 0 }
                                }
                                
                                TextFieldRound {
                                    id: tds
                                    Layout.fillWidth: true
                                    placeholderText: "Time Dial Setting"
                                    validator: DoubleValidator { bottom: 0 }
                                }
                            }

                            StyledButton {
                                Layout.alignment: Qt.AlignVCenter
                                
                                ToolTip.text: "Add Relay"
                                icon.source: "../../../icons/rounded/add.svg"

                                onClicked: {

                                    if (!relayName.text || !pickupCurrent.text || !tds.text) {
                                        console.log("Please fill all relay fields")
                                    } else {
                                        console.log("Adding relay:", relayName.text)

                                        calculator.addRelay({
                                            "name": relayName.text,
                                            "pickup": parseFloat(pickupCurrent.text),
                                            "tds": parseFloat(tds.text),
                                            "curve_constants": calculator.getCurveConstants(curveType.currentText)
                                            })
                                    }
                                }
                            }
                        }
                    }

                    // Added Relays List
                    WaveCard {
                        title: "Relays"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180

                        ListView {
                            anchors.fill: parent
                            model: calculator.relayList
                            
                            clip: true

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: ListView.view.width
                                height: relayInfo.height + 10
                                radius: 3

                                Column {
                                    id: relayInfo
                                    width: parent.width

                                    Text {
                                        width: parent.width
                                        text: modelData ? modelData.name : ""
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: modelData ? "Pickup: " + modelData.pickup + "A" : ""
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: modelData ? "TDS: " + modelData.tds : ""
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }

                    // Configuration Section
                    WaveCard {
                        title: "Configuration"
                        
                        Layout.fillWidth: true
                        Layout.minimumHeight: 180
                        
                        GridLayout {
                            columns: 3
                            anchors.fill: parent
                            // uniformCellHeights: true

                            Label {text: "Margin: "}

                            Slider {
                                id: marginSlider
                                Layout.minimumWidth: 200
                                Layout.fillWidth: true
                                from: 0.1
                                to: 1.0
                                value: calculator.minimumMargin
                                stepSize: 0.05
                                onValueChanged: calculator.minimumMargin = value
                            }

                            Label {
                                text: marginSlider.value.toFixed(2) + "s"
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Label {
                                text: "Fault Level: "
                                Layout.alignment: Qt.AlignVCenter
                            }

                            TextFieldRound {
                                id: faultCurrent
                                Layout.fillWidth: true

                                placeholderText: "Add Fault Current Level (A)"
                                validator: DoubleValidator { bottom: 0 }
                                enabled: calculator.relayCount >= 2
                            }

                            StyledButton {
                                id: addFaultLevel
                                Layout.alignment: Qt.AlignHCenter
                                
                                ToolTip.text: "Add Fault Level"
                                icon.source: "../../../icons/rounded/add.svg"

                                onClicked: {

                                    if (calculator.relayCount < 2) {
                                        console.log ("Please add at least 2 relays")
                                    } else if (calculator.relayCount >= 2 && !faultCurrent.text) {
                                        console.log("Please enter a number")
                                    } else {
                                        console.log("Adding fault level:", parseFloat(faultCurrent.text))
                                        calculator.addFaultLevel(parseFloat(faultCurrent.text))
                                    }
                                }
                            }
                        }
                    }

                    // Results Section
                    WaveCard {
                        title: "Discrimination Results"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 200

                        ListView {
                            id: resultsList
                            anchors.fill: parent
                            model: calculator.results
                            clip: true

                            Text {
                                text: "Add at least 2 relays to see discrimination results"
                                visible: calculator.relayCount < 2
                                anchors.fill: parent
                                color: Universal.foreground
                                wrapMode: Text.Wrap

                            }

                            delegate: Column {
                                required property var resultData
                                width: ListView.view.width
                                spacing: 4
                                visible: resultData !== undefined && resultData !== null
                                
                                Text {
                                    text: {
                                        if (!resultData || !resultData.primary || !resultData.backup) return ""
                                        return resultData.primary + " → " + resultData.backup
                                    }
                                    font.bold: true
                                    color: Universal.foreground
                                }
                                Repeater {
                                    model: (resultData && resultData.margins) ? resultData.margins : []
                                    delegate: Text {
                                        required property var modelData
                                        visible: modelData !== undefined && modelData !== null
                                        text: {
                                            if (!modelData || !modelData.fault_current || modelData.margin === undefined) 
                                                return ""
                                            return "  " + modelData.fault_current.toFixed(1) + "A: " + 
                                                modelData.margin.toFixed(2) + "s"
                                        }
                                        color: modelData && modelData.coordinated ? 
                                            Universal.theme === Universal.Dark ? "#90EE90" : "green" : 
                                            Universal.theme === Universal.Dark ? "#ff8080" : "red"
                                    }
                                }
                            }
                        }
                    }
                }

                // Right Column - Visualization
                WaveCard {
                    Layout.fillWidth: true
                    // Layout.fillHeight: true
                    Layout.minimumHeight: leftColumn.height

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        

                        Label {
                            width: parent.width
                            text: "Margin Analysis Chart"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        DiscriminationChart {id: marginChart}

                    }
                }
            }
        }
    }

    Connections {
        target: calculator
        function onAnalysisComplete() {
            console.log("Analysis complete signal received")
            marginChart.scatterSeries.clear()
            let model = calculator.results
            console.log("Model rowCount:", model.rowCount())
            for(let i = 0; i < model.rowCount(); i++) {
                let modelIndex = model.index(i, 0)
                let result = model.data(modelIndex, calculator.results.DataRole)
                console.log("Chart data for index", i, ":", JSON.stringify(result))
                if (result && result.margins) {
                    result.margins.forEach(function(margin) {
                        if (margin.fault_current && margin.margin != null && 
                            isFinite(margin.fault_current) && isFinite(margin.margin) &&
                            margin.margin > 0 && margin.margin < 10) {
                            marginChart.scatterSeries.append(margin.fault_current, margin.margin)
                        }
                    })
                }
            }
        }

        function onRelayCountChanged() {
            marginChart.createRelaySeries()
        }
        function onMarginChanged() {
            marginChart.updateMarginLine()
        }
    }
}
