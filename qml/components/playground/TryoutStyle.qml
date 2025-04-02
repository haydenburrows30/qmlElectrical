import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "../"
import "../../components"
import "../style"
import "../backgrounds"

import Conversion 1.0

Item {
    ConversionCalculator {
        id: converter
    }

    // Add color theme properties
    property color accentColor: "#2979FF"
    property color secondaryColor: "#42A5F5"
    property color backgroundColor: "#F5F5F5"
    property int animationDuration: 200

    Component.onCompleted: {
        conversionTypeText.color = accentColor
        conversionTypeText.font.bold = true
    }

    function rfocusChanged() {
        const textElements = {
            'conversionType': conversionTypeText,
            'wHRPM': wHRPMText,
            'temp': tempText
        }
        
        // Reset all to default
        Object.values(textElements).forEach(element => {
            element.color = Universal.foreground
            element.font.bold = false
        })
        
        // Highlight active one with animation
        textElements[activeComboBox].color = accentColor
        textElements[activeComboBox].font.bold = true
        highlightAnimation.target = textElements[activeComboBox]
        highlightAnimation.restart()
    }
    
    property string activeComboBox: "conversionType"

    // Add highlight animation
    NumberAnimation {
        id: highlightAnimation
        property var target
        target: null
        property: "scale"
        from: 1.0
        to: 1.05
        duration: animationDuration
        easing.type: Easing.OutQuad
        onStopped: {
            highlightAnimationReverse.start()
        }
    }
    
    NumberAnimation {
        id: highlightAnimationReverse
        target: highlightAnimation.target
        property: "scale"
        from: 1.05
        to: 1.0
        duration: animationDuration
        easing.type: Easing.InQuad
    }

    Popup {
        id: tipsPopup
        width: 600
        height: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        visible: results.open
        
        // Add background and styling
        background: Rectangle {
            color: backgroundColor
            radius: 10
            border.color: secondaryColor
            border.width: 2
            
            // Add gradient effect
            Rectangle {
                anchors.fill: parent
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(backgroundColor, 1.05) }
                    GradientStop { position: 1.0; color: backgroundColor }
                }
            }
        }

        // Add close button
        Rectangle {
            id: closeButton
            width: 30
            height: 30
            radius: 15
            color: "transparent"
            border.color: secondaryColor
            border.width: 1
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            
            Text {
                anchors.centerIn: parent
                text: "✕"
                color: secondaryColor
                font.pixelSize: 16
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: tipsPopup.close()
                
                hoverEnabled: true
                onEntered: parent.color = Qt.lighter(secondaryColor, 1.7)
                onExited: parent.color = "transparent"
            }
        }

        onAboutToHide: {
            results.open = false
        }
        
        // Improve text display
        Flickable {
            anchors.fill: parent
            anchors.margins: 20
            contentWidth: width
            contentHeight: popupText.height
            clip: true
            
            Text {
                id: popupText
                width: parent.width
                text: {"<h3>Unit Converter </h3><br>" +
                    "The unit converter helps you convert units of voltage, current, frequency, power, and temperature. The converter provides you with a simple and easy-to-use interface to convert units between different systems of measurement. Simply select the conversion type, enter the value you want to convert, and the converter will provide you with the converted value.<br>" +
                    "The unit converter supports a wide range of conversion types, including line to phase voltage, phase to line voltage, line to phase current, phase to line current, watts to dBmW, dBmW to watts, rad/s to Hz, horsepower to watts, RPM to Hz, radians to Hz, Hz to RPM, watts to horsepower, Celsius to Fahrenheit, and Fahrenheit to Celsius. The converter also provides you with a visual representation of the conversion formula, helping you understand the relationship between the different units of measurement."}
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                lineHeight: 1.2
            }
        }
    }

    RowLayout {
        anchors.centerIn: parent
        anchors.margins: 10
        

        WaveCard {
            id: results
            Layout.minimumHeight: 400
            Layout.minimumWidth: 600
            title: "Unit Converter"

            showSettings: true

            ColumnLayout {
                id: waveCardLayout
                anchors.centerIn: parent
                 * 1.5  // Increase spacing for better readability

                RowLayout {
                    Layout.fillWidth: true
                    Layout.minimumHeight: 140
                     * 1.5  // Increase spacing

                    ColumnLayout {
                        id: conversionTypeLayout
                         * 1.2

                        // Styled category headers with icon
                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: Qt.lighter(accentColor, 1.5)
                            Layout.bottomMargin: 5
                        }

                        RowLayout {
                            Rectangle {
                                width: 6
                                height: 30
                                color: accentColor
                                radius: 3
                                opacity: activeComboBox === "conversionType" ? 1.0 : 0.3
                            }
                            
                            Label {
                                text: "Voltage"
                                Layout.minimumWidth: 100
                                font.bold: true
                                font.pixelSize: 16
                                color: Qt.darker(Universal.foreground, activeComboBox === "conversionType" ? 1.2 : 1.0)
                            }

                            // Styled ComboBox
                            ComboBox {
                                id: conversionType
                                Layout.minimumWidth: 200
                                model: [
                                    "Line to Phase Voltage",
                                    "Phase to Line Voltage",
                                    "Line to Phase Current",
                                    "Phase to Line Current",
                                ]
                                onCurrentTextChanged: {
                                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                                    activeComboBox = "conversionType"
                                }
                                onActivated: {
                                    activeComboBox = "conversionType"
                                    rfocusChanged()
                                }

                                // Custom styling
                                background: Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 40
                                    border.color: conversionType.pressed ? accentColor : Qt.lighter(accentColor, 1.5)
                                    border.width: activeComboBox === "conversionType" ? 2 : 1
                                    radius: 5
                                    color: activeComboBox === "conversionType" ? Qt.lighter(accentColor, 1.9) : "white"
                                    
                                    // Add subtle gradient
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 5
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: activeComboBox === "conversionType" ? Qt.lighter(accentColor, 1.95) : "white" }
                                            GradientStop { position: 1.0; color: activeComboBox === "conversionType" ? Qt.lighter(accentColor, 1.85) : Qt.lighter(backgroundColor, 1.02) }
                                        }
                                        z: -1
                                    }
                                }

                                contentItem: Text {
                                    id: conversionTypeText
                                    leftPadding: 10
                                    text: conversionType.displayText
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 14
                                }
                                
                                // Add dropdown indicator
                                indicator: Text {
                                    text: "▼"
                                    font.pixelSize: 12
                                    color: activeComboBox === "conversionType" ? accentColor : secondaryColor
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: Qt.lighter(accentColor, 1.5)
                            Layout.topMargin: 5
                            Layout.bottomMargin: 5
                        }

                        RowLayout {
                            Rectangle {
                                width: 6
                                height: 30
                                color: accentColor
                                radius: 3
                                opacity: activeComboBox === "wHRPM" ? 1.0 : 0.3
                            }
                            
                            Label {
                                text: "Frequency"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.minimumWidth: 100
                                color: Qt.darker(Universal.foreground, activeComboBox === "wHRPM" ? 1.2 : 1.0)
                            }

                            ComboBox {
                                id: wHRPM
                                Layout.minimumWidth: 200
                                model: [
                                    "Watts to dBmW",
                                    "dBmW to Watts",
                                    "Rad/s to Hz",
                                    "Horsepower to Watts",
                                    "RPM to Hz",
                                    "Radians to Hz",
                                    "Hz to RPM",
                                    "Watts to Horsepower",
                                ]
                                onCurrentTextChanged: {
                                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                                    activeComboBox = "wHRPM"
                                }
                                onActivated: {
                                    activeComboBox = "wHRPM"
                                    rfocusChanged()
                                }

                                // Custom styling
                                background: Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 40
                                    border.color: wHRPM.pressed ? accentColor : Qt.lighter(accentColor, 1.5)
                                    border.width: activeComboBox === "wHRPM" ? 2 : 1
                                    radius: 5
                                    color: activeComboBox === "wHRPM" ? Qt.lighter(accentColor, 1.9) : "white"
                                    
                                    // Add subtle gradient
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 5
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: activeComboBox === "wHRPM" ? Qt.lighter(accentColor, 1.95) : "white" }
                                            GradientStop { position: 1.0; color: activeComboBox === "wHRPM" ? Qt.lighter(accentColor, 1.85) : Qt.lighter(backgroundColor, 1.02) }
                                        }
                                        z: -1
                                    }
                                }

                                contentItem: Text {
                                    id: wHRPMText
                                    leftPadding: 10
                                    text: wHRPM.displayText
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 14
                                }
                                
                                // Add dropdown indicator
                                indicator: Text {
                                    text: "▼"
                                    font.pixelSize: 12
                                    color: activeComboBox === "wHRPM" ? accentColor : secondaryColor
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: Qt.lighter(accentColor, 1.5)
                            Layout.topMargin: 5
                            Layout.bottomMargin: 5
                        }

                        RowLayout {
                            Rectangle {
                                width: 6
                                height: 30
                                color: accentColor
                                radius: 3
                                opacity: activeComboBox === "temp" ? 1.0 : 0.3
                            }
                            
                            Label {
                                text: "Temperature"
                                font.bold: true
                                font.pixelSize: 16
                                Layout.minimumWidth: 100
                                color: Qt.darker(Universal.foreground, activeComboBox === "temp" ? 1.2 : 1.0)
                            }

                            ComboBox {
                                id: temp
                                Layout.minimumWidth: 200
                                model: [
                                    "Celsius to Fahrenheit",
                                    "Fahrenheit to Celsius"
                                ]
                                onCurrentTextChanged: {
                                    converter.setConversionType(currentText.toLowerCase().replace(/ /g, "_"))
                                    activeComboBox = "temp"
                                }
                                onActivated: {
                                    activeComboBox = "temp"
                                    rfocusChanged()
                                }

                                // Custom styling
                                background: Rectangle {
                                    implicitWidth: 200
                                    implicitHeight: 40
                                    border.color: temp.pressed ? accentColor : Qt.lighter(accentColor, 1.5)
                                    border.width: activeComboBox === "temp" ? 2 : 1
                                    radius: 5
                                    color: activeComboBox === "temp" ? Qt.lighter(accentColor, 1.9) : "white"
                                    
                                    // Add subtle gradient
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 5
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: activeComboBox === "temp" ? Qt.lighter(accentColor, 1.95) : "white" }
                                            GradientStop { position: 1.0; color: activeComboBox === "temp" ? Qt.lighter(accentColor, 1.85) : Qt.lighter(backgroundColor, 1.02) }
                                        }
                                        z: -1
                                    }
                                }

                                contentItem: Text {
                                    id: tempText
                                    leftPadding: 10
                                    text: temp.displayText
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: 14
                                }
                                
                                // Add dropdown indicator
                                indicator: Text {
                                    text: "▼"
                                    font.pixelSize: 12
                                    color: activeComboBox === "temp" ? accentColor : secondaryColor
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // Improved TextArea with styling
                    ColumnLayout {
                        Layout.fillHeight: true
                        Layout.leftMargin: 15
                        
                        Label {
                            text: "Enter Value:"
                            font.pixelSize: 14
                            font.bold: true
                            color: secondaryColor
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.minimumHeight: conversionTypeLayout.height - 30
                            radius: 8
                            border.color: enterField.focus ? accentColor : Qt.lighter(accentColor, 1.5)
                            border.width: enterField.focus ? 2 : 1
                            
                            // Add subtle gradient
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "white" }
                                GradientStop { position: 1.0; color: Qt.lighter(backgroundColor, 1.05) }
                            }

                            TextArea {
                                id: enterField
                                anchors.fill: parent
                                anchors.margins: 10
                                placeholderText: "Enter value"
                                placeholderTextColor: Qt.lighter(secondaryColor, 1.5)
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 34
                                color: accentColor
                                
                                onTextChanged: {
                                    if (text) converter.setInputValue(parseFloat(text))
                                }
                                wrapMode: TextEdit.Wrap
                                
                                // Add focus animation
                                background: Rectangle {
                                    color: "transparent"
                                }
                            }
                            
                            // Add subtle shadow
                            layer.enabled: true
                            layer.effect: DropShadow {
                                transparentBorder: true
                                horizontalOffset: 0
                                verticalOffset: 2
                                radius: 4.0
                                samples: 9
                                color: "#30000000"
                            }
                        }
                    }
                }

                // Improved result display
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.minimumHeight: 80
                    Layout.minimumWidth: 300
                    Layout.fillWidth: true
                    Layout.margins: 10
                    radius: 10
                    color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.1)
                    border.color: Qt.lighter(accentColor, 1.3)
                    border.width: 1
                    
                    // Add result title
                    Label {
                        text: "Result"
                        font.pixelSize: 14
                        font.bold: true
                        color: secondaryColor
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 10
                    }
                    
                    RowLayout {
                        anchors.centerIn: parent
                        

                        Label {
                            text: converter.result.toFixed(2)
                            font.pixelSize: 34
                            font.bold: true
                            color: accentColor
                        }

                        Label {
                            id: unitLabel
                            text: {
                                if (activeComboBox === "conversionType") {
                                    switch(conversionType.currentText.toLowerCase().replace(/ /g, "_")) {
                                        case "line_to_phase_voltage":
                                        case "phase_to_line_voltage": return "V"
                                        case "line_to_phase_current":
                                        case "phase_to_line_current": return "A"
                                        default: return ""
                                    }
                                } else if (activeComboBox === "wHRPM") {
                                    switch(wHRPM.currentText.toLowerCase().replace(/ /g, "_")) {
                                        case "watts_to_dbmw": return "dBmW"
                                        case "dbmw_to_watts": return "W"
                                        case "rad/s_to_hz":
                                        case "radians_to_hz":
                                        case "rpm_to_hz": return "Hz"
                                        case "horsepower_to_watts": return "W"
                                        case "hz_to_rpm": return "RPM"
                                        case "watts_to_horsepower": return "HP"
                                        default: return ""
                                    }
                                } else if (activeComboBox === "temp") {
                                    switch(temp.currentText.toLowerCase().replace(/ /g, "_")) {
                                        case "celsius_to_fahrenheit": return "°F"
                                        case "fahrenheit_to_celsius": return "°C"
                                        default: return ""
                                    }
                                }
                                return ""
                            }
                            font.pixelSize: 34
                            color: secondaryColor
                            
                            // Add text change animation
                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: unitLabel; property: "opacity"; to: 0; duration: 100 }
                                    PropertyAction { target: unitLabel; property: "text" }
                                    NumberAnimation { target: unitLabel; property: "opacity"; to: 1; duration: 100 }
                                }
                            }
                        }
                    }
                }

                // Improved formula display
                Rectangle {
                    id: formulaContainer
                    Layout.maximumWidth: 800
                    Layout.minimumHeight: 120
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: 10
                    radius: 8
                    color: Qt.rgba(secondaryColor.r, secondaryColor.g, secondaryColor.b, 0.05)
                    border.color: Qt.lighter(secondaryColor, 1.5)
                    border.width: 1
                    
                    // Add formula title
                    Label {
                        text: "Formula"
                        font.pixelSize: 14
                        font.bold: true
                        color: secondaryColor
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 10
                    }

                    Image {
                        id: formulaImage
                        anchors.centerIn: formulaContainer
                        anchors.margins: 20
                        fillMode: Image.PreserveAspectFit
                        width: parent.width - 40
                        height: parent.height - 40
                        source: {
                            let formulaPath = "../../../assets/formulas/"

                            if (activeComboBox === "conversionType") {
                                switch(conversionType.currentText.toLowerCase().replace(/ /g, "_")) {
                                    case "line_to_phase_voltage": return formulaPath + "line_phase_voltage.png"
                                    case "phase_to_line_voltage": return formulaPath + "phase_line_voltage.png"
                                    case "line_to_phase_current": return formulaPath + "line_phase_current.png"
                                    case "phase_to_line_current": return formulaPath + "phase_line_current.png"
                                    case "kva_to_kw_pf": return formulaPath + "kva_to_kw.png"
                                    case "per_unit_voltage": return formulaPath + "per_unit.png"
                                    case "impedance_base_change": return formulaPath + "impedance_base_change.png"
                                    case "sequence_pos_to_abc": return formulaPath + "sequence_pos.png"
                                    case "sequence_neg_to_abc": return formulaPath + "sequence_neg.png"
                                    case "sym_to_phase_fault": return formulaPath + "sym_fault.png"
                                    case "power_three_to_single": return formulaPath + "three_phase_power.png"
                                    case "reactance_freq_change": return formulaPath + "reactance_freq.png"
                                }
                            } else if (activeComboBox === "wHRPM") {
                                switch(wHRPM.currentText.toLowerCase().replace(/ /g, "_")) {
                                    case "watts_to_dbmw": return formulaPath + "watts_to_dbm.png"
                                    case "dbmw_to_watts": return formulaPath + "dbmw_to_watts.png"
                                    case "rad/s_to_hz": return formulaPath + "rad_to_hz.png"
                                    case "radians_to_hz": return formulaPath + "radians_to_hz.png"
                                    case "horsepower_to_watts": return formulaPath + "hp_to_watts.png"
                                    case "rpm_to_hz": return formulaPath + "rpm_to_hz.png"
                                    case "hz_to_rpm": return formulaPath + "hz_to_rpm.png"
                                    case "watts_to_horsepower": return formulaPath + "watts_to_horsepower.png"
                                }
                            } else if (activeComboBox === "temp") {
                                switch(temp.currentText.toLowerCase().replace(/ /g, "_")) {
                                    case "celsius_to_fahrenheit": return formulaPath + "celsius_to_fahrenheit.png"
                                    case "fahrenheit_to_celsius": return formulaPath + "fahrenheit_to_celsius.png"
                                }
                            }
                            
                            return ""
                        }
                        
                        // Add image change animation
                        opacity: 1
                        Behavior on source {
                            SequentialAnimation {
                                NumberAnimation { target: formulaImage; property: "opacity"; to: 0; duration: 150 }
                                PropertyAction { target: formulaImage; property: "source" }
                                NumberAnimation { target: formulaImage; property: "opacity"; to: 1; duration: 200 }
                            }
                        }
                    }
                    
                    // Add subtle shadow
                    layer.enabled: true
                    layer.effect: DropShadow {
                        transparentBorder: true
                        horizontalOffset: 0
                        verticalOffset: 2
                        radius: 4.0
                        samples: 9
                        color: "#20000000"
                    }
                }
            }
        }
    }
}
