import QtQuick 2.15

FocusableItem {
    id: root

    property var game: null
    property bool blurActive: false

    function collectionShortName(g) {
        if (!g || !g.collections || g.collections.count === 0) return ""
        var collection = g.collections.get(0)
        return collection ? collection.shortName : ""
    }

    Image {
        id: art
        anchors.fill: parent
        anchors.margins: Style.spacingSmall
        source: {
            if (!game) return "";
            if (game.assets.boxFront !== "") return game.assets.boxFront;
            return game.assets.cartridge;
        }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: source !== "" && status === Image.Ready
    }

    Image {
        id: systemArt
        anchors.fill: parent
        anchors.margins: Style.spacingSmall
        source: {
            if (!game || art.visible) return "";
            var shortName = root.collectionShortName(game);
            return shortName !== "" ? "assets/images/systems/" + shortName + ".png" : "";
        }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: !art.visible && source !== "" && status === Image.Ready
    }

    Rectangle {
        id: favoriteBadge
        visible: !!(game && game.favorite)
        width: Math.round(26 * Style.scale)
        height: width
        radius: width / 2
        color: Style.colorAccent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Style.spacingSmall

        IconImage {
            iconName: "favorite"
            overlayColor: Style.colorBackground
            anchors.centerIn: parent
            width: Math.round(20 * Style.scale)
            height: width
        }
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.spacingSmall
        text: game ? game.title : ""
        color: Style.colorTextPrimary
        font.family: global.fonts.condensed
        font.pixelSize: Style.fontSizeSmall
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        visible: !art.visible
    }

    Rectangle {
        id: cardOverlay
        anchors.fill: parent
        color: "#F2000000"
        radius: Style.radiusPanel
        opacity: root.blurActive ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutQuad
            }
        }
    }
}
