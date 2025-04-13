import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Effects

import "."

Rectangle {
    id: controlRect
    color: "transparent" // color handled by rectangle
    
    property string title: ""
    property bool showSettings: false //show help button
    property bool open: false
    property bool titleVisible: true  //enable/disable the title

    default property alias content: contentItem.data

    property color back : Qt.lighter(palette.accent,1.5)
    property color fore : Qt.lighter(palette.accent,1.5)

    RoundButton {
        id: helpButton
        text: "i"
        width: 35
        anchors.right: parent.right
        anchors.top: parent.top
        visible: showSettings
        onClicked: open = true
        z: 2

        background: Rectangle {
            border.width: 1
            color: "transparent"
            radius: 100
            border.color: (helpButton.down || helpButton.hovered) ? helpButton.Universal.baseMediumLowColor :
            helpButton.enabled && (helpButton.highlighted || helpButton.checked) ? helpButton.Universal.accent :
                                                                            "transparent"
            anchors.fill: parent
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: titleVisible ? 20 : 10 // change margins if title not visible
        z: 2 // without z:2 the content is not visible
        
        Label {
            Layout.fillWidth: true
            text: controlRect.title
            font.bold: true
            font.pixelSize: 16
            bottomPadding: 10
            visible: titleVisible
        }

        Item {
            id: contentItem
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    Rectangle {
        id: buttonBackground
        anchors.fill: parent
        color: Universal.background
        radius: 10
        border.width: window.modeToggled ? 1 : 0
        border.color: window.modeToggled ? Universal.baseLowColor : "transparent"
    }

    MultiEffect {
        source: buttonBackground
        anchors.fill: buttonBackground
        // anchors.margins: window.modeToggled ? -5 : 0 // Add negative margins to extend the effect beyond the rectangle
        autoPaddingEnabled: true
        colorization: window.modeToggled ? 0.7 : 0.5
        colorizationColor: window.modeToggled ? Qt.lighter(Universal.accent, 1.1) : Universal.background
        shadowBlur: window.modeToggled ? 2.0 : 1.0 // Significantly increase shadow blur
        blurMax: window.modeToggled ? 30 : 10 // Increase max blur
        shadowEnabled: true
        shadowVerticalOffset: window.modeToggled ? 2 : 0 // Add slight shadow offset in dark mode
        shadowHorizontalOffset: window.modeToggled ? 2 : 0
        shadowColor: window.modeToggled ? Qt.rgba(1, 1, 1, 0.5) : "#000000" // Brighter shadow in dark mode
        shadowOpacity: 0.3
    }
}
