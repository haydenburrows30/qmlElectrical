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
    property string applicationDirPath: Qt.application.directoryPath || "."
    property bool isDestructing: false  // Add this flag to track destruction
    
    function safeCalculatorProperty(propertyName, defaultValue) {
        if (isDestructing || !calculator) return defaultValue
        return calculator[propertyName]
    }
    
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

    MessagePopup {
        id: messagePopup
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
                            if (!isDestructing && calculator) {
                                calculator.reset()
                                relayName.text = ""
                                pickupCurrent.text = ""
                                tds.text = ""
                                faultCurrent.text = ""
                                marginChart.resetChart()
                                showFaultPoints.checked = false
                                
                                // Reset axis controls
                                xAxisMin.text = marginChart.getXAxisMin().toString()
                                xAxisMax.text = marginChart.getXAxisMax().toString()
                                yAxisMin.text = marginChart.getYAxisMin().toString()
                                yAxisMax.text = marginChart.getYAxisMax().toString()
                            }
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

                    ColumnLayout {
                        id: leftColumn
                        Layout.maximumWidth: 400
                        Layout.minimumWidth: 400

                        WaveCard {
                            title: "Add New Relay"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 240

                            RowLayout {
                                anchors.fill: parent

                                ColumnLayout {

                                    Label {
                                        Layout.columnSpan: 2
                                        text: "Relays added: " + safeCalculatorProperty("relayCount", 0) + " (minimum 2 needed)"
                                        color: safeCalculatorProperty("relayCount", 0) < 2 ? 
                                            Universal.theme === Universal.Dark ? "#ff8080" : "red" : 
                                            Universal.theme === Universal.Dark ? "#90EE90" : "green"
                                        font.bold: true
                                    }
                                    
                                    ComboBoxRound {
                                        id: curveType
                                        Layout.fillWidth: true
                                        Layout.columnSpan: 2
                                        model: safeCalculatorProperty("curveTypes", [])
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
                                        if (isDestructing || !calculator) return
                                        
                                        if (!relayName.text) {
                                            relayName.focus = true
                                        } else if (!pickupCurrent.text || parseFloat(pickupCurrent.text) <= 0) {
                                            pickupCurrent.focus = true
                                        } else if (!tds.text || parseFloat(tds.text) <= 0) {
                                            tds.focus = true
                                        } else {
                                            calculator.addRelay({
                                                "name": relayName.text,
                                                "pickup": parseFloat(pickupCurrent.text),
                                                "tds": parseFloat(tds.text),
                                                "curve_constants": calculator.getCurveConstants(curveType.currentText)
                                            })
                                            relayName.text = ""
                                            pickupCurrent.text = ""
                                            tds.text = ""
                                            relayName.focus = true
                                        }
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Relays"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180

                            ListView {
                                anchors.fill: parent
                                model: safeCalculatorProperty("relayList", [])
                                
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
                                                if (!isDestructing && calculator) {
                                                    calculator.removeRelay(index)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

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
                                    enabled: safeCalculatorProperty("relayCount", 0) >= 2
                                    from: 0.1
                                    to: 1.0
                                    value: safeCalculatorProperty("minimumMargin", 0.1)
                                    stepSize: 0.01
                                    onValueChanged: {
                                        if (!isDestructing && calculator) {
                                            calculator.minimumMargin = value
                                        }
                                    }
                                }

                                Label {
                                    text: marginSlider.value.toFixed(2) + "s"
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Label {text: "Current Level: "}

                                TextFieldRound {
                                    id: currentLevelSlider
                                    Layout.fillWidth: true
                                    text: "100"
                                    placeholderText: "Current Level (A)"

                                    onEditingFinished: {
                                        if (!isDestructing && calculator) {
                                            calculator.currentLevel = parseFloat(text)
                                        }
                                    }
                                }

                                Label {}

                                Label {
                                    text: "Fault Level: "
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                TextFieldRound {
                                    id: faultCurrent
                                    Layout.fillWidth: true
                                    placeholderText: "Add Fault Current Level (A)"
                                    validator: DoubleValidator { bottom: 0 }
                                    enabled: safeCalculatorProperty("relayCount", 0) >= 2
                                }

                                StyledButton {
                                    id: addFaultLevel
                                    Layout.alignment: Qt.AlignHCenter
                                    enabled: safeCalculatorProperty("relayCount", 0) >= 2 && faultCurrent.text

                                    ToolTip.text: "Add Fault Level"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500

                                    icon.source: "../../../icons/rounded/add.svg"

                                    onClicked: {
                                        if (isDestructing || !calculator) return
                                        
                                        if (safeCalculatorProperty("relayCount", 0) < 2) {
                                        } else if (!faultCurrent.text || parseFloat(faultCurrent.text) <= 0) {
                                            faultCurrent.focus = true
                                        } else {
                                            let current = parseFloat(faultCurrent.text)
                                            calculator.addFaultLevel(current)
                                            faultCurrent.text = ""
                                            faultCurrent.focus = true
                                        }
                                    }
                                }

                                Label {
                                    text: "Export Data: "
                                    visible: safeCalculatorProperty("relayCount", 0) >= 2
                                }

                                StyledButton {
                                    id: exportButton
                                    text: "Export Results"
                                    Layout.columnSpan: 2

                                    ToolTip.text: "Export results to PDF"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    visible: safeCalculatorProperty("relayCount", 0) >= 2
                                    icon.source: "../../../icons/rounded/download.svg"

                                    onClicked: {
                                        if (isDestructing || !calculator || !marginChart) return
                                            calculator.exportResults()
                                    }
                                }

                                Label {
                                    text: "Show Fault Points: "
                                    visible: safeCalculatorProperty("relayCount", 0) >= 2
                                }

                                CheckBox {
                                    id: showFaultPoints
                                    checked: false
                                    Layout.columnSpan: 1
                                    visible: safeCalculatorProperty("relayCount", 0) >= 2
                                    
                                    onCheckedChanged: {
                                        showFaultPointsGrid.updateFaultPoints()
                                    }
                                }
                                
                                StyledButton {
                                    icon.source: "../../../icons/rounded/refresh.svg"
                                    visible: safeCalculatorProperty("relayCount", 0) >= 2 && showFaultPoints.checked

                                    ToolTip.text: "Refresh Fault Points"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        showFaultPointsGrid.updateFaultPoints();
                                    }
                                }

                                function updateFaultPoints() {
                                    if (!isDestructing && calculator) {
                                        marginChart.updateFaultPoints(
                                            calculator.faultPoints, 
                                            showFaultPoints && showFaultPoints.checked
                                        );
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Axis Configuration"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 250
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent

                                // X-Axis Controls
                                Label {
                                    text: "X-Axis Min (A): "
                                    Layout.columnSpan: 1
                                }

                                TextFieldRound {
                                    id: xAxisMin
                                    Layout.fillWidth: true
                                    text: "10"
                                    placeholderText: "X-Axis Minimum"
                                    validator: DoubleValidator { bottom: 0.1 }
                                    
                                    onEditingFinished: {
                                        if (!isDestructing && marginChart) {
                                            let minValue = parseFloat(text)
                                            if (minValue > 0 && minValue < parseFloat(xAxisMax.text)) {
                                                marginChart.setXAxisMin(minValue)
                                            } else {
                                                text = marginChart.getXAxisMin().toString()
                                            }
                                        }
                                    }
                                }

                                Label {
                                    text: "X-Axis Max (A): "
                                }

                                TextFieldRound {
                                    id: xAxisMax
                                    Layout.fillWidth: true
                                    text: "10000"
                                    placeholderText: "X-Axis Maximum"
                                    validator: DoubleValidator { bottom: 1 }
                                    
                                    onEditingFinished: {
                                        if (!isDestructing && marginChart) {
                                            let maxValue = parseFloat(text)
                                            if (maxValue > parseFloat(xAxisMin.text)) {
                                                marginChart.setXAxisMax(maxValue)
                                            } else {
                                                text = marginChart.getXAxisMax().toString()
                                            }
                                        }
                                    }
                                }

                                // Y-Axis Controls
                                Label {
                                    text: "Y-Axis Min (s): "
                                }

                                TextFieldRound {
                                    id: yAxisMin
                                    Layout.fillWidth: true
                                    text: "0.01"
                                    placeholderText: "Y-Axis Minimum"
                                    validator: DoubleValidator { bottom: 0.001 }
                                    
                                    onEditingFinished: {
                                        if (!isDestructing && marginChart) {
                                            let minValue = parseFloat(text)
                                            if (minValue > 0 && minValue < parseFloat(yAxisMax.text)) {
                                                marginChart.setYAxisMin(minValue)
                                            } else {
                                                text = marginChart.getYAxisMin().toString()
                                            }
                                        }
                                    }
                                }

                                Label {
                                    text: "Y-Axis Max (s): "
                                }

                                TextFieldRound {
                                    id: yAxisMax
                                    Layout.fillWidth: true
                                    text: "10"
                                    placeholderText: "Y-Axis Maximum"
                                    validator: DoubleValidator { bottom: 0.01 }
                                    
                                    onEditingFinished: {
                                        if (!isDestructing && marginChart) {
                                            let maxValue = parseFloat(text)
                                            if (maxValue > parseFloat(yAxisMin.text)) {
                                                marginChart.setYAxisMax(maxValue)
                                            } else {
                                                text = marginChart.getYAxisMax().toString()
                                            }
                                        }
                                    }
                                }

                                StyledButton {
                                    text: "Reset Axis"
                                    icon.source: "../../../icons/rounded/refresh.svg"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    
                                    ToolTip.text: "Reset axis to default ranges"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
                                    
                                    onClicked: {
                                        if (!isDestructing && marginChart) {
                                            marginChart.resetAxisToDefault()
                                            xAxisMin.text = marginChart.getXAxisMin().toString()
                                            xAxisMax.text = marginChart.getXAxisMax().toString()
                                            yAxisMin.text = marginChart.getYAxisMin().toString()
                                            yAxisMax.text = marginChart.getYAxisMax().toString()
                                        }
                                    }
                                }

                                function updateFaultPoints() {
                                    if (!isDestructing && calculator) {
                                        marginChart.updateFaultPoints(
                                            calculator.faultPoints, 
                                            showFaultPoints && showFaultPoints.checked
                                        );
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Fuse Curves"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 350
                            
                            GridLayout {
                                columns: 2
                                anchors.fill: parent
                                uniformCellWidths: true
                                
                                Label { text: "Manufacturer:" }
                                ComboBoxRound {
                                    id: fuseManufacturer
                                    model: ["ABB", "EATON"]
                                    currentIndex: 0
                                    Layout.fillWidth: true
                                    onCurrentTextChanged: {
                                        updateFuseTypes()
                                    }
                                }
                                
                                Label { text: "Fuse Type:" }
                                ComboBoxRound {
                                    id: fuseType
                                    model: []
                                    Layout.fillWidth: true
                                    onCurrentTextChanged: {
                                        updateFuseRatings()
                                    }
                                }
                                
                                Label { text: "Fuse Rating:" }
                                ComboBoxRound {
                                    id: fuseRating
                                    model: []
                                    Layout.fillWidth: true
                                }
                                
                                StyledButton {
                                    text: "Add Fuse Curve"
                                    icon.source: "../../../icons/rounded/add.svg"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    enabled: fuseType.currentIndex >= 0 && fuseRating.currentIndex >= 0
                                    onClicked: {
                                        if (fuseType.currentText && fuseRating.currentText) {
                                            let success = calculator.addFuseCurveToPlot(
                                                fuseType.currentText,
                                                parseFloat(fuseRating.currentText),
                                                fuseManufacturer.currentText
                                            )
                                            if (success) {
                                                updateLoadedFusesList()
                                                messagePopup.showSuccess("Fuse curve added successfully")
                                            } else {
                                                messagePopup.showError("Failed to add fuse curve")
                                            }
                                        }
                                    }
                                }
                                
                                Label { text: "Loaded Fuses:" }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 100
                                    Layout.maximumHeight: 180
                                    color: "transparent"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    radius: 4
                                    
                                    ListView {
                                        id: loadedFusesList
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        model: []
                                        
                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 30
                                            color: "transparent"
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 5
                                                
                                                Label {
                                                    text: modelData.label || ""
                                                    Layout.fillWidth: true
                                                    font.pixelSize: 12
                                                }
                                                
                                                StyledButton {
                                                    icon.source: "../../../icons/rounded/close.svg"
                                                    Layout.preferredWidth: 60
                                                    Layout.preferredHeight: 25
                                                    onClicked: {
                                                        calculator.clearFuseCurves()
                                                        updateLoadedFusesList()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                StyledButton {
                                    text: "Clear All Fuses"
                                    icon.source: "../../../icons/rounded/clear_all.svg"
                                    Layout.columnSpan: 2
                                    Layout.fillWidth: true
                                    onClicked: {
                                        calculator.clearFuseCurves()
                                        updateLoadedFusesList()
                                        messagePopup.showSuccess("All fuse curves cleared")
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Discrimination Results"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 250

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8

                                Text {
                                    text: "System Coordination Status: " + 
                                          (safeCalculatorProperty("isFullyCoordinated", false) ? "Fully Coordinated" : "Coordination Issues")
                                    visible: safeCalculatorProperty("relayCount", 0) >= 2
                                    font.bold: true
                                    color: safeCalculatorProperty("isFullyCoordinated", false) ? 
                                           Universal.theme === Universal.Dark ? "#90EE90" : "green" : 
                                           Universal.theme === Universal.Dark ? "#ff8080" : "red"
                                    Layout.fillWidth: true
                                }

                                ListView {
                                    id: resultsList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: isDestructing ? null : calculator ? calculator.results : null
                                    clip: true

                                    Text {
                                        text: "Add at least 2 relays to see discrimination results"
                                        visible: safeCalculatorProperty("relayCount", 0) < 2
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

    Connections {
        target: calculator
        enabled: !isDestructing && calculator
        
        function onAnalysisComplete() {
            if (isDestructing || !calculator || !marginChart) return
            
            marginChart.scatterSeries.clear()
            let model = calculator.results
            try {
                if (model) {
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
                }
                
                Qt.callLater(function() {
                    if (isDestructing || !calculator) return
                    if (showFaultPoints && showFaultPoints.checked) {
                        showFaultPointsGrid.updateFaultPoints();
                    }
                });
            } catch (e) {
                console.error("Error updating chart:", e)
            }
        }
        
        function onRelayCountChanged() {
            if (isDestructing || !calculator || !marginChart) return
            marginChart.createRelaySeries()
        }
        
        function onMarginChanged() {
            if (isDestructing || !calculator || !marginChart) return
            marginChart.updateMarginLine()
        }

        function onCurrentLevelChanged() {
            if (isDestructing || !calculator || !marginChart) return
            marginChart.updateCurrentLevelLine()
        }
        
        function onExportComplete(success, message) {
            if (isDestructing) return
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError(message)
            }
        }
        
        function onExportChart(filename) {
            if (isDestructing || !calculator || !marginChart) return
            marginChart.saveChartImage(filename)
        }
        
        function onFuseCurvesChanged() {
            if (isDestructing || !calculator || !marginChart) return
            marginChart.updateFuseCurves()
        }
    }
        
    Component.onCompleted: {
        Qt.callLater(function() {
            if (isDestructing || !calculator || !marginChart) return
            
            if (marginChart && marginChart.createRelaySeries) {
                marginChart.createRelaySeries();
            }
            
            updateFuseTypes()
            updateLoadedFusesList()
            
            // Initialize axis controls with current chart values
            xAxisMin.text = marginChart.getXAxisMin().toString()
            xAxisMax.text = marginChart.getXAxisMax().toString()
            yAxisMin.text = marginChart.getYAxisMin().toString()
            yAxisMax.text = marginChart.getYAxisMax().toString()
        });
    }
    
    // Fuse curve functions
    function updateFuseTypes() {
        if (!calculator) return
        let types = calculator.getFuseTypes(fuseManufacturer.currentText)
        fuseType.model = types
        fuseType.currentIndex = types.length > 0 ? 0 : -1
        updateFuseRatings()
    }
    
    function updateFuseRatings() {
        if (!calculator) return
        if (fuseType.currentIndex >= 0 && fuseType.currentText) {
            let ratings = calculator.getFuseRatings(fuseType.currentText, fuseManufacturer.currentText)
            fuseRating.model = ratings
            fuseRating.currentIndex = ratings.length > 0 ? 0 : -1
        } else {
            fuseRating.model = []
            fuseRating.currentIndex = -1
        }
    }
    
    function updateLoadedFusesList() {
        if (!calculator) return
        let loadedFuses = calculator.getLoadedFuseCurves()
        loadedFusesList.model = loadedFuses
    }
}