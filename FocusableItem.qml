import QtQuick 2.15

Rectangle {
    id: root

    property bool isCurrent: false

    color: "transparent"
    radius: Style.radiusPanel
    border.width: isCurrent ? Style.borderWidth * 3 : Style.borderWidth
    border.color: isCurrent ? Style.colorFocus : Style.colorBorder
    scale: isCurrent ? 1.04 : 1.0

    Behavior on border.color { ColorAnimation { duration: Style.animationFast } }
    Behavior on scale { NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutQuad } }
}
