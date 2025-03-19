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

font.bold: true // bold text
font.italic: true // italic text
font.pixelSize: 20 // font size

// Layout

Layout.minimumHeight
Layout.minimumWidth: 
Layout.alignment: Qt.AlignTop
spacing: 10
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
        text: { "<h3>Battery Calculator</h3><br>" +
                "This calculator estimates the battery capacity required for a given load and backup time.<br><br>" +
                "<b>Load:</b> The power consumption in watts.<br>" +
                "<b>System Voltage:</b> The voltage of the battery system.<br>" +
                "<b>Backup Time:</b> The duration for which the battery should provide power.<br>" +
                "<b>Depth of Discharge:</b> The percentage of battery capacity that can be used.<br>" +
                "<b>Battery Type:</b> The type of battery used.<br><br>" +
                "The calculator estimates the current draw, required capacity, recommended capacity, and energy storage.<br>" +
                "The battery visualization shows the depth of discharge and recommended capacity." }
        wrapMode: Text.WordWrap
    }
}