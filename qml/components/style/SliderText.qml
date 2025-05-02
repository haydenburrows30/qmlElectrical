import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal

Slider {
    id: control
    value: 1.0

    property int sliderDecimal: 1
    property int textPadding: 5
    property real maxTextWidth: 0
    property int extraWidth: 0

    rightPadding: maxTextWidth + 10

    signal textChangedSignal()

    TextField {
        id: textValue
        z:1
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        ToolTip.text: acceptableInput === false ? ("Enter number from: " + control.from + "-" + control.to) : ""
        ToolTip.visible: hovered && !acceptableInput
        ToolTip.delay: 0
        ToolTip.timeout: 5000

        text: control.value.toFixed(sliderDecimal)

        leftPadding: 0
        rightPadding: 0

        horizontalAlignment: Text.AlignRight

        background: Rectangle {
            border.width: 0
            color: "transparent"
        }

        validator: IntValidator {
            bottom: control.from
            top: control.to
        }

        onAcceptableInputChanged: {
            textValue.color = acceptableInput ? window.modeToggled ? "white" : "black" : "red";
        }


        onEditingFinished: {
            // Convert to number and validate
            var newValue = parseFloat(text)
            if (!isNaN(newValue)) {
                control.value = newValue
                textChangedSignal()
            } else {
                text = control.value.toFixed(sliderDecimal)
                textChangedSignal()
            }
        }
    }

    // Calculate max width after component is fully initialized
    Component.onCompleted: {
        calculateMaxTextWidth();
    }

    function calculateMaxTextWidth() {
        // Calculate the width of text at minimum and maximum values, each value calculates 7 pixels/value
        var minText = control.from.toFixed(sliderDecimal).length * 7;
        var maxText = control.to.toFixed(sliderDecimal).length * 7;

        maxTextWidth = Math.max(minText, maxText) + extraWidth;
    }
}