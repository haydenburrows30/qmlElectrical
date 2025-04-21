import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.platform as Platform

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/exports"

import SolkorRfCalculator 1.0

Item {

    property SolkorRfCalculator calculator: SolkorRfCalculator {}

    function saveToPdf() {
        // Use the calculator's exportToPdf with null parameter
        // to let FileSaver handle the file dialog
        calculator.exportToPdf(null)
    }

    Connections {
        target: calculator
        function onPdfSaved(success, message) {
            if (success) {
                messagePopup.showSuccess(message)
            } else {
                messagePopup.showError("Error saving PDF: " + message)
            }
        }

        Component.onCompleted: calculator.updateComparisons()
    }

    MessagePopup {
        id: messagePopup
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 40
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5

            ColumnLayout {
                id: mainLayout
                anchors.centerIn: parent
                width: 880
                spacing: 10

                // Header with title and help button
                RowLayout {
                    id: topHeader
                    Layout.fillWidth: true
                    Layout.bottomMargin: 5
                    Layout.leftMargin: 5

                    Label {
                        text: "Solkor RF Calculator"
                        font.pixelSize: 20
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Save to PDF"
                        onClicked: saveToPdf()
                        Layout.preferredHeight: 30
                    }

                    // StyledButton {
                    //     id: helpButton
                    //     icon.source: "../../../icons/rounded/info.svg"
                    //     ToolTip.text: "Help"
                    //     onClicked: popUpText.open()
                    // }
                }

                // site information section
                RowLayout {
                    spacing: 10

                    WaveCard {
                        id: siteInfoCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        Layout.alignment: Qt.AlignHCenter

                        title: "Site Information"

                        GridLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            columns: 2

                            Label {
                                text: "Site Name Relay 1:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: siteNameRelay1
                                placeholderText: "Enter site name"
                                Layout.fillWidth: true
                                text: calculator.site_name_relay1
                                onTextChanged: calculator.site_name_relay1 = text
                            }

                            Label {
                                text: "Site Name Relay 2:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: siteNameRelay2
                                placeholderText: "Enter site name"
                                Layout.fillWidth: true
                                text: calculator.site_name_relay2
                                onTextChanged: calculator.site_name_relay2 = text
                            }

                            Label {
                                text: "Serial Number Relay 1:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: serialNumberRelay1
                                placeholderText: "Enter serial number"
                                Layout.fillWidth: true
                                text: calculator.serial_number_relay1
                                onTextChanged: calculator.serial_number_relay1 = text
                            }

                            Label {
                                text: "Serial Number Relay 2:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: serialNumberRelay2
                                placeholderText: "Enter serial number"
                                Layout.fillWidth: true
                                text: calculator.serial_number_relay2
                                onTextChanged: calculator.serial_number_relay2 = text
                            }

                            Label {
                                text: "L1-L2+E:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: l1l2e
                                placeholderText: "Enter L1-L2+E value"
                                Layout.fillWidth: true
                                text: calculator.l1_l2_e
                                onTextChanged: calculator.l1_l2_e = text
                            }

                            Label {
                                text: "L2-L1+E:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: l2l1e
                                placeholderText: "Enter L2-L1+E value"
                                Layout.fillWidth: true
                                text: calculator.l2_l1_e
                                onTextChanged: calculator.l2_l1_e = text
                            }
                        }
                    }
                    // Resistance Calc
                    WaveCard {
                        id: resistanceCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 280
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

                        title: "Resistance"

                        GridLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            columns: 2

                            Label {
                                text: "Loop Resistance:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldRound {
                                id: loopResistance
                                placeholderText: "Enter loop resistance"
                                Layout.fillWidth: true
                                text: calculator.loop_resistance
                                onTextChanged: calculator.loop_resistance = text
                            }

                            Label {
                                text: "Padding Resistance:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldBlue {
                                text: calculator.padding_resistance
                                Layout.fillWidth: true
                                color: calculator.padding_resistance === "Error" ? "red" : Universal.foreground
                            }

                            Label {
                                text: "Standard Padding:"
                                Layout.alignment: Qt.AlignRight
                                Layout.minimumWidth: 120
                            }
                            TextFieldBlue {
                                text: calculator.standard_padding_resistance
                                Layout.fillWidth: true
                                color: calculator.standard_padding_resistance === "Error" ? "red" : "blue"
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }

                // Tableview
                WaveCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 320
                    Layout.alignment: Qt.AlignHCenter
                    titleVisible: false

                    TableView {
                        id: tableView
                        anchors.fill: parent
                        columnSpacing: 0
                        rowSpacing: 0
                        clip: true
                        topMargin: columnHeaderHeight
                        leftMargin: rowHeaderWidth

                        property real rowHeaderWidth: 80
                        property real columnHeaderHeight: 60

                        property int rows: calculator ? calculator.rowCount() : 0
                        property int columns: calculator ? calculator.columnCount() : 0

                        model: calculator

                        rowHeightProvider: function() { return 40 }
                        columnWidthProvider: function() { return 110 }

                        Rectangle {
                            id: cornerRect
                            width: tableView.rowHeaderWidth
                            height: tableView.columnHeaderHeight
                            x: tableView.contentX
                            y: tableView.contentY
                            z: 3
                            color: "#e0e0e0"
                            border.width: 1
                            border.color: "#d0d0d0"

                            Text {
                                anchors.centerIn: parent
                                text: "Fault Type"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Row {
                            id: columnHeader
                            y: tableView.contentY
                            z: 2
                            x: tableView.rowHeaderWidth + tableView.contentX

                            Repeater {
                                model: tableView.columns
                                delegate: Rectangle {
                                    width: tableView.columnWidthProvider(modelData)
                                    height: tableView.columnHeaderHeight
                                    color: "#f0f0f0"
                                    border.width: 1
                                    border.color: "#d0d0d0"

                                    Text {
                                        width: parent.width
                                        height: parent.height
                                        horizontalAlignment : Text.AlignHCenter
                                        verticalAlignment : Text.AlignVCenter
                                        text: calculator.headerData(modelData, Qt.Horizontal)
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }

                        Column {
                            id: rowHeader
                            x: tableView.contentX
                            z: 2
                            y: tableView.columnHeaderHeight + tableView.contentY

                            Repeater {
                                model: tableView.rows
                                delegate: Rectangle {
                                    width: tableView.rowHeaderWidth
                                    height: tableView.rowHeightProvider(modelData)
                                    color: "#f0f0f0"
                                    border.width: 1
                                    border.color: "#d0d0d0"

                                    Text {
                                        anchors.centerIn: parent
                                        text: calculator.headerData(modelData, Qt.Vertical)
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        delegate: Item {
                            id: cellItem
                            implicitWidth: 120
                            implicitHeight: 40

                            property bool isTextCell: {
                                if (model.column !== undefined) {
                                    return model.column === 6;
                                } else {
                                    let rows = tableView.rows > 0 ? tableView.rows : 6;
                                    let col = Math.floor(model.index / rows);
                                    return col === 6;
                                }
                            }

                            property string currentValue: model.display

                            property bool isOutOfSpec: {
                                try {
                                    let val = parseFloat(currentValue);
                                    let row = model.row !== undefined ? model.row : (model.index % tableView.rows);
                                    let col = model.column !== undefined ? model.column : Math.floor(model.index / tableView.rows);

                                    if (col === 1 || col === 2 || col === 4 || col === 5) {
                                        return (val !== 0) && (Math.abs(val - 11.0) > 0.5);
                                    }

                                    if (col === 0 || col === 3) {
                                        let faultSetting = parseFloat(calculator.data(calculator.index(row, 6)));
                                        if (val === 0) return false;

                                        let percentage = (val / faultSetting) * 100;
                                        return (percentage < 90 || percentage > 110);
                                    }
                                    
                                    return false;
                                } catch (e) {
                                    return false;
                                }
                            }
                            
                            property bool isOk: {
                                try {
                                    let val = parseFloat(currentValue);
                                    if (val === 0) return false;
                                    return !isOutOfSpec && val !== 0;
                                } catch (e) {
                                    return false;
                                }
                            }

                            Connections {
                                target: calculator
                                function onComparisonResultsChanged() {
                                    cellItem.currentValue = Qt.binding(function() { return model.display; });
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                sourceComponent: isTextCell ? textComponent : numberComponent
                            }

                            Component {
                                id: numberComponent
                                
                                TextField {
                                    anchors.fill: parent
                                    text: model.display
                                    horizontalAlignment: TextInput.AlignHCenter
                                    verticalAlignment: TextInput.AlignVCenter

                                    onTextChanged: {
                                        cellItem.currentValue = text;
                                    }
                                    
                                    background: Rectangle {
                                        id: cellBackground
                                        border.width: 1
                                        border.color: "#d0d0d0"
                                        color: {
                                            if (cellItem.isOutOfSpec) return "#ffe0e0";
                                            else if (cellItem.isOk) return "#e0ffe0";
                                            else return "white";
                                        }
                                    }
                                    
                                    onEditingFinished: {
                                        model.edit = text;
                                        cellItem.currentValue = text;
                                    }
                                }
                            }

                            Component {
                                id: textComponent
                                
                                Rectangle {
                                    anchors.fill: parent
                                    border.width: 1
                                    border.color: "#d0d0d0"
                                    color: "#f5f5f5"
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: model.display
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }

                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                        
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        Component.onCompleted: {
                            if (calculator) {
                                tableView.forceLayout()
                            }
                        }
                    }
                }
            }
        }
    }
}
