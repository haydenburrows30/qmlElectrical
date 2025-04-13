import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import QtQuick.Shapes

Item {
    id: root
    
    // Properties from the parent
    property string transformerType: "CT"    // CT or VT
    property string primaryRating: "100"     // Primary current or voltage
    property string secondaryRating: "5"     // Secondary current or voltage
    property string accuracyClass: "0.5"     // Accuracy class
    property string burden: "15"             // Burden in VA
    property string insulationLevel: "12"    // Insulation level in kV
    property string application: "metering"  // Application type
    property bool darkMode: false            // Dark mode state
    
    // Colors based on theme
    property color primaryColor: darkMode ? "#00B0FF" : "#0077CC"
    property color secondaryColor: darkMode ? "#FF9800" : "#FF6F00"
    property color wireColor: darkMode ? "#CCCCCC" : "#333333" 
    property color insulationColor: darkMode ? "#444444" : "#DDDDDD"
    property color textColor: darkMode ? "#FFFFFF" : "#000000"
    property color backgroundColor: darkMode ? "#303030" : "#FFFFFF"
    
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        radius: 5
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 10

            // Parameters display
            GridLayout {
                Layout.maximumWidth: 200
                columns: 2
                columnSpacing: 10
                rowSpacing: 5
                
                Text { 
                    text: "Type:"
                    color: textColor
                    font.pixelSize: 12
                }
                Text { 
                    text: transformerType === "CT" ? "Current Transformer" : "Voltage Transformer"
                    color: textColor
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text { 
                    text: transformerType === "CT" ? "Ratio:" : "Ratio:"
                    color: textColor
                    font.pixelSize: 12
                }
                Text { 
                    text: primaryRating + ":" + secondaryRating
                    color: textColor
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text { 
                    text: "Accuracy Class:"
                    color: textColor
                    font.pixelSize: 12
                }
                Text { 
                    text: accuracyClass
                    color: textColor
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text { 
                    text: "Burden:"
                    color: textColor
                    font.pixelSize: 12
                }
                Text { 
                    text: burden + " VA"
                    color: textColor
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text { 
                    text: "Insulation:"
                    color: textColor
                    font.pixelSize: 12
                }
                Text { 
                    text: insulationLevel + " kV"
                    color: textColor
                    font.pixelSize: 12
                    font.bold: true
                }
                
                Text { 
                    text: "Application:"
                    color: textColor
                    font.pixelSize: 12
                }
                Text { 
                    text: application.charAt(0).toUpperCase() + application.slice(1)
                    color: textColor
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            // Main visualization 
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                // Draw different visualizations for CT vs VT
                Item {
                    id: transformer
                    anchors.fill: parent
                    
                    // CT visualization
                    Item {
                        anchors.fill: parent
                        visible: transformerType === "CT"
                        
                        // Core
                        Rectangle {
                            id: ctCore
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.5
                            height: width
                            radius: width/2
                            color: "transparent"
                            border.width: width * 0.1
                            border.color: "#777777"
                        }
                        
                        // Primary wire (passes through center)
                        Rectangle {
                            id: ctPrimary
                            anchors.centerIn: parent
                            height: parent.height * 0.8
                            width: ctCore.width * 0.25
                            color: primaryColor
                            z: -1
                            
                            // Primary label
                            Text {
                                anchors.top: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: primaryRating + "A"
                                color: textColor
                                font.pixelSize: 12
                            }
                            
                            // Add P1/P2 labels to primary
                            Text {
                                anchors.bottom: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "P1"
                                color: textColor
                                font.pixelSize: 11
                                font.bold: true
                            }
                            
                            Text {
                                anchors.top: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: 20
                                text: "P2"
                                color: textColor
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }
                        
                        // Secondary winding (wrapped around core)
                        Shape {
                            anchors.fill: parent
                            
                            ShapePath {
                                strokeColor: secondaryColor
                                fillColor: "transparent"
                                strokeWidth: 2
                                capStyle: ShapePath.RoundCap
                                
                                // Draw a spiral to represent secondary winding
                                PathSvg {
                                    path: generateSecondaryWindingSVG()
                                }
                            }
                        }
                        
                        // Secondary terminals - moved closer to CT core
                        Rectangle {
                            id: terminal1
                            x: parent.width * 0.63 // Moved closer to core
                            y: parent.height * 0.4
                            width: 10
                            height: 10
                            color: secondaryColor
                        }
                        
                        Rectangle {
                            id: terminal2
                            x: parent.width * 0.63 // Moved closer to core
                            y: parent.height * 0.6
                            width: 10
                            height: 10
                            color: secondaryColor
                        }
                        
                        // Terminal labels
                        Text {
                            anchors.left: terminal1.right
                            anchors.verticalCenter: terminal1.verticalCenter
                            text: "S1"
                            color: textColor
                            font.pixelSize: 10
                        }
                        
                        Text {
                            anchors.left: terminal2.right
                            anchors.verticalCenter: terminal2.verticalCenter
                            text: "S2"
                            color: textColor
                            font.pixelSize: 10
                        }
                        
                        // Secondary rating
                        Text {
                            anchors.left: terminal1.right
                            anchors.leftMargin: 25
                            anchors.verticalCenter: parent.verticalCenter
                            text: secondaryRating + "A"
                            color: textColor
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                    
                    // VT visualization - significantly larger and improved
                    Item {
                        anchors.fill: parent
                        visible: transformerType === "VT"
                        
                        // Core - made much larger
                        Rectangle {
                            id: vtCore
                            anchors.centerIn: parent
                            width: Math.min(parent.width, parent.height) * 0.75 // Increased from 0.6 to 0.75
                            height: width * 1.3
                            color: "#777777"
                            
                            // Add a subtle gradient to give depth
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.darker("#777777", 1.1) }
                                GradientStop { position: 0.5; color: "#777777" }
                                GradientStop { position: 1.0; color: Qt.darker("#777777", 1.15) }
                            }
                            
                            // Add border for definition
                            border.width: 1
                            border.color: "#555555"
                        }
                        
                        // Primary winding
                        Rectangle {
                            id: primaryWinding
                            anchors.left: vtCore.left
                            anchors.right: vtCore.right
                            anchors.top: vtCore.top
                            height: vtCore.height * 0.4
                            color: primaryColor
                            
                            // Gradient for depth
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(primaryColor, 1.1) }
                                GradientStop { position: 1.0; color: Qt.darker(primaryColor, 1.1) }
                            }
                            
                            // Primary label
                            Text {
                                anchors.centerIn: parent
                                text: "Primary"
                                color: "#FFFFFF"
                                font.pixelSize: 14 // Increased font size
                                font.bold: true
                            }
                        }
                        
                        // Secondary winding
                        Rectangle {
                            id: secondaryWinding
                            anchors.left: vtCore.left
                            anchors.right: vtCore.right
                            anchors.bottom: vtCore.bottom
                            height: vtCore.height * 0.4
                            color: secondaryColor
                            
                            // Gradient for depth
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(secondaryColor, 1.1) }
                                GradientStop { position: 1.0; color: Qt.darker(secondaryColor, 1.1) }
                            }
                            
                            // Secondary label
                            Text {
                                anchors.centerIn: parent
                                text: "Secondary"
                                color: "#FFFFFF"
                                font.pixelSize: 14 // Increased font size
                                font.bold: true
                            }
                        }
                        
                        // Primary terminals - repositioned for better visibility
                        Rectangle {
                            id: vtPrimaryTerminal1
                            x: vtCore.x - 40 // Moved further out
                            y: vtCore.y + vtCore.height * 0.2
                            width: 15 // Made larger
                            height: 15
                            radius: 3 // Rounded corners
                            color: primaryColor
                        }
                        
                        Rectangle {
                            id: vtPrimaryTerminal2
                            x: vtCore.x + vtCore.width + 25 // Moved further out
                            y: vtCore.y + vtCore.height * 0.2
                            width: 15
                            height: 15
                            radius: 3
                            color: primaryColor
                        }
                        
                        // Primary terminal connections - thicker lines
                        Rectangle {
                            x: vtPrimaryTerminal1.x + vtPrimaryTerminal1.width
                            y: vtPrimaryTerminal1.y + vtPrimaryTerminal1.height/2 - 2
                            width: vtCore.x - (vtPrimaryTerminal1.x + vtPrimaryTerminal1.width)
                            height: 4 // Thicker line
                            color: primaryColor
                        }
                        
                        Rectangle {
                            x: vtCore.x + vtCore.width
                            y: vtPrimaryTerminal2.y + vtPrimaryTerminal2.height/2 - 2
                            width: vtPrimaryTerminal2.x - (vtCore.x + vtCore.width)
                            height: 4 // Thicker line
                            color: primaryColor
                        }
                        
                        // Secondary terminals - repositioned for better visibility
                        Rectangle {
                            id: vtSecondaryTerminal1
                            x: vtCore.x - 40 // Moved further out
                            y: vtCore.y + vtCore.height * 0.8
                            width: 15 // Made larger
                            height: 15
                            radius: 3 // Rounded corners
                            color: secondaryColor
                        }
                        
                        Rectangle {
                            id: vtSecondaryTerminal2
                            x: vtCore.x + vtCore.width + 25 // Moved further out
                            y: vtCore.y + vtCore.height * 0.8
                            width: 15
                            height: 15
                            radius: 3
                            color: secondaryColor
                        }
                        
                        // Secondary terminal connections - thicker lines
                        Rectangle {
                            x: vtSecondaryTerminal1.x + vtSecondaryTerminal1.width
                            y: vtSecondaryTerminal1.y + vtSecondaryTerminal1.height/2 - 2
                            width: vtCore.x - (vtSecondaryTerminal1.x + vtSecondaryTerminal1.width)
                            height: 4 // Thicker line
                            color: secondaryColor
                        }
                        
                        Rectangle {
                            x: vtCore.x + vtCore.width
                            y: vtSecondaryTerminal2.y + vtSecondaryTerminal2.height/2 - 2
                            width: vtSecondaryTerminal2.x - (vtCore.x + vtCore.width)
                            height: 4 // Thicker line
                            color: secondaryColor
                        }
                        
                        // Terminal labels - changed to A/N and a/n
                        Text {
                            anchors.right: vtPrimaryTerminal1.left
                            anchors.rightMargin: 5
                            anchors.verticalCenter: vtPrimaryTerminal1.verticalCenter
                            text: "A"
                            color: textColor
                            font.pixelSize: 13 
                            font.bold: true
                        }
                        
                        Text {
                            anchors.left: vtPrimaryTerminal2.right
                            anchors.leftMargin: 5
                            anchors.verticalCenter: vtPrimaryTerminal2.verticalCenter
                            text: "N"
                            color: textColor
                            font.pixelSize: 13
                            font.bold: true
                        }
                        
                        Text {
                            anchors.right: vtSecondaryTerminal1.left
                            anchors.rightMargin: 5
                            anchors.verticalCenter: vtSecondaryTerminal1.verticalCenter
                            text: "a"
                            color: textColor
                            font.pixelSize: 13
                            font.bold: true
                        }
                        
                        Text {
                            anchors.left: vtSecondaryTerminal2.right
                            anchors.leftMargin: 5
                            anchors.verticalCenter: vtSecondaryTerminal2.verticalCenter
                            text: "n"
                            color: textColor
                            font.pixelSize: 13
                            font.bold: true
                        }
                        
                        // Primary voltage - larger and more prominent
                        Rectangle {
                            anchors.horizontalCenter: vtCore.horizontalCenter
                            anchors.bottom: vtCore.top
                            anchors.bottomMargin: 8
                            width: primaryVoltageText.width + 20
                            height: primaryVoltageText.height + 10
                            radius: 5
                            color: darkMode ? "#3a3a3a" : "#f0f0f0"
                            border.width: 1
                            border.color: primaryColor
                            
                            Text {
                                id: primaryVoltageText
                                anchors.centerIn: parent
                                text: primaryRating + "V"
                                color: textColor
                                font.pixelSize: 16 // Increased font size
                                font.bold: true
                            }
                        }
                        
                        // Secondary voltage - larger and more prominent
                        Rectangle {
                            anchors.horizontalCenter: vtCore.horizontalCenter
                            anchors.top: vtCore.bottom
                            anchors.topMargin: 8
                            width: secondaryVoltageText.width + 20
                            height: secondaryVoltageText.height + 10
                            radius: 5
                            color: darkMode ? "#3a3a3a" : "#f0f0f0"
                            border.width: 1
                            border.color: secondaryColor
                            
                            Text {
                                id: secondaryVoltageText
                                anchors.centerIn: parent
                                text: secondaryRating + "V"
                                color: textColor
                                font.pixelSize: 16 // Increased font size
                                font.bold: true
                            }
                        }
                        
                        // Add vertical line in the middle to show core division
                        Rectangle {
                            anchors.horizontalCenter: vtCore.horizontalCenter
                            anchors.top: vtCore.top
                            anchors.bottom: vtCore.bottom
                            width: 2
                            color: "#555555"
                        }
                        
                        // Add horizontal winding lines for better visualization
                        Item {
                            id: windingLines
                            anchors.fill: vtCore
                            
                            // Primary windings (coils)
                            Repeater {
                                model: 7
                                Rectangle {
                                    x: 2
                                    y: vtCore.y + vtCore.height * 0.05 + index * (primaryWinding.height - vtCore.height * 0.1) / 6
                                    width: vtCore.width - 4
                                    height: 2
                                    color: "#ffffff"
                                    opacity: 0.5
                                    visible: index > 0 && index < 6
                                }
                            }
                            
                            // Secondary windings (coils)
                            Repeater {
                                model: 7
                                Rectangle {
                                    x: 2
                                    y: vtCore.y + vtCore.height * 0.6 + index * (secondaryWinding.height - vtCore.height * 0.1) / 6
                                    width: vtCore.width - 4
                                    height: 2
                                    color: "#ffffff"
                                    opacity: 0.5
                                    visible: index > 0 && index < 6
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Generate an SVG path for the secondary winding spiral
    function generateSecondaryWindingSVG() {
        const centerX = width / 2;
        const centerY = height / 2;
        const radius = Math.min(width, height) * 0.25;
        
        let path = "";
        const turns = 8;  // Number of winding turns
        const angleStep = Math.PI * 2 / 30;  // Smaller steps for smoother curve
        const radiusStep = radius / (turns * 30);
        
        // Starting point
        let currentRadius = radius;
        let currentAngle = 0;
        
        // Move to starting point
        path += `M ${centerX + currentRadius} ${centerY}`;
        
        // Create spiral
        for (let i = 0; i < turns * 30; i++) {
            currentAngle += angleStep;
            currentRadius -= radiusStep;
            const x = centerX + currentRadius * Math.cos(currentAngle);
            const y = centerY + currentRadius * Math.sin(currentAngle);
            path += ` L ${x} ${y}`;
        }
        
        // Connect to terminal - updated connection point for moved terminals
        path += ` L ${terminal1.x + terminal1.width/2} ${terminal1.y + terminal1.height/2}`;
        path += ` M ${terminal2.x + terminal2.width/2} ${terminal2.y + terminal2.height/2}`;
        
        // Draw a second spiral in the opposite direction
        currentRadius = radius * 0.5;
        currentAngle = Math.PI;
        path += ` L ${centerX + currentRadius * Math.cos(currentAngle)} ${centerY + currentRadius * Math.sin(currentAngle)}`;
        
        for (let i = 0; i < turns * 15; i++) {
            currentAngle -= angleStep;
            currentRadius += radiusStep * 0.5;
            const x = centerX + currentRadius * Math.cos(currentAngle);
            const y = centerY + currentRadius * Math.sin(currentAngle);
            path += ` L ${x} ${y}`;
        }
        
        return path;
    }
}