pragma Singleton
import QtQuick

QtObject {
    // Colors

    readonly property color transparent: "transparent"
    readonly property color buttonBackground: "#606060"
    readonly property color buttonHovered: "#505050"
    readonly property color buttonPressed: "#404040"
    readonly property color buttonBorder: "#808080"
    readonly property color textFieldBorder: "#0078d7"
    
    // Dimensions
    readonly property int iconSize: 30
    readonly property int sideBarWidth: 60
    readonly property int delegateHeight: 60
    readonly property int tooltipWidth: 110
    
    // Animations
    readonly property int tooltipDelay: 500
    readonly property int colorAnimationDuration: 150
    readonly property int sidebarAnimationDuration: 200
    
    // Opacities
    readonly property real fadeOpacity: 0.8
    readonly property real highlightOpacity: 0.1

    // devicestile

    readonly property color background: "#e2e2e2"

    readonly property color white: "#fafafa"
    readonly property color black: "#050506"
    readonly property color red: "#e25141"
    readonly property color blue: "#405ff5"
    readonly property color blueGreen: "#5b32f5"
    readonly property color green: "#5ac461"
    readonly property color yellow: "#f19537"
    readonly property color yellowLight: "#e29155"
    readonly property color iconColor: "#4a4a4a"


    property color textColor: "#FFFFFF"
    property color charcoalGrey: "#404040"
    property color granite: "#808080"
    property color paleSlate: "#BFBFBF"
    property color lightColor4: "#000000"

    property color lightLime: "#A5FF5D"
    property color pastelBlue: "#96C6FF"
    property color cinder: "#151515"
    property color seashell: "#F1F1F1"

    function alphaColor(color, alpha) {
        let actualColor = Qt.darker(color, 1)
        actualColor.a = alpha
        return actualColor
    }

    property var basic: [
        { name: qsTr("Impedance Calculator"), source: "calculators/basic/ImpedanceCalculator.qml" },
        { name: qsTr("kVA / kw / A"), source: "calculators/basic/PowerCurrentCalculator.qml" },
        { name: qsTr("Unit Converter"), source: "calculators/basic/UnitConverter.qml" },
        { name: qsTr("Power Factor Correction"), source: "calculators/basic/PowerFactorCorrection.qml" },
        { name: qsTr("Ohm's Law"), source: "calculators/basic/OhmsLawCalculator.qml" },
        { name: qsTr("Voltage Divider"), source: "calculators/basic/VoltageDividerCalculator.qml" }
    ]
}
