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
    
    // Signals
    signal tabSelected(int index)
    
    // Read-only properties
    readonly property bool isOnLeftSide: floatingBar.isOnLeftSide
    
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
        width: compactMode ? 70 : 80 // Adjust width based on screen size
        height: tabButtonColumn.height + 40 // Add padding (20px on top and bottom)
        radius: 28
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
        
        // Add property for tooltip visibility
        property bool showTooltips: true
        
        // Add property for screen adaptation
        property bool compactMode: parent.parent ? parent.parent.width < 800 : false
        
        // Add keyboard focus properties for accessibility
        activeFocusOnTab: true
        
        // Add property to track if bar is on the left side
        property bool isOnLeftSide: false
        
        // Function to update the side property
        function updateSidePosition() {
            // Consider it on the left side if it's closer to the left edge than the right edge
            isOnLeftSide = x < (parent.parent ? (parent.parent.width - width - x) : 0)
        }
        
        // Update the side position whenever x changes
        onXChanged: updateSidePosition()
        
        // Initialize side position on component completion
        Component.onCompleted: updateSidePosition()
        
        // Merged states array that combines keyboard focus and dragging states
        states: [
            State {
                name: "keyboardFocus"
                when: floatingBar.activeFocus
                PropertyChanges {
                    target: floatingBar
                    border.width: 2
                    border.color: "#FFFFFF"
                }
            },
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
        
        // Handle keyboard navigation
        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                var newIndex = Math.max(0, root.currentIndex - 1)
                root.currentIndex = newIndex
                root.tabSelected(newIndex)
                event.accepted = true
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                var newIndex = Math.min(root.tabModel.length - 1, root.currentIndex + 1)
                root.currentIndex = newIndex
                root.tabSelected(newIndex)
                event.accepted = true
            }
        }
        
        // Improve dark/light mode transitions
        Behavior on color {
            ColorAnimation { duration: 200 }
        }
        
        // Properties for animations and snap points
        property bool snapToEdges: true
        property real snapThreshold: 40 // Distance in pixels to snap to edge
        
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
        
        // Visual feedback when dragging - transitions remain the same
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
            },
            // Add transition for keyboard focus state
            Transition {
                from: ""
                to: "keyboardFocus"
                NumberAnimation {
                    properties: "border.width"
                    duration: 150
                }
            },
            Transition {
                from: "keyboardFocus"
                to: ""
                NumberAnimation {
                    properties: "border.width"
                    duration: 150
                }
            }
        ]
        
        Column {
            id: tabButtonColumn
            anchors.centerIn: parent
            spacing: 20
            
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
                        visible: tabButtonMouse.containsMouse && floatingBar.showTooltips
                        text: modelData.text
                        delay: 800
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
                        
                        // Make cursor a pointer on hover
                        cursorShape: Qt.PointingHandCursor
                        
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
        
        // Add drag area with improved behaviors
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
                // Use the top 20px as drag handle area
                if (mouseX < 20) {
                    isDragging = true
                    cursorShape = Qt.ClosedHandCursor
                    // Only accept the event when we're actually dragging
                    mouse.accepted = true
                } else {
                    isDragging = false
                    // Let the event propagate to child MouseAreas
                    mouse.accepted = false
                }
            }
            
            onPositionChanged: function(mouse) {
                if (!isDragging) {
                    drag.target = null
                    mouse.accepted = false
                } else {
                    drag.target = floatingBar
                    mouse.accepted = true
                }
            }
            
            onReleased: function(mouse) {
                cursorShape = Qt.ArrowCursor
                isDragging = false
                
                // Only handle snapping if we actually dragged
                if (drag.active) {
                    // If we barely moved, treat as a click
                    if (Math.abs(floatingBar.x - startPosition.x) < 5 && 
                        Math.abs(floatingBar.y - startPosition.y) < 5) {
                        // Since this is a small movement, pass the event through
                        mouse.accepted = false
                        return
                    }
                    
                    if (floatingBar.snapToEdges && root.parent) {
                        // Calculate snap positions dynamically based on parent size
                        var parentWidth = root.parent.width
                        var parentHeight = root.parent.height
                        var snapPositions = [
                            {x: 0, y: (parentHeight - floatingBar.height) / 2}, // Left center
                            {x: parentWidth - floatingBar.width, y: (parentHeight - floatingBar.height) / 2}, // Right center
                            {x: (parentWidth - floatingBar.width) / 2, y: 0}, // Top center
                            {x: (parentWidth - floatingBar.width) / 2, y: parentHeight - floatingBar.height}, // Bottom center
                            {x: 0, y: 0}, // Top left
                            {x: parentWidth - floatingBar.width, y: 0}, // Top right
                            {x: 0, y: parentHeight - floatingBar.height}, // Bottom left
                            {x: parentWidth - floatingBar.width, y: parentHeight - floatingBar.height} // Bottom right
                        ]
                    
                        // Snap to closest position if enabled
                        var closestDist = Number.MAX_VALUE
                        var closestPos = null
                        
                        for (var i = 0; i < snapPositions.length; i++) {
                            var pos = snapPositions[i]
                            var dist = Math.sqrt(
                                Math.pow(floatingBar.x - pos.x, 2) + 
                                Math.pow(floatingBar.y - pos.y, 2)
                            )
                            
                            if (dist < closestDist) {
                                closestDist = dist
                                closestPos = pos
                            }
                        }
                        
                        // Add edge snap detection
                        var leftDist = Math.abs(floatingBar.x)
                        var rightDist = Math.abs((parentWidth - floatingBar.width) - floatingBar.x)
                        var topDist = Math.abs(floatingBar.y)
                        var bottomDist = Math.abs((parentHeight - floatingBar.height) - floatingBar.y)
                        
                        if (leftDist < floatingBar.snapThreshold && leftDist < closestDist) {
                            closestPos = {x: 0, y: floatingBar.y}
                            closestDist = leftDist
                        }
                        if (rightDist < floatingBar.snapThreshold && rightDist < closestDist) {
                            closestPos = {x: parentWidth - floatingBar.width, y: floatingBar.y}
                            closestDist = rightDist
                        }
                        if (topDist < floatingBar.snapThreshold && topDist < closestDist) {
                            closestPos = {x: floatingBar.x, y: 0}
                            closestDist = topDist
                        }
                        if (bottomDist < floatingBar.snapThreshold && bottomDist < closestDist) {
                            closestPos = {x: floatingBar.x, y: parentHeight - floatingBar.height}
                            closestDist = bottomDist
                        }
                        
                        // Apply the snap position
                        if (closestPos) {
                            floatingBar.x = closestPos.x
                            floatingBar.y = closestPos.y
                        }
                    }
                } else {
                    // Not dragging, let other MouseAreas handle it
                    mouse.accepted = false
                }
            }
            
            // Handle cursor appearance during hover over handle
            hoverEnabled: true
            onEntered: {
                if (mouseX < 20) {
                    cursorShape = Qt.OpenHandCursor
                }
            }
            onExited: {
                cursorShape = Qt.ArrowCursor
            }
            onMouseXChanged: {
                if (mouseX < 20 && !pressed) {
                    cursorShape = Qt.OpenHandCursor
                } else if (!pressed) {
                    cursorShape = Qt.ArrowCursor
                }
            }
        }
    }
    
    // Public methods
    function resetPosition() {
        if (parent) {
            floatingBar.x = parent.width - floatingBar.width - 20
            floatingBar.y = (parent.height - floatingBar.height) / 2
        }
    }
    
    // Function to position the tabbar initially
    function setPosition(x, y) {
        floatingBar.x = x
        floatingBar.y = y
    }
}
