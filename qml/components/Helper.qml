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

icon.source: "../../../icons/svg/copy_all/baseline.svg"
icon.source: "../../../icons/svg/restart_alt/baseline.svg"
icon.source: "../../../icons/svg/file_download/baseline.svg"
icon.source: "../../../icons/svg/info/baseline.svg"
icon.source: "../../../icons/svg/pause/baseline.svg"
icon.source: "../../../icons/svg/save/baseline.svg"

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

// buttons

MessageButton {
    id: saveButton
    
    ToolTip.text: "Add Relay"
    buttonIcon: '\ue145'
    buttonColor: Style.blueGreen

    defaultMessage: ""
    successMessage: "Adding relay:" + relayName.text
    errorMessage: "Please fill in all relay fields"

    onButtonClicked: {

        startOperation()

        if (!relayName.text || !pickupCurrent.text || !tds.text) {
            console.log("Please fill all relay fields")
            operationFailed(2000)
        } else {
            console.log("Adding relay:", relayName.text)

            calculator.addRelay({
                "name": relayName.text,
                "pickup": parseFloat(pickupCurrent.text),
                "tds": parseFloat(tds.text),
                "curve_constants": calculator.getCurveConstants(curveType.currentText)
                })
            operationSucceeded(2000)
        }
    }
}