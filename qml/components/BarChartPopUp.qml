import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.qmlmodels 1.0
import QtQuick.Controls.Universal
import QtCharts

import QtQuick.Studio.DesignEffects

Rectangle {
    id: myWindow
    x: Math.round((window.width - width) / 2)
    y: Math.round(window.height / 6)
    width: 200
    height: 200
    z: 99
    visible: false

    CButton {
        id: close
        icon_name: "Close"
        tooltip_text: "Close"
        anchors.top: parent.top
        anchors.right: parent.right

        onClicked: { 
            myWindow.visible = false
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

    Rectangle {
        id: background
        color: "#45d9d9d9"
        border.color: "#ededed"
        border.width: 1
        anchors.fill: parent
    }
}