import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import "../style"

RoundButton {
    id: control
    
    width: 60
    height: 60
    z:999
    x: 0
    y: parent.height - height

    icon.width: Style.iconSize
    icon.height: Style.iconSize

    property bool inOriginalPosition: x === 0 && y === parent.height - height
    property string tooltip_text: ""

    ToolTip {
        id: toolTip
        text: tooltip_text
        visible: parent.hovered
        x: parent.width
        y: parent.height
        delay: Style.tooltipDelay
    }
    
    background: Rectangle {
        radius: control.radius //inOriginalPosition ? 0 : control.radius
        color: {
            if (control.down) return Style.buttonPressed
            if (control.hovered) return Style.buttonHovered
            return Style.buttonBackground
        }
        border.width: 1
        border.color: Style.buttonBorder
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: menu
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0 
        drag.maximumX: parent.parent.width - menu.width
        drag.minimumY: 0
        drag.maximumY: parent.parent.height - menu.height
        
        property bool isDragging: false
        property point startPos
        
        function handlePressed(mouseX, mouseY) {
            startPos = Qt.point(mouseX, mouseY)
        }
        
        function handlePositionChanged(mouseX, mouseY) {
            if (!isDragging) {
                let dx = mouseX - startPos.x
                let dy = mouseY - startPos.y
                isDragging = Math.sqrt(dx * dx + dy * dy) > 5
            }
            
            if (isDragging) {
                settings.menuX = menu.x
                settings.menuY = menu.y
                let isOriginalPosition = menu.x === 0 && menu.y === parent.parent.height - menu.height
                
                if (isOriginalPosition) {
                    sideBar.menuMoved = false
                    if (!menu.inOriginalPosition) {
                        sideBar.open()
                    }
                } else {
                    sideBar.menuMoved = true
                    if (menu.inOriginalPosition && sideBar.position === 1) {
                        sideBar.close()
                    }
                }
            }
        }
        
        onPressed: (mouse) => {
                handlePressed(mouse.x, mouse.y)
        }
        onPositionChanged: (mouse) => {
            handlePositionChanged(mouse.x, mouse.y)
        }
        
        onReleased: {
            if (!isDragging) {
                menu.clicked()
            }
            isDragging = false
            settings.menuX = menu.x
            settings.menuY = menu.y
        }
        
        onClicked: if (!isDragging) menu.clicked()
    }

    onXChanged: sideBar.menuMoved = !inOriginalPosition
    onYChanged: sideBar.menuMoved = !inOriginalPosition

    onClicked: { 
        sideBar.react()
        forceActiveFocus()
        toolTip.hide()
    }
}