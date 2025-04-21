import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtCharts

import "../style"
import "../charts"

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
    readonly property var ctPrimary: parseFloat(ctRatio.split('/')[0])
    readonly property var ctSecondary: parseFloat(ctRatio.split('/')[1])
    readonly property var vtPrimary: parseFloat(vtRatio.split('/')[0])
    readonly property var vtSecondary: parseFloat(vtRatio.split('/')[1])
    
    // Visualization Mode
    property int viewMode: 0  // 0=Circuit, 1=Saturation, 2=Waveform
    
    // Utility function to update visualizations
    function updateVisualizations() {
        if (viewMode === 1 && saturationChart) {
            saturationChart.updateSaturationCurve();
        } else if (viewMode === 2 && waveformChart) {
            waveformChart.generateWaveforms();
        }
    }
    
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
    
    // Function to adjust layout based on available space - moved to top level
    function adjustLayout() {
        if (!circuitView) return;
        
        // Adjust transformer section size based on available space
        var availableWidth = circuitView.width;
        var availableHeight = circuitView.height - 120; // Account for header and status sections
        
        if (availableWidth < 600) {
            transformerSection.width = Math.min(160, availableWidth * 0.4);
        } else {
            transformerSection.width = 180;
        }
        
        if (availableHeight < 300) {
            transformerSection.height = Math.max(200, availableHeight * 0.8);
        } else {
            transformerSection.height = 250;
        }
    }
    
    // Connections for layout updates - moved to top level
    Connections {
        target: circuitView
        function onWidthChanged() { layoutTimer.restart() }
        function onHeightChanged() { layoutTimer.restart() }
    }
    
    // Timer for layout updates - moved to top level
    Timer {
        id: layoutTimer
        interval: 100
        onTriggered: adjustLayout()
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
                
                Rectangle {
                    id: transformerSection
                    width: 180
                    height: 250
                    color: "transparent"
                    border.color: circuitView.satLevel < 0.8 ? gridColor : secondaryColor
                    border.width: 2
                    anchors.centerIn: parent
                    
                    Shape {
                        id: ctSymbol
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120
                        height: 80
                        
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
                    
                    Shape {
                        id: vtSymbol
                        anchors.top: ctSymbol.bottom
                        anchors.topMargin: 30
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 120
                        height: 80
                        
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
                
                Rectangle {
                    id: statusSection
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width * 0.9, 500)
                    height: parent.height < 400 ? 70 : 80
                    color: "transparent"
                    border.color: gridColor
                    border.width: 1
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: parent.width < 450 ? 5 : 10
                        
                        Rectangle {
                            Layout.preferredWidth: parent.parent.width < 450 ? 130 : 150
                            Layout.preferredHeight: parent.parent.height < 400 ? 40 : 50
                            color: saturationColor(circuitView.satLevel)
                            radius: 5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "CT Status: " + (circuitView.satLevel < 0.5 ? "Good" : 
                                                    (circuitView.satLevel < 0.8 ? "Warning" : "Saturated"))
                                color: "white"
                                font.bold: true
                                font.pixelSize: parent.parent.parent.width < 450 ? 10 : 12
                            }
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: parent.parent.width < 450 ? 130 : 150
                            Layout.preferredHeight: parent.parent.height < 400 ? 40 : 50
                            color: ctErrorMargin > parseFloat(ctAccuracyClass) ? "#F44336" : "#4CAF50"
                            radius: 5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "Error: " + ctErrorMargin.toFixed(2) + "%\nClass: " + ctAccuracyClass
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: parent.parent.parent.width < 450 ? 10 : 12
                            }
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: parent.parent.width < 450 ? 130 : 150
                            Layout.preferredHeight: parent.parent.height < 400 ? 40 : 50
                            color: vtUtilization < 50 ? "#4CAF50" : (vtUtilization < 80 ? "#FF9800" : "#F44336")
                            radius: 5
                            
                            Text {
                                anchors.centerIn: parent
                                text: "VT Load: " + vtUtilization.toFixed(1) + "%\n" + 
                                     (vtImpedance > 0 ? vtImpedance.toFixed(1) + " Ω" : "")
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: parent.parent.parent.width < 450 ? 10 : 12
                            }
                        }
                    }
                }
            }
            
            SaturationChart {id: saturationChart}
            
            CTWaveFormChart {id: waveformChart}
        }
    }

    // Property change handlers - grouped together for better organization
    onCtBurdenChanged: updateVisualizations()
    onCtKneePointChanged: updateVisualizations()
    onViewModeChanged: Qt.callLater(updateVisualizations) // Removed parentheses
    onCtRatioChanged: Qt.callLater(updateVisualizations)  // Removed parentheses
    onCtPowerFactorChanged: Qt.callLater(updateVisualizations)  // Removed parentheses

    // Component initialization
    Component.onCompleted: {
        Qt.callLater(function() {
            if (circuitView) {
                adjustLayout();
            }
            updateVisualizations();
        });
    }
}
