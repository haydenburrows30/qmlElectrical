import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import ProtectionRelay 1.0

Item {
    id: protectionRelayCard

    property ProtectionRelayCalculator relay: ProtectionRelayCalculator {}

    Popup {
        id: tipsPopup
        width: 700
        height: 500
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
            text: { "<h3>Protection Relay Calculator</h3><br>" +
                    "This calculator estimates the operating time of a protection relay for a given fault current and settings.<br><br>" +
                    "<b>Pickup Current:</b> The current at which the relay should trip.<br>" +
                    "<b>Time Dial Setting:</b> The time dial setting of the relay.<br>" +
                    "<b>Curve Type:</b> The type of curve used by the relay.<br>" +
                    "<br>" +
                    "<b>Fault Current:</b> The current at which the fault occurs.<br>" +
                    "<br>" +
                    "The operating time of the relay is calculated based on the selected settings and fault current.<br>" +
                    "The time-current curve of the relay is also displayed for reference.<br>" +
                    "<br>" +
                    "Note: The operating time is an approximation and may vary based on the relay model and manufacturer.<br>" +
                    "<br>" +
                    "For more information, refer to the relay's datasheet or contact the manufacturer.<br>" +
                    "<br>" +
                    "<b>References:</b><br>" +
                    "IEEE Standard C37.112-1996<br>" +
                    "IEC 60255-151:2009<br>" +
                    "ANSI/IEEE C37.112-1996<br>"}
            wrapMode: Text.WordWrap
        }
    }

    RowLayout {
        spacing: 10
        anchors.centerIn: parent

        ColumnLayout {
            Layout.preferredWidth: 350
            id: settingsColumn

            WaveCard {
                title: "Relay Settings"
                Layout.fillWidth: true
                Layout.minimumHeight: 400
                id: results
                showSettings: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Pickup Current (A):" }
                    TextField {
                        id: pickupCurrent
                        placeholderText: "Enter current"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) relay.pickupCurrent = parseFloat(text)
                        Layout.minimumWidth: 180
                    }

                    Label { text: "Time Dial:" }
                    TextField {
                        id: timeDial
                        placeholderText: "Enter TDS"
                        validator: DoubleValidator { bottom: 0; top: 1 }
                        onTextChanged: if(text) relay.timeDial = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Curve Type:" }
                    ComboBox {
                        id: curveType
                        model: relay.curveTypes
                        onCurrentTextChanged: relay.curveType = currentText
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.columnSpan: 2
                        Layout.margins: 10
                        height: 1
                        color: sideBar.toggle1 ? "#404040" : "#e0e0e0"
                    }

                    Label { text: "Results:" ; Layout.columnSpan: 2 ; font.bold: true ; font.pixelSize: 16}

                    Label { text: "Fault Current (A):" }
                    TextField {
                        id: faultCurrent
                        placeholderText: "Enter fault current"
                        validator: DoubleValidator { bottom: 0 }
                        onTextChanged: if(text) relay.faultCurrent = parseFloat(text)
                        Layout.fillWidth: true
                    }

                    Label { text: "Operating Time:" }
                    Label {
                        text: relay.operatingTime.toFixed(2) + " s"
                        font.bold: true
                    }
                }
            }
        }

        WaveCard {
            title: "Time-Current Curve"
            Layout.minimumHeight: settingsColumn.height
            Layout.minimumWidth: settingsColumn.height * 1.75


        // Time-Current Curve Chart
            ChartView {
                id: relayChart
                theme: Universal.theme
                anchors.fill: parent

                antialiasing: true
                
                LogValueAxis {
                    id: currentAxis
                    min: 10
                    max: 10000
                    base: 10
                    titleText: "Current (A)"
                }
                
                LogValueAxis {
                    id: timeAxis
                    min: 0.01
                    max: 100
                    base: 10
                    titleText: "Time (s)"
                }

                LineSeries {
                    id: tripCurve
                    name: "Trip Curve"
                    axisX: currentAxis
                    axisY: timeAxis
                }

                // Add connection to update curve when calculations complete
                Connections {
                    target: relay
                    function onCalculationsComplete() {
                        tripCurve.clear()
                        var points = relay.curvePoints
                        for (var i = 0; i < points.length; i++) {
                            tripCurve.append(points[i].current, points[i].time)
                        }
                    }
                }
            }
        }
    }
}
