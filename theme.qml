import QtQuick 2.15

FocusScope {
    id: themeRoot
    focus: true

    property bool interfaceReady: false
    property bool minSplashTimeElapsed: false

    function checkInterfaceReady() {
        console.log("[theme][DEBUG] checkInterfaceReady t=" + Date.now() + " restoreComplete=" + gameView.restoreComplete + " gridOrientationResolved=" + gameView.gridOrientationResolved);
        if (interfaceReady) return;
        if (gameView.restoreComplete && gameView.gridOrientationResolved) {
            interfaceReady = true;
            console.log("[theme][DEBUG] interfaceReady = true en t=" + Date.now());
        }
    }

    Connections {
        target: gameView
        function onRestoreCompleteChanged() { themeRoot.checkInterfaceReady(); }
        function onGridOrientationResolvedChanged() { themeRoot.checkInterfaceReady(); }
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colorBackground
    }

    GameView {
        id: gameView
        anchors.fill: parent
    }

    onWidthChanged: {
        console.log("[theme][DEBUG] themeRoot.width cambió a " + width + " t=" + Date.now());
        Style.updateScale(width, height);
    }
    onHeightChanged: {
        console.log("[theme][DEBUG] themeRoot.height cambió a " + height + " t=" + Date.now());
        Style.updateScale(width, height);
    }

    Component.onCompleted: {
        console.log("[theme][DEBUG] Component.onCompleted t=" + Date.now() + " width=" + width + " height=" + height);
        Style.updateScale(width, height);

        var savedTheme = api.memory.has('selectedTheme')
            ? api.memory.get('selectedTheme')
            : Style.defaultThemeName;
        console.log("[theme] Restaurando tema de color: " + savedTheme);
        Style.applyTheme(savedTheme);

        var kind = api.memory.has('collectionKind') ? api.memory.get('collectionKind') : "lastplayed";
        var name = api.memory.has('collectionName') ? api.memory.get('collectionName') : "Last Played";
        var title = api.memory.has('gameTitle') ? api.memory.get('gameTitle') : "";
        console.log("[theme] Cargando: kind=" + kind + ", name=" + name + ", title=" + title);
        gameView.restoreState(kind, name, title);
    }

    Component.onDestruction: {
        if (gameView && gameView.collectionBar && gameView.gameGrid) {
            var entry = gameView.collectionBar.currentEntry;
            var kind = entry ? entry.kind : "lastplayed";
            var name = entry ? entry.label : "Last Played";
            var title = gameView.currentGame ? gameView.currentGame.title : "";
            console.log("[theme] Guardando al destruir: kind=" + kind + ", name=" + name + ", title=" + title);
            api.memory.set('collectionKind', kind);
            api.memory.set('collectionName', name);
            api.memory.set('gameTitle', title);
        } else {
            console.warn("[theme] No se pudo guardar estado al destruir");
        }
    }

    Rectangle {
        id: splashOverlay
        anchors.fill: parent
        color: Style.colorBackground
        z: 1000

        property int minSplashDuration: 700
        readonly property bool splashHidden: themeRoot.interfaceReady && themeRoot.minSplashTimeElapsed

        opacity: splashHidden ? 0 : 1
        visible: opacity > 0

        onSplashHiddenChanged: {
            console.log("[theme][DEBUG] splashHidden=" + splashHidden + " t=" + Date.now());
            if (splashHidden) {
                gameView.focusGames();
            }
        }

        Timer {
            interval: splashOverlay.minSplashDuration
            running: true
            repeat: false
            onTriggered: themeRoot.minSplashTimeElapsed = true
        }

        Behavior on opacity {
            NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            enabled: splashOverlay.visible
        }

        Column {
            anchors.centerIn: parent
            spacing: Style.spacingLarge

            Text {
                id: brandText
                anchors.horizontalCenter: parent.horizontalCenter
                text: "AMBERLINE"
                color: Style.colorTextPrimary
                font.family: Fonts.pixelify
                font.pixelSize: Style.fontSizeTitle * 2.6
                font.letterSpacing: Math.round(2 * Style.scale)

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: splashOverlay.visible
                    NumberAnimation { from: 0.75; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.0; to: 0.75; duration: 900; easing.type: Easing.InOutSine }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.spacingSmall

                Repeater {
                    model: 3
                    Rectangle {
                        width: Math.round(12 * Style.scale)
                        height: width
                        radius: width / 2
                        color: Style.colorAccent

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: splashOverlay.visible
                            PauseAnimation { duration: index * 140 }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 320; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 1.0; to: 0.25; duration: 320; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Loading your library..."
                color: Style.colorTextSecondary
                font.family: Fonts.smooch
                font.pixelSize: Style.fontSizeLarge
            }
        }
    }
}

