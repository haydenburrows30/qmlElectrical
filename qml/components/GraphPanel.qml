import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

import '../components'

Window {
    id: myWindow
    width: 200
    height: 200
    flags: Qt.Window | Qt.FramelessWindowHint
    color: Qt.darker(palette.dark, 2)

    CButton {
        id: close
        icon_name: "Close"
        tooltip_text: "Close"
        anchors.top: parent.top
        anchors.right: parent.right

        onClicked: { 
            myWindow.close()
        }
    }

    GridLayout {
        anchors.centerIn: parent
        columns: 2
        Label { 
            text: "RMSA: "
            }

        CheckBox {
            id: checkbox_a
            checked: false
            onCheckedChanged: {
                showRMSA = checked
                updateSeries()
            }

            AToolTip {
                text: "Show/hide A chart line"
            }
        }

        Label { 
            text: "RMSB: "
            }
            
        CheckBox {
            checked: false
            onCheckedChanged: {
                showRMSB = checked
                updateSeries()
            }

            AToolTip {
                text: "Show/hide B chart line"
            }
        }

        Label { 
            text: "RMSC: "
            }
            
        CheckBox {
            checked: false
            onCheckedChanged: {
                showRMSC = checked
                updateSeries()
            }
            AToolTip {
                text: "Show/hide C chart line"
            }
        }
    }

    DragHandler {
        id: handler
        onActiveChanged: if (active) myWindow.startSystemMove()
    }
    
    // Rectangle {
    //     anchors.fill: parent
    //     border.color : palette.base
    //     border.width : 1

    //     // gradient: Gradient {
    //     //     orientation: Gradient.Vertical
    //     //     GradientStop { position: 1.0; color: "transparent" }
    //     //     GradientStop { position: 0.2; color: palette.dark }
    //     //     }
    // }

}