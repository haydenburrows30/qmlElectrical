import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../components"
import "../components/buttons/"
import "../components/playground/"

Page {
    // anchors.fill: parent
    CalculatorPad {
        anchors.centerIn: parent
    }
}
