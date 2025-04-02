import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../buttons"

Popup {
    id: tipsPopup
    width: 500
    height: 300
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
        text: {"<h3>RLC Circuit</h3><br>"
            + "This page simulates the response of a series or parallel RLC circuit to an input frequency. "
            + "The circuit consists of a resistor (R), inductor (L), and capacitor (C) in series or parallel. "
            + "The circuit parameters can be adjusted to see how they affect the impedance and gain of the circuit. "
            + "The resonant frequency and quality factor (Q) are also calculated based on the circuit parameters. "
            + "The circuit response is displayed in a chart showing the gain or impedance vs. frequency. "
            + "The phase vector diagram shows the phase angle of the impedance and the current in the circuit. " }
        wrapMode: Text.WordWrap
    }
}