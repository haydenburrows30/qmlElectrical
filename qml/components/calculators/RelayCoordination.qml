import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

import "../"
import "../../components"

WaveCard {
    id: protectionCoordinationCard
    title: 'Protection Coordination'
    Layout.minimumWidth: 600
    Layout.minimumHeight: 350

    info: ""

    RowLayout {
        anchors.fill: parent

        // Left column - Relay Controls
        ColumnLayout {
            Layout.preferredWidth: 300

            // Add Relay Section
            GroupBox {
                title: "Add Relay"
                Layout.fillWidth: true

                ColumnLayout {
                    spacing: 5

                    TextField {
                        id: relayName
                        placeholderText: "Relay Name"
                        Layout.fillWidth: true
                    }

                    TextField {
                        id: pickupCurrent
                        placeholderText: "Pickup Current (A)"
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0 }
                    }

                    TextField {
                        id: timeDial
                        placeholderText: "Time Dial Setting"
                        Layout.fillWidth: true
                        validator: DoubleValidator { bottom: 0; top: 1 }
                    }

                    ComboBox {
                        id: curveType
                        model: ["Standard Inverse", "Very Inverse", "Extremely Inverse"]
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Add Relay"
                        Layout.fillWidth: true
                        onClicked: relayCoordination.addRelay(
                            relayName.text,
                            parseFloat(pickupCurrent.text),
                            parseFloat(timeDial.text),
                            curveType.currentText
                        )
                    }
                }
            }

            // Relay List
            ListView {
                id: relayList
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                model: relayCoordination.relays
                delegate: ItemDelegate {
                    width: parent.width
                    contentItem: Column {
                        Text {
                            text: modelData.name
                            font.bold: true
                        }
                        Text {
                            text: modelData.pickup + "A, TDS=" + modelData.tds
                            color: "gray"
                        }
                    }
                    onClicked: relayCoordination.removeRelay(index)
                }
            }

            // Coordination Results
            GroupBox {
                title: "Coordination Results"
                Layout.fillWidth: true

                ColumnLayout {
                    Text {
                        text: "Status: " + (relayCoordination.isCoordinated ? "Coordinated" : "Not Coordinated")
                        color: relayCoordination.isCoordinated ? "green" : "red"
                    }

                    Repeater {
                        model: relayCoordination.coordinationIntervals
                        delegate: Text {
                            text: modelData.primary + " → " + modelData.backup + ": " + 
                                  modelData.interval.toFixed(2) + "s"
                            color: modelData.interval >= 0.3 ? "green" : "red"
                        }
                    }
                }
            }
        }

        // Right column - Time-Current Curves
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
        }
    }
}
