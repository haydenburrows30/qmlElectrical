import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

ToolBar {
    id:toolBar
    property bool toggle : action.checked

    background: Rectangle {
        color: toolBar.toggle ? "black" : "white"
    }

    signal mySignal()

    RowLayout {
        anchors.fill: parent

        CButton {
            id: menu
            icon_name: "Menu"
            tooltip_text: sideBar.open_closed ? "Close Menu":"Open Menu"
            onClicked: { 
                mySignal() 
            }
        }

        Label {
            text: "Electrical Calculators"
            elide: Label.ElideRight
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.leftMargin: menu.width
        }

        DarkLightButton {
            id: action
            icon_name1: "Dark"
            icon_name2: "Light"
            mode_1: "Light Mode"
            mode_2: "Dark Mode"
        }

        CButton {
            icon_name: "Setting"
            tooltip_text: "Settings"
            onClicked: { settings.open() }
        }
    }
}