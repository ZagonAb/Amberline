import QtQuick 2.15
import QtGraphicalEffects 1.12

Rectangle {
    id: overlay
    anchors.fill: parent
    color: Style.colorBackground
    opacity: 0.0
    z: 1000
    visible: false

    property string gameTitle: ""
    property string collectionName: ""

    function show(title, collection) {
        gameTitle = title
        collectionName = collection
        visible = true
        fadeIn.start()
        scaleIn.start()
    }

    function hide() {
        visible = false
        opacity = 0.0
        centerBox.scale = 0.0
    }

    MouseArea {
        anchors.fill: parent
        enabled: overlay.visible
    }

    Rectangle {
        id: centerBox
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.6, 600 * Style.scale)
        height: width * 0.55
        radius: Style.radiusPanel * 2
        color: Style.colorPanel
        border.color: Style.colorAccent
        border.width: Style.borderWidth * 3
        scale: 0.0

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4 * Style.scale
            radius: 8 * Style.scale
            color: Qt.rgba(0,0,0,0.4)
        }

        Column {
            anchors.centerIn: parent
            spacing: Style.spacingMedium
            width: parent.width * 0.8

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Launching game…"
                color: Style.colorTextPrimary
                font.family: Fonts.pixelify
                font.pixelSize: Style.fontSizeTitle * 1.2
                font.letterSpacing: 2
                opacity: 0.7
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: overlay.gameTitle
                color: Style.colorAccent
                font.family: Fonts.sekuya
                font.pixelSize: Style.fontSizeMediumLarge * 1.5
                font.bold: true
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                maximumLineCount: 4
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: overlay.collectionName
                color: Style.colorTextSecondary
                font.family: Fonts.smooch
                font.pixelSize: Style.fontSizeTitle * 1.2
                elide: Text.ElideRight
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: overlay
        property: "opacity"
        from: 0.0
        to: 0.98
        duration: Style.animationNormal * 2
        easing.type: Easing.InOutQuad
    }

    NumberAnimation {
        id: scaleIn
        target: centerBox
        property: "scale"
        from: 0.0
        to: 1.0
        duration: 1000
        easing.type: Easing.OutBack
    }

    Component.onDestruction: hide()
}
