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
    property string collectionShortName: ""

    function show(title, collection, shortName) {
        gameTitle = title
        collectionName = collection
        collectionShortName = shortName || ""
        visible = true
        fadeIn.start()
        scaleIn.start()
        collectionImage.y = -collectionImage.height
        systemLogo.y = -systemLogo.height
        bounceIn.start()
        bounceInLogo.start()
    }

    function hide() {
        visible = false
        opacity = 0.0
        centerBox.scale = 0.0
        collectionImage.y = -collectionImage.height
        systemLogo.y = -systemLogo.height
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

    Image {
        id: systemLogo
        source: overlay.collectionShortName !== "" ? "assets/images/systems/" + overlay.collectionShortName + ".png" : ""
        visible: source !== "" && status === Image.Ready
        fillMode: Image.PreserveAspectFit
        width: Math.min(parent.width * 0.18, 120 * Style.scale)
        height: width
        asynchronous: true
        smooth: true

        anchors.right: collectionImage.left
        anchors.rightMargin: Style.spacingMedium
        y: -height

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 3 * Style.scale
            radius: 6 * Style.scale
            color: Qt.rgba(0,0,0,0.4)
        }
    }

    Image {
        id: collectionImage
        source: overlay.collectionShortName !== "" ? "assets/images/systems/" + overlay.collectionShortName + "-content.png" : ""
        visible: source !== "" && status === Image.Ready
        fillMode: Image.PreserveAspectFit
        width: Math.min(parent.width * 0.18, 120 * Style.scale)
        height: width
        asynchronous: true
        smooth: true

        anchors.right: parent.right
        anchors.rightMargin: Style.spacingLarge * 1.5
        y: -height

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 3 * Style.scale
            radius: 6 * Style.scale
            color: Qt.rgba(0,0,0,0.4)
        }
    }

    SequentialAnimation {
        id: bounceIn

        PauseAnimation { duration: 360 }

        NumberAnimation {
            target: collectionImage
            property: "y"
            from: -collectionImage.height
            to: Style.spacingTiny * 1.5
            duration: 1000
            easing.type: Easing.OutBounce
        }
    }

    NumberAnimation {
        id: bounceInLogo
        target: systemLogo
        property: "y"
        from: -systemLogo.height
        to: Style.spacingTiny * 1.5
        duration: 1000
        easing.type: Easing.OutBounce
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
