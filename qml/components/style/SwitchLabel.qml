import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects

import "../../../data/MaterialDesignRegular.js" as MD

ShadowRectangle {
    id: control

    property bool on: false
    property string title: "Parallel"
    property string subTitle: "Series"

    color: Universal.background

    property bool inActive: false

    property alias toggled: switchOn.checked

    GridLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        uniformCellWidths: true
        columns: 2

        Label {
            text: control.on ? title : subTitle
            font.pixelSize: 16
            font.bold: Font.DemiBold
            Layout.alignment: Qt.AlignRight
        }

        PrefsSwitch {
            id: switchOn
            Layout.alignment: Qt.AlignLeft
            ToolTip.visible: switchOn.hovered
            ToolTip.text: control.on ? "Change to series" : "Change to parallel"
            ToolTip.delay: 500
            
            checked: control.on

            onToggled: {
                if(!inActive){
                    control.on = !control.on
                }
                rlcPage.react()  //send signal to parent
            }
        }
    }
}

