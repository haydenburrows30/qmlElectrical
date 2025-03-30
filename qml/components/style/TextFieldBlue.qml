import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

import "../backgrounds"

TextField {
    id: textField
    readOnly: true
    Layout.fillWidth: true

    text: ""

    // ToolTip.text: textField.text
    ToolTip.visible: hovered
    ToolTip.delay: 500
    
    background: ProtectionRectangle {}
}