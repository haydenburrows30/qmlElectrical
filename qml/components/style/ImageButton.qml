import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Controls
import QtQuick.Controls.impl as Impl
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import "../../../scripts/MaterialDesignRegular.js" as MD

Button {
    id: control

    FontLoader {
        id: iconFont
        source: "../../../icons/MaterialIcons-Regular.ttf"
    }

    property color color: Style.textColor
    property color backgroundColor: Style.granite
    property color borderColor: backgroundColor
    property real radius: implicitHeight /2
    property string iconImage
    property int iconWidth: 24
    property int iconHeight: 24
    property string iconName: '\ue161'

    // font.pixelSize: 20
    implicitHeight: 42
    implicitWidth: 42

    // icon.name: iconImage
    // icon.width: 30
    // icon.height: 30

    Text {
        anchors.centerIn: parent
        topPadding: 6
        font.pixelSize: 30
        text: iconName
        color: Style.textColor
    }

    background: Rectangle{
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth
        radius: control.radius
        color: control.backgroundColor
        border.color: control.borderColor

        Rectangle {
            id: indicator
            property int mx
            property int my
            x: mx - width / 2
            y: my - height / 2
            height: width
            radius: width / 2
            color: Qt.lighter("#B8FF01")
        }
    }

    ColorOverlay {
        anchors.fill: control
        source: control
        color: control.color
    }

    MouseArea {
        id: mouseArea
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        anchors.fill: parent
    }

    ParallelAnimation {
        id: anim
        NumberAnimation {
            target: indicator
            property: 'width'
            from: 0
            to: control.width * 1.5
            duration: 200
        }
        NumberAnimation {
            target: indicator;
            property: 'opacity'
            from: 0.9
            to: 0
            duration: 200
        }
    }

    onPressed: {
        indicator.mx = mouseArea.mouseX
        indicator.my = mouseArea.mouseY
        anim.restart();
    }
}
