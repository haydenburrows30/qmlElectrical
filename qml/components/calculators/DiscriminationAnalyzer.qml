import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../../components"

import DiscriminationAnalyzer 1.0

WaveCard {
    id: discriminationAnalyzerCard
    title: 'Discrimination Analysis'
    Layout.minimumWidth: 1000
    Layout.minimumHeight: 700
    Layout.fillWidth: true
    Layout.fillHeight: true

    property DiscriminationAnalyzer calculator: DiscriminationAnalyzer {}

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 20

        // Left Column - Controls and Results
        ColumnLayout {
            Layout.preferredWidth: 400
            Layout.fillHeight: true
            spacing: 10

            // Configuration Section
            GroupBox {
                title: "Configuration"
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 10

                    Text {
                        text: "Minimum Margin: " + marginSlider.value.toFixed(2) + "s"
                        font.bold: true
                    }
                    Slider {
                        id: marginSlider
                        Layout.fillWidth: true
                        from: 0.1
                        to: 1.0
                        value: calculator.minimumMargin
                        stepSize: 0.05
                        onValueChanged: calculator.minimumMargin = value
                    }
                }
            }

            // Relay Input Section
            GroupBox {
                title: "Add New Relay"
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 5
                    Text {
                        text: "Relays added: " + calculator.relayCount + " (minimum 2 needed)"
                        color: calculator.relayCount < 2 ? "red" : "green"
                        font.bold: true
                    }
                    
                    ComboBox {
                        id: curveType
                        Layout.fillWidth: true
                        model: calculator.curveTypes
                        currentIndex: 0
                    }

                    TextField {
                        id: relayName
                        Layout.fillWidth: true
                        placeholderText: "Relay Name"
                    }
                    TextField {
                        id: pickupCurrent
                        Layout.fillWidth: true
                        placeholderText: "Pickup Current (A)"
                        validator: DoubleValidator { bottom: 0 }
                    }
                    TextField {
                        id: tds
                        Layout.fillWidth: true
                        placeholderText: "Time Dial Setting"
                        validator: DoubleValidator { bottom: 0 }
                    }

                    RowLayout {
                        Button {
                            text: "Add Relay"
                            Layout.fillWidth: true
                            onClicked: {
                                if (!relayName.text || !pickupCurrent.text || !tds.text) {
                                    console.log("Please fill all relay fields")
                                    return
                                }
                                console.log("Adding relay:", relayName.text)
                                calculator.addRelay({
                                    "name": relayName.text,
                                    "pickup": parseFloat(pickupCurrent.text),
                                    "tds": parseFloat(tds.text),
                                    "curve_constants": calculator.getCurveConstants(curveType.currentText)
                                })
                            }
                        }
                        Button {
                            text: "Reset All"
                            Layout.fillWidth: true
                            onClicked: {
                                calculator.reset()
                                relayName.text = ""
                                pickupCurrent.text = ""
                                tds.text = ""
                                faultCurrent.text = ""
                                marginPoints.clear()
                            }
                        }
                    }
                }
            }

            // Fault Current Section
            GroupBox {
                title: "Fault Current Analysis"
                Layout.fillWidth: true

                ColumnLayout {
                    TextField {
                        id: faultCurrent
                        Layout.fillWidth: true
                        placeholderText: "Add Fault Current Level (A)"
                        validator: DoubleValidator { bottom: 0 }
                    }
                    Button {
                        text: "Add Fault Level"
                        Layout.fillWidth: true
                        onClicked: {
                            console.log("Adding fault level:", parseFloat(faultCurrent.text))
                            calculator.addFaultLevel(
                                parseFloat(faultCurrent.text)
                            )
                        }
                    }
                }
            }

            // Added Relays List
            GroupBox {
                title: "Added Relays"
                Layout.fillWidth: true
                Layout.preferredHeight: 150

                ListView {
                    anchors.fill: parent
                    model: calculator.relayList
                    spacing: 5
                    clip: true

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: relayInfo.height + 10
                        color: index % 2 ? "#f0f0f0" : "white"
                        radius: 3

                        Column {
                            id: relayInfo
                            width: parent.width
                            anchors.margins: 5
                            spacing: 2

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

            // Results Section
            GroupBox {
                title: "Discrimination Results"
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    model: calculator.results
                    clip: true

                    Text {
                        text: "Add at least 2 relays to see discrimination results"
                        visible: calculator.relayCount < 2
                        anchors.centerIn: parent
                        color: "gray"
                    }

                    delegate: Column {
                        required property var resultData  // Changed from modelData
                        width: ListView.view.width
                        spacing: 4
                        visible: resultData !== undefined && resultData !== null
                        
                        Text {
                            text: {
                                if (!resultData || !resultData.primary || !resultData.backup) return ""
                                return resultData.primary + " → " + resultData.backup
                            }
                            font.bold: true
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
                                color: modelData && modelData.coordinated ? "green" : "red"
                            }
                        }
                    }
                }
            }
        }

        // Right Column - Visualization
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 600
            color: "white"
            border.color: "#cccccc"
            border.width: 1
            radius: 4

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label {
                    width: parent.width
                    text: "Margin Analysis Chart"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }

                ChartView {
                    id: marginChart
                    width: parent.width
                    height: parent.height - parent.spacing - parent.children[0].height
                    antialiasing: true
                    legend.alignment: Qt.AlignBottom

                    ValueAxis {
                        id: marginAxis
                        min: 0
                        max: 10  // Increased to show more of the curves
                        titleText: "Time (s)"
                    }
                    
                    LogValueAxis {  // Changed to LogValueAxis
                        id: faultAxis
                        min: 100
                        max: 20000
                        titleText: "Fault Current (A)"
                        base: 10
                        labelFormat: "%.0f"
                    }

                    LineSeries {
                        id: marginLine
                        name: "Minimum Margin"
                        axisX: faultAxis
                        axisY: marginAxis
                        width: 2
                    }

                    ScatterSeries {
                        id: marginPoints
                        name: "Margin Points"
                        axisX: faultAxis
                        axisY: marginAxis
                        markerSize: 10
                    }

                    function updateMarginLine() {
                        marginLine.clear()
                        marginLine.append(faultAxis.min, calculator.minimumMargin)
                        marginLine.append(faultAxis.max, calculator.minimumMargin)
                    }

                    function createRelaySeries() {
                        console.log("Creating relay series...")
                        // Remove existing relay series
                        let seriesToRemove = []
                        for (let i = 0; i < marginChart.count; i++) {
                            let series = marginChart.series(i)
                            if (series !== marginLine && series !== marginPoints) {
                                seriesToRemove.push(series)
                            }
                        }
                        seriesToRemove.forEach(series => marginChart.removeSeries(series))

                        // Add new series for each relay
                        calculator.relayList.forEach(function(relay) {
                            console.log("Creating series for relay:", relay.name)
                            let series = marginChart.createSeries(ChartView.SeriesTypeLine, relay.name, faultAxis, marginAxis)
                            series.width = 2

                            // Generate curve points
                            const numPoints = 100
                            const minCurrent = Math.max(100, relay.pickup)
                            const maxCurrent = 20000
                            const step = (Math.log10(maxCurrent) - Math.log10(minCurrent)) / numPoints

                            for (let i = 0; i <= numPoints; i++) {
                                const current = Math.pow(10, Math.log10(minCurrent) + i * step)
                                const multiple = current / relay.pickup
                                if (multiple <= 1) continue
                                
                                const time = (relay.curve_constants.a * relay.tds) / 
                                           (Math.pow(multiple, relay.curve_constants.b) - 1)
                                if (isFinite(time) && time > 0 && time < 10) {
                                    series.append(current, time)
                                }
                            }
                        })
                    }

                    Component.onCompleted: {
                        createRelaySeries()
                        updateMarginLine()
                    }

                    Connections {
                        target: calculator
                        function onRelayCountChanged() {
                            marginChart.createRelaySeries()
                        }
                        function onMarginChanged() {
                            marginChart.updateMarginLine()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: calculator
        function onAnalysisComplete() {
            console.log("Analysis complete signal received")
            marginPoints.clear()
            let model = calculator.results
            console.log("Model rowCount:", model.rowCount())
            for(let i = 0; i < model.rowCount(); i++) {
                let modelIndex = model.index(i, 0)
                let result = model.data(modelIndex, calculator.results.DataRole)  // Fixed data role access
                console.log("Chart data for index", i, ":", JSON.stringify(result))
                if (result && result.margins) {
                    result.margins.forEach(function(margin) {
                        if (margin.fault_current && margin.margin != null && 
                            isFinite(margin.fault_current) && isFinite(margin.margin) &&
                            margin.margin > 0 && margin.margin < 10) {  // Add bounds check
                            marginPoints.append(margin.fault_current, margin.margin)
                        }
                    })
                }
            }
        }
    }
}
