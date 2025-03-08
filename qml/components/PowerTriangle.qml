import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import components 1.0

Rectangle {
    id: root
    color: "transparent"
    property real activePower: 0
    property real reactivePower: 0
    property real apparentPower: 0
    property real powerFactor: 0
    property real triangleScale: 5

    // Container for triangle and labels
    Item {
        id: triangleContainer
        anchors.fill: parent
        anchors.margins: 10

        // Calculate triangle dimensions
        property real baseLength: activePower * triangleScale
        property real triangleHeight: reactivePower * triangleScale
        property real maxSize: Math.min(width * 1, height * 1)
        
        // Scale factor to fit triangle within container
        property real scaleFactor: Math.min(
            maxSize / Math.max(baseLength, 0.8),
            maxSize / Math.max(triangleHeight, 0.8)
        )

        // Triangle shape
        Shape {
            id: triangle
            anchors.centerIn: parent
            // anchors.right: parent.right
            // anchors.bottom: parent.bottom

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
        
        Text {
            id: apparentPowerLabel
            anchors.horizontalCenter: triangle.horizontalCenter
            anchors.bottom: triangle.verticalCenter
            anchors.bottomMargin: triangleContainer.height * 0.1
            text: "S = " + apparentPower.toFixed(1) + " kVA"
            rotation: -Math.atan2(triangleContainer.triangleHeight, triangleContainer.baseLength) * 180 / Math.PI
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
}
