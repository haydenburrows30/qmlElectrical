import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtCharts

import "../style"
import "../backgrounds"

Item {
    id: root
    
    // CT Properties
    property string ctRatio: "100/5"
    property real ctBurden: 15.0
    property real ctKneePoint: 0
    property real ctMaxFault: 0
    property real ctErrorMargin: 0
    property string ctAccuracyClass: "0.5"
    property real ctPowerFactor: 0.8
    
    // VT Properties
    property string vtRatio: "11000/110"
    property real vtBurden: 100.0
    property real vtUtilization: 0
    property real vtImpedance: 0
    
    // Visual Properties
    property bool darkMode: false
    property color textColor: "black"
    property color primaryColor: darkMode ? "#4FC3F7" : "#0277BD"
    property color secondaryColor: darkMode ? "#FF8A65" : "#E64A19"
    property color backgroundColor: darkMode ? "#424242" : "#FFFFFF"
    property color gridColor: darkMode ? "#606060" : "#E0E0E0"
    
    // Internal properties
    property var ctPrimary: parseFloat(ctRatio.split('/')[0])
    property var ctSecondary: parseFloat(ctRatio.split('/')[1])
    property var vtPrimary: parseFloat(vtRatio.split('/')[0])
    property var vtSecondary: parseFloat(vtRatio.split('/')[1])
    
    // Visualization Mode
    property int viewMode: 0  // 0=Circuit, 1=Saturation, 2=Waveform
    
    // Return a color based on the saturation level
    function saturationColor(level) {
        if (level < 0.5) return "#4CAF50";
        if (level < 0.8) return "#FF9800";
        return "#F44336";
    }

    function calculateCurrent(voltage) {
        if (voltage <= 0 || ctKneePoint <= 0) return 0;
        
        if (voltage <= ctKneePoint) {
            // Linear region
            return voltage * ctSecondary / ctKneePoint;
        } else {
            // Saturation region
            var excess = voltage - ctKneePoint;
            return ctSecondary + 2 * Math.pow(excess / ctKneePoint, 0.3) * ctSecondary;
        }
    }
    
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        
        TabBar {
            id: tabBar
            width: parent.width
            anchors.top: parent.top
            
            TabButton {
                text: "Circuit Diagram"
                onClicked: viewMode = 0
            }
            TabButton {
                text: "Saturation Curve"
                onClicked: viewMode = 1
            }
            TabButton {
                text: "Waveforms"
                onClicked: viewMode = 2
            }
        }
        
        StackLayout {
            anchors.top: tabBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            currentIndex: viewMode
            
            // Tab 1: Circuit Diagram
            Item {
                id: circuitView
                
                // Calculate saturation level for coloring
                property real satLevel: ctBurden > 0 && ctKneePoint > 0 ? 
                                        (ctSecondary * Math.sqrt(ctBurden)) / ctKneePoint : 0
                
                Text {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Instrument Transformer Circuit"
                    font.pixelSize: 18
                    font.bold: true
                    color: textColor
                }
                
                // Power System
                Rectangle {
                    id: powerSystem
                    width: 80
                    height: 80
                    radius: 40
                    color: "transparent"
                    border.color: primaryColor
                    border.width: 2
                    anchors.left: parent.left
                    anchors.leftMargin: parent.width * 0.1
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Power\nSystem"
                        horizontalAlignment: Text.AlignHCenter
                        color: textColor
                    }
                }
                
                // Primary Circuit
                Shape {
                    id: primaryCircuit
                    anchors.left: powerSystem.right
                    anchors.right: transformerSection.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: 100
                    
                    ShapePath {
                        strokeWidth: 3
                        strokeColor: primaryColor
                        startX: 0
                        startY: 0
                        PathLine { x: 80; y: 0 }
                    }
                    
                    Text {
                        anchors.bottom: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Primary Side\n" + ctPrimary + "A / " + vtPrimary + "V"
                        horizontalAlignment: Text.AlignHCenter
                        color: textColor
                    }
                    
                    // Current arrow
                    Shape {
                        y: -15
                        x: 30
                        
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: primaryColor
                            fillColor: primaryColor
                            startX: 0
                            startY: 20
                            PathLine { x: 20; y: 10 }
                            PathLine { x: 20; y: 15 }
                            PathLine { x: 35; y: 15 }
                            PathLine { x: 35; y: 25 }
                            PathLine { x: 20; y: 25 }
                            PathLine { x: 20; y: 30 }
                            PathLine { x: 0; y: 20 }
                        }
                    }
                }
                
                // Transformer Section
                Rectangle {
                    id: transformerSection
                    width: 180
                    height: 250
                    color: "transparent"
                    border.color: circuitView.satLevel < 0.8 ? gridColor : secondaryColor
                    border.width: 2
                    anchors.centerIn: parent
                    
                    // CT Symbol (Two coils facing each other)
                    Shape {
                        id: ctSymbol
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120
                        height: 80
                        
                        // Left Coil (Primary)
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: primaryColor
                            startX: 20
                            startY: 0
                            PathLine { x: 20; y: 80 }
                            PathMove { x: 0; y: 10 }
                            PathArc { x: 40; y: 10; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 0; y: 30 }
                            PathArc { x: 40; y: 30; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 0; y: 50 }
                            PathArc { x: 40; y: 50; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 0; y: 70 }
                            PathArc { x: 40; y: 70; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                        }
                        
                        // Right Coil (Secondary)
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: secondaryColor
                            startX: 100
                            startY: 0
                            PathLine { x: 100; y: 80 }
                            PathMove { x: 80; y: 10 }
                            PathArc { x: 120; y: 10; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 80; y: 30 }
                            PathArc { x: 120; y: 30; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 80; y: 50 }
                            PathArc { x: 120; y: 50; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 80; y: 70 }
                            PathArc { x: 120; y: 70; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                        }
                        
                        // Iron Core
                        ShapePath {
                            strokeWidth: 1
                            strokeColor: textColor
                            fillColor: gridColor
                            startX: 50
                            startY: 5
                            PathLine { x: 70; y: 5 }
                            PathLine { x: 70; y: 75 }
                            PathLine { x: 50; y: 75 }
                            PathLine { x: 50; y: 5 }
                        }
                        
                        Text {
                            anchors.top: parent.bottom
                            anchors.topMargin: 5
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Current Transformer\n" + ctRatio
                            horizontalAlignment: Text.AlignHCenter
                            color: textColor
                        }
                        
                        // Knee point indicator
                        Rectangle {
                            visible: ctKneePoint > 0
                            width: 12
                            height: 12
                            radius: 6
                            x: 100
                            y: 80
                            color: saturationColor(circuitView.satLevel)
                            border.color: textColor
                            border.width: 1
                            
                            Text {
                                anchors.left: parent.right
                                anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Vk: " + ctKneePoint.toFixed(1) + "V"
                                color: textColor
                                font.pixelSize: 10
                            }
                        }
                    }
                    
                    // VT Symbol (Two coils facing each other)
                    Shape {
                        id: vtSymbol
                        anchors.top: ctSymbol.bottom
                        anchors.topMargin: 30
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120
                        height: 80
                        
                        // Left Coil (Primary)
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: primaryColor
                            startX: 20
                            startY: 0
                            PathLine { x: 20; y: 80 }
                            PathMove { x: 0; y: 10 }
                            PathArc { x: 40; y: 10; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 0; y: 30 }
                            PathArc { x: 40; y: 30; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 0; y: 50 }
                            PathArc { x: 40; y: 50; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 0; y: 70 }
                            PathArc { x: 40; y: 70; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                        }
                        
                        // Right Coil (Secondary)
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: secondaryColor
                            startX: 100
                            startY: 0
                            PathLine { x: 100; y: 80 }
                            PathMove { x: 80; y: 10 }
                            PathArc { x: 120; y: 10; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 80; y: 30 }
                            PathArc { x: 120; y: 30; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 80; y: 50 }
                            PathArc { x: 120; y: 50; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                            PathMove { x: 80; y: 70 }
                            PathArc { x: 120; y: 70; radiusX: 20; radiusY: 10; useLargeArc: false; direction: PathArc.Counterclockwise }
                        }
                        
                        // Iron Core
                        ShapePath {
                            strokeWidth: 1
                            strokeColor: textColor
                            fillColor: gridColor
                            startX: 50
                            startY: 5
                            PathLine { x: 70; y: 5 }
                            PathLine { x: 70; y: 75 }
                            PathLine { x: 50; y: 75 }
                            PathLine { x: 50; y: 5 }
                        }
                        
                        Text {
                            anchors.top: parent.bottom
                            anchors.topMargin: 5
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Voltage Transformer\n" + vtRatio
                            horizontalAlignment: Text.AlignHCenter
                            color: textColor
                        }
                        
                        // Burden indicator
                        Rectangle {
                            visible: vtUtilization > 0
                            width: 12
                            height: 12
                            radius: 6
                            x: 100
                            y: 80
                            color: vtUtilization < 50 ? "#4CAF50" : (vtUtilization < 80 ? "#FF9800" : "#F44336")
                            border.color: textColor
                            border.width: 1
                            
                            Text {
                                anchors.left: parent.right
                                anchors.leftMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Utilization: " + vtUtilization.toFixed(1) + "%"
                                color: textColor
                                font.pixelSize: 10
                            }
                        }
                    }
                }
                
                // Secondary Circuit and Load
                Rectangle {
                    id: load
                    width: 100
                    height: 60
                    color: "transparent"
                    border.color: secondaryColor
                    border.width: 2
                    anchors.left: transformerSection.right
                    anchors.leftMargin: 80
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Load\n" + ctBurden.toFixed(1) + " VA\n" + (ctPowerFactor * 100).toFixed(0) + "% PF"
                        horizontalAlignment: Text.AlignHCenter
                        color: textColor
                    }
                }
                
                // Secondary wiring
                Shape {
                    id: secondaryCircuit
                    anchors.left: transformerSection.right
                    anchors.right: load.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: 100
                    
                    ShapePath {
                        strokeWidth: 3
                        strokeColor: secondaryColor
                        startX: 0
                        startY: 0
                        PathLine { x: 80; y: 0 }
                    }
                    
                    Text {
                        anchors.bottom: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Secondary Side\n" + ctSecondary + "A / " + vtSecondary + "V"
                        horizontalAlignment: Text.AlignHCenter
                        color: textColor
                    }
                    
                    // Current arrow
                    Shape {
                        y: -15
                        x: 30
                        
                        ShapePath {
                            strokeWidth: 2
                            strokeColor: secondaryColor
                            fillColor: secondaryColor
                            startX: 0
                            startY: 20
                            PathLine { x: 20; y: 10 }
                            PathLine { x: 20; y: 15 }
                            PathLine { x: 35; y: 15 }
                            PathLine { x: 35; y: 25 }
                            PathLine { x: 20; y: 25 }
                            PathLine { x: 20; y: 30 }
                            PathLine { x: 0; y: 20 }
                        }
                    }
                }
                
                // Status indicators
                Rectangle {
                    id: statusSection
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.8
                    height: 80
                    color: "transparent"
                    border.color: gridColor
                    border.width: 1
                    
                    Grid {
                        anchors.centerIn: parent
                        columns: 3
                        
                        
                        // CT Status
                        Rectangle {
                            width: 100
                            height: 50
                            color: saturationColor(circuitView.satLevel)
                            radius: 5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "CT Status: " + (circuitView.satLevel < 0.5 ? "Good" : 
                                                    (circuitView.satLevel < 0.8 ? "Warning" : "Saturated"))
                                color: "white"
                                font.bold: true
                            }
                        }
                        
                        // Error Margin
                        Rectangle {
                            width: 100
                            height: 50
                            color: ctErrorMargin > parseFloat(ctAccuracyClass) ? "#F44336" : "#4CAF50"
                            radius: 5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Error: " + ctErrorMargin.toFixed(2) + "%\nClass: " + ctAccuracyClass
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                        
                        // VT Status
                        Rectangle {
                            width: 100
                            height: 50
                            color: vtUtilization < 50 ? "#4CAF50" : (vtUtilization < 80 ? "#FF9800" : "#F44336")
                            radius: 5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "VT Load: " + vtUtilization.toFixed(1) + "%\n" + 
                                     (vtImpedance > 0 ? vtImpedance.toFixed(1) + " Ω" : "")
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }
            }
            
            // Tab 2: Saturation Curve
            ChartView {
                id: saturationChart
                title: "CT Saturation Curve"
                antialiasing: true
                legend.visible: true
                legend.alignment: Qt.AlignBottom
                theme: darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
                
                ValueAxis {
                    id: axisX
                    titleText: "Voltage (V)"
                    min: 0
                    max: ctKneePoint * 2.5 || 100
                }
                
                ValueAxis {
                    id: axisY
                    titleText: "Current (A)"
                    min: 0
                    max: ctSecondary * 4 || 20
                }

                function updateSaturationCurve() {
                    if (!satCurve) return;
                    
                    // Clear existing data
                    satCurve.clear();
                    
                    // Always create a curve, even with zero knee point
                    var effectiveKneePoint = ctKneePoint > 0 ? ctKneePoint : 50;
                    var effectiveSecondary = ctSecondary > 0 ? ctSecondary : 5;
                    
                    // First create linear region (up to knee point)
                    for (var i = 0; i <= 10; i++) {
                        var v = (effectiveKneePoint * i) / 10;
                        var current = (v * effectiveSecondary) / effectiveKneePoint;
                        satCurve.append(v, current);
                    }
                    
                    // Then create non-linear saturation region (after knee point)
                    for (var j = 1; j <= 15; j++) {
                        var factor = 0.2 * j; // 0.2 to 3.0
                        var v = effectiveKneePoint * (1 + factor);
                        var excess = v - effectiveKneePoint;
                        
                        // More pronounced saturation curve
                        var current = effectiveSecondary + (effectiveSecondary * 3 * Math.pow(excess / effectiveKneePoint, 0.7));
                        satCurve.append(v, current);
                    }
                    
                    // Update knee point marker
                    if (kneePoint) {
                        kneePoint.clear();
                        if (ctKneePoint > 0) {
                            kneePoint.append(ctKneePoint, ctSecondary);
                        }
                    }
                    
                    // Update operating point
                    if (operatingPoint) {
                        operatingPoint.clear();
                        if (ctBurden > 0 && ctSecondary > 0) {
                            var vOp = ctSecondary * Math.sqrt(ctBurden);
                            var iOp = calculateCurrent(vOp);
                            operatingPoint.append(0, 0);
                            operatingPoint.append(vOp, iOp);
                        }
                    }
                    
                    // Update axis limits based on data
                    axisX.max = ctKneePoint > 0 ? ctKneePoint * 3 : 150;
                    axisY.max = ctSecondary > 0 ? ctSecondary * 5 : 25;
                }

                LineSeries {
                    id: satCurve
                    name: "Saturation Curve"
                    axisX: axisX
                    axisY: axisY
                    color: primaryColor
                    width: 2
                    
                    Component.onCompleted: {
                        saturationChart.updateSaturationCurve();
                    }
                }
                
                LineSeries {
                    id: operatingPoint
                    name: "Operating Point"
                    axisX: axisX
                    axisY: axisY
                    color: secondaryColor
                    width: 2
                    
                    // Remove the Component.onCompleted handler that's causing issues
                }
                
                ScatterSeries {
                    id: kneePoint
                    name: "Knee Point"
                    axisX: axisX
                    axisY: axisY
                    color: "#F44336"
                    markerSize: 10
                    
                    Component.onCompleted: {
                        if (ctKneePoint > 0) {
                            append(ctKneePoint, ctSecondary);
                        }
                    }
                }
                
                // Update the chart when properties change
                onWidthChanged: updateSaturationCurve()
            }
            
            // Tab 3: Waveforms
            ChartView {
                id: waveformChart
                title: "Current and Voltage Waveforms"
                antialiasing: true
                legend.visible: true
                legend.alignment: Qt.AlignBottom
                theme: darkMode ? ChartView.ChartThemeDark : ChartView.ChartThemeLight
                
                ValueAxis {
                    id: timeAxis
                    titleText: "Time (ms)"
                    min: 0
                    max: 20  // One cycle at 50Hz = 20ms
                }
                
                ValueAxis {
                    id: currentAxis
                    titleText: "Current (A)"
                    min: -ctPrimary * 1.5 || -150
                    max: ctPrimary * 1.5 || 150
                }
                
                ValueAxis {
                    id: voltageAxis
                    titleText: "Voltage (V)"
                    min: -vtSecondary * 1.5 || -150
                    max: vtSecondary * 1.5 || 150
                    visible: false
                }
                
                LineSeries {
                    id: primaryCurrentWave
                    name: "Primary Current"
                    axisX: timeAxis
                    axisY: currentAxis
                    color: primaryColor
                    width: 2
                }
                
                LineSeries {
                    id: secondaryCurrentWave
                    name: "Secondary Current (scaled)"
                    axisX: timeAxis
                    axisY: currentAxis
                    color: secondaryColor
                    width: 2
                }
                
                LineSeries {
                    id: secondaryVoltageWave
                    name: "Secondary Voltage"
                    axisX: timeAxis
                    axisY: voltageAxis
                    color: "#9C27B0"  // Purple
                    width: 2
                }
                
                // Generate waveforms
                Component.onCompleted: generateWaveforms()
                
                // Function to generate waveforms
                function generateWaveforms() {
                    primaryCurrentWave.clear();
                    secondaryCurrentWave.clear();
                    secondaryVoltageWave.clear();
                    
                    // CT Ratio and saturation calculations
                    var ratio = ctPrimary / ctSecondary;
                    var satLevel = 0;
                    if (ctBurden > 0 && ctKneePoint > 0) {
                        var vOp = ctSecondary * Math.sqrt(ctBurden);
                        satLevel = vOp / ctKneePoint;
                    }
                    
                    // Generate sine waves for one cycle (50Hz = 20ms)
                    for (var t = 0; t <= 20; t += 0.1) {
                        // Calculate primary current
                        var primaryI = ctPrimary * Math.sin(2 * Math.PI * t / 20);
                        primaryCurrentWave.append(t, primaryI);
                        
                        // Calculate secondary current (with saturation distortion if applicable)
                        var secondaryI;
                        if (satLevel > 0.8 && Math.abs(primaryI) > 0.8 * ctPrimary) {
                            // Add saturation distortion - limit the peaks
                            secondaryI = (primaryI / ratio) * (1 - 0.5 * Math.pow((Math.abs(primaryI) - 0.8 * ctPrimary) / (0.2 * ctPrimary), 2));
                        } else {
                            secondaryI = primaryI / ratio;
                        }
                        
                        // Scale secondary current for visibility
                        secondaryCurrentWave.append(t, secondaryI * ratio);
                        
                        // Calculate secondary voltage (90 degrees out of phase with current)
                        var secondaryV = vtSecondary * Math.sin(2 * Math.PI * t / 20 + Math.PI/2);
                        secondaryVoltageWave.append(t, secondaryV);
                    }
                }
            }
        }
    }

    onCtBurdenChanged: {
        if (viewMode === 2 && waveformChart) {
            waveformChart.generateWaveforms();
        } 
        if (viewMode === 1 && saturationChart) {
            saturationChart.updateSaturationCurve();
        }
    }
    
    onCtKneePointChanged: {
        if (viewMode === 2 && waveformChart) {
            waveformChart.generateWaveforms();
        }
        if (viewMode === 1 && saturationChart) {
            saturationChart.updateSaturationCurve();
        }
    }

    onViewModeChanged: {
        Qt.callLater(function() {
            if (viewMode === 1 && saturationChart) {
                saturationChart.updateSaturationCurve();
            } else if (viewMode === 2 && waveformChart) {
                waveformChart.generateWaveforms();
            }
        });
    }
}
