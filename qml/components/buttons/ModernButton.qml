import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Effects

Button {
    id: control
    
    property color primaryColor: Universal.accent
    property color textColor: "white"
    property bool isCircular: false
    property int buttonRadius: isCircular ? width / 2 : 4
    
    implicitWidth: Math.max(implicitContentWidth + leftPadding + rightPadding, 80)
    implicitHeight: Math.max(implicitContentHeight + topPadding + bottomPadding, 36)
    
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.down || control.hovered ? Qt.darker(textColor, 1.1) : textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    background: Rectangle {
        id: buttonBackground
        implicitWidth: 80
        implicitHeight: 36
        radius: buttonRadius
        color: {
            if (control.down)
                return Qt.darker(primaryColor, 1.2)
            else if (control.hovered)
                return Qt.lighter(primaryColor, 1.1)
            else
                return primaryColor
        }
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Use MultiEffect instead of DropShadow
    MultiEffect {
        source: buttonBackground
        anchors.fill: buttonBackground
        shadowEnabled: control.enabled
        shadowBlur: 0.5
        shadowColor: "#30000000"
        shadowHorizontalOffset: control.down ? 1 : 2
        shadowVerticalOffset: control.down ? 1 : 2
    }
    
    states: State {
        name: "pressed"
        when: control.down
        PropertyChanges {
            target: control
            scale: 0.97
        }
    }
    
    transitions: Transition {
        NumberAnimation {
            properties: "scale"
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
}
