import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"
import "../style"
import "../backgrounds"

Popup {
    id: tipsPopup
    width: parent.width * widthFactor
    height: parent.height * heightFactor
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    visible: parentCard.open

    property string popupText: ""
    property double widthFactor: 0.5
    property double heightFactor: 0.5
    property var parentCard: {}

    onAboutToHide: {
        parentCard.open = false
    }

    background: Rectangle {
            color: Universal.background
            radius: 10
            anchors.fill: parent
    }

    contentItem: Label {
                    anchors.fill: parent
                    padding: 10
                    wrapMode: Text.WordWrap
                    text: popupText
                    }
}