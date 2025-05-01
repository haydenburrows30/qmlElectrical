import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import QtQuick.Controls.Universal
import QtQuick.Dialogs

import LightningProtectionCalculator 1.0

Dialog {
    id: visualizerDialog
    title: "Lightning Protection System - Visualization"
    modal: true
    width: 800
    height: 800
    
    property LightningProtectionCalculator calculator
    
    // Define colors as string properties
    property string roofColor: "#4285F4"        // Google blue
    property string wallColor: "#DADCE0"        // Light gray
    property string groundColor: "#34A853"      // Google green
    property string meshColor: "#F4B400"        // Google yellow
    property string downConductorColor: "#EA4335" // Google red
    property string sphereColor: "#F4B400"      // Google yellow
    
    // Rename the signal to avoid conflict with built-in Dialog.closed signal
    signal visualizerClosed()
    
    onRejected: visualizerClosed()
    
    standardButtons: Dialog.Close
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        Label {
            text: "Visualization of protection system for a structure " + 
                  calculator.structureLength + "m × " + calculator.structureWidth + "m × " + calculator.structureHeight + "m"
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Legend for the visualization
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            
            Rectangle {
                width: 16
                height: 16
                color: roofColor
            }
            Label {
                text: "Structure"
                Layout.rightMargin: 10
            }
            
            Rectangle {
                width: 16
                height: 16
                color: meshColor
            }
            Label {
                text: "Mesh Grid"
                Layout.rightMargin: 10
                visible: calculator.useMeshMethod
            }
            
            Rectangle {
                width: 16
                height: 16
                color: downConductorColor
            }
            Label {
                text: "Down Conductors"
                Layout.rightMargin: 10
            }
            
            Rectangle {
                width: 16
                height: 16
                color: sphereColor
                opacity: 0.5
            }
            Label {
                text: "Protection Zone"
                visible: calculator.useRollingSphere
            }
        }
        
        // 2D Visualization (top view and side view)
        TabBar {
            id: viewSelector
            Layout.fillWidth: true
            
            TabButton {
                text: "Top View"
                width: implicitWidth
            }
            TabButton {
                text: "Side View"
                width: implicitWidth
            }
        }
        
        StackLayout {
            currentIndex: viewSelector.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            // Top View
            Item {
                width: parent.width
                height: parent.height
                
                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    border.color: "gray"
                }
                
                Item {
                    id: topViewContainer
                    anchors.fill: parent
                    anchors.margins: 20
                    
                    // Calculate scale to fit view
                    property real scale: Math.min(
                        width / (calculator.structureLength * 1.2),
                        height / (calculator.structureWidth * 1.2)
                    )
                    
                    // Building outline
                    Rectangle {
                        id: buildingTopView
                        x: (parent.width - width) / 2
                        y: (parent.height - height) / 2
                        width: calculator.structureLength * parent.scale
                        height: calculator.structureWidth * parent.scale
                        color: wallColor
                        border.color: "black"
                        border.width: 1
                    }
                    
                    // Protection zone (if rolling sphere is enabled) - Fixed to draw correct protection zone
                    Canvas {
                        visible: calculator.useRollingSphere
                        anchors.fill: parent
                        
                        onPaint: {
                            if (!calculator.useRollingSphere) return;
                            
                            var ctx = getContext("2d");
                            ctx.reset();
                            
                            // Set up styles for the protection zone
                            ctx.strokeStyle = sphereColor;
                            ctx.lineWidth = 2;
                            ctx.fillStyle = Qt.rgba(
                                parseInt(sphereColor.substr(1, 2), 16) / 255,
                                parseInt(sphereColor.substr(3, 2), 16) / 255,
                                parseInt(sphereColor.substr(5, 2), 16) / 255,
                                0.1
                            );
                            
                            // Calculate the protection zone boundary (a rounded rectangle)
                            var structureX = buildingTopView.x;
                            var structureY = buildingTopView.y;
                            var structureWidth = buildingTopView.width;
                            var structureHeight = buildingTopView.height;
                            var radius = calculator.rollingSphereRadius * topViewContainer.scale;
                            
                            // Create a path for the protection zone (rounded rectangle with corner radius matching the sphere radius)
                            ctx.beginPath();
                            
                            // Draw the protection zone as four separate arcs (one for each corner) connected by straight lines
                            // Top-left corner
                            ctx.moveTo(structureX - radius, structureY);
                            ctx.lineTo(structureX - radius, structureY - radius);
                            ctx.arcTo(structureX - radius, structureY - radius, structureX, structureY - radius, radius);
                            
                            // Top-right corner
                            ctx.lineTo(structureX + structureWidth, structureY - radius);
                            ctx.arcTo(structureX + structureWidth + radius, structureY - radius, 
                                     structureX + structureWidth + radius, structureY, radius);
                            
                            // Bottom-right corner
                            ctx.lineTo(structureX + structureWidth + radius, structureY + structureHeight);
                            ctx.arcTo(structureX + structureWidth + radius, structureY + structureHeight + radius,
                                     structureX + structureWidth, structureY + structureHeight + radius, radius);
                            
                            // Bottom-left corner
                            ctx.lineTo(structureX, structureY + structureHeight + radius);
                            ctx.arcTo(structureX - radius, structureY + structureHeight + radius,
                                     structureX - radius, structureY + structureHeight, radius);
                            
                            // Close the path
                            ctx.lineTo(structureX - radius, structureY);
                            
                            // Draw the path
                            ctx.stroke();
                            ctx.fill();
                        }
                    }
                    
                    // Mesh grid (if enabled)
                    Canvas {
                        id: meshGridCanvas
                        anchors.fill: buildingTopView
                        visible: calculator.useMeshMethod
                        
                        onPaint: {
                            if (!calculator.useMeshMethod) return;
                            
                            var ctx = getContext("2d");
                            ctx.strokeStyle = meshColor;
                            ctx.lineWidth = 2;
                            
                            var meshSize = calculator.meshSize * topViewContainer.scale;
                            var width = buildingTopView.width;
                            var height = buildingTopView.height;
                            
                            // Draw horizontal lines
                            for (var y = 0; y <= height; y += meshSize) {
                                ctx.beginPath();
                                ctx.moveTo(0, y);
                                ctx.lineTo(width, y);
                                ctx.stroke();
                            }
                            
                            // Draw vertical lines
                            for (var x = 0; x <= width; x += meshSize) {
                                ctx.beginPath();
                                ctx.moveTo(x, 0);
                                ctx.lineTo(x, height);
                                ctx.stroke();
                            }
                        }
                    }
                    
                    // Down conductors (red dots)
                    Repeater {
                        id: downConductorsRepeater
                        model: {
                            var conductors = [];
                            var spacing = calculator.downConductorSpacing;
                            var length = calculator.structureLength;
                            var width = calculator.structureWidth;
                            
                            // Corner conductors
                            conductors.push({x: 0, y: 0});
                            conductors.push({x: length, y: 0});
                            conductors.push({x: 0, y: width});
                            conductors.push({x: length, y: width});
                            
                            // Conductors along length
                            if (length > spacing) {
                                var numConductorsLength = Math.floor(length / spacing) - 1;
                                for (var i = 1; i <= numConductorsLength; i++) {
                                    conductors.push({x: i * spacing, y: 0});
                                    conductors.push({x: i * spacing, y: width});
                                }
                            }
                            
                            // Conductors along width
                            if (width > spacing) {
                                var numConductorsWidth = Math.floor(width / spacing) - 1;
                                for (var i = 1; i <= numConductorsWidth; i++) {
                                    conductors.push({x: 0, y: i * spacing});
                                    conductors.push({x: length, y: i * spacing});
                                }
                            }
                            
                            return conductors;
                        }
                        
                        Rectangle {
                            x: buildingTopView.x + (modelData.x * topViewContainer.scale) - width/2
                            y: buildingTopView.y + (modelData.y * topViewContainer.scale) - height/2
                            width: 8
                            height: 8
                            radius: 4
                            color: downConductorColor
                            
                            ToolTip.visible: mouseArea.containsMouse
                            ToolTip.text: "Down Conductor"
                            
                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                    
                    Label {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Building dimensions: " + calculator.structureLength + "m × " + calculator.structureWidth + "m"
                    }
                }
            }
            
            // Side View
            Item {
                width: parent.width
                height: parent.height
                
                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    border.color: "gray"
                }
                
                Item {
                    id: sideViewContainer
                    anchors.fill: parent
                    anchors.margins: 20
                    
                    // Calculate scale to fit view
                    property real scale: Math.min(
                        width / (calculator.structureLength * 1.5),
                        height / ((calculator.structureHeight + calculator.rollingSphereRadius) * 1.2)
                    )
                    
                    // Building side view
                    Rectangle {
                        id: buildingSideView
                        x: (parent.width - width) / 2
                        y: parent.height - height - 40 // Leave space at bottom for text
                        width: calculator.structureLength * parent.scale
                        height: calculator.structureHeight * parent.scale
                        color: wallColor
                        border.color: "black"
                        border.width: 1
                    }
                    
                    // Roof
                    Rectangle {
                        x: buildingSideView.x
                        y: buildingSideView.y
                        width: buildingSideView.width
                        height: 5
                        color: roofColor
                    }
                    
                    // Ground
                    Rectangle {
                        x: 0
                        y: buildingSideView.y + buildingSideView.height
                        width: parent.width
                        height: 10
                        color: groundColor
                    }
                    
                    // Down conductors
                    Repeater {
                        model: {
                            var conductors = [];
                            var spacing = calculator.downConductorSpacing;
                            var length = calculator.structureLength;
                            
                            // Ensure we show at least the corners
                            conductors.push({x: 0});
                            conductors.push({x: length});
                            
                            // Add additional conductors based on spacing
                            if (length > spacing) {
                                var numConductors = Math.floor(length / spacing) - 1;
                                for (var i = 1; i <= numConductors; i++) {
                                    conductors.push({x: i * spacing});
                                }
                            }
                            
                            return conductors;
                        }
                        
                        Rectangle {
                            x: buildingSideView.x + (modelData.x * sideViewContainer.scale) - width/2
                            y: buildingSideView.y
                            width: 4
                            height: buildingSideView.height
                            color: downConductorColor
                        }
                    }
                    
                    // Rolling sphere visualization (only if enabled)
                    Canvas {
                        id: rollingSphereCanvas
                        anchors.fill: parent
                        visible: calculator.useRollingSphere
                        
                        onPaint: {
                            if (!calculator.useRollingSphere) return;
                            
                            var ctx = getContext("2d");
                            ctx.strokeStyle = sphereColor;
                            ctx.fillStyle = Qt.rgba(
                                parseInt(sphereColor.substr(1, 2), 16) / 255,
                                parseInt(sphereColor.substr(3, 2), 16) / 255,
                                parseInt(sphereColor.substr(5, 2), 16) / 255,
                                0.2
                            );
                            ctx.lineWidth = 2;
                            
                            var radius = calculator.rollingSphereRadius * sideViewContainer.scale;
                            var buildingLeft = buildingSideView.x;
                            var buildingRight = buildingSideView.x + buildingSideView.width;
                            var roofY = buildingSideView.y;
                            
                            // Draw sphere on left corner
                            ctx.beginPath();
                            ctx.arc(buildingLeft, roofY, radius, -Math.PI, 0);
                            ctx.stroke();
                            ctx.fill();
                            
                            // Draw sphere on right corner
                            ctx.beginPath();
                            ctx.arc(buildingRight, roofY, radius, -Math.PI, 0);
                            ctx.stroke();
                            ctx.fill();
                            
                            // If building width is greater than 2x sphere radius, draw sphere in middle positions
                            if (buildingSideView.width > radius * 2) {
                                var numSpheres = Math.floor(buildingSideView.width / (radius * 2));
                                for (var i = 1; i <= numSpheres; i++) {
                                    var centerX = buildingLeft + (i * buildingSideView.width / (numSpheres + 1));
                                    ctx.beginPath();
                                    ctx.arc(centerX, roofY, radius, -Math.PI, 0);
                                    ctx.stroke();
                                    ctx.fill();
                                }
                            }
                        }
                    }
                    
                    Label {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Building height: " + calculator.structureHeight + "m, length: " + calculator.structureLength + "m"
                    }
                }
            }
        }
        
        // Information and metrics
        GroupBox {
            title: "Protection System Parameters"
            Layout.fillWidth: true
            
            GridLayout {
                columns: 3
                anchors.fill: parent
                
                Label { 
                    text: "Protection Level:" 
                    font.bold: true
                }
                Label { 
                    text: calculator.protectionLevel
                    Layout.columnSpan: 2
                }
                
                Label { 
                    text: "Rolling Sphere Radius:" 
                    font.bold: true
                    visible: calculator.useRollingSphere
                }
                Label { 
                    text: calculator.rollingSphereRadius + " m"
                    visible: calculator.useRollingSphere
                    Layout.columnSpan: 2
                }
                
                Label { 
                    text: "Mesh Size:" 
                    font.bold: true
                    visible: calculator.useMeshMethod
                }
                Label { 
                    text: calculator.meshSize + " m × " + calculator.meshSize + " m"
                    visible: calculator.useMeshMethod
                    Layout.columnSpan: 2
                }
                
                Label { 
                    text: "Down Conductor Spacing:" 
                    font.bold: true
                }
                Label { 
                    text: calculator.downConductorSpacing + " m"
                    Layout.columnSpan: 2
                }
                
                Label { 
                    text: "Required Down Conductors:" 
                    font.bold: true
                }
                Label { 
                    text: calculator.downConductorCount.toString()
                    Layout.columnSpan: 2
                }
                
                Label { 
                    text: "Protection Probability:" 
                    font.bold: true
                }
                ProgressBar {
                    from: 0
                    to: 100
                    value: (calculator && (calculator.useMeshMethod || calculator.useRollingSphere)) 
                           ? calculator.protectionProbability : 0
                    Layout.fillWidth: true
                }
                Label {
                    text: calculator.protectionProbability.toFixed(1) + "%"
                    font.bold: true
                }
            }
        }
    }
}
