import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    
    // Public properties that can be set from outside
    property var tabModel: []  // Model for tab items
    property int currentIndex: 0 // Current active tab index
    property color barColor: "#4a86e8" // Default bar color
    property color textColor: "#FFFFFF" // Default text color
    property color highlightColor: "#FFFFFF" // Default highlight color
    property bool darkMode: false // Dark mode state
    
    // Add property to control collapse behavior
    property bool collapsedByDefault: true
    property bool isCollapsed: collapsedByDefault
    property int collapseDelay: 2000 // ms to wait before collapsing after mouse leaves
    
    // Signals
    signal tabSelected(int index)
    
    // Read-only properties
    readonly property bool isOnLeftSide: floatingBar.isOnLeftSide
    readonly property bool isOnRightSide: floatingBar.isOnRightSide
    
    // Size properties
    width: floatingBar.width
    height: floatingBar.height
    
    // Watch for currentIndex changes
    onCurrentIndexChanged: {
        // Update all tab states
        for (var i = 0; i < tabButtonRepeater.count; i++) {
            var tab = tabButtonRepeater.itemAt(i)
            if (tab) {
                tab.updateActiveState()
            }
        }
    }
    
    // The actual floating bar rectangle
    Rectangle {
        id: floatingBar
        width: isCollapsed ? 50 : (compactMode ? 70 : 80) // Narrower when collapsed
        height: isCollapsed ? 50 : tabButtonColumn.height + 10 // Just enough for the menu icon
        radius: 18
        color: root.darkMode ? "#2D2D2D" : root.barColor
        
        // Add property to track theme colors
        property color textColor: root.textColor
        property color activeTextColor: root.textColor
        property color inactiveTextColor: darkMode ? "#B0B0B0" : "#FFFFFFB0"
        property color highlightColor: root.highlightColor
        
        // Add shadow for better floating appearance
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#80000000"
            shadowVerticalOffset: 3
            shadowHorizontalOffset: 3
            shadowBlur: 12
        }
        
        // Add property for screen adaptation
        property bool compactMode: parent.parent ? parent.parent.width < 800 : false
        
        // Add property to track if bar is on the left or right side
        property bool isOnLeftSide: false
        property bool isOnRightSide: false
        
        // Function to update the side property
        function updateSidePosition() {
            // Consider it on the left side if it's closer to the left edge than the right edge
            isOnLeftSide = x < (parent.parent ? (parent.parent.width - width - x) : 0)
            isOnRightSide = x > (parent.parent ? (parent.parent.width - width - x) : 0)
        }
        
        // Update the side position whenever x changes
        onXChanged: updateSidePosition()
        
        // Initialize side position on component completion
        Component.onCompleted: updateSidePosition()
        
        // menu icon for collapsed state
        Rectangle {
            id: menuIcon
            width: 40
            height: 40
            radius: 20
            color: "transparent"
            anchors.centerIn: isCollapsed ? parent : undefined
            anchors.horizontalCenter: isCollapsed ? undefined : parent.horizontalCenter
            anchors.top: isCollapsed ? undefined : parent.top
            anchors.topMargin: isCollapsed ? 0 : 5
            visible: true
            
            // Menu icon lines (hamburger menu)
            Column {
                anchors.centerIn: parent
                spacing: 4
                
                Repeater {
                    model: 3
                    Rectangle {
                        width: 20
                        height: 2
                        radius: 1
                        color: floatingBar.textColor
                    }
                }
            }
            
            // Show menu icon only in collapsed state
            opacity: isCollapsed ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }
        
        // Timer to handle auto-collapse after mouse leaves
        Timer {
            id: collapseTimer
            interval: root.collapseDelay
            onTriggered: {
                if (!hoverArea.containsMouse && !dragArea.isDragging) {
                    root.isCollapsed = true
                }
            }
        }
        
        // Hover area to detect mouse over the bar
        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            
            onEntered: {
                root.isCollapsed = false
                collapseTimer.stop()
            }
            
            onExited: {
                if (collapsedByDefault && !dragArea.isDragging) {
                    collapseTimer.restart()
                }
            }
            
            onPressed: mouse.accepted = false
            onReleased: mouse.accepted = false
            onClicked: mouse.accepted = false
        }

        // drag area
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: floatingBar
            drag.minimumX: 0
            drag.maximumX: root.parent ? root.parent.width - floatingBar.width : 0
            drag.minimumY: 0
            drag.maximumY: root.parent ? root.parent.height - floatingBar.height : 0
            drag.threshold: 5
            z: 1
            
            property bool isDragging: false
            property point startPosition
            
            // Enable mouse events to pass through to children when not dragging
            propagateComposedEvents: true
            
            onPressed: function(mouse) {
                startPosition = Qt.point(floatingBar.x, floatingBar.y)
                isDragging = true
                cursorShape = Qt.ClosedHandCursor
                mouse.accepted = true
                
                // Expand when dragging
                root.isCollapsed = false
                collapseTimer.stop()
            }
            
            onReleased: function(mouse) {
                cursorShape = Qt.ArrowCursor
                isDragging = false
                
                // Start collapse timer after releasing drag
                if (collapsedByDefault && !hoverArea.containsMouse) {
                    collapseTimer.restart()
                }
            }
        }
        
        // dragging states
        states: [
            State {
                name: "dragging"
                when: dragArea.drag.active
                PropertyChanges {
                    target: floatingBar
                    opacity: 0.8
                    scale: 1.05
                }
            }
        ]
        
        // Improve dark/light mode transitions
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        
        // Smooth position animations
        Behavior on x {
            enabled: !dragArea.drag.active
            NumberAnimation { 
                duration: 300 
                easing.type: Easing.OutQuad
            }
        }
        
        Behavior on y {
            enabled: !dragArea.drag.active
            NumberAnimation { 
                duration: 300 
                easing.type: Easing.OutQuad
            }
        }
        
        // Visual feedback when dragging
        transitions: [
            Transition {
                from: ""
                to: "dragging"
                NumberAnimation {
                    properties: "opacity,scale"
                    duration: 200
                }
            },
            Transition {
                from: "dragging"
                to: ""
                NumberAnimation {
                    properties: "opacity,scale"
                    duration: 300
                }
            }
        ]
        
        // main bar
        Column {
            id: tabButtonColumn
            anchors.centerIn: parent
            spacing: 5
            // Hide tabs in collapsed state
            opacity: isCollapsed ? 0.0 : 1.0
            visible: opacity > 0
            
            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
            
            // Move tabs down in expanded state to make room for the menu icon
            // anchors.verticalCenterOffset: isCollapsed ? 0 : 15
            
            Repeater {
                id: tabButtonRepeater
                model: root.tabModel
                
                Item {
                    id: tabButton
                    width: 70
                    height: 64
                    objectName: "tabButton"
                    
                    // Store the index directly in a property
                    property int tabButtonIndex: modelData.index
                    
                    // Track if this is the active tab - fixed binding
                    property bool isActive: false
                    
                    // Function to update active state
                    function updateActiveState() {
                        isActive = (root.currentIndex === tabButtonIndex)
                    }
                    
                    // Initialize on component completion
                    Component.onCompleted: {
                        updateActiveState()
                    }
                    
                    // Background highlight for active tab
                    Rectangle {
                        id: tabButtonBg
                        anchors.fill: parent
                        radius: 16
                        color: floatingBar.highlightColor 
                        opacity: tabButton.isActive ? 0.3 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                    
                    Column {
                        id: tabButtonItemColumn
                        anchors.centerIn: parent
                        spacing: 4
                        
                        // Use the emoji from the model directly - increased size
                        Text {
                            text: modelData.icon
                            font.pixelSize: 22
                            color: floatingBar.textColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: tabButton.isActive ? 1.0 : 0.7
                            // Add transition for smooth opacity change
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                        
                        Text {
                            text: modelData.text
                            font.pixelSize: 12
                            font.bold: tabButton.isActive // Make active tab text bold
                            color: floatingBar.textColor
                            anchors.horizontalCenter: parent.horizontalCenter
                            opacity: tabButton.isActive ? 1.0 : 0.7
                            // Add transition for smooth opacity change
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }
                    }
                    
                    // Indicator dot for selected tab - dynamic positioning based on side
                    Rectangle {
                        id: indicatorDot
                        width: 5
                        height: 5
                        radius: 2.5
                        color: root.darkMode ? floatingBar.textColor : "#333333" // Dark in light mode
                        anchors.verticalCenter: parent.verticalCenter
                        
                        // Fix the shape issue by ensuring aspect ratio and size is maintained
                        // Make sure width and height are fixed regardless of anchoring
                        implicitWidth: 5
                        implicitHeight: 5
                        
                        // Ensure radius is always half of the width for a proper circle
                        onWidthChanged: radius = width / 2
                        
                        // Dynamic anchoring based on the side of the screen - keep margins consistent
                        states: [
                            State {
                                name: "rightSide"
                                when: !floatingBar.isOnLeftSide
                                AnchorChanges {
                                    target: indicatorDot
                                    anchors.right: undefined
                                    anchors.left: parent.left
                                }
                                PropertyChanges {
                                    target: indicatorDot
                                    anchors.leftMargin: -8
                                    anchors.rightMargin: 0
                                }
                            },
                            State {
                                name: "leftSide"
                                when: floatingBar.isOnLeftSide
                                AnchorChanges {
                                    target: indicatorDot
                                    anchors.left: undefined
                                    anchors.right: parent.right
                                }
                                PropertyChanges {
                                    target: indicatorDot
                                    anchors.rightMargin: -8
                                    anchors.leftMargin: 0
                                }
                            }
                        ]
                        
                        // Add smooth transitions between states
                        transitions: Transition {
                            AnchorAnimation { duration: 300; easing.type: Easing.OutQuad }
                        }
                        
                        visible: tabButton.isActive
                        
                        // Reset and run animation when becoming visible
                        onVisibleChanged: {
                            if (visible) {
                                scaleAnim.restart()
                            }
                        }
                        
                        // Separate animation definition for better control
                        SequentialAnimation {
                            id: scaleAnim
                            running: false
                            NumberAnimation { 
                                target: indicatorDot
                                property: "scale"
                                from: 0 
                                to: 1.2
                                duration: 150
                                easing.type: Easing.OutQuad 
                            }
                            NumberAnimation { 
                                target: indicatorDot
                                property: "scale"
                                from: 1.2
                                to: 1.0
                                duration: 100
                                easing.type: Easing.InOutQuad 
                            }
                        }
                    }
                    
                    // Add ripple effect for better touch feedback
                    Rectangle {
                        id: rippleEffect
                        anchors.centerIn: parent
                        width: 0
                        height: 0
                        radius: width/2
                        color: floatingBar.highlightColor
                        opacity: 0
                        
                        // Ripple animation
                        PropertyAnimation {
                            id: rippleAnimation
                            target: rippleEffect
                            properties: "width,height,opacity"
                            from: 0
                            to: tabButton.width * 1.5
                            duration: 300
                            easing.type: Easing.OutQuad
                            onFinished: {
                                rippleEffect.width = 0
                                rippleEffect.height = 0
                                rippleEffect.opacity = 0
                            }
                        }
                    }
                    
                    // Tooltip for better UX
                    ToolTip {
                        visible: tabButtonMouse.containsMouse
                        text: modelData.text
                        delay: 700
                    }
                    
                    // Improve touch feedback
                    MouseArea {
                        id: tabButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        
                        onClicked: {
                            root.currentIndex = tabButtonIndex
                            root.tabSelected(tabButtonIndex)
                            rippleEffect.opacity = 0.4
                            rippleAnimation.start()
                        }

                        // Highlight on hover
                        onEntered: {
                            if (!tabButton.isActive) {
                                tabButtonBg.opacity = 0.15
                            }
                        }
                        
                        onExited: {
                            if (!tabButton.isActive) {
                                tabButtonBg.opacity = 0
                            }
                        }
                        
                        // Make sure clicks aren't intercepted by the drag area
                        z: 10
                    }
                }
            }
        }
        
        // Add smooth transitions for size changes
        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }
        
        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }
    }
    
    // Public methods
    function resetPosition() {
        if (parent) {
            floatingBar.x = 10
            floatingBar.y = 10
        }
    }
    
    // Function to position the tabbar initially
    function setPosition(x, y) {
        floatingBar.x = x
        floatingBar.y = y
    }
}
