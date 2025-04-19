import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Item {
    id: root
    
    // Single property for the Python calculator model
    property var calculator
    property bool darkMode: false
    
    // Colors adjusted for light/dark mode
    property color backgroundColor: darkMode ? "#2a2a2a" : "#f8f8f8"
    property color borderColor: darkMode ? "#555555" : "#333333"
    property color textColor: darkMode ? "#ffffff" : "#000000"
    property color cabinetColor: darkMode ? "#444444" : "#e0e0e0" 
    property color disconnectorColor: "#bf8f00"
    property color smallDisconnectorColor: "#bf6000"
    property color cableColor: "#444444"
    property color coverPlateColor: darkMode ? "#333333" : "#bbbbbb"
    property color mcbColor: "#555555"
    property color serviceDisconnectColor: "#bf6000"
    
    Canvas {
        id: canvas
        objectName: "diagramCanvas"
        anchors.fill: parent
        
        // Ensure highest quality rendering
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Cooperative
        
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            
            var width = canvas.width;
            var height = canvas.height;
            
            // Draw cabinet background
            ctx.fillStyle = cabinetColor;
            ctx.strokeStyle = borderColor;
            ctx.lineWidth = 2;
            
            // Main cabinet body
            ctx.fillRect(width * 0.15, height * 0.05, width * 0.7, height * 0.8);
            ctx.strokeRect(width * 0.15, height * 0.05, width * 0.7, height * 0.8);
            
            // Calculate positions for disconnectors
            var cabinetWidth = width * 0.8;
            var cabinetHeight = height * 0.8;
            var cabinetX = width * 0.1;
            var cabinetY = height * 0.1;

            // Calculate spacing for vertical disconnectors
            var disconnectorWidth = cabinetWidth * 0.15;
            var disconnectorHeight = cabinetHeight * 0.6;
            var disconnectorSpacing = cabinetWidth * 0.17;
            var disconnectorX = cabinetX + cabinetWidth * 0.2;
            var disconnectorY = cabinetY + cabinetHeight * 0.2;
            
            // Draw 3 distinct phase bus bars behind the disconnects
            var busbarWidth = cabinetWidth * 0.8;
            var singleBusbarHeight = disconnectorHeight * 0.08;
            var busbarGap = disconnectorHeight * 0.06;
            var busbarY = disconnectorY + disconnectorHeight * 0.3;
            
            // Colors for each phase - standard Red, White, Blue
            var phaseColors = ["#cc0000", "#f0f0f0", "#0066cc"];
            var phaseStrokes = ["#990000", "#c0c0c0", "#004c99"];
            var phaseNames = ["L1 (Red)", "L2 (White)", "L3 (Blue)"];
            
            // Draw the 3 separate bus bars
            for (var p = 0; p < 3; p++) {
                var currentBusbarY = busbarY + (singleBusbarHeight + busbarGap) * p;
                
                // Draw individual phase bus bar
                ctx.fillStyle = phaseColors[p];
                ctx.fillRect(cabinetX + cabinetWidth * 0.1, currentBusbarY, busbarWidth, singleBusbarHeight);
                ctx.strokeStyle = phaseStrokes[p];
                ctx.lineWidth = 1;
                ctx.strokeRect(cabinetX + cabinetWidth * 0.1, currentBusbarY, busbarWidth, singleBusbarHeight);
                
                // Add phase label - darker text for white phase to ensure visibility
                ctx.fillStyle = p === 1 ? "#333333" : "#ffffff";
                ctx.font = "bold 9px sans-serif";
                ctx.textAlign = "left";
                ctx.fillText(phaseNames[p], cabinetX + cabinetWidth * 0.12, currentBusbarY + singleBusbarHeight * 0.7);
            }
            
            // Get active ways from calculator or use default if calculator is null
            var activeWays = calculator ? calculator.activeWays : 4;
            
            // Draw all 4 positions - either active disconnectors, 160A disconnects, or cover plates
            for (var i = 0; i < 4; i++) {
                if (i < activeWays) {
                    // Get way type from calculator or use default
                    var wayType = calculator && calculator.wayTypes ? calculator.wayTypes[i] : 0;
                    
                    // Check the way type
                    if (wayType === 0) {
                        // Draw single 630A disconnector
                        ctx.fillStyle = disconnectorColor;
                        ctx.fillRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                        ctx.strokeRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                        
                        // Connection from all 3 bus bars to disconnector
                        for (var p2 = 0; p2 < 3; p2++) {
                            var currentBusbarY = busbarY + (singleBusbarHeight + busbarGap) * p2;
                            var connectionY = currentBusbarY + singleBusbarHeight/2;
                            
                            ctx.strokeStyle = phaseColors[p2];
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.moveTo(disconnectorX, connectionY);
                            ctx.lineTo(disconnectorX - width * 0.02, connectionY);
                            ctx.stroke();
                        }
                        
                        // Disconnector text (rotated vertical)
                        ctx.save();
                        ctx.translate(disconnectorX + disconnectorWidth * 0.5, disconnectorY + disconnectorHeight * 0.5);
                        ctx.rotate(-Math.PI/2);
                        ctx.fillStyle = textColor;
                        ctx.font = "bold 14px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("630A Fuse Disconnect", 0, 0);
                        ctx.restore();
                        
                        // Cable out to bottom
                        ctx.strokeStyle = cableColor;
                        ctx.lineWidth = 3;
                        ctx.beginPath();
                        ctx.moveTo(disconnectorX + disconnectorWidth * 0.5, disconnectorY + disconnectorHeight);
                        ctx.lineTo(disconnectorX + disconnectorWidth * 0.5, cabinetY + cabinetHeight);
                        ctx.stroke();
                        
                        // Get cable size and conductor type from calculator or use default
                        var cableSize = calculator && calculator.cableSizes ? calculator.cableSizes[i] : "300mm²";
                        var conductorType = calculator && calculator.conductorTypes ? calculator.conductorTypes[i] : "Al";
                        
                        // Cable size text
                        ctx.fillStyle = textColor;
                        ctx.font = "12px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText(cableSize + " " + conductorType, 
                                   disconnectorX + disconnectorWidth * 0.5, 
                                   cabinetY + cabinetHeight + height * 0.03);
                    } else if (wayType === 1) {
                        // Draw two 160A disconnects side by side but vertically oriented
                        ctx.fillStyle = cabinetColor;
                        ctx.fillRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                        ctx.strokeRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                        
                        // Connection from all 3 bus bars to disconnect frame
                        for (var p3 = 0; p3 < 3; p3++) {
                            var currentBusbarY = busbarY + (singleBusbarHeight + busbarGap) * p3;
                            var connectionY = currentBusbarY + singleBusbarHeight/2;
                            
                            ctx.strokeStyle = phaseColors[p3];
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.moveTo(disconnectorX, connectionY);
                            ctx.lineTo(disconnectorX - width * 0.02, connectionY);
                            ctx.stroke();
                        }
                        
                        // Draw title for the way
                        ctx.fillStyle = textColor;
                        ctx.font = "9px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("Service Way " + (i+1), 
                                   disconnectorX + disconnectorWidth * 0.5, 
                                   disconnectorY - 5);
                        
                        // Calculate dimensions for the two vertical disconnects
                        var smallDisconnectorWidth = disconnectorWidth * 0.4;
                        var smallDisconnectorHeight = disconnectorHeight * 0.8;
                        var smallDisconnectorSpacing = disconnectorWidth * 0.2;
                        var smallDisconnectorX1 = disconnectorX + smallDisconnectorSpacing * 0.5;
                        var smallDisconnectorX2 = disconnectorX + disconnectorWidth - smallDisconnectorWidth - smallDisconnectorSpacing * 0.5;
                        var smallDisconnectorY = disconnectorY + (disconnectorHeight - smallDisconnectorHeight) * 0.5;
                        
                        // Get number of connections from calculator or use default
                        var connectionCount = calculator && calculator.connectionCounts ? calculator.connectionCounts[i] : 2;
                        
                        // Get number of connections to display (max 3 per 160A disconnect, so max 6 total)
                        var numConnections = Math.min(connectionCount, 6);
                        var connectionsPerDisconnect, secondDisconnectConnections;
                        
                        // Fill up left side first (up to 3), then right side
                        if (numConnections <= 3) {
                            connectionsPerDisconnect = numConnections;
                            secondDisconnectConnections = 0;
                        } else {
                            connectionsPerDisconnect = 3;
                            secondDisconnectConnections = numConnections - 3;
                        }
                        
                        // Draw first 160A disconnect only if it has connections
                        if (connectionsPerDisconnect > 0) {
                            // Draw first 160A disconnect (vertical)
                            ctx.fillStyle = smallDisconnectorColor;
                            ctx.fillRect(smallDisconnectorX1, smallDisconnectorY, 
                                        smallDisconnectorWidth, smallDisconnectorHeight);
                            ctx.strokeRect(smallDisconnectorX1, smallDisconnectorY, 
                                         smallDisconnectorWidth, smallDisconnectorHeight);
                            
                            // Disconnect texts (rotated vertical)
                            ctx.save();
                            ctx.translate(smallDisconnectorX1 + smallDisconnectorWidth * 0.5, smallDisconnectorY + smallDisconnectorHeight * 0.5);
                            ctx.rotate(-Math.PI/2);
                            ctx.fillStyle = textColor;
                            ctx.font = "bold 10px sans-serif";
                            ctx.textAlign = "center";
                            ctx.fillText("63A Fuse", 0, 0);
                            ctx.restore();
                            
                            // Get service cable size and conductor type from calculator or use default
                            var serviceCableSize = calculator && calculator.serviceCableSizes ? calculator.serviceCableSizes[i] : "35mm²";
                            var serviceConductorType = calculator && calculator.serviceConductorTypes ? calculator.serviceConductorTypes[i] : "Al";
                            
                            // Draw connection cables based on number required
                            for (var c1 = 0; c1 < connectionsPerDisconnect; c1++) {
                                // Calculate position with even spacing
                                var cableX = smallDisconnectorX1 + smallDisconnectorWidth * (c1 + 1) / (connectionsPerDisconnect + 1);
                                
                                // Cable out to bottom
                                ctx.strokeStyle = cableColor;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(cableX, smallDisconnectorY + smallDisconnectorHeight);
                                ctx.lineTo(cableX, cabinetY + cabinetHeight);
                                ctx.stroke();
                                
                                // Cable size text
                                if (c1 === 0) { // Only show text for the first cable to avoid clutter
                                    ctx.fillStyle = textColor;
                                    ctx.font = "10px sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.fillText(serviceCableSize + " " + serviceConductorType, 
                                            smallDisconnectorX1 + smallDisconnectorWidth * 0.5, 
                                            cabinetY + cabinetHeight + height * 0.03);
                                }
                            }
                        }
                        
                        // Draw second 160A disconnect only if it has connections
                        if (secondDisconnectConnections > 0) {
                            // Draw second 160A disconnect (vertical)
                            ctx.fillStyle = smallDisconnectorColor;
                            ctx.fillRect(smallDisconnectorX2, smallDisconnectorY, 
                                        smallDisconnectorWidth, smallDisconnectorHeight);
                            ctx.strokeRect(smallDisconnectorX2, smallDisconnectorY, 
                                         smallDisconnectorWidth, smallDisconnectorHeight);
                            
                            // Disconnect texts (rotated vertical)
                            ctx.save();
                            ctx.translate(smallDisconnectorX2 + smallDisconnectorWidth * 0.5, smallDisconnectorY + smallDisconnectorHeight * 0.5);
                            ctx.rotate(-Math.PI/2);
                            ctx.fillStyle = textColor;
                            ctx.font = "bold 10px sans-serif";
                            ctx.textAlign = "center";
                            ctx.fillText("63A Fuse", 0, 0);
                            ctx.restore();
                            
                            // Get service cable size and conductor type from calculator or use default
                            var serviceCableSize = calculator && calculator.serviceCableSizes ? calculator.serviceCableSizes[i] : "35mm²";
                            var serviceConductorType = calculator && calculator.serviceConductorTypes ? calculator.serviceConductorTypes[i] : "Al";
                            
                            // Draw connection cables based on number required
                            for (var c2 = 0; c2 < secondDisconnectConnections; c2++) {
                                // Calculate position with even spacing
                                var cableX2 = smallDisconnectorX2 + smallDisconnectorWidth * (c2 + 1) / (secondDisconnectConnections + 1);
                                
                                // Cable out to bottom
                                ctx.strokeStyle = cableColor;
                                ctx.lineWidth = 2;
                                ctx.beginPath();
                                ctx.moveTo(cableX2, smallDisconnectorY + smallDisconnectorHeight);
                                ctx.lineTo(cableX2, cabinetY + cabinetHeight);
                                ctx.stroke();
                                
                                // Cable size text
                                if (c2 === 0) { // Only show text for the first cable to avoid clutter
                                    ctx.fillStyle = textColor;
                                    ctx.font = "10px sans-serif";
                                    ctx.textAlign = "center";
                                    ctx.fillText(serviceCableSize + " " + serviceConductorType, 
                                            smallDisconnectorX2 + smallDisconnectorWidth * 0.5, 
                                            cabinetY + cabinetHeight + height * 0.03);
                                }
                            }
                        }
                        
                    } else if (wayType === 2) {
                        // Draw 1x160A disconnect with cover
                        ctx.fillStyle = cabinetColor;
                        ctx.fillRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                        ctx.strokeRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                        
                        // Connection from all 3 bus bars to disconnect frame
                        for (var p4 = 0; p4 < 3; p4++) {
                            var currentBusbarY = busbarY + (singleBusbarHeight + busbarGap) * p4;
                            var connectionY = currentBusbarY + singleBusbarHeight/2;
                            
                            ctx.strokeStyle = phaseColors[p4];
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.moveTo(disconnectorX, connectionY);
                            ctx.lineTo(disconnectorX - width * 0.02, connectionY);
                            ctx.stroke();
                        }
                        
                        // Draw title for the way
                        ctx.fillStyle = textColor;
                        ctx.font = "9px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("Service Way " + (i+1), 
                                   disconnectorX + disconnectorWidth * 0.5, 
                                   disconnectorY - 5);
                        
                        // Calculate dimensions for the vertical disconnect and cover
                        var smallDisconnectorWidth = disconnectorWidth * 0.4;
                        var smallDisconnectorHeight = disconnectorHeight * 0.8;
                        var smallDisconnectorSpacing = disconnectorWidth * 0.2;
                        var smallDisconnectorX = disconnectorX + smallDisconnectorSpacing * 0.5;
                        var coverX = disconnectorX + disconnectorWidth - smallDisconnectorWidth - smallDisconnectorSpacing * 0.5;
                        var smallDisconnectorY = disconnectorY + (disconnectorHeight - smallDisconnectorHeight) * 0.5;
                        
                        // Get number of connections from calculator or use default
                        var singleConnectionCount = calculator && calculator.connectionCounts ? calculator.connectionCounts[i] : 2;
                        
                        // Get number of connections to display (max 3)
                        var singleNumConnections = Math.min(singleConnectionCount, 3);
                        
                        // Draw 160A disconnect (vertical)
                        ctx.fillStyle = smallDisconnectorColor;
                        ctx.fillRect(smallDisconnectorX, smallDisconnectorY, 
                                    smallDisconnectorWidth, smallDisconnectorHeight);
                        ctx.strokeRect(smallDisconnectorX, smallDisconnectorY, 
                                     smallDisconnectorWidth, smallDisconnectorHeight);
                        
                        // Draw cover plate on the right side
                        ctx.fillStyle = coverPlateColor;
                        ctx.fillRect(coverX, smallDisconnectorY, 
                                    smallDisconnectorWidth, smallDisconnectorHeight);
                        ctx.strokeStyle = borderColor;
                        ctx.lineWidth = 2;
                        ctx.strokeRect(coverX, smallDisconnectorY, 
                                     smallDisconnectorWidth, smallDisconnectorHeight);
                                     
                        // Add cover plate screws
                        var screwRadius = Math.min(width, height) * 0.005;
                        var screwMargin = Math.min(width, height) * 0.015;
                        ctx.fillStyle = darkMode ? "#555555" : "#666666";
                        
                        // Top-left screw
                        ctx.beginPath();
                        ctx.arc(coverX + screwMargin, smallDisconnectorY + screwMargin, screwRadius, 0, Math.PI * 2);
                        ctx.fill();
                        
                        // Top-right screw
                        ctx.beginPath();
                        ctx.arc(coverX + smallDisconnectorWidth - screwMargin, smallDisconnectorY + screwMargin, screwRadius, 0, Math.PI * 2);
                        ctx.fill();
                        
                        // Bottom-left screw
                        ctx.beginPath();
                        ctx.arc(coverX + screwMargin, smallDisconnectorY + smallDisconnectorHeight - screwMargin, screwRadius, 0, Math.PI * 2);
                        ctx.fill();
                        
                        // Bottom-right screw
                        ctx.beginPath();
                        ctx.arc(coverX + smallDisconnectorWidth - screwMargin, smallDisconnectorY + smallDisconnectorHeight - screwMargin, screwRadius, 0, Math.PI * 2);
                        ctx.fill();
                        
                        // Add "Cover" text on plate
                        ctx.save();
                        ctx.translate(coverX + smallDisconnectorWidth * 0.5, smallDisconnectorY + smallDisconnectorHeight * 0.5);
                        ctx.rotate(-Math.PI/2);
                        ctx.fillStyle = textColor;
                        ctx.font = "10px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("Cover", 0, 0);
                        ctx.restore();
                        
                        // Disconnect text (rotated vertical)
                        ctx.save();
                        ctx.translate(smallDisconnectorX + smallDisconnectorWidth * 0.5, smallDisconnectorY + smallDisconnectorHeight * 0.5);
                        ctx.rotate(-Math.PI/2);
                        ctx.fillStyle = textColor;
                        ctx.font = "bold 10px sans-serif";
                        ctx.textAlign = "center";
                        ctx.fillText("63A Fuse", 0, 0);
                        ctx.restore();
                        
                        // Get service cable size and conductor type from calculator or use default
                        var serviceCableSize = calculator && calculator.serviceCableSizes ? calculator.serviceCableSizes[i] : "35mm²";
                        var serviceConductorType = calculator && calculator.serviceConductorTypes ? calculator.serviceConductorTypes[i] : "Al";
                        
                        // Draw connection cables based on number required
                        for (var c3 = 0; c3 < singleNumConnections; c3++) {
                            // Calculate position with even spacing
                            var cableX3 = smallDisconnectorX + smallDisconnectorWidth * (c3 + 1) / (singleNumConnections + 1);
                            
                            // Cable out to bottom
                            ctx.strokeStyle = cableColor;
                            ctx.lineWidth = 2;
                            ctx.beginPath();
                            ctx.moveTo(cableX3, smallDisconnectorY + smallDisconnectorHeight);
                            ctx.lineTo(cableX3, cabinetY + cabinetHeight);
                            ctx.stroke();
                            
                            // Cable size text
                            if (c3 === 0) { // Only show text for the first cable to avoid clutter
                                ctx.fillStyle = textColor;
                                ctx.font = "10px sans-serif";
                                ctx.textAlign = "center";
                                ctx.fillText(serviceCableSize + " " + serviceConductorType, 
                                        smallDisconnectorX + smallDisconnectorWidth * 0.5, 
                                        cabinetY + cabinetHeight + height * 0.03);
                            }
                        }
                    }
                } else {
                    // Draw cover plate for unused position
                    ctx.fillStyle = coverPlateColor;
                    ctx.fillRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                    ctx.strokeStyle = borderColor;
                    ctx.lineWidth = 2;
                    ctx.strokeRect(disconnectorX, disconnectorY, disconnectorWidth, disconnectorHeight);
                    
                    // Add cover plate screws
                    var screwRadius = Math.min(width, height) * 0.005;
                    var screwMargin = Math.min(width, height) * 0.015;
                    
                    // Top-left screw
                    ctx.fillStyle = darkMode ? "#555555" : "#666666";
                    ctx.beginPath();
                    ctx.arc(disconnectorX + screwMargin, disconnectorY + screwMargin, screwRadius, 0, Math.PI * 2);
                    ctx.fill();
                    
                    // Top-right screw
                    ctx.beginPath();
                    ctx.arc(disconnectorX + disconnectorWidth - screwMargin, disconnectorY + screwMargin, screwRadius, 0, Math.PI * 2);
                    ctx.fill();
                    
                    // Bottom-left screw
                    ctx.beginPath();
                    ctx.arc(disconnectorX + screwMargin, disconnectorY + disconnectorHeight - screwMargin, screwRadius, 0, Math.PI * 2);
                    ctx.fill();
                    
                    // Bottom-right screw
                    ctx.beginPath();
                    ctx.arc(disconnectorX + disconnectorWidth - screwMargin, disconnectorY + disconnectorHeight - screwMargin, screwRadius, 0, Math.PI * 2);
                    ctx.fill();
                    
                    // Add "Cover Plate" text
                    ctx.save();
                    ctx.translate(disconnectorX + disconnectorWidth * 0.5, disconnectorY + disconnectorHeight * 0.5);
                    ctx.rotate(-Math.PI/2);
                    ctx.fillStyle = textColor;
                    ctx.font = "10px sans-serif";
                    ctx.textAlign = "center";
                    ctx.fillText("Cover Plate", 0, 0);
                    ctx.restore();
                }
                
                // Move to next position
                disconnectorX += disconnectorSpacing;
            }
            
            // Draw streetlighting distribution panel if enabled
            if (calculator.showStreetlightingPanel) {
                // Small distribution board on left side
                var panelWidth = cabinetWidth * 0.15;
                var panelHeight = cabinetHeight * 0.25;
                var panelX = cabinetX - panelWidth * 0.6;
                var panelY = cabinetY + cabinetHeight * 0.4;
                
                // Draw the panel box
                ctx.fillStyle = cabinetColor;
                ctx.strokeStyle = borderColor;
                ctx.lineWidth = 2;
                ctx.fillRect(panelX, panelY, panelWidth, panelHeight);
                ctx.strokeRect(panelX, panelY, panelWidth, panelHeight);
                
                // Draw panel title
                ctx.fillStyle = textColor;
                ctx.font = "9px sans-serif";
                ctx.textAlign = "center";
                ctx.fillText("Streetlighting", panelX + panelWidth/2, panelY - 5);
                
                // Draw MCBs
                var mcbWidth = panelWidth * 0.6;
                var mcbHeight = panelHeight * 0.25;
                var mcbSpacing = panelHeight * 0.15;
                var mcbX = panelX + (panelWidth - mcbWidth) / 2;
                var mcbY = panelY + panelHeight * 0.2;
                
                // Draw 2 MCBs
                for (var j = 0; j < 2; j++) {
                    // MCB box
                    ctx.fillStyle = mcbColor;
                    ctx.fillRect(mcbX, mcbY, mcbWidth, mcbHeight);
                    ctx.strokeRect(mcbX, mcbY, mcbWidth, mcbHeight);
                    
                    // MCB text
                    ctx.fillStyle = "#ffffff";
                    ctx.font = "8px sans-serif";
                    ctx.textAlign = "center";
                    ctx.fillText("16A MCB", mcbX + mcbWidth/2, mcbY + mcbHeight/2 + 3);
                    
                    // Cable out to left
                    ctx.strokeStyle = cableColor;
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(panelX, mcbY + mcbHeight/2);
                    ctx.lineTo(panelX - width * 0.05, mcbY + mcbHeight/2);
                    ctx.stroke();
                    
                    // Draw "SL" text for streetlight
                    ctx.fillStyle = textColor;
                    ctx.font = "8px sans-serif";
                    ctx.textAlign = "left";
                    ctx.fillText("SL " + (j+1), panelX - width * 0.07, mcbY + mcbHeight/2 + 3);
                    
                    // Connection to main cabinet
                    ctx.strokeStyle = "#cc0000";
                    ctx.lineWidth = 3;
                    ctx.beginPath();
                    ctx.moveTo(panelX + panelWidth, mcbY + mcbHeight/2);
                    ctx.lineTo(cabinetX, mcbY + mcbHeight/2);
                    ctx.stroke();
                    
                    // Move to next MCB position
                    mcbY += mcbHeight + mcbSpacing;
                }
            }
            
            // Draw local service disconnects if enabled
            if (calculator.showServicePanel) {
                // Service panel on right side
                
                var servicePanelWidth = cabinetWidth * 0.15;
                var servicePanelHeight = cabinetHeight * 0.4;
                var servicePanelX = cabinetX + cabinetWidth - servicePanelWidth * 0.4;
                var servicePanelY = cabinetY + cabinetHeight * 0.3;
                
                // Draw the panel box
                ctx.fillStyle = cabinetColor;
                ctx.strokeStyle = borderColor;
                ctx.lineWidth = 2;
                ctx.fillRect(servicePanelX, servicePanelY, servicePanelWidth, servicePanelHeight);
                ctx.strokeRect(servicePanelX, servicePanelY, servicePanelWidth, servicePanelHeight);
                
                // Draw panel title
                ctx.fillStyle = textColor;
                ctx.font = "9px sans-serif";
                ctx.textAlign = "center";
                ctx.fillText("Local Services", servicePanelX + servicePanelWidth/2, servicePanelY - 5);
                
                // Draw Fuse Disconnects
                var fuseWidth = servicePanelWidth * 0.7;
                var fuseHeight = servicePanelHeight * 0.2;
                var fuseSpacing = servicePanelHeight * 0.1;
                var fuseX = servicePanelX + (servicePanelWidth - fuseWidth) / 2;
                var fuseY = servicePanelY + servicePanelHeight * 0.1;
                
                // Draw 3 local service disconnects
                for (var k = 0; k < 3; k++) {
                    // Fuse disconnect box
                    ctx.fillStyle = serviceDisconnectColor;
                    ctx.fillRect(fuseX, fuseY, fuseWidth, fuseHeight);
                    ctx.strokeRect(fuseX, fuseY, fuseWidth, fuseHeight);
                    
                    // Disconnect text with fuse rating
                    ctx.fillStyle = "#ffffff";
                    ctx.font = "8px sans-serif";
                    ctx.textAlign = "center";
                    var fuseRating = "63A";
                    ctx.fillText(fuseRating + " Fuse", fuseX + fuseWidth/2, fuseY + fuseHeight/2 + 3);
                    
                    // Cable out to right
                    ctx.strokeStyle = cableColor;
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(servicePanelX + servicePanelWidth, fuseY + fuseHeight/2);
                    ctx.lineTo(servicePanelX + servicePanelWidth + width * 0.05, fuseY + fuseHeight/2);
                    ctx.stroke();
                    
                    // Draw "S" text for service
                    ctx.fillStyle = textColor;
                    ctx.font = "8px sans-serif";
                    ctx.textAlign = "left";
                    ctx.fillText("Service " + (k+1), servicePanelX + servicePanelWidth + width * 0.06, fuseY + fuseHeight/2 + 3);
                    
                    // Connection to main cabinet
                    ctx.strokeStyle = "#cc0000";
                    ctx.lineWidth = 3;
                    ctx.beginPath();
                    ctx.moveTo(servicePanelX, fuseY + fuseHeight/2);
                    ctx.lineTo(cabinetX + cabinetWidth, fuseY + fuseHeight/2);
                    ctx.stroke();
                    
                    // Draw 3-phase symbol
                    ctx.fillStyle = "#aaaaaa";
                    ctx.beginPath();
                    ctx.arc(servicePanelX + servicePanelWidth + width * 0.04, fuseY + fuseHeight/2, width * 0.01, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.stroke();
                    
                    ctx.fillStyle = textColor;
                    ctx.font = "7px sans-serif";
                    ctx.textAlign = "center";
                    ctx.fillText("3Φ", servicePanelX + servicePanelWidth + width * 0.04, fuseY + fuseHeight/2 + 3);
                    
                    // Move to next fuse position
                    fuseY += fuseHeight + fuseSpacing;
                }
            }
        }
    }
    
    // Update function to capture a diagram optimized for PDF inclusion
    function captureImage() {
        // First ensure we have the latest panel visibility
        canvas.requestPaint()
        
        // Determine optimal scale factor based on canvas size
        let scaleFactor
        if (canvas.width > 800 || canvas.height > 800) {
            scaleFactor = 1.5  // For very large canvases
        } else if (canvas.width > 500 || canvas.height > 500) {
            scaleFactor = 1.75  // For medium canvases
        } else {
            scaleFactor = 2.0  // For small canvases
        }

        // Save the high-res image data
        let imageData = canvas.toDataURL("image/png")
        
        // Force a repaint to restore the canvas
        canvas.requestPaint()
        
        return imageData
    }
    
    // Update function to force a canvas repaint
    function forceRefresh() {
        canvas.requestPaint()
    }
    
    // Force update panel visibility and repaint
    function updatePanelVisibility() {
        canvas.requestPaint()
    }
}
