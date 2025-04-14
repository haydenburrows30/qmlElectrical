// Text

<br> // html linebreak in text
<b></b> // html bold in text
<h1><h1> // html header in text
√ // square root symbol in text
× // multiplication symbol in text
² // superscript 2 in text
θ // theta symbol in text
∠ // angle symbol in text
° // degree symbol in text
π // pi symbol in text
≈ // approximately equal to symbol in text
≠ // not equal to symbol in text
≥ // greater than or equal to symbol in text
≤ // less than or equal to symbol in text
≡ // identical to symbol in text
± // plus-minus symbol in text

font.bold: true // bold text
font.italic: true // italic text
font.pixelSize: 20 // font size

// Layout

Layout.minimumHeight
Layout.minimumWidth: 
Layout.alignment: Qt.AlignTop

anchors.centerIn: parent
anchors.fill: parent
Layout.fillWidth: true
Layout.fillHeight: true
Layout.topMargin: 5
anchors.margins: 10


// help Popup

id: results
showSettings: true

import "../popups"

PopUpText {
        parentCard: results
        popupText: 
        widthFactor: 0.5
        heightFactor: 0.5
    }

// Fonts

icon.source: "../../../icons/rounded/download.svg"
icon.source: "../../../icons/rounded/settings.svg"
icon.source: "../../../icons/rounded/speed.svg"
icon.source: "../../../icons/rounded/restart_alt.svg"
icon.source: "../../../icons/rounded/check.svg"
icon.source: "../../../icons/rounded/info.svg"
icon.source: "../../../icons/rounded/add.svg"
icon.source: "../../../icons/rounded/close.svg"
icon.source: "../../../icons/rounded/calculate.svg"
icon.source: "../../../icons/rounded/history.svg"
icon.source: "../../../icons/rounded/copy_all.svg"
icon.source: "../../../icons/rounded/save.svg"
icon.source: "../../../icons/rounded/bolt.svg"
icon.source: "../../../icons/rounded/compare.svg"
icon.source: "../../../icons/rounded/folder_open.svg"
icon.source: "../../../icons/rounded/pause.svg"
icon.source: "../../../icons/rounded/play_arrow.svg"
icon.source: "../../../icons/rounded/show_chart.svg"
icon.source: "../../../icons/rounded/lightbulb.svg"
icon.source: "../../../icons/rounded/home_app_logo.svg"

FontLoader {
    id: iconFont
    source: "../../../icons/MaterialIcons-Regular.ttf"
}

MD.icons["copy"]

import "../../../scripts/MaterialDesignRegular.js" as MD

// Results

TextFieldBlue {
    text: ""
    ToolTip.text: "Estimated temperature rise above ambient"
    ToolTip.visible: hovered
    ToolTip.delay: 500
}

// imports

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"
import "../../components/exports"
import "../../components/charts"
import "../../components/displays"


// copilot checks

Are you able to check the calculations in this file please?
Are there any changes needed to the qml file?


// section header

// Header with title and help button
RowLayout {
    id: topHeader
    Layout.fillWidth: true
    Layout.bottomMargin: 5
    Layout.leftMargin: 5

    Label {
        text: "Transmission Line Calculator"
        font.pixelSize: 20
        font.bold: true
        Layout.fillWidth: true
    }

    StyledButton {
        id: helpButton
        visible: false
        icon.source: "../../../icons/rounded/info.svg"
        ToolTip.text: "Help"
        onClicked: popUpText.open()
    }
}