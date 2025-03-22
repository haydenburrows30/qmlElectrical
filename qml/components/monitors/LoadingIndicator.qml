import QtQuick
import QtQuick.Controls

Item {
    id: root
    anchors.fill: parent
    visible: false
    z: 999
    
    function show() {
        visible = true
    }
    
    function hide() {
        visible = false
    }
    
    Rectangle {
        anchors.fill: parent
        color: "#80000000"
    }
    
    BusyIndicator {
        anchors.centerIn: parent
        running: root.visible
    }
}
