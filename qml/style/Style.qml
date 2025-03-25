pragma Singleton
import QtQuick

QtObject {
    // Colors
    readonly property color transparent: "transparent"
    readonly property color buttonBackground: "#606060"
    readonly property color buttonHovered: "#505050"
    readonly property color buttonPressed: "#404040"
    readonly property color buttonBorder: "#808080"
    
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
}
