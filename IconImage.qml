import QtQuick 2.15
import QtGraphicalEffects 1.12

Item {
    id: root

    property string iconName: ""
    property color overlayColor: "transparent"

    Image {
        id: icon
        anchors.fill: parent
        source: root.iconName !== "" ? "assets/images/icons/" + root.iconName + ".svg" : ""
        sourceSize.width: root.width
        sourceSize.height: root.height
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        visible: source !== "" && status === Image.Ready && root.overlayColor.a === 0
    }

    ColorOverlay {
        anchors.fill: icon
        source: icon
        color: root.overlayColor
        visible: icon.source !== "" && icon.status === Image.Ready && root.overlayColor.a > 0
    }
}
