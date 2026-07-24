import QtQuick 2.15
import QtMultimedia 5.15
import "qrc:/qmlutils" as PegasusUtils

Rectangle {
    id: root

    property var game: null

    property string currentAssetType: "screenshot"

    readonly property bool raPanelOpen: raLoader.active

    signal raPanelClosed()

    onRaPanelOpenChanged: {
        if (raPanelOpen) {
            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                mediaPlayer.pause();
            }
        } else {
            if (currentAssetType === "video" && mediaPlayer.source !== "") {
                mediaPlayer.play();
            }
        }
    }

    readonly property var imageAssetTypes: [
        "screenshot", "boxFront", "boxBack", "logo", "titlescreen",
        "marquee", "poster", "steam", "banner", "tile", "cartridge",
        "boxSpine", "boxFull", "bezel", "panel", "cabinetLeft",
        "cabinetRight", "background", "video"
    ]

    function getAvailableAssetTypes(g) {
        if (!g || !g.assets) return []
            var result = []
            for (var i = 0; i < imageAssetTypes.length; ++i) {
                var type = imageAssetTypes[i]
                var assetUrl = g.assets[type]
                if (assetUrl && assetUrl !== "") result.push(type)
            }
            return result
    }

    readonly property var availableAssetTypes: game ? getAvailableAssetTypes(game) : []
    readonly property int currentDotIndex: availableAssetTypes.indexOf(currentAssetType)

    function collectionShortName(g) {
        if (!g || !g.collections || g.collections.count === 0) return ""
            var collection = g.collections.get(0)
            return collection ? collection.shortName : ""
    }

    function hasAnyAsset(g) {
        if (!g || !g.assets) return false
            for (var i = 0; i < imageAssetTypes.length; ++i) {
                var url = g.assets[imageAssetTypes[i]]
                if (url && url !== "") return true
            }
            return false
    }

    function getFirstAvailableAssetType(game) {
        if (!game || !game.assets) return "screenshot"
            for (var i = 0; i < imageAssetTypes.length; ++i) {
                var type = imageAssetTypes[i]
                var assetUrl = game.assets[type]
                if (assetUrl && assetUrl !== "") {
                    return type
                }
            }
            return "screenshot"
    }

    function getNextAvailableAssetType(game, currentType) {
        if (!game || !game.assets) return currentType
            var currentIndex = imageAssetTypes.indexOf(currentType)
            if (currentIndex === -1) currentIndex = 0
                for (var i = 1; i <= imageAssetTypes.length; ++i) {
                    var nextIndex = (currentIndex + i) % imageAssetTypes.length
                    var nextType = imageAssetTypes[nextIndex]
                    var assetUrl = game.assets[nextType]
                    if (assetUrl && assetUrl !== "") {
                        return nextType
                    }
                }
                return currentType
    }

    function formatPlayTime(totalSeconds) {
        if (!totalSeconds || totalSeconds <= 0) return "00:00:00"
            var hrs = Math.floor(totalSeconds / 3600)
            var mins = Math.floor((totalSeconds % 3600) / 60)
            var secs = Math.floor(totalSeconds % 60)
            function pad(n) { return (n < 10 ? "0" : "") + n }
            return pad(hrs) + ":" + pad(mins) + ":" + pad(secs)
    }

    function _raHasCredentials() {
        return api.memory.has("ra_api_key") && api.memory.get("ra_api_key") !== ""
        && api.memory.has("ra_api_user") && api.memory.get("ra_api_user") !== ""
    }

    function toggleRAPanel() {
        if (raLoader.active) {
            _closeRAPanel()
        } else {
            raLoader.sourceComponent = _raHasCredentials() ? _raInfoComponent : _raCredentialsComponent
            raLoader.opacity = 0
            raLoader.active = true
            _raOpenAnim.start()
        }
    }

    function _closeRAPanel() {
        if (raLoader.item && raLoader.item.hasOwnProperty("isOpen")) {
            raCloseDelay.start()
        } else {
            _raCloseAnim.start()
        }
    }

    function cycleAsset() {
        if (!game) return
            var nextType = getNextAvailableAssetType(game, currentAssetType)
            if (nextType !== currentAssetType) {
                currentAssetType = nextType
            }
    }

    function updateContent() {
        if (!game || !hasAnyAsset(game)) {
            if (mediaPlayer.playbackState !== MediaPlayer.StoppedState) {
                mediaPlayer.stop()
            }
            mediaPlayer.source = ""
            videoContainer.visible = false
            imageContainer.visible = false
            systemContentContainer.visible = true
            var shortName = collectionShortName(game)
            systemImage.source = shortName !== "" ? "assets/images/systems/" + shortName + "-content.png" : ""
            return
        }

        systemContentContainer.visible = false

        var assetUrl = game.assets[currentAssetType]
        var isVideo = (currentAssetType === "video" && assetUrl !== "")

        if (!isVideo) {
            if (mediaPlayer.playbackState !== MediaPlayer.StoppedState) {
                mediaPlayer.stop()
            }
            mediaPlayer.source = ""
            videoContainer.visible = false
            imageContainer.visible = true
            image.source = assetUrl || ""
        } else {
            imageContainer.visible = false
            videoContainer.visible = true
            if (mediaPlayer.source !== assetUrl) {
                mediaPlayer.source = assetUrl
                mediaPlayer.play()
            }
        }
    }

    onGameChanged: {
        if (game) {
            currentAssetType = getFirstAvailableAssetType(game)
        } else {
            currentAssetType = "screenshot"
        }
        updateContent()
    }

    onCurrentAssetTypeChanged: {
        updateContent()
    }

    color: Style.colorPanel
    radius: Style.radiusPanel
    border.width: Style.borderWidth
    border.color: Style.colorBorder
    clip: true

    Item {
        id: contentWrapper
        anchors.fill: parent

        transform: Translate { id: contentWrapperSlide; y: 0 }

        Row {
            id: assetDotLine
            anchors.top: parent.top
            anchors.topMargin: Style.spacingSmall
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.spacingSmall
            z: 5
            visible: !!root.game && root.availableAssetTypes.length > 1

            Repeater {
                model: root.availableAssetTypes

                delegate: Rectangle {
                    width: Math.round(16 * Style.scale)
                    height: Math.round(4 * Style.scale)
                    radius: height / 2
                    color: index === root.currentDotIndex ? Style.colorAccent : Style.colorBackground

                    Behavior on color {
                        ColorAnimation { duration: Style.animationFast }
                    }
                }
            }
        }

        Item {
            id: imageContainer
            anchors.top: assetDotLine.bottom
            anchors.topMargin: Style.spacingSmall
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Style.spacingMedium
            anchors.rightMargin: Style.spacingMedium
            height: parent.height * 0.42
            visible: true

            Image {
                id: image
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                source: ""
            }
        }

        Item {
            id: videoContainer
            anchors.top: assetDotLine.bottom
            anchors.topMargin: Style.spacingSmall
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Style.spacingMedium
            anchors.rightMargin: Style.spacingMedium
            height: parent.height * 0.42
            visible: false
            clip: true

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
                source: mediaPlayer
            }

            MediaPlayer {
                id: mediaPlayer
                autoPlay: false
                loops: MediaPlayer.Infinite
                onStatusChanged: {
                    if (status === MediaPlayer.EndOfMedia) {
                    }
                }
                onError: {
                    console.warn("Video playback error:", errorString)
                }
            }

            Rectangle {
                id: videoProgressBar
                x: videoOutput.contentRect.x
                y: videoOutput.contentRect.y + videoOutput.contentRect.height - height
                width: videoOutput.contentRect.width
                height: 4
                radius: 2
                color: "#40FFFFFF"
                z: 10
                visible: mediaPlayer.duration > 0 && videoContainer.visible

                Rectangle {
                    id: videoProgressFill
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: mediaPlayer.duration > 0
                        ? parent.width * (mediaPlayer.position / mediaPlayer.duration)
                        : 0
                    radius: parent.radius
                    color: Style.colorAccent
                    opacity: 0.9
                }

                Timer {
                    id: progressTimer
                    interval: 32
                    running: mediaPlayer.playbackState === MediaPlayer.PlayingState
                    repeat: true
                    property real lastPosition: 0
                    property real lastTimestamp: 0

                    onTriggered: {
                        var now = Date.now();
                        var elapsed = (now - lastTimestamp);
                        if (mediaPlayer.playbackState === MediaPlayer.PlayingState && mediaPlayer.duration > 0) {
                            var interpolated = Math.min(mediaPlayer.position + elapsed, mediaPlayer.duration);
                            videoProgressFill.width = videoProgressBar.width * (interpolated / mediaPlayer.duration);
                        }
                        lastTimestamp = now;
                    }

                    onRunningChanged: {
                        if (running) lastTimestamp = Date.now();
                    }
                }
            }
        }

        Item {
            id: systemContentContainer
            anchors.top: assetDotLine.bottom
            anchors.topMargin: Style.spacingSmall
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Style.spacingMedium
            anchors.rightMargin: Style.spacingMedium
            height: parent.height * 0.42
            visible: false

            Image {
                id: systemImage
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
                source: ""
            }
        }

        Text {
            anchors.horizontalCenter: systemContentContainer.horizontalCenter
            anchors.verticalCenter: systemContentContainer.verticalCenter
            width: root.width * 0.7
            visible: !game
            text: "Game artwork and details will appear here once you start your journey."
            color: Style.colorTextSecondary
            font.family: Fonts.smooch
            font.pixelSize: Style.fontSizeLarge
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }

        Column {
            id: infoColumn
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.42 + Style.spacingLarge
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Style.spacingMedium
            spacing: Style.spacingSmall

            Text {
                width: parent.width
                text: game ? game.title : ""
                color: Style.colorTextPrimary
                font.family: Fonts.sekuya
                font.pixelSize: Style.fontSizeMedium
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: {
                    if (!game) return "";
                    var parts = [];
                    if (game.developer !== "") parts.push(game.developer);
                    if (game.releaseYear > 0) parts.push(String(game.releaseYear));
                    return parts.join("  \u2022  ");
                }
                color: Style.colorTextSecondary
                font.family: Fonts.smooch
                font.pixelSize: Style.fontSizeLarge
                elide: Text.ElideRight
            }

            Item {
                width: parent.width
                height: Math.max(playCountRow.height, playTimeRow.height)

                Row {
                    id: playCountRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacingSmall

                    IconImage {
                        iconName: "play"
                        overlayColor: Style.colorIconMono
                        width: Math.round(16 * Style.scale)
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: game ? "Play Count: " + game.playCount : ""
                        color: Style.colorTextSecondary
                        font.family: Fonts.smooch
                        font.pixelSize: Style.fontSizeLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    id: playTimeRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacingSmall

                    IconImage {
                        iconName: "time"
                        overlayColor: Style.colorIconMono
                        width: Math.round(16 * Style.scale)
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: game ? "Play Time: " + formatPlayTime(game.playTime) : ""
                        color: Style.colorTextSecondary
                        font.family: Fonts.smooch
                        font.pixelSize: Style.fontSizeLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        Item {
            id: descriptionContainer
            anchors.top: infoColumn.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Style.spacingMedium

            PegasusUtils.AutoScroll {
                id: autoscroll
                anchors.fill: parent
                pixelsPerSecond: 20
                scrollWaitDuration: 2000

                Column {
                    width: parent.width * 0.94
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Style.spacingSmall

                    Text {
                        width: parent.width
                        text: {
                            if (game && game.description) return game.description;
                            if (game) return "No description available. You can generate metadata with these tools:";
                            return "Every game has a story to tell. Select one and its description will appear here.";
                        }
                        color: Style.colorTextPrimary
                        font.family: Fonts.smooch
                        font.pixelSize: Style.fontSizeLarge
                        wrapMode: Text.WordWrap
                        lineHeight: 1.1
                        topPadding: Style.spacingSmall
                    }

                    Row {
                        visible: game && !game.description
                        spacing: Style.spacingMedium

                        Text {
                            id: skraperLink
                            text: "Skraper"
                            color: Style.colorAccent
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.underline: skraperMa.containsMouse

                            MouseArea {
                                id: skraperMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: Qt.openUrlExternally("https://www.skraper.net/")
                            }
                        }

                        Text {
                            text: "•"
                            color: Style.colorTextSecondary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                        }

                        Text {
                            id: bellerophonLink
                            text: "Bellerophon"
                            color: Style.colorAccent
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.underline: bellerophonMa.containsMouse

                            MouseArea {
                                id: bellerophonMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: Qt.openUrlExternally("https://github.com/valsou/bellerophon")
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        id: raLoader
        anchors.fill: contentWrapper
        active: false
        opacity: 0
        z: 10

        onLoaded: {
            if (item && item.forceActiveFocus) item.forceActiveFocus()
                if (item) {
                    if (item.openCredentialsRequested) {
                        item.openCredentialsRequested.connect(function() {
                            raLoader.sourceComponent = _raCredentialsComponent
                            raLoader.opacity = 0
                            _raOpenAnim.restart()
                        })
                    }
                    if (item.credentialsSaved) {
                        item.credentialsSaved.connect(function() {
                            raLoader.sourceComponent = _raInfoComponent
                            raLoader.opacity = 0
                            _raOpenAnim.restart()
                        })
                    }
                    if (item.popupClosed) {
                        item.popupClosed.connect(function() {
                            if (api.memory.has("ra_api_key") && api.memory.has("ra_api_user")) {
                                raLoader.sourceComponent = _raInfoComponent
                                raLoader.opacity = 0
                                _raOpenAnim.restart()
                            } else {
                                _raCloseAnim.start()
                            }
                        })
                    }
                }
        }
    }

    readonly property int raTransitionDuration: 450

    ParallelAnimation {
        id: _raOpenAnim
        NumberAnimation {
            target: contentWrapperSlide
            property: "y"
            to: -contentWrapper.height
            duration: root.raTransitionDuration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: raLoader
            property: "opacity"
            to: 1
            duration: root.raTransitionDuration
            easing.type: Easing.InOutQuad
        }
    }

    ParallelAnimation {
        id: _raCloseAnim
        NumberAnimation {
            target: contentWrapperSlide
            property: "y"
            to: 0
            duration: root.raTransitionDuration
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: raLoader
            property: "opacity"
            to: 0
            duration: root.raTransitionDuration
            easing.type: Easing.InOutQuad
        }
        onFinished: {
            raLoader.active = false
            root.raPanelClosed()
        }
    }

    Timer {
        id: raCloseDelay
        interval: 230
        onTriggered: _raCloseAnim.start()
    }

    Component {
        id: _raCredentialsComponent
        RACredentialsPopup {
            anchors.fill: parent
            onCredentialsSaved: raLoader.sourceComponent = _raInfoComponent
            onPopupClosed: root._closeRAPanel()
            Component.onCompleted: open()
        }
    }

    Component {
        id: _raInfoComponent
        RAGameInfoSection {
            anchors.fill: parent
            gameData: root.game
            onCloseRequested: root._closeRAPanel()
        }
    }

    Component.onDestruction: {
        mediaPlayer.stop()
        mediaPlayer.source = ""
    }
}
