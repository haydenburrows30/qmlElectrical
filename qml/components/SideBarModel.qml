import QtQuick

ListModel {
    ListElement {
        title: "Home"
        source: "../pages/Home.qml"
        icon: "Home"
    }
    ListElement {
        title: "Voltage Drop"
        source: "../pages/VoltageDrop.qml"
        icon: "Voltage Drop"
    }
    ListElement {
        title: "Calculator"
        source: "../pages/Calculator.qml"
        icon: "Calculator"
    }
    ListElement {
        title: "Three Phase"
        source: "../pages/ThreePhase.qml"
        icon: "Wave"
    }
    ListElement {
        title: "RLC"
        source: "../pages/RLC.qml"
        icon: "RLC"
    }
    ListElement {
        title: "Real Time"
        source: "../pages/RealTime.qml"
        icon: "RealTime"
    }
}