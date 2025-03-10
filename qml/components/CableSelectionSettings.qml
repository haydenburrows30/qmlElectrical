import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Controls.Universal

GridLayout {
    id: cableSelectionSettings
    columns: 2
    columnSpacing: 16
    rowSpacing: 16
    
    property alias voltageSelect: voltageSelect
    property alias admdCheckBox: admdCheckBox
    property alias conductorSelect: conductorSelect
    property alias coreTypeSelect: coreTypeSelect
    property alias cableSelect: cableSelect
    property alias lengthInput: lengthInput
    property alias installationMethodCombo: installationMethodCombo
    property alias temperatureInput: temperatureInput
    property alias groupingFactorInput: groupingFactorInput
    property alias kvaPerHouseInput: kvaPerHouseInput
    property alias numberOfHousesInput: numberOfHousesInput
    
    signal resetRequested()
    signal resetCompleted()

    function resetAllValues() {
        // First set UI controls to default values
        voltageSelect.currentIndex = 1  // 415V
        conductorSelect.currentIndex = 1  // Al
        coreTypeSelect.currentIndex = 1  // 3C+E
        cableSelect.currentIndex = 13
        lengthInput.text = "0"
        temperatureInput.text = "25"
        groupingFactorInput.text = "1.0"
        kvaPerHouseInput.text = "7"
        numberOfHousesInput.text = "1"
        admdCheckBox.checked = false
        installationMethodCombo.currentIndex = 5  // "D1 - Underground direct buried"
        
        // Now explicitly update the model with these values to ensure calculations are updated
        voltageDrop.setSelectedVoltage(voltageSelect.currentText)
        voltageDrop.setConductorMaterial(conductorSelect.currentText)
        voltageDrop.setCoreType(coreTypeSelect.currentText)
        voltageDrop.selectCable(cableSelect.currentText)
        voltageDrop.setLength(parseFloat(lengthInput.text) || 0)
        voltageDrop.setInstallationMethod(installationMethodCombo.currentText)
        voltageDrop.setTemperature(parseFloat(temperatureInput.text) || 25)
        voltageDrop.setGroupingFactor(parseFloat(groupingFactorInput.text) || 1.0)
        voltageDrop.setADMDEnabled(admdCheckBox.checked)
        
        // Calculate total load using default values
        let kva = parseFloat(kvaPerHouseInput.text) || 7
        let houses = parseInt(numberOfHousesInput.text) || 1
        voltageDrop.setNumberOfHouses(houses)
        voltageDrop.calculateTotalLoad(kva, houses)
        
        // Trigger an explicit recalculation
        voltageDrop.reset()
        
        // Signal that reset is complete
        resetCompleted()
    }

    Label { text: "System Voltage:" }
    RowLayout {
        ComboBox {
            id: voltageSelect
            model: voltageDrop.voltageOptions
            currentIndex: voltageDrop.selectedVoltage === "230V" ? 0 : 1
            onCurrentTextChanged: {
                if (currentText) {
                    console.log("Selecting voltage:", currentText)
                    voltageDrop.setSelectedVoltage(currentText)
                    // Disable ADMD checkbox for 230V
                    admdCheckBox.enabled = (currentText === "415V")
                    if (currentText !== "415V") {
                        admdCheckBox.checked = false
                    }
                }
            }
            Layout.fillWidth: true
        }
        
        CheckBox {
            id: admdCheckBox
            text: "ADMD (neutral)"
            enabled: voltageSelect.currentText === "415V"
            onCheckedChanged: voltageDrop.setADMDEnabled(checked)
            ToolTip.visible: hovered
            ToolTip.text: "Apply 1.5 factor for neutral calculations"
        }
        Layout.fillWidth: true
    }

    Label { text: "Conductor:" }
    ComboBox {
        id: conductorSelect
        model: voltageDrop.conductorTypes
        currentIndex: 1
        onCurrentTextChanged: {
            if (currentText) {
                console.log("Selecting conductor:", currentText)
                voltageDrop.setConductorMaterial(currentText)
            }
        }
        Layout.fillWidth: true
    }

    Label { text: "Cable Type:" }
    ComboBox {
        id: coreTypeSelect
        model: voltageDrop.coreConfigurations
        currentIndex: 1
        onCurrentTextChanged: {
            if (currentText) {
                console.log("Selecting core type:", currentText)
                voltageDrop.setCoreType(currentText)
            }
        }
        Layout.fillWidth: true
    }

    Label { text: "Cable Size:" }
    ComboBox {
        id: cableSelect
        model: voltageDrop.availableCables
        currentIndex: 13  // Set default selection
        onCurrentTextChanged: {
            if (currentText) {
                console.log("Selecting cable:", currentText)
                voltageDrop.selectCable(currentText)
            }
        }
        Component.onCompleted: {
            if (currentText) {
                console.log("Initial cable selection:", currentText)
                voltageDrop.selectCable(currentText)
            }
        }
        Layout.fillWidth: true
    }

    Label { text: "Length (m):" }
    TextField {
        id: lengthInput
        placeholderText: "Enter length"
        onTextChanged: voltageDrop.setLength(parseFloat(text) || 0)
        Layout.fillWidth: true
        validator: DoubleValidator { bottom: 0 }
    }

    Label { text: "Installation Method:" }
    ComboBox {
        id: installationMethodCombo
        currentIndex: 6
        model: voltageDrop.installationMethods
        onCurrentTextChanged: voltageDrop.setInstallationMethod(currentText)
        Layout.fillWidth: true
    }

    Label { text: "Temperature (°C):" }
    TextField {
        id: temperatureInput
        text: "25"
        onTextChanged: voltageDrop.setTemperature(parseFloat(text) || 75)
        Layout.fillWidth: true
        validator: DoubleValidator { bottom: 0; top: 120 }
    }

    Label { text: "Grouping Factor:" }
    TextField {
        id: groupingFactorInput
        text: "1.0"
        onTextChanged: voltageDrop.setGroupingFactor(parseFloat(text) || 1.0)
        Layout.fillWidth: true
        validator: DoubleValidator { bottom: 0; top: 2 }
    }

    Label { text: "KVA per House:" }
    TextField {
        id: kvaPerHouseInput
        placeholderText: "Enter kVA"
        text: "7"  // Default 7kVA per house
        onTextChanged: {
            let kva = parseFloat(text) || 0
            let houses = parseInt(numberOfHousesInput.text) || 0
            voltageDrop.calculateTotalLoad(kva, houses)
        }
        Layout.fillWidth: true
        validator: DoubleValidator { bottom: 0 }
    }

    Label { text: "Number of Houses:" }
    TextField {
        id: numberOfHousesInput
        placeholderText: "Enter number"
        text: "1"  // Default 1 house
        onTextChanged: {
            let houses = parseInt(text) || 1
            let kva = parseFloat(kvaPerHouseInput.text) || 0
            voltageDrop.setNumberOfHouses(houses)
            voltageDrop.calculateTotalLoad(kva, houses)
        }
        Layout.fillWidth: true
        validator: IntValidator { bottom: 1 }
    }

    Button {
        text: "Reset"
        icon.name: "Reset"
        Layout.fillWidth: true
        onClicked: {
            resetAllValues()
            resetRequested()  // Signal to parent that a reset was performed
        }
    }
}
