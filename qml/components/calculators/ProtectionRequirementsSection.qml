import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"  // Import for WaveCard component

Item {
    id: protectionSection

    property var transformerCalculator
    property var windTurbineCalculator
    property bool transformerReady
    property bool windTurbineReady
    property real totalGeneratedPower
    property var safeValueFunction

    signal calculate()
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        
        Flickable {
            contentWidth: parent.width
            contentHeight: mainLayout.height + 10
            bottomMargin: 5
            leftMargin: 5
            rightMargin: 5
            topMargin: 5
    
            ColumnLayout {
                id: mainLayout
                width: scrollView.width

                Button {
                    text: "Calculate Complete System"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 250
                    Layout.bottomMargin: 40
                    onClicked: calculate()
                }

                RowLayout {
                    WaveCard {
                        title: "LV Wind Generator Protection (400V)"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 350
                        Layout.alignment: Qt.AlignTop
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 5
                            
                            Text {
                                text: "<b>Key Protection Elements:</b>"
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: lvProtectionLayout.implicitHeight + 20
                                color: "#f0f7ff"
                                border.color: "#0078d7"
                                radius: 5
                                
                                ColumnLayout {
                                    id: lvProtectionLayout
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 5
                                    
                                    Text {
                                        text: "1. <b>Generator Circuit Breaker:</b> Rated for " + 
                                                (((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)) * 1.25).toFixed(0) + 
                                                "A (125% of full load current)"
                                    }
                                    
                                    Text {
                                        text: "2. <b>Protection Relays:</b>"
                                    }
                                    
                                    GridLayout {
                                        columns: 2
                                        Layout.fillWidth: true
                                        
                                        Text { text: "• Overcurrent (ANSI 50/51)" }
                                        Text { text: "Pickup: " + (((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)) * 1.1).toFixed(0) + "A" }
                                        
                                        Text { text: "• Earth Fault (ANSI 50N/51N)" }
                                        Text { text: "Pickup: 20% of rated current" }
                                        
                                        Text { text: "• Overvoltage (ANSI 59)" }
                                        Text { text: "Pickup: 110% of 400V" }
                                        
                                        Text { text: "• Undervoltage (ANSI 27)" }
                                        Text { text: "Pickup: 80% of 400V" }
                                        
                                        Text { text: "• Over/Under Frequency (ANSI 81O/U)" }
                                        Text { text: "Pickup: ±2% of nominal" }
                                        
                                        Text { text: "• Reverse Power (ANSI 32)" }
                                        Text { text: "Pickup: 5% of rated power" }
                                    }
                                    
                                    Text {
                                        text: "3. <b>Anti-Islanding Protection:</b> Rate of Change of Frequency (ROCOF) or Vector Shift"
                                    }
                                }
                            }
                        }
                    }
                    
                    WaveCard {
                        title: "Transformer Protection"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 350
                        Layout.alignment: Qt.AlignTop
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 5
                            
                            Text {
                                text: "<b>Key Protection Elements:</b>"
                                font.bold: true
                            }
                            
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: transformerProtectionLayout.implicitHeight + 20
                                color: "#f0fff0"
                                border.color: "#21be2b"
                                radius: 5
                                
                                ColumnLayout {
                                    id: transformerProtectionLayout
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 5
                                    
                                    Text {
                                        text: "1. <b>Transformer Primary Protection:</b>"
                                    }
                                    
                                    GridLayout {
                                        columns: 2
                                        Layout.fillWidth: true
                                        
                                        Text { text: "• Differential Protection (ANSI 87T)" }
                                        Text { text: "Required for transformers >5 MVA" }
                                        
                                        Text { text: "• Overcurrent (ANSI 50/51)" }
                                        Text { 
                                            text: transformerReady ? 
                                                    "Pickup: " + safeValueFunction(transformerCalculator.relayPickupCurrent, 0).toFixed(0) + "A" : 
                                                    "Pickup: Calculating..." 
                                        }
                                        
                                        Text { text: "• Restricted Earth Fault (ANSI 64)" }
                                        Text { text: "Recommended for Y-connected winding" }
                                    }
                                    
                                    Text {
                                        text: "2. <b>Transformer Mechanical Protection:</b>"
                                    }
                                    
                                    GridLayout {
                                        columns: 2
                                        Layout.fillWidth: true
                                        
                                        Text { text: "• Buchholz Relay" }
                                        Text { text: "For oil-filled transformers" }
                                        
                                        Text { text: "• Pressure Relief Device" }
                                        Text { text: "Opens at excessive pressure" }
                                        
                                        Text { text: "• Winding Temperature" }
                                        Text { text: "Alarm at 100°C, Trip at 120°C" }
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {

                    WaveCard {
                        id: ref615Card
                        title: "ABB REF615 Relay Configuration (11kV)"
                        Layout.fillWidth: true
                        Layout.minimumHeight: 700
                        Layout.alignment: Qt.AlignTop
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: ref615Layout.implicitHeight + 20
                                color: "#eef6fc"
                                border.color: "#4a90e2"
                                radius: 5
                                
                                ColumnLayout {
                                    id: ref615Layout
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8
                                    
                                    Text {
                                        text: "<b>REF615 Protection Configuration:</b>"
                                        font.pixelSize: 14
                                    }
                                    
                                    GridLayout {
                                        columns: 2
                                        Layout.fillWidth: true
                                        columnSpacing: 15

                                        Text { text: "<b>Phase Overcurrent (ANSI 51P)</b>"; font.bold: true }
                                        Text { text: "" }
                                        
                                        Text { text: "• Operating Mode:" }
                                        Text { text: "3-phase, IEC Very Inverse (VI)" }
                                        
                                        Text { text: "• Startup Value:" }
                                        Text { 
                                            text: transformerReady ? 
                                                (safeValueFunction(transformerCalculator.relayPickupCurrent, 0) * 1.1).toFixed(1) + " A" : 
                                                "Calculating..." 
                                        }
                                        
                                        Text { text: "• Time Multiplier:" }
                                        Text { text: "0.4 (coordinate with downstream)" }

                                        Text { text: "<b>Earth Fault (ANSI 51N)</b>"; font.bold: true }
                                        Text { text: "" }
                                        
                                        Text { text: "• Operating Mode:" }
                                        Text { text: "IEC Extremely Inverse (EI)" }
                                        
                                        Text { text: "• Startup Value:" }
                                        Text { 
                                            text: transformerReady ? 
                                                (safeValueFunction(transformerCalculator.relayPickupCurrent, 0) * 0.2).toFixed(1) + " A (20% of rated)" : 
                                                "Calculating..." 
                                        }
                                        
                                        Text { text: "• Time Multiplier:" }
                                        Text { text: "0.5" }

                                        Text { text: "<b>Instantaneous Overcurrent (ANSI 50P)</b>"; font.bold: true }
                                        Text { text: "" }
                                        
                                        Text { text: "• Startup Value:" }
                                        Text { 
                                            text: transformerReady ? 
                                                (safeValueFunction(transformerCalculator.faultCurrentHV, 0) * 0.8).toFixed(1) + " A (80% of fault current)" : 
                                                "Calculating..." 
                                        }
                                        
                                        Text { text: "• Operating Delay:" }
                                        Text { text: "100 ms" }
                                        
                                        Text { text: "<b>Directional Overcurrent (ANSI 67)</b>"; font.bold: true }
                                        Text { text: "" }
                                        
                                        Text { text: "• Direction Mode:" }
                                        Text { text: "Forward (from wind turbine to grid)" }
                                        
                                        Text { text: "• Characteristic Angle:" }
                                        Text { text: "60°" }

                                        Text { text: "<b>Additional Functions:</b>"; font.bold: true }
                                        Text { text: "" }
                                        
                                        Text { text: "• Auto-Reclosing (ANSI 79):" }
                                        Text { text: "Enabled with 1 fast + 1 delayed cycle" }
                                        
                                        Text { text: "• Undervoltage (ANSI 27):" }
                                        Text { text: "0.8 × Un, delay 3.0s" }
                                        
                                        Text { text: "• Overvoltage (ANSI 59):" }
                                        Text { text: "1.1 × Un, delay 2.0s" }
                                        
                                        Text { text: "• Breaker Failure (ANSI 50BF):" }
                                        Text { text: "Enabled, operate time 150ms" }
                                    }
                                }
                            }
                            
                            // ABB Ring Main Unit (RMU) Configuration
                            Text {
                                text: "<b>ABB Ring Main Unit Configuration:</b>"
                                font.pixelSize: 14
                                Layout.topMargin: 5
                            }
                            
                            Text {
                                text: "• Use SafeRing/SafePlus with vacuum circuit breaker module (V) for protection\n" +
                                    "• CT Ratio: " + (transformerReady ? transformerCalculator.relayCtRatio : "300/5") + "\n" +
                                    "• VT Ratio: 11000/110V\n" +
                                    "• Ensure SF6 gas pressure monitoring is connected to alarm\n" +
                                    "• Configure local/remote control mode selection\n" +
                                    "• Connect motor operators for remote circuit breaker control"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.minimumHeight: ref615Card.height
                
                        WaveCard {
                            title: "Line Protection (11kV)"
                            Layout.fillWidth: true
                            Layout.minimumHeight: 300
                            Layout.alignment: Qt.AlignTop
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 5
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: lineProtectionLayout.implicitHeight + 20
                                    color: "#fff0f0"
                                    border.color: "#d73a49"
                                    radius: 5
                                    
                                    ColumnLayout {
                                        id: lineProtectionLayout
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 5
                                        
                                        Text {
                                            text: "<b>HV Line Protection Requirements:</b>"
                                        }
                                        
                                        GridLayout {
                                            columns: 2
                                            Layout.fillWidth: true
                                            
                                            Text { text: "• Overcurrent (ANSI 50/51)" }
                                            Text { 
                                                text: transformerReady ? 
                                                        "Very Inverse curve, TMS: " + safeValueFunction(transformerCalculator.relayTimeDial, 0.3).toFixed(2) : 
                                                        "Very Inverse curve, TMS: 0.30" 
                                            }
                                            
                                            Text { text: "• Earth Fault (ANSI 50N/51N)" }
                                            Text { text: "Pickup: 10-20% of CT primary rating" }
                                            
                                            Text { text: "• CT Ratio" }
                                            Text { 
                                                text: transformerReady ? 
                                                        transformerCalculator.relayCtRatio : 
                                                        "300/5" 
                                            }
                                        }
                                        
                                        Text {
                                            text: "2. <b>Additional Protection for Wind Generation:</b>"
                                        }
                                        
                                        GridLayout {
                                            columns: 1
                                            Layout.fillWidth: true
                                            
                                            Text { text: "• <b>Loss of Mains Protection:</b> Required to detect islanding situations" }
                                            Text { text: "• <b>Synchronization Check (ANSI 25):</b> For reconnection to the grid" }
                                            Text { text: "• <b>Power Quality Monitoring:</b> To monitor harmonic content" }
                                            Text { text: "• <b>Directional Overcurrent (ANSI 67):</b> For bidirectional power flow" }
                                        }
                                    }
                                }
                            }
                        }

                        WaveCard {
                            title: "Grid Connection Requirements"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 300
                            // Layout.alignment: Qt.AlignTop
                            
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10
                                
                                Text {
                                    text: "<b>Wind Turbine Grid Integration Requirements:</b><br>" +
                                            "• Compliance with G59/G99 or equivalent grid connection standards<br>" +
                                            "• Low Voltage Ride Through (LVRT) capability<br>" +
                                            "• Active power control for frequency regulation<br>" +
                                            "• Reactive power capability (power factor control)<br>" +
                                            "• Harmonics and flicker within acceptable limits<br>" +
                                            "• Fault level contribution within grid limits"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                                
                                Text {
                                    text: "<b>SCADA and Communication:</b><br>" +
                                            "• Remote monitoring and control capabilities<br>" +
                                            "• Generation forecasting<br>" +
                                            "• Communication with grid operator (if required)<br>" +
                                            "• Data logging for regulatory compliance"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        Item {Layout.fillHeight: true} // Spacer
                    }
                }
            }
        }
    }
}
