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
    Layout.minimumWidth: 600
    Layout.minimumHeight: 400

    property ProtectionRelayCalculator relay: ProtectionRelayCalculator {}

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Input Panel
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
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                name: "Trip Curve"
                axisX: currentAxis
                axisY: timeAxis
                
                // Points are updated by the calculator
                XYPoint { x: relay.pickupCurrent; y: relay.operatingTime }
            }
        }
    }
}
