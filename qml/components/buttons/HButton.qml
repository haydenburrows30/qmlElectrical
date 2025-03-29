import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Button {
    id: control
    text: ""

    icon.width: 60
    icon.height: 60
    Layout.minimumWidth: 150
    Layout.minimumHeight: 150

    property var gradient: null

    display: AbstractButton.TextUnderIcon

    property string tooltip_text: ""

    property color back : Qt.lighter(palette.accent,1.5)
    property color fore : Qt.lighter(palette.accent,1.5)

    background: Item {

        Rectangle {
            id: backgroundID
            anchors.fill: parent
            gradient: control.gradient
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.down ? control.Universal.baseMediumLowColor :
            control.enabled && (control.highlighted || control.checked) ? control.Universal.accent :
                                                                            back

            Rectangle {
                width: parent.width
                height: parent.height
                color: fore
                visible: enabled && control.hovered
                border.width: 2
                border.color: control.Universal.baseMediumLowColor
            }
        }

        DropShadow {
            anchors.fill: backgroundID
            horizontalOffset: 2
            verticalOffset: 2
            radius: 8.0
            samples: 18
            color: alphaColor("#80000000",0.3)
            source: backgroundID
        }
    }

    function alphaColor(color, alpha) {
        let actualColor = Qt.darker(color, 1)
        actualColor.a = alpha
        return actualColor
    }
}