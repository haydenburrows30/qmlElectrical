import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import components 1.0

Rectangle {
    id: root
    color: "transparent"
    
    // Bind power values directly to the model
    property real activePower: sineModel.activePower
    property real reactivePower: sineModel.reactivePower
    property real apparentPower: sineModel.apparentPower
    property real powerFactor: sineModel.averagePowerFactor
    
    // Scaling properties
    property real triangleScale: 100
    property real minPowerValue: 0.1
    property real maxPowerValue: 2000
    property real minScale: 400
    property real padding: 10
    property real labelPadding: 40

    // Container for triangle and labels
    Item {
        id: triangleContainer
        anchors.fill: parent
        anchors.margins: 10

        // Calculate triangle dimensions
        property real baseLength: activePower * triangleScale
        property real triangleHeight: reactivePower * triangleScale
        property real maxSize: Math.min(width * 1, height * 1)

        // Calculate hypotenuse length using Pythagorean theorem
        property real hypotenuseLength: Math.sqrt(baseLength * baseLength + triangleHeight * triangleHeight)
        
        // Scale factor to fit triangle within container
        property real scaleFactor: Math.min(
            maxSize / Math.max(baseLength, 0.8),
            maxSize / Math.max(triangleHeight, 0.8)
        )

        // Triangle shape
        Shape {
            id: triangle
            anchors.centerIn: parent

            ShapePath {
                strokeWidth: 2
                strokeColor: "black"
                fillColor: "transparent"
                
                // Start at origin point
                startX: 0
                startY: 0
                
                // Draw active power (horizontal line)
                PathLine {
                    x: triangleContainer.baseLength * triangleContainer.scaleFactor
                    y: 0
                }
                
                // Draw hypotenuse
                PathLine {
                    x: 0
                    y: -triangleContainer.triangleHeight * triangleContainer.scaleFactor
                }
                
                // Close triangle
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        // Labels with dynamic positioning
        Text {
            id: activePowerLabel
            anchors.top: triangle.bottom
            anchors.horizontalCenter: triangle.horizontalCenter
            anchors.topMargin: 10
            text: "P = " + activePower.toFixed(1) + " kW"
        }
        
        Text {
            id: reactivePowerLabel
            anchors.right: triangle.left
            anchors.verticalCenter: triangle.verticalCenter
            anchors.rightMargin: 10
            text: "Q = " + reactivePower.toFixed(1) + " kVAR"
        }

        // Direct Text element approach for apparent power label
        Item {
            id: apparentPowerLabelContainer
            anchors.fill: parent
            
            // Calculate midpoint of hypotenuse
            property real centerX: width / 2
            property real centerY: height / 2
            property real scaledHeight: triangleContainer.triangleHeight * triangleContainer.scaleFactor
            property real scaledBase: triangleContainer.baseLength * triangleContainer.scaleFactor
            property real startX: centerX
            property real startY: centerY - scaledHeight
            property real endX: centerX + scaledBase
            property real endY: centerY
            property real midX: (startX + endX) / 2
            property real midY: (startY + endY) / 2
            
            // Calculate angle in radians then convert to degrees
            property real angleRadians: Math.atan2(startY - endY, endX - startX)
            property real angleDegrees: angleRadians * 180 / Math.PI
            
            Text {
                id: apparentPowerText
                text: "S = " + apparentPower.toFixed(1) + " kVA"
                anchors.centerIn: parent
                
                // Position at midpoint of hypotenuse
                x: parent.midX - width/2 - parent.centerX
                y: parent.midY - height/2 - parent.centerY - 15 // Offset above line
                
                // Apply rotation to align with hypotenuse
                transformOrigin: Item.Center
                rotation: parent.angleDegrees
                
                color: sideBar.toggle1 ? "#ffffff" : "#000000"
                visible: false // Hide this, used as reference
            }
            
            // Draw using Canvas for perfect alignment
            Canvas {
                id: apparentPowerCanvas
                anchors.fill: parent
                property string powerText: "S = " + apparentPower.toFixed(1) + " kVA"
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    // Get coordinates
                    var centerX = width / 2;
                    var centerY = height / 2;
                    var scaledHeight = triangleContainer.triangleHeight * triangleContainer.scaleFactor;
                    var scaledBase = triangleContainer.baseLength * triangleContainer.scaleFactor;
                    
                    var startX = centerX;
                    var startY = centerY - scaledHeight;
                    var endX = centerX + scaledBase;
                    var endY = centerY;
                    
                    var midX = (startX + endX) / 2;
                    var midY = (startY + endY) / 2;
                    
                    // Calculate the angle for text alignment - key fix here!
                    var angleForLine = Math.atan2(startY - endY, endX - startX);
                    
                    // Key fix: We need to align text along the hypotenuse, not perpendicular to it
                    // For text to be parallel to the line, we rotate by the same angle
                    
                    ctx.save();
                    ctx.translate(midX, midY - 10); // Position slightly above line
                    ctx.rotate(angleForLine); // Use the exact same angle as the line
                    
                    // Set text properties
                    ctx.font = "14px sans-serif";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    ctx.fillStyle = sideBar.toggle1 ? "#ffffff" : "#000000";
                    
                    // Draw text at origin (which is now at midpoint of hypotenuse)
                    ctx.fillText(powerText, 0, 0);
                    
                    ctx.restore();
                }
            }
        }

        Text {
            id: powerFactorLabel
            anchors.right: triangle.right
            anchors.bottom: triangle.bottom
            anchors.margins: 10
            text: "PF = " + powerFactor.toFixed(3)
            font.bold: true
        }

        // Angle arc
        Shape {
            id: angleArc
            anchors.fill: triangle

            ShapePath {
                strokeWidth: 1
                strokeColor: "blue"
                fillColor: "transparent"
                
                PathArc {
                    x: 30
                    y: 0
                    radiusX: 30
                    radiusY: 30
                    useLargeArc: false
                }
            }
        }

        // Angle label
        Text {
            anchors.left: triangle.left
            anchors.bottom: triangle.bottom
            anchors.margins: 25
            text: "φ = " + (Math.acos(powerFactor) * 180 / Math.PI).toFixed(1) + "°"
            font.italic: true
        }
    }
    
    // Update the canvas when the triangle values change
    onActivePowerChanged: apparentPowerCanvas.requestPaint()
    onReactivePowerChanged: apparentPowerCanvas.requestPaint()
    onApparentPowerChanged: apparentPowerCanvas.requestPaint()
    onWidthChanged: apparentPowerCanvas.requestPaint()
    onHeightChanged: apparentPowerCanvas.requestPaint()
}
