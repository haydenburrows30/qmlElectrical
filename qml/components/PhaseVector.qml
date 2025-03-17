import QtQuick

Canvas {
    id: phaseCanvas
    
    // Properties to control appearance and behavior
    property bool darkMode: false
    property real frequency: 50.0
    property real resistance: 10.0
    property real inductance: 0.1
    property real capacitance: 0.0001013
    property int circuitType: 0  // 0 for series, 1 for parallel
    
    property color bgColor: darkMode ? "#2a2a2a" : "#f0f0f0"
    property color axisColor: darkMode ? "#CCCCCC" : "#404040"
    property color gridColor: darkMode ? "#555555" : "#DDDDDD"
    property color vectorVColor: "#D04030"  // Voltage vector
    property color vectorIColor: "#3070B0"  // Current vector
    property color vectorRColor: "#505050"  // Resistive component
    property color vectorLColor: "#3070B0"  // Inductive component
    property color vectorCColor: "#D04030"  // Capacitive component
    property color textColor: darkMode ? "#FFFFFF" : "#000000"
    
    property real phase: 0.0
    property bool showComponents: true
    property bool isAnimating: false
    
    // Timeline for animation
    property real timeScale: 1.0  // Animation speed multiplier
    
    // Request repaint when properties change
    onCircuitTypeChanged: requestPaint()
    onDarkModeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onResistanceChanged: requestPaint()
    onInductanceChanged: requestPaint()
    onCapacitanceChanged: requestPaint()
    onFrequencyChanged: requestPaint()
    onShowComponentsChanged: requestPaint()
    
    // Timer for animation
    Timer {
        id: animationTimer
        interval: 16 // ~60 fps
        running: isAnimating
        repeat: true
        onTriggered: {
            phase = (phase + 0.04 * timeScale) % (2 * Math.PI)
            phaseCanvas.requestPaint()
        }
    }
    
    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        
        // Fill background
        ctx.fillStyle = bgColor
        ctx.fillRect(0, 0, width, height)
        
        // Calculate center point
        var centerX = width / 2
        var centerY = height / 2
        var radius = Math.min(centerX, centerY) * 0.8
        
        // Draw grid
        drawGrid(ctx, centerX, centerY, radius)
        
        // Draw axes
        drawAxes(ctx, centerX, centerY, radius)
        
        // Calculate component values
        var omega = 2 * Math.PI * frequency
        
        // Reactances
        var xl = omega * inductance
        var xc = 1 / (omega * capacitance)
        
        // Different behaviors for series vs parallel
        if (circuitType === 0) {  // Series
            // Calculate impedance components
            var r = resistance
            var x = xl - xc  // Net reactance
            
            // Impedance magnitude
            var z = Math.sqrt(r*r + x*x)
            
            // Phase angle
            var phi = Math.atan2(x, r)
            
            drawSeriesPhasors(ctx, centerX, centerY, radius, r, xl, xc, phi)
        } else {  // Parallel
            // Calculate admittance components
            var g = 1 / resistance  // Conductance
            var bl = 1 / xl         // Inductive susceptance
            var bc = 1 / xc         // Capacitive susceptance
            var b = bc - bl         // Net susceptance
            
            // Admittance magnitude
            var y = Math.sqrt(g*g + b*b)
            
            // Phase angle
            var phi = Math.atan2(-b, g)
            
            drawParallelPhasors(ctx, centerX, centerY, radius, g, bl, bc, phi)
        }
        
        // Draw title
        drawTitle(ctx)
    }
    
    function drawGrid(ctx, centerX, centerY, radius) {
        ctx.strokeStyle = gridColor
        ctx.lineWidth = 1
        
        // Draw concentric circles
        for (var r = radius / 4; r <= radius; r += radius / 4) {
            ctx.beginPath()
            ctx.arc(centerX, centerY, r, 0, 2 * Math.PI)
            ctx.stroke()
        }
        
        // Draw radial lines
        for (var angle = 0; angle < 360; angle += 30) {
            var radian = angle * Math.PI / 180
            ctx.beginPath()
            ctx.moveTo(centerX, centerY)
            ctx.lineTo(
                centerX + radius * Math.cos(radian),
                centerY + radius * Math.sin(radian)
            )
            ctx.stroke()
        }
    }
    
    function drawAxes(ctx, centerX, centerY, radius) {
        ctx.strokeStyle = axisColor
        ctx.lineWidth = 2
        
        // X-axis (Real)
        ctx.beginPath()
        ctx.moveTo(centerX - radius, centerY)
        ctx.lineTo(centerX + radius, centerY)
        ctx.stroke()
        
        // Y-axis (Imaginary)
        ctx.beginPath()
        ctx.moveTo(centerX, centerY - radius)
        ctx.lineTo(centerX, centerY + radius)
        ctx.stroke()
        
        // Labels
        ctx.fillStyle = textColor
        ctx.font = "14px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "middle"
        
        ctx.fillText("Real", centerX + radius * 0.9, centerY + 20)
        ctx.fillText("Imaginary", centerX - 20, centerY - radius * 0.9)
        
        // Origin
        ctx.beginPath()
        ctx.arc(centerX, centerY, 3, 0, 2 * Math.PI)
        ctx.fill()
    }
    
    function drawSeriesPhasors(ctx, centerX, centerY, radius, r, xl, xc, phi) {
        // Calculate component lengths proportional to their values
        // Normalize to fit within the view
        var maxComponent = Math.max(r, xl, xc, Math.abs(xl-xc))
        var scale = radius * 0.8 / maxComponent
        
        // Resistive component always along real axis
        var rLength = r * scale
        var xlLength = xl * scale
        var xcLength = xc * scale
        var xLength = Math.abs(xl - xc) * scale
        
        // Total voltage vector (magnitude is fixed and serves as reference)
        var vMag = radius * 0.8
        
        // Rotating phase for animation
        var rotatedPhase = phase
        
        // Calculate endpoint coordinates
        var vEndX = centerX + vMag * Math.cos(rotatedPhase)
        var vEndY = centerY + vMag * Math.sin(rotatedPhase)
        
        // Current vector with phase shift phi
        var iMag = vMag * 0.8  // Slightly smaller for visual clarity
        var iEndX = centerX + iMag * Math.cos(rotatedPhase - phi)
        var iEndY = centerY + iMag * Math.sin(rotatedPhase - phi)
        
        // Draw component vectors if enabled
        if (showComponents) {
            // Draw resistive voltage component
            ctx.beginPath()
            ctx.strokeStyle = vectorRColor
            ctx.lineWidth = 2
            var vrEndX = centerX + rLength * Math.cos(rotatedPhase)
            var vrEndY = centerY + rLength * Math.sin(rotatedPhase)
            ctx.moveTo(centerX, centerY)
            ctx.lineTo(vrEndX, vrEndY)
            ctx.stroke()
            
            if (xl > xc) {
                // Net reactance is inductive
                ctx.beginPath()
                ctx.strokeStyle = vectorLColor
                ctx.lineWidth = 2
                var vxEndX = centerX + xLength * Math.cos(rotatedPhase + Math.PI/2)
                var vxEndY = centerY + xLength * Math.sin(rotatedPhase + Math.PI/2)
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(vxEndX, vxEndY)
                ctx.stroke()
                
                // Label
                ctx.fillStyle = vectorLColor
                ctx.font = "12px sans-serif"
                ctx.textAlign = "center"
                ctx.fillText("VL-VC", vxEndX + 10, vxEndY)
            } else if (xc > xl) {
                // Net reactance is capacitive
                ctx.beginPath()
                ctx.strokeStyle = vectorCColor
                ctx.lineWidth = 2
                var vxEndX = centerX + xLength * Math.cos(rotatedPhase - Math.PI/2)
                var vxEndY = centerY + xLength * Math.sin(rotatedPhase - Math.PI/2)
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(vxEndX, vxEndY)
                ctx.stroke()
                
                // Label
                ctx.fillStyle = vectorCColor
                ctx.font = "12px sans-serif"
                ctx.textAlign = "center"
                ctx.fillText("VC-VL", vxEndX - 10, vxEndY)
            }
            
            // Labels
            ctx.fillStyle = vectorRColor
            ctx.font = "12px sans-serif"
            ctx.textAlign = "center"
            ctx.fillText("VR", vrEndX + 10, vrEndY + 10)
        }
        
        // Draw voltage vector (reference)
        ctx.beginPath()
        ctx.strokeStyle = vectorVColor
        ctx.lineWidth = 3
        ctx.moveTo(centerX, centerY)
        ctx.lineTo(vEndX, vEndY)
        ctx.stroke()
        
        // Draw arrowhead for voltage
        drawArrowhead(ctx, vEndX, vEndY, rotatedPhase, 10, vectorVColor)
        
        // Draw current vector
        ctx.beginPath()
        ctx.strokeStyle = vectorIColor
        ctx.lineWidth = 3
        ctx.moveTo(centerX, centerY)
        ctx.lineTo(iEndX, iEndY)
        ctx.stroke()
        
        // Draw arrowhead for current
        drawArrowhead(ctx, iEndX, iEndY, rotatedPhase - phi, 10, vectorIColor)
        
        // Labels for main vectors
        ctx.font = "14px sans-serif"
        ctx.textAlign = "center"
        
        ctx.fillStyle = vectorVColor
        ctx.fillText("V", vEndX + 15 * Math.cos(rotatedPhase), vEndY + 15 * Math.sin(rotatedPhase))
        
        ctx.fillStyle = vectorIColor
        ctx.fillText("I", iEndX + 15 * Math.cos(rotatedPhase - phi), iEndY + 15 * Math.sin(rotatedPhase - phi))
        
        // Draw phase angle arc
        if (phi !== 0) {
            var arcRadius = radius * 0.2
            ctx.beginPath()
            ctx.strokeStyle = darkMode ? "#AAAAAA" : "#666666"
            ctx.lineWidth = 1
            
            // Draw arc from voltage to current
            var startAngle = rotatedPhase
            var endAngle = rotatedPhase - phi
            
            if (phi > 0) {
                ctx.arc(centerX, centerY, arcRadius, startAngle, endAngle, true)
            } else {
                ctx.arc(centerX, centerY, arcRadius, startAngle, endAngle, false)
            }
            ctx.stroke()
            
            // Label the angle
            var midAngle = (startAngle + endAngle) / 2
            var phiDeg = Math.abs(Math.round(phi * 180 / Math.PI))
            
            ctx.fillStyle = darkMode ? "#FFFFFF" : "#333333"
            ctx.font = "12px sans-serif"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            
            var textX = centerX + arcRadius * 0.7 * Math.cos(midAngle)
            var textY = centerY + arcRadius * 0.7 * Math.sin(midAngle)
            ctx.fillText(phiDeg + "°", textX, textY)
        }
    }
    
    function drawParallelPhasors(ctx, centerX, centerY, radius, g, bl, bc, phi) {
        // Calculate component lengths
        var maxComponent = Math.max(g, bl, bc, Math.abs(bl-bc))
        var scale = radius * 0.8 / maxComponent
        
        // Component lengths
        var gLength = g * scale
        var blLength = bl * scale
        var bcLength = bc * scale
        var bLength = Math.abs(bc - bl) * scale
        
        // Current vector (reference)
        var iMag = radius * 0.8
        var rotatedPhase = phase
        
        var iEndX = centerX + iMag * Math.cos(rotatedPhase)
        var iEndY = centerY + iMag * Math.sin(rotatedPhase)
        
        // Voltage vector with phase shift phi
        var vMag = iMag * 0.8
        var vEndX = centerX + vMag * Math.cos(rotatedPhase + phi)
        var vEndY = centerY + vMag * Math.sin(rotatedPhase + phi)
        
        // Draw component currents if enabled
        if (showComponents) {
            // Resistive component
            ctx.beginPath()
            ctx.strokeStyle = vectorRColor
            ctx.lineWidth = 2
            var irEndX = centerX + gLength * Math.cos(rotatedPhase)
            var irEndY = centerY + gLength * Math.sin(rotatedPhase)
            ctx.moveTo(centerX, centerY)
            ctx.lineTo(irEndX, irEndY)
            ctx.stroke()
            ctx.fillStyle = vectorRColor
            ctx.fillText("IR", irEndX + 10, irEndY + 10)
            
            // Reactive components
            if (bc > bl) {
                // Net susceptance is capacitive
                ctx.beginPath()
                ctx.strokeStyle = vectorCColor
                ctx.lineWidth = 2
                var ibEndX = centerX + bLength * Math.cos(rotatedPhase + Math.PI/2)
                var ibEndY = centerY + bLength * Math.sin(rotatedPhase + Math.PI/2)
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(ibEndX, ibEndY)
                ctx.stroke()
                ctx.fillStyle = vectorCColor
                ctx.fillText("IC-IL", ibEndX + 10, ibEndY)
            } else if (bl > bc) {
                // Net susceptance is inductive
                ctx.beginPath()
                ctx.strokeStyle = vectorLColor
                ctx.lineWidth = 2
                var ibEndX = centerX + bLength * Math.cos(rotatedPhase - Math.PI/2)
                var ibEndY = centerY + bLength * Math.sin(rotatedPhase - Math.PI/2)
                ctx.moveTo(centerX, centerY)
                ctx.lineTo(ibEndX, ibEndY)
                ctx.stroke()
                ctx.fillStyle = vectorLColor
                ctx.fillText("IL-IC", ibEndX - 10, ibEndY)
            }
        }
        
        // Draw current vector (reference)
        ctx.beginPath()
        ctx.strokeStyle = vectorIColor
        ctx.lineWidth = 3
        ctx.moveTo(centerX, centerY)
        ctx.lineTo(iEndX, iEndY)
        ctx.stroke()
        
        // Draw arrowhead for current
        drawArrowhead(ctx, iEndX, iEndY, rotatedPhase, 10, vectorIColor)
        
        // Draw voltage vector
        ctx.beginPath()
        ctx.strokeStyle = vectorVColor
        ctx.lineWidth = 3
        ctx.moveTo(centerX, centerY)
        ctx.lineTo(vEndX, vEndY)
        ctx.stroke()
        
        // Draw arrowhead for voltage
        drawArrowhead(ctx, vEndX, vEndY, rotatedPhase + phi, 10, vectorVColor)
        
        // Labels
        ctx.font = "14px sans-serif"
        ctx.textAlign = "center"
        
        ctx.fillStyle = vectorIColor
        ctx.fillText("I", iEndX + 15 * Math.cos(rotatedPhase), iEndY + 15 * Math.sin(rotatedPhase))
        
        ctx.fillStyle = vectorVColor
        ctx.fillText("V", vEndX + 15 * Math.cos(rotatedPhase + phi), vEndY + 15 * Math.sin(rotatedPhase + phi))
        
        // Draw phase angle arc
        if (phi !== 0) {
            var arcRadius = radius * 0.2
            ctx.beginPath()
            ctx.strokeStyle = darkMode ? "#AAAAAA" : "#666666"
            ctx.lineWidth = 1
            
            // Draw arc from current to voltage
            var startAngle = rotatedPhase
            var endAngle = rotatedPhase + phi
            
            if (phi < 0) {
                ctx.arc(centerX, centerY, arcRadius, startAngle, endAngle, true)
            } else {
                ctx.arc(centerX, centerY, arcRadius, startAngle, endAngle, false)
            }
            ctx.stroke()
            
            // Label the angle
            var midAngle = (startAngle + endAngle) / 2
            var phiDeg = Math.abs(Math.round(phi * 180 / Math.PI))
            
            ctx.fillStyle = darkMode ? "#FFFFFF" : "#333333"
            ctx.font = "12px sans-serif"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            
            var textX = centerX + arcRadius * 0.7 * Math.cos(midAngle)
            var textY = centerY + arcRadius * 0.7 * Math.sin(midAngle)
            ctx.fillText(phiDeg + "°", textX, textY)
        }
    }
    
    function drawArrowhead(ctx, x, y, angle, size, color) {
        ctx.save()
        ctx.translate(x, y)
        ctx.rotate(angle)
        
        // Draw arrowhead
        ctx.beginPath()
        ctx.fillStyle = color
        ctx.moveTo(0, 0)
        ctx.lineTo(-size, -size/2)
        ctx.lineTo(-size, size/2)
        ctx.closePath()
        ctx.fill()
        
        ctx.restore()
    }
    
    function drawTitle(ctx) {
        var title = circuitType === 0 ? 
            "Series RLC Phasor Diagram" : 
            "Parallel RLC Phasor Diagram"
        
        ctx.fillStyle = textColor
        ctx.font = "bold 14px sans-serif"
        ctx.textAlign = "center"
        ctx.textBaseline = "top"
        ctx.fillText(title, width / 2, 10)
        
        // Add explanatory text at bottom
        var bottomText = circuitType === 0 ?
            "V leads I in inductive circuit, I leads V in capacitive circuit" :
            "I leads V in inductive circuit, V leads I in capacitive circuit"
        
        ctx.font = "12px sans-serif"
        ctx.textBaseline = "bottom"
        ctx.fillText(bottomText, width / 2, height - 10)
    }
    
    // Mouse interaction for manual rotation
    MouseArea {
        anchors.fill: parent
        
        property real lastX: 0
        property real lastY: 0
        
        onPressed: {
            lastX = mouseX
            lastY = mouseY
            isAnimating = false  // Stop animation when manually rotating
        }
        
        onPositionChanged: {
            if (pressed) {
                var centerX = width / 2
                var centerY = height / 2
                
                // Calculate angles between center and mouse positions
                var prevAngle = Math.atan2(lastY - centerY, lastX - centerX)
                var newAngle = Math.atan2(mouseY - centerY, mouseX - centerX)
                
                // Update the phase based on the change in angle
                phase = (phase + (newAngle - prevAngle)) % (2 * Math.PI)
                if (phase < 0) phase += 2 * Math.PI
                
                lastX = mouseX
                lastY = mouseY
                
                // Request repaint
                phaseCanvas.requestPaint()
            }
        }
        
        onDoubleClicked: {
            isAnimating = !isAnimating
        }
    }
}
