import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

import '../components'

Window {
    id: myWindow
    width: 300
    height: 400
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"
    
    Rectangle {
        anchors.fill: parent
        border.color : palette.base
        border.width : 1

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 1.0; color: "transparent" }
            GradientStop { position: 0.2; color: palette.dark }
            }

        DragHandler {
            id: handler
            onActiveChanged: if (active) myWindow.startSystemMove()
        }

        CButton {
            id: close
            icon_name: "Close"
            tooltip_text: "Close"
            onClicked: { 
                myWindow.close()
            }
        }
    }
}