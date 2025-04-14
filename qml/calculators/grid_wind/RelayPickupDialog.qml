// relay pickup dialog
Dialog {
    id: pickupDialog
    title: "Set Relay Pickup Current"
    width: 400
    height: 450
    modal: true
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    
    ColumnLayout {
        anchors.fill: parent
        spacing: 10
        
        Label {
            text: "Full Load Current (FLC):"
            font.bold: true
        }
        
        TextFieldBlue {
            id: flcText
            text: calculatorReady ? 
                ((calculator.transformerRating * 1000) / (Math.sqrt(3) * 11000)).toFixed(2) + " A" : 
                "15.75 A"
            readOnly: true
            Layout.fillWidth: true
        }
        
        Label {
            text: "Select pickup value as percentage of FLC:"
            font.bold: true
        }
        
        Slider {
            id: pickupSlider
            from: 100
            to: 150
            value: 125
            stepSize: 5
            snapMode: Slider.SnapAlways
            Layout.fillWidth: true
            
            ToolTip {
                parent: pickupSlider.handle
                visible: pickupSlider.pressed
                text: pickupSlider.value + "%"
            }
        }
        
        TextFieldBlue {
            text: pickupSlider.value.toFixed(0) + "% of FLC = " + 
                (calculatorReady ? 
                ((pickupSlider.value / 100) * (calculator.transformerRating * 1000) / (Math.sqrt(3) * 11000)).toFixed(2) : 
                "19.69") + " A"
            readOnly: true
            Layout.fillWidth: true
        }
        
        Label {
            text: "Protection guidelines:"
            font.bold: true
        }
        
        Label {
            text: "• Pickup should be above maximum load current\n" +
                    "• Typically set to 125% of FLC for transformers\n" +
                    "• Must be below minimum fault current\n" +
                    "• Consider cold load pickup conditions"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: true
            
            Button {
                text: "Cancel"
                onClicked: pickupDialog.close()
            }
            
            Button {
                text: "Apply"
                onClicked: {
                    if (calculatorReady) {
                        // This would need a method to update the pickup current in calculator
                        // For now just update the display
                        let flc = (calculator.transformerRating * 1000) / (Math.sqrt(3) * 11000);
                        let newPickup = (pickupSlider.value / 100) * flc;
                        relayPickupCurrentText.text = newPickup.toFixed(2);
                    }
                    pickupDialog.close();
                }
            }
        }
    }
}


// Update FLC calculations
    Connections {
        target: transformerRatingSpinBox
        function onValueModified() {
            if (calculatorReady) {
                // Update FLC calculations in the pickup dialog
                let flc = (transformerRatingSpinBox.value * 1000) / (Math.sqrt(3) * 11000);
                flcText.text = flc.toFixed(2) + " A";
                
                // Update the pickup current display as well
                let newPickup = (pickupSlider.value / 100) * flc;
                relayPickupCurrentText.text = newPickup.toFixed(2);
                
                // Force recalculation
                calculator.refreshCalculations();
            }
        }
    }