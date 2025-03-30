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
spacing: Style.spacing
anchors.centerIn: parent
anchors.fill: parent
Layout.fillWidth: true
Layout.fillHeight: true
Layout.topMargin: 5
anchors.margins: 10


// help Popup

id: results
showSettings: true

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
    Text {
        anchors.fill: parent
        text: { ""}
        wrapMode: Text.WordWrap
    }
}

// Fonts

FontLoader {
    id: iconFont
    source: "../../icons/MaterialIcons-Regular.ttf"
}

import "../../scripts/MaterialDesignRegular.js" as MD

// Results

TextField {
    Layout.fillWidth: true
    readOnly: true

    text: ""

    ToolTip.text: "Estimated temperature rise above ambient"
    ToolTip.visible: hovered
    ToolTip.delay: 500
    
    background: ProtectionRectangle {}
}