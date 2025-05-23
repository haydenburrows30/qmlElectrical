import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"

Popup {
    id: expertPopup
    modal: true
    padding: 10
    width: 800
    height: 800

    anchors.centerIn: Overlay.overlay
    
    property var calculator
    property var safeValueFunction
    
    onOpened: {
        if (calculator) {
            try {
                calculator.refreshCalculations();
                gridLayout.forceActiveFocus();
            } catch (e) {
                console.error("Error refreshing calculations:", e);
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        Label {
            text: "Expert Protection Settings"
            font.bold: true
            font.pixelSize: 16
        }
        Rectangle { height: 1; Layout.fillWidth: true; color: "gray"}
        
        TabBar {
            id: tabBar
            Layout.fillWidth: true
            
            TabButton {text: "System Parameters"}
            TabButton {text: "Time-Current Curves"}
            TabButton {text: "Protection Settings"}
        }
        
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex
            
            // Tab 1: System Parameters
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                GridLayout {
                    id: gridLayout
                    width: parent.width
                    columns: 2
                    
                    Label { 
                        text: "Detailed System Calculations"
                        font.bold: true
                        Layout.bottomMargin: 10
                    }
                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10
                        color: "gray"
                    }
                    
                    Label { text: "Z0 Transformer (Ω):" }
                    TextFieldBlue {
                        text: {
                            if (!calculator) return "0.000";
                            return safeValueFunction(calculator.z0Transformer, 0).toFixed(3);
                        }
                    }
                    
                    Label { text: "Z0 Line (Ω):" }
                    TextFieldBlue {
                        text: {
                            if (!calculator) return "0.000";
                            return safeValueFunction(calculator.z0Line, 0).toFixed(3);
                        }
                    }
                    
                    Label { text: "Zn Referred (Ω):" }
                    TextFieldBlue {
                        text: {
                            if (!calculator) return "0.000";
                            return safeValueFunction(calculator.zNeutralReferred, 0).toFixed(1);
                        }
                    }
                    
                    Label { text: "Load Angle (degrees):" }
                    TextFieldBlue {
                        text: calculator ? (Math.acos(safeValueFunction(calculator.loadPowerFactor, 0.85)) * 180 / Math.PI).toFixed(1) : "0.0"
                    }
                    
                    Label { text: "Load MVA Value:" }
                    TextFieldBlue {
                        text: calculator ? (safeValueFunction(calculator.loadMVA, 0.001)).toFixed(3): "0.001"
                    }
                    
                    Label { text: "Load Current (A):" }
                    TextFieldBlue {
                        id: loadCurrentField
                        text: {
                            if (!calculator) return "0.0∠0° A";
                            
                            let loadMVA = Math.max(0.001, safeValueFunction(calculator.loadMVA, 0.001));
                            let currentMagnitude = (loadMVA * 1000000) / (Math.sqrt(3) * 11000);
                            let powerFactor = safeValueFunction(calculator.loadPowerFactor, 0.85);
                            let angle = Math.acos(powerFactor);
                            
                            return `${currentMagnitude.toFixed(1)}∠${(-angle * 180 / Math.PI).toFixed(1)}° A`;
                        }
                    }
                    
                    Label { text: "Ground Fault Current (A):" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.groundFaultCurrent, 10).toFixed(4) : "0.000"
                    }
                    
                    Label { text: "Voltage Drop:" }
                    TextFieldBlue {
                        text: calculator ? 
                            `${safeValueFunction(calculator.voltageDrop, 0.01).toFixed(2)}% ∠${(Math.acos(safeValueFunction(calculator.loadPowerFactor, 0.85)) * 180 / Math.PI).toFixed(1)}°` : 
                            "0.00% ∠0.0°"
                    }
                    
                    Label { text: "Receiving End Voltage:" }
                    TextFieldBlue {
                        text: calculator ? 
                            `${safeValueFunction(calculator.unregulatedVoltage, 11).toFixed(2)} kV` : 
                            "11.00 kV"
                    }
                    
                    // Additional calculated values
                    
                    Label { text: "Symmetrical 3Φ Fault (kA):" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.faultCurrentHV, 0).toFixed(2) : "0.00"
                    }
                    
                    Label { text: "SLG Fault Current (kA):" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.faultCurrentSLG, 0).toFixed(2) : "0.00"
                    }
                    
                    Label { text: "X/R Ratio at Fault Point:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.xrRatioAtFault, 0).toFixed(2) : "0.00"
                    }
                    
                    Label { text: "Asymmetry Factor:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.asymmetryFactor, 1).toFixed(2) : "1.00"
                    }
                    
                    Label { text: "Transformer MVA Base:" }
                    TextFieldBlue {
                        text: calculator ? (safeValueFunction(calculator.transformerRating, 0) / 1000).toFixed(3) : "0.000"
                    }
                    
                    Label { text: "Per Unit Impedance:" }
                    TextFieldBlue {
                        text: calculator ? (safeValueFunction(calculator.transformerImpedance, 0) / 100).toFixed(3) : "0.000"
                    }
                    
                    Label { text: "Short Circuit MVA:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.shortCircuitMVA, 0).toFixed(2) : "0.00"
                    }
                    
                    Label { 
                        text: "Protection Coordination" 
                        font.bold: true
                        Layout.topMargin: 10
                        Layout.bottomMargin: 5
                        Layout.columnSpan: 2
                    }
                    
                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10
                        Layout.columnSpan: 2
                        color: "gray"
                    }
                    
                    Label { text: "Time-Overcurrent Margin:" }
                    TextFieldBlue {
                        text: {
                            return "0.3s (min required)";
                        }
                    }
                    
                    Label { text: "Instantaneous Pickup (A):" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.instantaneousPickup, 0).toFixed(2) : "0.00"
                    }
                    
                    Label { text: "Trip Time at Max Fault:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.tripTimeMaxFault, 0).toFixed(3) + "s" : "0.000s"
                    }
                    
                    Label { text: "Breaker Duty Factor:" }
                    TextFieldBlue {
                        text: {
                            if (!calculator) return "1.0";
                            return "1.0";
                        }
                    }
                    
                    Label { 
                        text: "TCC Curve Parameters" 
                        font.bold: true
                        Layout.topMargin: 10
                        Layout.bottomMargin: 5
                        Layout.columnSpan: 2
                    }
                    
                    Rectangle {
                        height: 1
                        Layout.fillWidth: true
                        Layout.bottomMargin: 10
                        Layout.columnSpan: 2
                        color: "gray"
                    }
                    
                    Label { text: "A Constant:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.curveAConstant, 13.5).toString() : "13.5"
                    }
                    
                    Label { text: "B Exponent:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.curveBExponent, 1.0).toString() : "1.0"
                    }
                }
            }
            
            // Tab 2: Time-Current Curves
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Rectangle {
                    id: curveArea
                    color: "#f0f0f0"
                    border.color: "#c0c0c0"
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: curveControls.top
                    anchors.bottomMargin: 10
                    
                    Canvas {
                        id: curveCanvas
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        property real xScale: width / 10
                        property real yScale: height / 10
                        property string selectedCurve: curveTypeCombo.currentText
                        property real timeDial: timeDialSlider.value
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            
                            ctx.strokeStyle = "#c0c0c0";
                            ctx.lineWidth = 1;
                            
                            ctx.beginPath();
                            for(var i = 0; i <= 10; i++) {
                                ctx.moveTo(0, i * yScale);
                                ctx.lineTo(width, i * yScale);
                                
                                ctx.moveTo(i * xScale, 0);
                                ctx.lineTo(i * xScale, height);
                            }
                            ctx.stroke();
                            
                            ctx.fillStyle = "#000000";
                            ctx.font = "12px sans-serif";
                            ctx.textAlign = "center";
                            ctx.fillText("Current (× Pickup)", width / 2, height - 5);
                            
                            ctx.save();
                            ctx.translate(10, height / 2);
                            ctx.rotate(-Math.PI / 2);
                            ctx.textAlign = "center";
                            ctx.fillText("Time (seconds)", 0, 0);
                            ctx.restore();
                            
                            drawCurve(ctx);
                        }
                        
                        function drawCurve(ctx) {
                            ctx.beginPath();
                            ctx.strokeStyle = "#0066cc";
                            ctx.lineWidth = 2;
                            
                            let pickup = 1;
                            let points = [];
                            
                            for(let x = 1; x < 10; x += 0.1) {
                                let t = 0;
                                
                                switch(selectedCurve) {
                                    case "Standard Inverse":
                                        t = timeDial * 0.14 / (Math.pow(x/pickup, 0.02) - 1);
                                        break;
                                    case "Very Inverse":
                                        t = timeDial * 13.5 / ((x/pickup) - 1);
                                        break;
                                    case "Extremely Inverse":
                                        t = timeDial * 80 / (Math.pow(x/pickup, 2) - 1);
                                        break;
                                    case "Long-Time Inverse":
                                        t = timeDial * 120 / ((x/pickup) - 1);
                                        break;
                                    case "Definite Time":
                                        t = timeDial;
                                        break;
                                }
                                
                                t = Math.max(Math.min(t, 10), 0.025);
                                
                                let canvasX = (Math.log10(x) / Math.log10(10)) * width;
                                let canvasY = height - (t * height / 10);
                                
                                points.push({x: canvasX, y: canvasY});
                            }
                            
                            if(points.length > 0) {
                                ctx.moveTo(points[0].x, points[0].y);
                                for(let i = 1; i < points.length; i++) {
                                    ctx.lineTo(points[i].x, points[i].y);
                                }
                                ctx.stroke();
                            }
                            
                            ctx.beginPath();
                            ctx.strokeStyle = "#cc0000";
                            ctx.lineWidth = 1;
                            ctx.setLineDash([5, 5]);
                            ctx.moveTo(xScale, 0);
                            ctx.lineTo(xScale, height);
                            ctx.stroke();
                            ctx.setLineDash([]);
                        }
                        
                        Connections {
                            target: curveTypeCombo
                            function onCurrentTextChanged() { curveCanvas.requestPaint(); }
                        }
                        
                        Connections {
                            target: timeDialSlider
                            function onValueChanged() { curveCanvas.requestPaint(); }
                        }
                    }
                    
                    Rectangle {
                        id: legendBox
                        width: 180
                        height: 80
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        color: "#ffffff"
                        border.color: "#c0c0c0"
                        
                        Column {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5
                            
                            Label {
                                text: "Legend"
                                font.bold: true
                            }
                            
                            Row {
                                spacing: 5
                                Rectangle {
                                    width: 20
                                    height: 2
                                    color: "#0066cc"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Label { text: curveTypeCombo.currentText }
                            }
                            
                            Row {
                                spacing: 5
                                Rectangle {
                                    width: 20
                                    height: 2
                                    color: "#cc0000"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Label { text: "Pickup Current (1×)" }
                            }
                        }
                    }
                }
                
                GridLayout {
                    id: curveControls
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    
                    Label { text: "Curve Type:" }
                    ComboBox {
                        id: curveTypeCombo
                        Layout.fillWidth: true
                        model: ["Standard Inverse", "Very Inverse", "Extremely Inverse", "Long-Time Inverse", "Definite Time"]
                        currentIndex: 1
                    }
                    
                    Label { text: "Time Dial Setting (TDS):" }
                    RowLayout {
                        Layout.fillWidth: true
                        
                        Slider {
                            id: timeDialSlider
                            from: 0.1
                            to: 1.0
                            value: 0.3
                            stepSize: 0.1
                            Layout.fillWidth: true
                            
                            ToolTip {
                                parent: timeDialSlider.handle
                                visible: timeDialSlider.pressed
                                text: timeDialSlider.value.toFixed(1)
                            }
                        }
                        
                        Label {
                            text: timeDialSlider.value.toFixed(1)
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: 30
                        }
                    }
                    
                    Label { text: "Pickup Current:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) + " A" : "0.00 A"
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Fault Current:" }
                    TextFieldBlue {
                        text: calculator ? (safeValueFunction(calculator.faultCurrentHV, 0) * 1000).toFixed(2) + " A" : "0.00 A"
                        Layout.fillWidth: true
                    }
                    
                    Label { text: "Trip Time (at fault current):" }
                    TextFieldBlue {
                        text: {
                            if (!calculator) return "0.00 s";
                            
                            let pickup = safeValueFunction(calculator.relayPickupCurrent, 1);
                            let fault = safeValueFunction(calculator.faultCurrentHV, 0) * 1000;
                            let multiple = fault / pickup;
                            let tds = timeDialSlider.value;
                            
                            let time = calculator.calculateTripTimeWithParams(multiple, tds, curveTypeCombo.currentText);
                            return time.toFixed(2) + " s";
                        }
                    }
                }
            }
            
            // Tab 3: Protection Settings
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                GridLayout {
                    width: 700
                    columns: 2
                    
                    Label { 
                        text: "Protection Settings"
                        font.bold: true
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                    }
                    Rectangle { 
                        Layout.fillWidth: true
                        height: 1
                        color: "darkgray"
                        Layout.topMargin: 10
                        Layout.bottomMargin: 10
                    }
                    
                    Label { text: "Relay Pickup Current (A):" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.relayPickupCurrent, 0).toFixed(2) : "0.00"
                    }

                    Label { text: "Under/Over Frequency (Hz):" }
                    TextFieldBlue {
                        text: calculator && calculator.frequencyRelaySettings ? 
                            calculator.frequencyRelaySettings.under_freq.toFixed(1) + " / " + 
                            calculator.frequencyRelaySettings.over_freq.toFixed(1) : "47.5 / 51.5"
                    }
                    
                    Label { text: "Rate of Change (Hz/s):" }
                    TextFieldBlue {
                        text: calculator ? calculator.frequencyRelaySettings.df_dt.toFixed(2) : "0.50"
                    }

                    Label { text: "Under/Over Voltage (pu):" }
                    TextFieldBlue {
                        text: calculator && calculator.voltageRelaySettings ? 
                            calculator.voltageRelaySettings.under_voltage.toFixed(2) + " / " +
                            calculator.voltageRelaySettings.over_voltage.toFixed(2) : "0.80 / 1.20"
                    }
                    
                    Label { text: "Differential Slope (%):" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.differentialRelaySlope, 25).toString() : "25"
                    }

                    Label { text: "Reverse Power Trip (%):" }
                    TextFieldBlue {
                        text: calculator ? (calculator.reversePowerThreshold * 100).toFixed(1) : "-10.0"
                    }
                    
                    Label { text: "CT Ratio:" }
                    TextFieldBlue {
                        id: relayCtRatioText
                        text: calculator ? calculator.relayCtRatio : "300/5"
                    }
                    
                    Label { text: "Time Dial Setting:" }
                    TextFieldBlue {
                        id: relayTimeDialText
                        text: calculator ? safeValueFunction(calculator.relayTimeDial, 0.3).toFixed(2) : "0.30"
                    }
                    
                    Label { text: "Curve Type:" }
                    TextFieldBlue {
                        id: relayCurveTypeText
                        text: calculator ? calculator.relayCurveType : "Very Inverse"
                    }
                    
                    Label { text: "Minimum Fault Current:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.minimumFaultCurrent, 0).toFixed(1) + " A" : "0.0 A"
                    }
                    
                    Label { text: "Remote Backup Trip Time:" }
                    TextFieldBlue {
                        text: calculator ? safeValueFunction(calculator.remoteBackupTripTime, 0.7).toFixed(1) + "s" : "0.7s"
                    }

                    Label { text: "Coordination Notes:" }
                    TextArea {
                        text: "• Time margin between protection devices: 0.3-0.4s\n" +
                              "• Overcurrent pickup margin: 20-30%\n" +
                              "• Curve selection optimized for transformer protection\n" +
                              "• Refer to grid code requirements for exact settings"
                        readOnly: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        wrapMode: Text.Wrap
                    }

                    Label { text: "Curve Calculation Formulas:" }
                    Layout.columnSpan: 2
                    TextArea {
                        id: curveFormulas
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        readOnly: true
                        text: "Standard Inverse (IEC): t = TDS * 0.14 / ((I/Is)^0.02 - 1)\n" +
                              "Very Inverse (IEC): t = TDS * 13.5 / ((I/Is) - 1)\n" +
                              "Extremely Inverse (IEC): t = TDS * 80 / ((I/Is)^2 - 1)\n" +
                              "Long-Time Inverse: t = TDS * 120 / ((I/Is) - 1)\n" +
                              "Definite Time: t = TDS\n\n" +
                              "Where: I = fault current, Is = pickup current, TDS = time dial setting"
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight

            StyledButton {
                text: "Debug"
                icon.source: "../../../icons/rounded/restart_alt.svg"
                Layout.alignment: Qt.AlignRight
                ToolTip.visible: hovered
                ToolTip.text: "Debug calculations.  Check log for output."
                ToolTip.delay: 500
                onClicked: calculator.debug_calculations();
            }
            
            StyledButton {
                text: "Refresh Values"
                icon.source: "../../../icons/rounded/restart_alt.svg"
                Layout.alignment: Qt.AlignRight
                onClicked: calculator.refreshCalculations();
            }
            
            StyledButton {
                text: "Close"
                icon.source: "../../../icons/rounded/close.svg"
                Layout.alignment: Qt.AlignRight
                onClicked: expertPopup.close()
            }
        }
    }
}
