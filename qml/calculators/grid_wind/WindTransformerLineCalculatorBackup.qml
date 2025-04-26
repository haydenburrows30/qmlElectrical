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
    
    // Vertical tabbar
    Rectangle {
        id: floatingBar
        width: compactMode ? 70 : 80 // Adjust width based on screen size
        height: tabButtonColumn.height + 15 // Add padding (20px on top and bottom)
        radius: 15
        color: window.modeToggled ? "#2D2D2D" : "#4a86e8"
        
        // Add property to track theme colors
        property color textColor: window.modeToggled ? "#FFFFFF" : "#FFFFFF"
        property color activeTextColor: window.modeToggled ? "#FFFFFF" : "#FFFFFF"
        property color inactiveTextColor: window.modeToggled ? "#B0B0B0" : "#FFFFFFB0"
        property color highlightColor: window.modeToggled ? "#505050" : "#FFFFFF"
        
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
        property bool compactMode: parent.width < 800

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
        
        // Initial position - right side
        x: parent.width - width - 20
        y: (parent.height - height) / 2
        
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
                    
                    // Track if this is the active tab
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

                    // Improve touch feedback
                    MouseArea {
                        id: tabButtonMouse
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            floatingBar.currentIndex = tabButtonIndex
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
                        z: 20
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
