import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../"
import "../../components"
import RelayCoordination 1.0

WaveCard {
    id: coordinationCard
    title: 'Relay Coordination'

    property RelayCoordinationCalculator calculator: RelayCoordinationCalculator {}

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // Left Panel - Relay Settings
        ColumnLayout {
            SplitView.minimumWidth: 300
            SplitView.preferredWidth: 350

            GroupBox {
                title: "Add Relay"
                Layout.fillWidth: true

                GridLayout {
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10

                    Label { text: "Name:" }
                    TextField {
                        id: relayName
                        placeholderText: "Relay Name"
                        Layout.fillWidth: true
                    }

                    Label { text: "Pickup (A):" }
                    TextField {
                        id: pickupCurrent
                        placeholderText: "Current"
                        validator: DoubleValidator { bottom: 0 }
                        Layout.fillWidth: true
                    }

                    Label { text: "Time Dial:" }
                    TextField {
                        id: timeDial
                        placeholderText: "TDS"
                        validator: DoubleValidator { bottom: 0 }
                        Layout.fillWidth: true
                    }

                    Label { text: "Curve:" }
                    ComboBox {
                        id: curveType
                        model: ["Standard Inverse", "Very Inverse", "Extremely Inverse"]
                        Layout.fillWidth: true
                    }
                }
            }

            Button {
                text: "Add Relay"
                Layout.fillWidth: true
                onClicked: {
                    calculator.addRelay(
                        relayName.text,
                        parseFloat(pickupCurrent.text),
                        parseFloat(timeDial.text),
                        curveType.currentText
                    )
                }
            }

            GroupBox {
                title: "Relay List"
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    anchors.fill: parent
                    model: calculator.relays
                    delegate: ItemDelegate {
                        width: parent.width
                        text: modelData.name + " - " + modelData.pickup + "A"
                        onClicked: calculator.removeRelay(index)
                    }
                }
            }

            GroupBox {
                title: "Coordination Status"
                Layout.fillWidth: true

                ColumnLayout {
                    Label {
                        text: "Status: " + (calculator.isCoordinated ? "Coordinated ✓" : "Not Coordinated ✗")
                        color: calculator.isCoordinated ? "green" : "red"
                    }

                    Repeater {
                        model: calculator.coordinationIntervals
                        delegate: Label {
                            text: modelData.primary + " → " + modelData.backup + 
                                  ": " + modelData.interval.toFixed(2) + "s"
                            color: modelData.interval >= 0.3 ? "green" : "red"
                        }
                    }
                }
            }
        }

        // Right Panel - Time-Current Curves
        ChartView {
            id: tcChart  // Add ID to reference the ChartView
            SplitView.fillWidth: true
            antialiasing: true
            legend.visible: true

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

            Connections {
                target: calculator
                function onRelaysChanged() {
                    // Clear existing series
                    while (tcChart.count > 0) {
                        tcChart.removeSeries(tcChart.series(0))
                    }

                    // Add new series for each relay
                    var relays = calculator.relays
                    relays.forEach(function(relay, index) {
                        var series = tcChart.createSeries(ChartView.SeriesTypeLine, relay.name, currentAxis, timeAxis)

                        // Generate curve points
                        var current = 10
                        while (current <= 10000) {
                            var time = calculator.calculateOperatingTime(index, current)
                            series.append(current, time)
                            current *= 1.2  // Logarithmic steps
                        }
                    })
                }
            }
        }
    }
}
