import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Particles
import QtQuick.Shapes

import "../../components/style"
Page {

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
        }
        spacing: 24
        
        Label {
            text: "Material Design Text Fields"
            font.pixelSize: 24
            font.weight: Font.Medium
            Layout.fillWidth: true
        }
        
        // Filled style (default)
        MaterialTextField {
            Layout.fillWidth: true
            placeholderText: "Full Name"
            Layout.minimumHeight: 100
            // filled: false
        }

        Rectangle {
            width: 300
            height: 200
            border.color: window.modeToggled ? "white" : "black"
            border.width: 2
            color: "transparent"
            radius: 8

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                width: 40
                height: 40
                border.color: window.modeToggled ? "white" : "black"
                border.width: 2
                color: "transparent"
                bottomLeftRadius: 8
                topRightRadius: 8

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -3
                    anchors.bottomMargin: -3
                    anchors.rightMargin: -3
                    anchors.topMargin: -3
                    color: window.modeToggled ? "black" : "white"
                    bottomLeftRadius: 8
                    topRightRadius: 8
                    topLeftRadius: 0
                    bottomRightRadius: 0
                    z: -1
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -5
                    anchors.bottomMargin: -5
                    width: 40
                    height: 40
                    color: window.modeToggled ? "black" : "white"
                    z: -2
                    border.color: window.modeToggled ? "white" : "black"
                    border.width: 2
                    bottomLeftRadius: 11
                    topRightRadius: 8
                    topLeftRadius: 0
                    bottomRightRadius: 0
                }
            }
        }

        Rectangle {
            id: myRectangle
            width: 200
            height: 100
            radius: 50
            color: "#c0d0f0"
            RectangularShadow {
                anchors.fill: myRectangle
                // offset.x: -10
                // offset.y: -5
                radius: myRectangle.radius
                blur: 30
                spread: 10
                color: Qt.darker(myRectangle.color, 1.6)
            }
        }

        Rectangle {
            id: root
            width: 480; height: 160
            color: "#1f1f1f"

            ParticleSystem {
                id: particleSystem
            }

            Emitter {
                id: emitter
                anchors.centerIn: parent
                width: 160; height: 80
                system: particleSystem
                emitRate: 10
                lifeSpan: 1000
                lifeSpanVariation: 500
                size: 16
                endSize: 32
                // Tracer { color: 'green' }
            }

            ImageParticle {
                source: "assets/star.png"
                system: particleSystem
                color: '#FFD700'
                colorVariation: 0.2
                rotation: 0
                rotationVariation: 45
                rotationVelocity: 15
                rotationVelocityVariation: 15
                entryEffect: ImageParticle.Scale
            }
        }

        Canvas {
    id: canvas
    width: 800; height: 450
    
    property real hue: 0
    property real lastX: width * Math.random()
    property real lastY: height * Math.random()

// #region M1
    property bool requestLine: false
    property bool requestBlank: false
// #endregion M1

// #region M2
    Timer {
        id: lineTimer
        interval: 40
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            canvas.requestLine = true
            canvas.requestPaint()
        }
    }

    Timer {
        id: blankTimer
        interval: 50
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            canvas.requestBlank = true
            canvas.requestPaint()
        }
    }
// #endregion M2

    onPaint: {
        var context = getContext('2d')
        if(requestLine) {
            line(context)
            requestLine = false
        }
        if(requestBlank) {
            blank(context)
            requestBlank = false
        }
    }

    function line(context) {
        context.save()
        context.translate(canvas.width/2, canvas.height/2)
        context.scale(0.9, 0.9)
        context.translate(-canvas.width/2, -canvas.height/2)
        context.beginPath()
        context.lineWidth = 5 + Math.random() * 10
        context.moveTo(lastX, lastY)
        lastX = canvas.width * Math.random()
        lastY = canvas.height * Math.random()
        context.bezierCurveTo(canvas.width * Math.random(),
                              canvas.height * Math.random(),
                              canvas.width * Math.random(),
                              canvas.height * Math.random(),
                              lastX, lastY);

        hue += Math.random()*0.1
        if(hue > 1.0) {
            hue -= 1
        }
        context.strokeStyle = Qt.hsla(hue, 0.5, 0.5, 1.0)
        context.shadowColor = 'white';
        context.shadowBlur = 10;
        context.stroke()
        context.restore()
    }

    function blank(context) {
        context.fillStyle = Qt.rgba(0,0,0,0.1)
        context.fillRect(0, 0, canvas.width, canvas.height)
    }

    Component.onCompleted: {
        lineTimer.start()
        blankTimer.start()
    }

}

    }
}