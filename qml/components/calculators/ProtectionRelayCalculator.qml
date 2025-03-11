import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import ProtectionRelay 1.0

WaveCard {
    id: protectionRelayCard
    title: 'Protection Relay Calculator'

    property ProtectionRelayCalculator relay: ProtectionRelayCalculator {}

    RowLayout {
        spacing: 10
        anchors.centerIn: parent

        ColumnLayout {
            Layout.preferredWidth: 300

            GroupBox {
                title: "Relay Settings"
                Layout.fillWidth: true

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
                        Layout.fillWidth: true
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
                }
            }

            GroupBox {
                title: "Test Values"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

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

        // Time-Current Curve Chart
        ChartView {
            id: relayChart
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 600
            Layout.minimumHeight: 600

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
