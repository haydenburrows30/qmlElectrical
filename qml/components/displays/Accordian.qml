import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../"
import "../displays"
import "../style"

Pane {
    id: accordionPane
    property var accordionSections: []
    
    // Model for the accordion sections
    ListModel {
        id: accordionModel
        ListElement { title: "LV Wind Generator Protection (400V)"; component: "WindGenProtectionResults" }
        ListElement { title: "Line Protection (11kV)"; component: "LineProtectionResults" }
        ListElement { title: "Transformer Protection"; component: "ProtectionRequirementsResults" }
        ListElement { title: "Voltage Regulator Protection"; component: "VoltageRegResults" }
        ListElement { title: "ABB REF615"; component: "ABBConfig" }
        ListElement { title: "Grid Protection Requirements"; component: "GridConnectionReq" }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentHeight: root.implicitHeight + 40
        contentWidth: parent.width
        clip: true

        Pane {
            id: root
            anchors.fill: parent

            Column {
                id: mainLayout
                anchors.right: parent.right
                anchors.left: parent.left

                RowLayout {
                    Button {
                        text: "Calculate Complete System"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 250
                        Layout.bottomMargin: 15
                        font.pixelSize: 14
                        onClicked: calculate()
                    }

                    Button {
                        text: "Close All"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 250
                        Layout.bottomMargin: 15
                        font.pixelSize: 14
                        onClicked: {
                            for (let i = 0; i < accordionSections.length; i++) {
                                accordionSections[i].shown = false;
                            }
                        }
                    }

                    Button {
                        text: "Open All"
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 250
                        Layout.bottomMargin: 15
                        font.pixelSize: 14
                        onClicked: { 
                            for (let i = 0; i < accordionSections.length; i++) {
                                accordionSections[i].shown = true;
                            }
                        }
                    }
                }

                // Repeater for accordion sections
                Repeater {
                    id: accordionRepeater
                    model: accordionModel
                    
                    Column {
                        anchors.right: parent.right
                        anchors.left: parent.left
                        property bool showList: false

                        Button {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            text: model.title
                            onClicked: accordionPane.accordionSections[index].shown = !accordionPane.accordionSections[index].shown
                        }

                        Pane {
                            id: paneSection
                            Component.onCompleted: {
                                // Add this pane to the list of accordion sections
                                let sections = accordionPane.accordionSections;
                                sections.push(paneSection);
                                accordionPane.accordionSections = sections;
                            }

                            property bool shown: false
                            visible: height > 0
                            height: shown ? implicitHeight : 0
                            Behavior on height {
                                NumberAnimation {
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            clip: true
                            padding: 15
                            anchors.left: parent.left
                            anchors.right: parent.right

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 10
                                
                                // Dynamically create component based on model
                                Loader {
                                    sourceComponent: {
                                        switch(model.component) {
                                            case "WindGenProtectionResults": return windGenComponent;
                                            case "LineProtectionResults": return lineProtectionComponent;
                                            case "ProtectionRequirementsResults": return protectionReqComponent;
                                            case "VoltageRegResults": return voltageRegComponent;
                                            case "ABBConfig": return abbConfigComponent;
                                            case "GridConnectionReq": return gridConnectionComponent;
                                            default: return null;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Component definitions
                Component { id: windGenComponent; WindGenProtectionResults {} }
                Component { id: lineProtectionComponent; LineProtectionResults {} }
                Component { id: protectionReqComponent; ProtectionRequirementsResults {} }
                Component { id: voltageRegComponent; VoltageRegResults {} }
                Component { id: abbConfigComponent; ABBConfig {} }
                Component { id: gridConnectionComponent; GridConnectionReq {} }
            }
        }
    }
}