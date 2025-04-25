import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

import "../../components/style"
import "../../components/buttons"

import TransformerLine 1.0
import WindTurbine 1.0

Item {
    id: root
    property TransformerLineCalculator transformerCalculator : TransformerLineCalculator {}
    property WindTurbineCalculator windTurbineCalculator : WindTurbineCalculator {}
    
    property bool transformerReady: transformerCalculator !== null
    property bool windTurbineReady: windTurbineCalculator !== null
    property real totalGeneratedPower: windTurbineReady ? windTurbineCalculator.actualPower : 0
    
    function safeValue(value, defaultVal) {
        if (value === undefined || value === null) {
            return defaultVal;
        }
        
        if (typeof value !== 'number' || isNaN(value) || !isFinite(value)) {
            return defaultVal;
        }
        
        return value;
    }
                
    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0
        
        // Main content stack
        StackLayout {
            id: contentStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: floatingBar.currentIndex
            
            // Tab 1: Wind Turbine Parameters - operates independently
            WindTurbineSection {
                id: windTurbineSection
                Layout.fillWidth: true

                // Pass only necessary properties and functions
                calculator: windTurbineCalculator
                calculatorReady: windTurbineReady

                onCalculate: {
                    if (windTurbineReady) {
                        windTurbineCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }

            // Tab 2: Transformer & Line Parameters - operates independently
            TransformerLineSection {
                id: transformerLineSection
                Layout.fillWidth: true

                // Pass only necessary properties and functions
                calculator: transformerCalculator
                calculatorReady: transformerReady

                onCalculate: {
                    if (transformerReady) {
                        transformerCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }

            // Tab 3: Protection Requirements - still needs access to both
            ProtectionRequirementsSection {
                Layout.fillWidth: true

                // Pass the required properties
                transformerCalculator: root.transformerCalculator
                windTurbineCalculator: root.windTurbineCalculator
                transformerReady: root.transformerReady
                windTurbineReady: root.windTurbineReady
                totalGeneratedPower: root.totalGeneratedPower

                onCalculate: {
                    // For the protection tab, we need data from both systems
                    if (transformerReady && windTurbineReady) {
                        windTurbineCalculator.refreshCalculations()
                        transformerCalculator.refreshCalculations()
                    }
                }
                safeValueFunction: safeValue
            }
        }
    }
    
    // Refined floating navigation bar with snap points and animations - now vertical
    Rectangle {
        id: floatingBar
        width: 80 // Fixed width for vertical layout
        height: tabButtonColumn.height + 40 // Add padding (20px on top and bottom)
        radius: 28
        // Use window.modeToggled for theme-aware colors
        color: window.modeToggled ? "#2D2D2D" : "#4a86e8"
        
        // Add property to track theme colors
        property color textColor: window.modeToggled ? "#FFFFFF" : "#FFFFFF"
        property color activeTextColor: window.modeToggled ? "#FFFFFF" : "#FFFFFF"
        property color inactiveTextColor: window.modeToggled ? "#B0B0B0" : "#FFFFFFB0"
        property color highlightColor: window.modeToggled ? "#505050" : "#FFFFFF"
        
        // Initial position - right side
        x: parent.width - width - 20
        y: (parent.height - height) / 2
        
        // Properties for animations and snap points
        property bool snapToEdges: true
        property real snapThreshold: 40 // Distance in pixels to snap to edge
        property var snapPositions: [
            {x: 0, y: (parent.height - height) / 2}, // Left center
            {x: parent.width - width, y: (parent.height - height) / 2}, // Right center
            {x: (parent.width - width) / 2, y: 0}, // Top center
            {x: (parent.width - width) / 2, y: parent.height - height}, // Bottom center
            {x: 0, y: 0}, // Top left
            {x: parent.width - width, y: 0}, // Top right
            {x: 0, y: parent.height - height}, // Bottom left
            {x: parent.width - width, y: parent.height - height} // Bottom right
        ]
        
        // Property for current tab index with proper change handling
        property int currentIndex: 0
        
        // Add property to track if bar is on the left side
        property bool isOnLeftSide: false
        
        // Function to update the side property
        function updateSidePosition() {
            // Consider it on the left side if it's closer to the left edge than the right edge
            isOnLeftSide = x < (parent.width - width - x)
        }
        
        // Update the side position whenever x changes
        onXChanged: updateSidePosition()
        
        // Initialize side position on component completion
        Component.onCompleted: updateSidePosition()
        
        // Observe changes to the currentIndex property
        Connections {
            target: floatingBar
            function onCurrentIndexChanged() {
                // Update all tab states
                for (var i = 0; i < tabButtonRepeater.count; i++) {
                    var tab = tabButtonRepeater.itemAt(i)
                    if (tab) {
                        tab.updateActiveState()
                    }
                }
            }
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
        
        Column {
            id: tabButtonColumn
            anchors.centerIn: parent
            spacing: 20
            
            Repeater {
                id: tabButtonRepeater
                model: [
                    { text: "Wind Turbine", icon: "⚡", index: 0 },
                    { text: "Transformer", icon: "🔌", index: 1 },
                    { text: "Protection", icon: "🛡️", index: 2 }
                ]
                
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
                        isActive = (floatingBar.currentIndex === tabButtonIndex)
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
                        color: window.modeToggled ? floatingBar.textColor : "#333333" // Dark in light mode
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
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            floatingBar.currentIndex = tabButtonIndex
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
            drag.maximumX: root.width - floatingBar.width
            drag.minimumY: 0
            drag.maximumY: root.height - floatingBar.height
            drag.threshold: 5
            z: 1
            
            property bool isDragging: false
            property point startPosition
            
            // Enable mouse events to pass through to children when not dragging
            propagateComposedEvents: true
            
            function onPressed(mouse) {
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
            
            function onPositionChanged(mouse) {
                if (!isDragging) {
                    drag.target = null
                    mouse.accepted = false
                } else {
                    drag.target = floatingBar
                    mouse.accepted = true
                }
            }
            
            function onReleased(mouse) {
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
                    
                    // Snap to closest position if enabled
                    var closestDist = Number.MAX_VALUE
                    var closestPos = null
                    
                    for (var i = 0; i < floatingBar.snapPositions.length; i++) {
                        var pos = floatingBar.snapPositions[i]
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
                    var rightDist = Math.abs((root.width - floatingBar.width) - floatingBar.x)
                    var topDist = Math.abs(floatingBar.y)
                    var bottomDist = Math.abs((root.height - floatingBar.height) - floatingBar.y)
                    
                    if (leftDist < floatingBar.snapThreshold && leftDist < closestDist) {
                        closestPos = {x: 0, y: floatingBar.y}
                        closestDist = leftDist
                    }
                    if (rightDist < floatingBar.snapThreshold && rightDist < closestDist) {
                        closestPos = {x: root.width - floatingBar.width, y: floatingBar.y}
                        closestDist = rightDist
                    }
                    if (topDist < floatingBar.snapThreshold && topDist < closestDist) {
                        closestPos = {x: floatingBar.x, y: 0}
                        closestDist = topDist
                    }
                    if (bottomDist < floatingBar.snapThreshold && bottomDist < closestDist) {
                        closestPos = {x: floatingBar.x, y: root.height - floatingBar.height}
                        closestDist = bottomDist
                    }
                    
                    // Apply the snap position
                    if (closestPos) {
                        floatingBar.x = closestPos.x
                        floatingBar.y = closestPos.y
                    }
                } else {
                    // Not dragging, let other MouseAreas handle it
                    mouse.accepted = false
                }
            }
            
            // Helper function to walk up parent chain looking for tabButton
            function getTabButtonParent(item) {
                var current = item
                while (current) {
                    if (current.objectName === "tabButton") {
                        return current
                    }
                    current = current.parent
                }
                return null
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

        Connections {
            target: window
            function onModeToggledChanged() {
                var isDarkTheme = window.modeToggled
                floatingBar.color = isDarkTheme ? "#2D2D2D" : "#4a86e8"
                floatingBar.textColor = isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                floatingBar.activeTextColor = isDarkTheme ? "#FFFFFF" : "#FFFFFF"
                floatingBar.inactiveTextColor = isDarkTheme ? "#B0B0B0" : "#FFFFFFB0"
                floatingBar.highlightColor = isDarkTheme ? "#505050" : "#FFFFFF"
            }
        }
    }
}
