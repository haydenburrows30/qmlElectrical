import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls.Universal

import "style"
import "buttons"
import "tooltips"

Drawer {

    property int drawerWidth: Style.sideBarWidth
    property int delegateHeight: Style.delegateHeight
    property bool modeToggled: false
    property int hide: 0
    property int show: 0
    property int buttonMargin: buttonMargin

    width: drawerWidth
    
    modal: false
    interactive: false
    visible: true

    Behavior on width {
        NumberAnimation { 
            duration: Style.sidebarAnimationDuration
            easing.type: Easing.InOutQuad 
        }
    }

    onAboutToHide: {
        show = 0
        hide = 1
    }

    onAboutToShow: {
        hide = 0
        show = 1
    }

    function react() {
        if (sideBar.position == 0) {
            sideBar.open()
        }
        else {
            sideBar.close()
        }
    }

    function change(indexchange) {
        listView.currentIndex = indexchange
    }

    Rectangle {
        id: fade
        width: parent.width
        visible: sideBar.menuMoved
        anchors.bottom: parent.bottom
        height: 100
        opacity: 0.8
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color:"transparent"}
            GradientStop { position: 0.5; color: palette.base.alpha(0.5)}
            GradientStop { position: 1.0; color: palette.base }
        }
    }

    RowLayout {
        id: rowLayout
        height: parent.height - 10

        Layout.alignment: Qt.AlignHCenter

        ListView {
            id: listView
            currentIndex: 0
            Layout.preferredWidth: 60
            Layout.fillHeight: true

            clip: true
            footerPositioning : ListView.OverlayFooter

            delegate: ItemDelegate {
                implicitHeight: sideBar.delegateHeight
                implicitWidth: sideBar.drawerWidth

                background: Rectangle {
                    color: parent.hovered ? palette.highlight.alpha(Style.highlightOpacity) : Style.transparent
                    Behavior on color {
                        ColorAnimation { duration: Style.colorAnimationDuration }
                    }
                }

                highlighted: ListView.isCurrentItem

                icon.name: model.icon
                icon.width: 30
                icon.height: 30

                CToolTip {
                    id: toolTip
                    text: model.title
                    width: Style.tooltipWidth
                }

                onClicked: {
                    stackView.push(model.source,StackView.Immediate)
                    listView.currentIndex = index
                    toolTip.close()
                }
            }

            model: SideBarModel {}

            // footer:
            DarkLightButton {
                id: modeButton
                icon_name1: "Dark"
                icon_name2: "Light"
                mode_1: "Light Mode"
                mode_2: "Dark Mode"
                implicitHeight: 50
                implicitWidth: 50
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: buttonMargin

                onClicked: {
                    modeButton.checked ? modeToggled = true : modeToggled = false
                }
            }
        }
    }
}