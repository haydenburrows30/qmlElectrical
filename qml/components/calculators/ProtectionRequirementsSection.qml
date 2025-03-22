import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

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
            contentHeight: mainLayout.height + 40
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
                    Layout.bottomMargin: 10
                    onClicked: calculate()
                }

                WaveCard {
                    title: "LV Wind Generator Protection (400V)"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 250
                    Layout.alignment: Qt.AlignTop

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true

                        Label { text: "Generator Circuit Breaker Rating" }
                        Text { 
                            text: (((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)) * 1.25).toFixed(0) + "A (125% of full load current)"
                            font.bold: true
                            }

                        Label { text: "Overcurrent (ANSI 50/51)" }
                        Text {
                            text: (((totalGeneratedPower * 1000) / (Math.sqrt(3) * 400)) * 1.1).toFixed(0) + "A" 
                            font.bold: true
                            }

                        Label { text: "Earth Fault (ANSI 50N/51N)" }
                        Text { 
                            text: "20% of rated current" 
                            font.bold: true
                            }
                        
                        Label { text: "Overvoltage (ANSI 59)" }
                        Text { 
                            text: "110% of 400V" 
                            font.bold: true
                            }
                        
                        Label { text: "Undervoltage (ANSI 27)" }
                        Text { 
                            text: "80% of 400V" 
                            font.bold: true
                            }
                        
                        Label { text: "Over/Under Frequency (ANSI 81O/U)" }
                        Text { 
                            text: "±2% of nominal" 
                            font.bold: true
                            }
                        
                        Label { text: "Reverse Power (ANSI 32)" }
                        Text { 
                            text: "5% of rated power" 
                            font.bold: true
                            }

                        Label { text: "Anti-Islanding Protection:"}
                        Text { 
                            text: "Rate of Change of Frequency (ROCOF) or Vector Shift"
                            font.bold: true
                            }
                    }
                }
                
                WaveCard {
                    title: "Transformer Protection"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 200
                    Layout.alignment: Qt.AlignTop
                            
                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        
                        Text { text: "• Differential Protection (ANSI 87T)" }
                        Text { text: "Required for transformers >5 MVA" }
                        
                        Text { text: "• Overcurrent (ANSI 50/51)" }
                        Text { 
                            text: safeValueFunction(transformerCalculator.relayPickupCurrent, 0).toFixed(0) + "A"
                            font.bold: true
                        }
                        
                        Text { text: "• Restricted Earth Fault (ANSI 64)" }
                        Text { text: "Recommended for Y-connected winding" }

                        Text { text: "• Buchholz Relay" }
                        Text { text: "For oil-filled transformers" }
                        
                        Text { text: "• Pressure Relief Device" }
                        Text { text: "Opens at excessive pressure" }
                        
                        Text { text: "• Winding Temperature" }
                        Text { text: "Alarm at 100°C, Trip at 120°C" }
                    }
                }

                WaveCard {
                    id: ref615Card
                    title: "ABB REF615 Relay Configuration (11kV)"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 600
                    Layout.alignment: Qt.AlignTop
                    
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

                        Text {
                            text: "<b>ABB Ring Main Unit Configuration:</b>"
                            font.pixelSize: 14
                            Layout.topMargin: 5
                        }
            
                        Text {
                            text: "• Use SafeRing/SafePlus with vacuum circuit breaker module (V) for protection\n" +
                                "• CT Ratio: " + (transformerReady ? transformerCalculator.relayCtRatio : "300/1") + "\n" +
                                "• VT Ratio: 11000/110V\n" +
                                "• Ensure SF6 gas pressure monitoring is connected to alarm\n" +
                                "• Configure local/remote control mode selection\n" +
                                "• Connect motor operators for remote circuit breaker control"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }

                WaveCard {
                    title: "Line Protection (11kV)"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 200
                    Layout.alignment: Qt.AlignTop

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
                                    "300/1"  // Updated default value to match 1A secondary
                        }
                        Text { text: "• <b>Loss of Mains Protection:</b> Required to detect islanding situations" }
                        Text { text: "• <b>Synchronization Check (ANSI 25):</b> For reconnection to the grid" }
                        Text { text: "• <b>Power Quality Monitoring:</b> To monitor harmonic content" }
                        Text { text: "• <b>Directional Overcurrent (ANSI 67):</b> For bidirectional power flow" }
                    }
                }

                WaveCard {
                    title: "Grid Connection Requirements"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300

                    ColumnLayout {
                        id: gridConnectionLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                
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

                WaveCard {
                    title: "Voltage Regulator Protection (Eaton VR-32)"
                    Layout.fillWidth: true
                    Layout.minimumHeight: 500
                    Layout.alignment: Qt.AlignTop
                            
                    ColumnLayout {
                        id: regulatorProtectionLayout
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        
                        GridLayout {
                            columns: 2
                            Layout.fillWidth: true
                            columnSpacing: 15
                            
                            Text { text: "• Over/Under Voltage (ANSI 59/27):" }
                            Text { text: "±15% of nominal voltage" }
                            
                            Text { text: "• Current-limiting fuses:" }
                            Text { text: "200A on each phase" }
                            
                            Text { text: "• Control Power Backup:" }
                            Text { text: "UPS for microprocessor controller" }
                            
                            Text { text: "• Motor Control Protection:" }
                            Text { text: "Circuit breakers for each motor" }
                            
                            Text { text: "• Position Indication:" }
                            Text { text: "Tap position indicators & SCADA interface" }
                            
                            Text { text: "• Inter-phase Coordination:" }
                            Text { text: "Common controller for all 3 units" }
                            
                            Text { text: "• Bypass Provision:" }
                            Text { text: "Manual bypass switches for each phase" }
                            
                            Text { text: "• Surge Protection:" }
                            Text { text: "9kV MOV arresters on both sides" }
                        }
                        
                        Text {
                            text: "\n<b>Configuration Details:</b>\n" +
                                    "• Delta-connected single-phase 185kVA regulators for 11kV line\n" +
                                    "• 32-step voltage regulators with ±10% regulation range\n" +
                                    "• Step voltage change: 0.625% per step (10% ÷ 16 steps)\n" +
                                    "• Suitable for addressing voltage rise during high wind generation periods\n" +
                                    "• Bidirectional power flow capability\n" +
                                    "• Total capacity: 555kVA (3 × 185kVA single-phase units)"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
            
                        Text {
                            text: "<b>Control System Specifications:</b>\n" +
                                "• Cooper CL-6 or Eaton ComPak Plus voltage control system\n" +
                                "• Line drop compensation with R and X settings\n" +
                                "• Load balancing capability for the three single-phase units\n" +
                                "• Remote communications via DNP3.0 protocol\n" +
                                "• Data logging for voltage profiles and operations count\n" +
                                "• Reverse power detection for bidirectional regulation"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}
