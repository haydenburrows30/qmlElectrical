import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal

import "../"
import "../../components"
import "../style"
import "../backgrounds"

import DiscriminationAnalyzer 1.0

Item {
    id: discriminationAnalyzerCard
    Layout.fillWidth: true
    Layout.fillHeight: true

    property DiscriminationAnalyzer calculator: DiscriminationAnalyzer {}

    Popup {
        id: tipsPopup
        width: 500
        height: 300
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open

        onAboutToHide: {
            results.open = false
        }
        Text {
            anchors.fill: parent
            text: {"<h3>Discrimination Analyzer</h3><br>" +
                    "This tool analyzes the discrimination between relays in a protection system.<br><br>" +
                    "The user can add multiple relays with their pickup current and time dial setting (TDS).<br>" +
                    "The tool calculates the minimum margin between the primary and backup relays for different fault levels.<br><br>" +
                    "The visualization shows the margin analysis chart with the relay curves and margin points.<br><br>" +
                    "Developed by <b>Wave</b>."
            }
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Style.spacing

        // Left Column - Controls and Results
        ColumnLayout {
            Layout.maximumWidth: 300
            Layout.minimumWidth: 300
            Layout.fillHeight: true
            spacing: Style.spacing

            // Configuration Section
            WaveCard {
                title: "Configuration"
                Layout.fillWidth: true
                Layout.minimumHeight: 130

                id: results
                showSettings: true
                
                ColumnLayout {
                    spacing: Style.spacing
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        text: "Minimum Margin: "
                    }
                    RowLayout {

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
                    }
                }
            }

            // Relay Input Section
            WaveCard {
                title: "Add New Relay"
                Layout.fillWidth: true
                Layout.minimumHeight: 280

                ColumnLayout {
                    spacing: Style.spacing
                    Text {
                        text: "Relays added: " + calculator.relayCount + " (minimum 2 needed)"
                        color: calculator.relayCount < 2 ? 
                               Universal.theme === Universal.Dark ? "#ff8080" : "red" : 
                               Universal.theme === Universal.Dark ? "#90EE90" : "green"
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
            WaveCard {  
                title: "Fault Current Analysis"
                Layout.fillWidth: true
                Layout.minimumHeight: 120

                RowLayout {
                    spacing: Style.spacing
                    uniformCellSizes: true
                    Layout.fillWidth: true

                    TextField {
                        id: faultCurrent
                        Layout.fillWidth: true
                        placeholderText: "Add Fault Current Level (A)"
                        validator: DoubleValidator { bottom: 0 }
                    }
                    Button {
                        text: "Add Fault Level"
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
            WaveCard {
                title: "Added Relays"
                Layout.fillWidth: true
                Layout.preferredHeight: 180

                ListView {
                    anchors.fill: parent
                    model: calculator.relayList
                    spacing: Style.spacing
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
            WaveCard {
                title: "Discrimination Results"
                Layout.fillWidth: true
                Layout.fillHeight: true
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
            Layout.fillHeight: true

            Column {
                anchors.fill: parent
                anchors.margins: 10
                spacing: Style.spacing

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

                    theme: Universal.theme

                    ValueAxis {
                        id: marginAxis
                        min: 0
                        max: 10
                        titleText: "Time (s)"
                    }
                    
                    LogValueAxis {
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
                let result = model.data(modelIndex, calculator.results.DataRole)
                console.log("Chart data for index", i, ":", JSON.stringify(result))
                if (result && result.margins) {
                    result.margins.forEach(function(margin) {
                        if (margin.fault_current && margin.margin != null && 
                            isFinite(margin.fault_current) && isFinite(margin.margin) &&
                            margin.margin > 0 && margin.margin < 10) {
                            marginPoints.append(margin.fault_current, margin.margin)
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
