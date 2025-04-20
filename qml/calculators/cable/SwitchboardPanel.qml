import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Dialogs
import QtCharts

import "../../components"
import "../../components/buttons"
import "../../components/popups"
import "../../components/style"
import "../../components/visualizers"
import "../../components/charts"

import Switchboard 1.0

Item {
    id: switchboardPanel
    
    property SwitchboardManager manager: SwitchboardManager {}
    property color textColor: Universal.foreground

    PopUpText {
        id: popUpText
        parentCard: topHeader
        popupText: "<h3>Switchboard Designer</h3><br>" +
                   "This tool helps you design electrical switchboards by entering circuit data such as:<br><br>" +
                   "• Breaker details (size, poles, type)<br>" +
                   "• Circuit destination and load<br>" +
                   "• Cabling specifications<br>" +
                   "• Load characteristics<br><br>" +
                   "The tool will calculate loading, verify compliance, and enable export of the full switchboard schedule.<br><br>" +
                   "Double-click any row to edit circuit details, or use the + button to add a new circuit."
        widthFactor: 0.5
        heightFactor: 0.5
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        anchors.bottomMargin: 5

        // Header with title and help button
        RowLayout {
            id: topHeader
            Layout.fillWidth: true
            Layout.bottomMargin: 5
            Layout.leftMargin: 5

            Label {
                text: "Switchboard"
                font.pixelSize: 20
                font.bold: true
                Layout.fillWidth: true
            }

            StyledButton {
                id: helpButton
                icon.source: "../../../icons/rounded/info.svg"
                ToolTip.text: "Information"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                onClicked: popUpText.open()
            }
        }

        // Header section with general switchboard info
        WaveCard {
            id: results
            title: "Switchboard Information"
            Layout.fillWidth: true
            Layout.preferredHeight: 180

            GridLayout {
                anchors.fill: parent
                columns: 4

                Label { text: "Switchboard Name:" }
                TextFieldRound {
                    id: switchboardName
                    placeholderText: "Enter name (e.g., MSB-1)"
                    Layout.preferredWidth: 180
                    onTextChanged: manager.setName(text)
                }

                Label { text: "Location:" }
                TextFieldRound {
                    id: switchboardLocation
                    placeholderText: "Enter location"
                    Layout.fillWidth: true
                    onTextChanged: manager.setLocation(text)
                }

                Label { text: "Supply Voltage:" }
                ComboBoxRound {
                    id: supplyVoltage
                    model: ["230V", "400V", "415V", "11kV"]
                    currentIndex: 1
                    Layout.preferredWidth: 180
                    onCurrentTextChanged: manager.setVoltage(currentText)
                }

                Label { text: "Phases:" }
                ComboBoxRound {
                    id: phaseConfig
                    model: ["1Ø + N", "3Ø + N", "3Ø"]
                    currentIndex: 1
                    Layout.fillWidth: true
                    onCurrentTextChanged: manager.setPhases(currentText)
                }

                Label { text: "Main Incomer Rating:" }
                TextFieldRound {
                    id: mainRating
                    placeholderText: "Enter amps"
                    validator: IntValidator { bottom: 0 }
                    Layout.preferredWidth: 180
                    onTextChanged: if(text) manager.setMainRating(parseInt(text))
                }

                Label { text: "Switchboard Type:" }
                ComboBoxRound {
                    id: switchboardType
                    model: ["Main Switchboard", "Distribution Board", "Motor Control Center", "Sub-Board"]
                    Layout.fillWidth: true
                    onCurrentTextChanged: manager.setType(currentText)
                }
            }
        }

        // Circuit List Section
        WaveCard {
            title: "Circuit Schedule"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 400

            ColumnLayout {
                anchors.fill: parent
                
                TabBar {
                    id: tabBar
                    width: parent.width
                    
                    TabButton {
                        text: "Circuit List"
                        width: implicitWidth
                    }
                    TabButton {
                        text: "Load Distribution"
                        width: implicitWidth
                    }
                    TabButton {
                        text: "Single Line Diagram"
                        width: implicitWidth
                    }
                }

                StackLayout {
                    currentIndex: tabBar.currentIndex
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 300
                    
                    // Tab 1: Circuit List
                    Item {
                        width: parent.width
                        height: parent.height
                        
                        ColumnLayout {
                            anchors.fill: parent
                            

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                color: window.modeToggled ? "#303030" : "#e0e0e0"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 2

                                    Label { 
                                        text: "Circuit #" 
                                        Layout.preferredWidth: 60
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Destination" 
                                        Layout.preferredWidth: 150
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Rating" 
                                        Layout.preferredWidth: 60
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Poles" 
                                        Layout.preferredWidth: 50
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Type" 
                                        Layout.preferredWidth: 100
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Load"
                                        Layout.preferredWidth: 80
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Cable Size" 
                                        Layout.preferredWidth: 80
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Length" 
                                        Layout.preferredWidth: 60
                                        font.bold: true
                                    }
                                    Label { 
                                        text: "Status" 
                                        Layout.fillWidth: true
                                        font.bold: true
                                    }
                                }
                            }
                            
                            // Circuit list in tab 1
                            ListView {
                                id: circuitList
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                
                                model: manager.circuitCount

                                Text {
                                    anchors.centerIn: parent
                                    text: "Circuit count: " + manager.circuitCount
                                    visible: manager.circuitCount === 0
                                    color: "gray"
                                }

                                // This connection must remain with the ListView as it updates its model property
                                Connections {
                                    target: manager
                                    function onCircuitCountChanged() {
                                        circuitList.model = 0;
                                        circuitList.model = manager.circuitCount;
                                        console.log("ListView refreshed with new circuit count:", manager.circuitCount);
                                    }
                                }

                                delegate: Item {
                                    id: delegateRoot
                                    width: ListView.view ? ListView.view.width : 100
                                    height: 40

                                    Component.onCompleted: {
                                        console.log("Creating delegate for index", index)
                                        if (!circuitData || Object.keys(circuitData).length === 0) {
                                            console.error("No circuit data for index", index)
                                        }
                                    }
                                    
                                    property var circuitData: manager.getCircuitAt(index)

                                    Rectangle {
                                        anchors.fill: parent
                                        color: index % 2 ? 
                                            (window.modeToggled ? "#262626" : "#f5f5f5") : 
                                            (window.modeToggled ? "#1a1a1a" : "#ffffff")
                                    }

                                    Text {
                                        text: "Circuit #" + (delegateRoot.circuitData.number || "??")
                                        anchors.centerIn: parent
                                        color: "red"
                                        visible: false
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onDoubleClicked: {
                                            circuitEditor.loadCircuit(index)
                                            circuitEditor.open()
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 2

                                        Label { 
                                            text: delegateRoot.circuitData ? delegateRoot.circuitData.number : "??"
                                            Layout.preferredWidth: 60
                                        }
                                        Label { 
                                            text: delegateRoot.circuitData ? delegateRoot.circuitData.destination : "??"
                                            Layout.preferredWidth: 150
                                            elide: Text.ElideRight
                                        }
                                        Label { 
                                            text: (delegateRoot.circuitData ? delegateRoot.circuitData.rating : 0) + "A"
                                            Layout.preferredWidth: 60
                                        }
                                        Label { 
                                            text: delegateRoot.circuitData ? delegateRoot.circuitData.poles : "??"
                                            Layout.preferredWidth: 50
                                        }
                                        Label { 
                                            text: delegateRoot.circuitData ? delegateRoot.circuitData.type : "??"
                                            Layout.preferredWidth: 100
                                        }
                                        Label { 
                                            text: (delegateRoot.circuitData ? delegateRoot.circuitData.load : 0).toFixed(2) + "kW"
                                            Layout.preferredWidth: 80
                                        }
                                        Label { 
                                            text: delegateRoot.circuitData ? delegateRoot.circuitData.cableSize : "??"
                                            Layout.preferredWidth: 80
                                        }
                                        Label { 
                                            text: (delegateRoot.circuitData ? delegateRoot.circuitData.length : 0) + "m"
                                            Layout.preferredWidth: 60
                                        }
                                        Label { 
                                            text: delegateRoot.circuitData ? delegateRoot.circuitData.status : "??"
                                            Layout.fillWidth: true
                                            color: (delegateRoot.circuitData && delegateRoot.circuitData.status === "OK") ? 
                                                (Universal.theme === Universal.Dark ? "#90EE90" : "green") :
                                                (Universal.theme === Universal.Dark ? "#FF8080" : "red")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tab 2: Load Distribution Chart
                    Item {
                        id: loadChartContainer
                        width: parent.width
                        height: parent.height

                        LoadChart {
                            anchors.fill: parent
                            manager: switchboardPanel.manager
                            darkMode: window.modeToggled
                        }
                    }
                    
                    // Tab 3: Single Line Diagram
                    ScrollView {
                        id: diagramView
                        clip: true
                        
                        SwitchboardDiagram {
                            id: singleLineDiagram
                            width: Math.max(diagramView.width, 800)
                            height: Math.max(diagramView.height, 800)
                            switchboardName: manager.name
                            mainRating: manager.mainRating
                            voltage: manager.voltage
                            phases: manager.phases

                            property var circuitsList: []

                            // This connection must remain with the SwitchboardDiagram as it updates its circuits property
                            // Cannot be combined with the ListView's connection since they operate on different components
                            Connections {
                                target: manager
                                function onCircuitCountChanged() {
                                    // Update the circuits list for the diagram when circuit count changes
                                    let circuits = [];
                                    for (let i = 0; i < manager.circuitCount; i++) {
                                        circuits.push(manager.getCircuitAt(i));
                                    }
                                    singleLineDiagram.circuitsList = circuits;
                                    console.log("Single line diagram updated with", circuits.length, "circuits");
                                }
                            }

                            circuits: circuitsList
                            
                            Component.onCompleted: {
                                let circuits = [];
                                for (let i = 0; i < manager.circuitCount; i++) {
                                    circuits.push(manager.getCircuitAt(i));
                                }
                                circuitsList = circuits;
                                console.log("Single line diagram initialized with", circuits.length, "circuits");
                            }
                            
                            darkMode: window.modeToggled
                        }
                    }

                }

                // 3. Finally the buttons at the bottom
                RowLayout {
                    Layout.fillWidth: true

                    StyledButton {
                        text: "Add Circuit"
                        icon.source: "../../../icons/rounded/add.svg"
                        onClicked: {
                            circuitEditor.reset1()
                            circuitEditor.open()
                        }
                    }
                    
                    StyledButton {
                        text: "Export Schedule"
                        icon.source: "../../../icons/rounded/download.svg"
                        onClicked: exportMenu.open()
                        
                        Menu {
                            id: exportMenu
                            MenuItem {
                                text: "Export as CSV"
                                onTriggered: {
                                    let result = manager.exportCSV()
                                    messageDialog.text = result
                                    messageDialog.open()
                                }
                            }
                            MenuItem {
                                text: "Export as PDF"
                                onTriggered: {
                                    let result = manager.exportPDF()
                                    messageDialog.text = result
                                    messageDialog.open()
                                }
                            }
                            MenuItem {
                                text: "Print Schedule"
                                onTriggered: {
                                    let result = manager.printSchedule()
                                    messageDialog.text = result
                                    messageDialog.open()
                                }
                            }
                            MenuItem {
                                text: "Save as JSON"
                                onTriggered: {
                                    let result = manager.saveToJSON()
                                    messageDialog.text = result
                                    messageDialog.open()
                                }
                            }
                        }
                    }
                    
                    StyledButton {
                        text: "Load Schedule"
                        icon.source: "../../../icons/rounded/folder_open.svg"
                        onClicked: fileDialog.open()
                    }
                    
                    Item { Layout.fillWidth: true } // Spacer
                    
                    Label { 
                        text: "Total Load: " + manager.totalLoad.toFixed(2) + " kW"
                        font.bold: true
                    }
                    
                    Label { 
                        text: "Utilization: " + manager.utilizationPercent.toFixed(1) + "%"
                        font.bold: true
                        color: manager.utilizationPercent > 80 ? 
                            (Universal.theme === Universal.Dark ? "#FF8080" : "red") :
                            (Universal.theme === Universal.Dark ? "#90EE90" : "green")
                    }
                }
            }
        }
    }
    
    // Circuit Editor Dialog
    Dialog {
        id: circuitEditor
        title: editMode ? "Edit Circuit " + circuitNumber : "Add New Circuit"
        modal: true
        standardButtons: Dialog.Save | Dialog.Cancel
        width: 500
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        property bool editMode: false
        property int circuitIndex: -1
        property string circuitNumber: ""

        function handleAccepted() {

            let circuitData = {
                destination: destinationField.text,
                rating: parseInt(ratingCombo.currentText),
                poles: polesCombo.currentText,
                type: typeCombo.currentText,
                load: parseFloat(loadField.text || "0"),
                cableSize: cableSizeCombo.currentText,
                cableCores: cableCoresCombo.currentText,
                length: parseFloat(lengthField.text || "0"),
                notes: notesField.text
            };

            if (editMode) {
                let success = manager.updateCircuit(circuitIndex, circuitData);
                console.log("Circuit updated, success =", success);

                circuitList.model = 0;
                circuitList.model = manager.circuitCount;
            } else {
                let success = manager.addCircuit(circuitData);
                console.log("Circuit added, success =", success);
                console.log("Current circuit count after adding:", manager.circuitCount);
            }
        }

        onAccepted: handleAccepted()
        
        function reset1() {
            editMode = false
            circuitIndex = -1
            circuitNumber = ""
            
            // Clear fields
            destinationField.text = ""
            ratingCombo.currentIndex = 0
            polesCombo.currentIndex = 1
            typeCombo.currentIndex = 0
            loadField.text = ""
            cableSizeCombo.currentIndex = 0
            cableCoresCombo.currentIndex = 0
            lengthField.text = ""
            notesField.text = ""
        }
        
        function loadCircuit(index) {
            editMode = true
            circuitIndex = index
            let circuit = manager.getCircuit(index)
            circuitNumber = circuit.number

            destinationField.text = circuit.destination

            for (let i = 0; i < ratingCombo.model.length; i++) {
                if (ratingCombo.model[i] == circuit.rating.toString()) {
                    ratingCombo.currentIndex = i
                    break
                }
            }
            
            for (let i = 0; i < polesCombo.model.length; i++) {
                if (polesCombo.model[i] == circuit.poles) {
                    polesCombo.currentIndex = i
                    break
                }
            }
            
            for (let i = 0; i < typeCombo.model.length; i++) {
                if (typeCombo.model[i] == circuit.type) {
                    typeCombo.currentIndex = i
                    break
                }
            }
            
            loadField.text = circuit.load
            
            for (let i = 0; i < cableSizeCombo.model.length; i++) {
                if (cableSizeCombo.model[i] == circuit.cableSize) {
                    cableSizeCombo.currentIndex = i
                    break
                }
            }
            
            for (let i = 0; i < cableCoresCombo.model.length; i++) {
                if (cableCoresCombo.model[i] == circuit.cableCores) {
                    cableCoresCombo.currentIndex = i
                    break
                }
            }
            
            lengthField.text = circuit.length
            notesField.text = circuit.notes || ""
        }
        
        contentItem: GridLayout {
            columns: 2
            
            columnSpacing: 15
            
            Label { text: "Destination:" }
            TextFieldRound {
                id: destinationField
                placeholderText: "e.g., Lighting Circuit 1"
                Layout.fillWidth: true
            }
            
            Label { text: "Breaker Rating (A):" }
            ComboBoxRound {
                id: ratingCombo
                model: ["6", "10", "16", "20", "25", "32", "40", "50", "63", "80", "100", "125", "160", "200", "250"]
                Layout.fillWidth: true
            }
            
            Label { text: "Poles:" }
            ComboBoxRound {
                id: polesCombo
                model: ["1P", "2P", "3P", "4P"]
                currentIndex: 1  // Default to 2P
                Layout.fillWidth: true
            }
            
            Label { text: "Protection Type:" }
            ComboBoxRound {
                id: typeCombo
                model: ["MCB", "MCCB", "RCD", "RCBO", "Fuse"]
                Layout.fillWidth: true
            }
            
            Label { text: "Load (kW):" }
            TextFieldRound {
                id: loadField
                placeholderText: "Enter load"
                validator: DoubleValidator { bottom: 0 }
                Layout.fillWidth: true
            }
            
            Label { text: "Cable Size:" }
            ComboBoxRound {
                id: cableSizeCombo
                model: ["1.5mm²", "2.5mm²", "4mm²", "6mm²", "10mm²", "16mm²", "25mm²", "35mm²", "50mm²", "70mm²", "95mm²"]
                Layout.fillWidth: true
            }
            
            Label { text: "Cable Cores:" }
            ComboBoxRound {
                id: cableCoresCombo
                model: ["2C", "2C+E", "3C", "3C+E", "4C", "4C+E"]
                Layout.fillWidth: true
            }
            
            Label { text: "Cable Length (m):" }
            TextFieldRound {
                id: lengthField
                placeholderText: "Enter length"
                validator: DoubleValidator { bottom: 0 }
                Layout.fillWidth: true
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.columnSpan: 2
                height: 1
                color: window.modeToggled ? "#404040" : "#e0e0e0"
            }
            
            Label { 
                text: "Notes:" 
                Layout.alignment: Qt.AlignTop
            }
            TextArea {
                id: notesField
                placeholderText: "Optional notes about this circuit"
                Layout.fillWidth: true
                Layout.preferredHeight: 60
            }
        }
    }

    Dialog {
        id: messageDialog
        title: "Switchboard Manager"
        width: 400
        height: 200
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        standardButtons: Dialog.Ok
        
        property string text: ""
        
        ColumnLayout {
            anchors.fill: parent
            
            Label {
                text: messageDialog.text
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Load Switchboard Schedule"
        nameFilters: ["JSON files (*.json)"]
        onAccepted: {
            let result = manager.loadFromJSON(fileDialog.selectedFile.toString())
            messageDialog.text = result
            messageDialog.open()
        }
    }
}
