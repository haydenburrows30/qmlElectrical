import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"
import "../buttons"
import "../style"
import "../backgrounds"

Popup {
    id: tipsPopup
    width: parent.width * 0.2
    height: parent.height * 0.2
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    visible: results.open

    onAboutToHide: {
        results.open = false
    }
    Label {
        anchors.fill: parent
        text: "A = Open circuit voltage ratio\nB = Transfer impedance\n" +
                                      "C = Transfer admittance\nD = Short circuit current ratio"
        wrapMode: Text.WordWrap
    }
}