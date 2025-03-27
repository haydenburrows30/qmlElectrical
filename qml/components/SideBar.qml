import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import "style"

import "buttons"
import "tooltips"

Drawer {
    id: sideBar
    
    // Configuration properties
    property int drawerWidth: Style.sideBarWidth
    property int delegateHeight: Style.delegateHeight
    property bool menuMoved: false
    property bool toggle1: false
    property int hide: 0
    property int show: 0

    // Drawer setup
    width: drawerWidth
    height: parent ? (menuMoved ? parent.height : parent.height - 60) : 0
    
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
        anchors.bottom: parent.bottom
        height: 20
        opacity: 0.8  // Make fade more visible
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: palette.base.alpha(0.5) }
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

            // Move model to separate file
            model: SideBarModel {}

            footer:
                DarkLightButton {
                    id: action
                    icon_name1: "Dark"
                    icon_name2: "Light"
                    mode_1: "Light Mode"
                    mode_2: "Dark Mode"
                    implicitHeight: 50
                    implicitWidth: 50
                    anchors.horizontalCenter: parent.horizontalCenter

                    onClicked: {
                        action.checked ? toggle1 = true : toggle1= false
                    }
                }
        }
    }
}