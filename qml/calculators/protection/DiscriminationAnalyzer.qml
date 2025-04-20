import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal
import QtQuick.Dialogs

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
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Discrimination Analyzer</h3><br>" +
                    "This tool analyzes the discrimination between relays in a protection system.<br><br>" +
                    "The user can add multiple relays with their pickup current and time dial setting (TDS).<br><br>" +
                    "The tool calculates the minimum margin between the primary and backup relays for different fault levels.<br><br>" +
                    "The visualization shows the margin analysis chart with the relay curves and margin points.<br><br>" +
                    "Developed by <b>Wave</b>."
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true

        Flickable {
            id: flickableMain
            contentWidth: parent.width
            contentHeight: mainLayout.height + 20
            bottomMargin : 5
            leftMargin : 5
            rightMargin : 5
            topMargin : 5

            ColumnLayout {
                id: mainLayout
                width: flickableMain.width -20

                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Discrimination Analysis"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    StyledButton {
                        icon.source: "../../../icons/rounded/restart_alt.svg"
                        ToolTip.text: "Reset to default values"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500

                        onClicked: {
                            calculator.reset()
                            relayName.text = ""
                            pickupCurrent.text = ""
                            tds.text = ""
                            faultCurrent.text = ""
                            
                            // Use the complete chart reset function
                            marginChart.resetChart()
                            
                            // Reset the checkbox
                            showFaultPoints.checked = false
                        }
                    }

                    StyledButton {
                        id: helpButton
                        icon.source: "../../../icons/rounded/info.svg"
                        ToolTip.text: "Information"
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        onClicked: popUpText.open()
                    }
                }

                RowLayout {

                    // Left Column - Controls and Results
                    ColumnLayout {
                        id: leftColumn
                        Layout.maximumWidth: 400
                        Layout.minimumWidth: 400

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
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

                                    enabled: relayName.text && pickupCurrent.text && tds.text

                                    icon.source: "../../../icons/rounded/add.svg"

                                    onClicked: {
                                        // Add input validation with user feedback
                                        if (!relayName.text) {
                                            relayName.focus = true
                                            // console.log("Please enter a relay name")
                                        } else if (!pickupCurrent.text || parseFloat(pickupCurrent.text) <= 0) {
                                            pickupCurrent.focus = true
                                            // console.log("Please enter a valid pickup current")
                                        } else if (!tds.text || parseFloat(tds.text) <= 0) {
                                            tds.focus = true
                                            // console.log("Please enter a valid time dial setting")
                                        } else {
                                            // console.log("Adding relay:", relayName.text)

                                            calculator.addRelay({
                                                "name": relayName.text,
                                                "pickup": parseFloat(pickupCurrent.text),
                                                "tds": parseFloat(tds.text),
                                                "curve_constants": calculator.getCurveConstants(curveType.currentText)
                                            })
                                            
                                            // Clear fields after adding relay for better UX
                                            relayName.text = ""
                                            pickupCurrent.text = ""
                                            tds.text = ""
                                            relayName.focus = true
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
                                    color: Universal.theme === Universal.Dark ? 
                                           Qt.rgba(0.2, 0.2, 0.2, 0.3) : 
                                           Qt.rgba(0.9, 0.9, 0.9, 0.3)

                                    RowLayout {
                                        width: parent.width - 10
                                        anchors.centerIn: parent

                                        Column {
                                            id: relayInfo
                                            Layout.fillWidth: true

                                            Text {
                                                width: parent.width
                                                text: modelData ? modelData.name : ""
                                                font.bold: true
                                                color: Universal.foreground
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.width
                                                text: modelData ? "Pickup: " + modelData.pickup + "A" : ""
                                                font.pixelSize: 12
                                                color: Universal.foreground
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                width: parent.width
                                                text: modelData ? "TDS: " + modelData.tds : ""
                                                font.pixelSize: 12
                                                color: Universal.foreground
                                                elide: Text.ElideRight
                                            }
                                        }

                                        StyledButton {
                                            icon.source: "../../../icons/rounded/delete.svg"
                                            icon.color: Universal.theme === Universal.Dark ? "#ff8080" : "red"
                                            
                                            ToolTip.text: "Remove Relay " + modelData.name
                                            ToolTip.visible: hovered
                                            ToolTip.delay: 500

                                            onClicked: {
                                                calculator.removeRelay(index)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Configuration Section
                        WaveCard {
                            title: "Configuration"
                            
                            Layout.fillWidth: true
                            Layout.minimumHeight: 250
                            
                            GridLayout {
                                id: showFaultPointsGrid
                                columns: 3
                                anchors.fill: parent

                                Label {text: "Margin: "}

                                Slider {
                                    id: marginSlider
                                    Layout.minimumWidth: 200
                                    Layout.fillWidth: true
                                    enabled: calculator.relayCount >= 2
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
                                    enabled: calculator.relayCount >= 2 && faultCurrent.text

                                    ToolTip.text: "Add Fault Level"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

                                    icon.source: "../../../icons/rounded/add.svg"

                                    onClicked: {
                                        if (calculator.relayCount < 2) {
                                            // console.log("Please add at least 2 relays")
                                        } else if (!faultCurrent.text || parseFloat(faultCurrent.text) <= 0) {
                                            faultCurrent.focus = true
                                            // console.log("Please enter a valid fault current")
                                        } else {
                                            let current = parseFloat(faultCurrent.text)
                                            // console.log("Adding fault level:", current)
                                            calculator.addFaultLevel(current)
                                            faultCurrent.text = ""  // Clear after adding
                                            faultCurrent.focus = true
                                        }
                                    }
                                }

                                Label {
                                    text: "Export Data: "
                                    visible: calculator.relayCount >= 2
                                }

                                StyledButton {
                                    id: exportButton
                                    text: "Export Results"
                                    Layout.columnSpan: 2

                                    ToolTip.text: "Export results to PDF"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    visible: calculator.relayCount >= 2
                                    icon.source: "../../../icons/rounded/download.svg"
                                    
                                    onClicked: {
                                        let filename = calculator.exportResults()
                                        if (filename) {
                                            exportSuccessPopup.filepath = filename
                                            exportSuccessPopup.open()
                                        } else {
                                            // Show error message
                                        }
                                    }
                                }

                                Label {
                                    text: "Show Fault Points: "
                                    visible: calculator.relayCount >= 2
                                }

                                CheckBox {
                                    id: showFaultPoints
                                    checked: false
                                    Layout.columnSpan: 1
                                    visible: calculator.relayCount >= 2
                                    
                                    onCheckedChanged: {
                                        showFaultPointsGrid.updateFaultPoints()
                                    }
                                }
                                
                                StyledButton {
                                    icon.source: "../../../icons/rounded/refresh.svg"
                                    visible: calculator.relayCount >= 2 && showFaultPoints.checked

                                    ToolTip.text: "Refresh Fault Points"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        showFaultPointsGrid.updateFaultPoints();
                                    }
                                }

                                function updateFaultPoints() {
                                    marginChart.updateFaultPoints(
                                        calculator.faultPoints, 
                                        showFaultPoints && showFaultPoints.checked
                                    );
                                }
                            }
                        }

                        // Results Section
                        WaveCard {
                            title: "Discrimination Results"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 250

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: "System Coordination Status: " + 
                                          (calculator.isFullyCoordinated ? "Fully Coordinated" : "Coordination Issues")
                                    visible: calculator.relayCount >= 2
                                    font.bold: true
                                    color: calculator.isFullyCoordinated ? 
                                           Universal.theme === Universal.Dark ? "#90EE90" : "green" : 
                                           Universal.theme === Universal.Dark ? "#ff8080" : "red"
                                    Layout.fillWidth: true
                                }

                                ListView {
                                    id: resultsList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
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
                                        
                                        Rectangle {
                                            width: parent.width
                                            height: headerText.height + 8
                                            color: resultData.coordinated ? 
                                                   Universal.theme === Universal.Dark ? Qt.rgba(0, 0.5, 0, 0.2) : Qt.rgba(0, 0.8, 0, 0.1) : 
                                                   Universal.theme === Universal.Dark ? Qt.rgba(0.5, 0, 0, 0.2) : Qt.rgba(0.8, 0, 0, 0.1)
                                            radius: 3

                                            Text {
                                                id: headerText
                                                anchors.centerIn: parent
                                                width: parent.width - 16
                                                text: {
                                                    if (!resultData || !resultData.primary || !resultData.backup) return ""
                                                    return resultData.primary + " → " + resultData.backup + 
                                                           (resultData.coordinated ? " (Coordinated)" : " (Coordination Issue)")
                                                }
                                                font.bold: true
                                                color: Universal.foreground
                                            }
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
                                                        modelData.margin.toFixed(2) + "s " +
                                                        (modelData.coordinated ? "✓" : "✗")
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
                    }

                    // Right Column - Visualization
                    WaveCard {
                        Layout.fillWidth: true
                        Layout.minimumHeight: leftColumn.height

                        ColumnLayout {
                            width: parent.width
                            height: parent.height
                            spacing: 10

                            Label {
                                Layout.fillWidth: true
                                text: "Time-Current Curves and Margin Analysis"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }

                            DiscriminationChart {
                                id: marginChart
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                            }
                        }
                    }
                }
            }
        }
    }

    // Export success popup
    Popup {
        id: exportSuccessPopup
        anchors.centerIn: parent
        width: 400
        height: 180
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property string filepath: ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Label {
                text: "Results Exported Successfully"
                font.bold: true
                font.pixelSize: 16
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                text: "File saved to:\n" + exportSuccessPopup.filepath
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                onClicked: exportSuccessPopup.close()
            }
        }
    }

    Connections {
        target: calculator
        
        function onAnalysisComplete() {
            marginChart.scatterSeries.clear()
            let model = calculator.results
            try {
                for(let i = 0; i < model.rowCount(); i++) {
                    let modelIndex = model.index(i, 0)
                    let result = model.data(modelIndex, calculator.results.DataRole)
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
                
                // Update fault points after the analysis is complete
                Qt.callLater(function() {
                    if (showFaultPoints && showFaultPoints.checked) {
                        showFaultPointsGrid.updateFaultPoints();
                    }
                });
            } catch (e) {
                console.error("Error updating chart:", e)
            }
        }
        
        function onRelayCountChanged() {
            marginChart.createRelaySeries()
        }
        
        function onMarginChanged() {
            marginChart.updateMarginLine()
        }
        
        function onExportChart(filename) {
            marginChart.saveChartImage(filename)
        }
    }
    
    Connections {
        target: marginChart
        
        function onSvgContentReady(svgContent, filename) {
            calculator.saveSvgContent(svgContent, filename)
        }
    }
        
    Component.onCompleted: {
        // Wait for all components to be fully initialized before accessing them
        Qt.callLater(function() {
            // Initialize chart if it exists
            if (marginChart && marginChart.createRelaySeries) {
                marginChart.createRelaySeries();
            }
        });
    }
}
