import QtQuick
import QtQuick.Controls

Label {
    property real size: 24
    property string icon
    property bool appicon: true

    text: icon
    font.pixelSize: size
}
