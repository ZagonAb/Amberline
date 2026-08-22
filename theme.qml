import QtQuick 2.15

FocusScope {
    id: themeRoot
    focus: true

    readonly property string currentVersion: "1.0.0"
    property bool interfaceReady: false
    property bool minSplashTimeElapsed: false

    property string _pendingVersion: ""
    property string _pendingUrl: ""
    property string _pendingNotes: ""

    function checkInterfaceReady() {
        console.log("[theme][DEBUG] checkInterfaceReady t=" + Date.now() +
        " restoreComplete=" + gameView.restoreComplete +
        " gridOrientationResolved=" + gameView.gridOrientationResolved);
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

    function isNewerVersion(latest, current) {
        console.log("[theme][isNewerVersion] Comparando:", latest, "vs", current);
        var a = latest.split('.').map(Number);
        var b = current.split('.').map(Number);
        for (var i = 0; i < 3; i++) {
            if ((a[i] || 0) > (b[i] || 0)) {
                console.log("[theme][isNewerVersion] true en posición", i);
                return true;
            }
            if ((a[i] || 0) < (b[i] || 0)) {
                console.log("[theme][isNewerVersion] false en posición", i);
                return false;
            }
        }
        console.log("[theme][isNewerVersion] false (iguales)");
        return false;
    }

    function checkForUpdates() {
        console.log("[theme][checkForUpdates] Iniciando comprobación...");
        var xhr = new XMLHttpRequest();
        var url = "https://api.github.com/repos/ZagonAb/Amberline/releases/latest";
        console.log("[theme][checkForUpdates] URL:", url);
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            console.log("[theme][checkForUpdates] readyState:", xhr.readyState);
            if (xhr.readyState === XMLHttpRequest.DONE) {
                console.log("[theme][checkForUpdates] DONE - status:", xhr.status);
                console.log("[theme][checkForUpdates] responseText (primeros 200 chars):",
                            xhr.responseText ? xhr.responseText.substring(0, 200) : "(vacío)");
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        console.log("[theme][checkForUpdates] JSON parseado correctamente");
                        var latestTag = data.tag_name || "";
                        var latestVersion = latestTag.replace(/^v/, "");
                        var releaseUrl = data.html_url || "";
                        var releaseNotes = data.body || "";
                        console.log("[theme][checkForUpdates] latestTag:", latestTag,
                                    "latestVersion:", latestVersion,
                                    "releaseUrl:", releaseUrl);
                        if (latestVersion && isNewerVersion(latestVersion, currentVersion)) {
                            console.log("[theme][checkForUpdates] Versión más nueva detectada!");
                            var lastNotified = api.memory.has('lastUpdateNotified')
                            ? api.memory.get('lastUpdateNotified')
                            : "";
                            console.log("[theme][checkForUpdates] lastNotified:", lastNotified);
                            if (latestVersion !== lastNotified) {
                                console.log("[theme][checkForUpdates] Guardando notificación pendiente para versión:", latestVersion);
                                themeRoot._pendingVersion = latestVersion;
                                themeRoot._pendingUrl = releaseUrl;
                                themeRoot._pendingNotes = releaseNotes;
                                api.memory.set('lastUpdateNotified', latestVersion);
                                if (splashOverlay.splashHidden) {
                                    postSplashNotifTimer.restart();
                                }
                            } else {
                                console.log("[theme][checkForUpdates] Ya notificado para esta versión, omitiendo");
                            }
                        } else {
                            console.log("[theme][checkForUpdates] No es más nueva o no hay versión");
                        }
                    } catch (e) {
                        console.warn("[theme][checkForUpdates] Error parsing JSON:", e);
                        console.warn("[theme][checkForUpdates] responseText completo:", xhr.responseText);
                    }
                } else {
                    console.log("[theme][checkForUpdates] Error HTTP:", xhr.status, xhr.statusText);
                    if (xhr.responseText) console.log("[theme][checkForUpdates] response:", xhr.responseText);
                }
            }
        };
        xhr.onerror = function(e) {
            console.error("[theme][checkForUpdates] Error de red:", e);
        };
        xhr.send();
        console.log("[theme][checkForUpdates] Solicitud enviada.");
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colorBackground
    }

    GameView {
        id: gameView
        anchors.fill: parent
        enabled: !updateNotification.visible
    }

    UpdateNotification {
        id: updateNotification
        anchors.fill: parent
        visible: false
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
        console.log("[theme][DEBUG] Component.onCompleted t=" + Date.now() +
        " width=" + width + " height=" + height);
        Style.updateScale(width, height);

        var savedTheme = api.memory.has('selectedTheme')
        ? api.memory.get('selectedTheme')
        : Style.defaultThemeName;
        console.log("[theme] Restaurando tema de color: " + savedTheme);
        Style.applyTheme(savedTheme);

        var kind = api.memory.has('collectionKind')
        ? api.memory.get('collectionKind')
        : "lastplayed";
        var name = api.memory.has('collectionName')
        ? api.memory.get('collectionName')
        : "Last Played";
        var title = api.memory.has('gameTitle')
        ? api.memory.get('gameTitle')
        : "";
        console.log("[theme] Cargando: kind=" + kind + ", name=" + name + ", title=" + title);
        gameView.restoreState(kind, name, title);

        Qt.callLater(function() {
            console.log("[theme] Ejecutando checkForUpdates después de inicio");
            checkForUpdates();
        });
    }

    Component.onDestruction: {
        if (gameView && gameView.collectionBar && gameView.gameGrid) {
            var entry = gameView.collectionBar.currentEntry;
            var kind = entry ? entry.kind : "lastplayed";
            var name = entry ? entry.label : "Last Played";
            var title = gameView.currentGame ? gameView.currentGame.title : "";
            console.log("[theme] Guardando al destruir: kind=" + kind +
            ", name=" + name + ", title=" + title);
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
                if (themeRoot._pendingVersion !== "") {
                    postSplashNotifTimer.restart();
                } else {
                    gameView.focusGames();
                }
            }
        }

        Timer {
            interval: splashOverlay.minSplashDuration
            running: true
            repeat: false
            onTriggered: themeRoot.minSplashTimeElapsed = true
        }

        Timer {
            id: postSplashNotifTimer
            interval: 800
            repeat: false
            onTriggered: {
                if (themeRoot._pendingVersion !== "") {
                    console.log("[theme] Mostrando notificación post-splash para versión:", themeRoot._pendingVersion);
                    updateNotification.show(themeRoot._pendingVersion, themeRoot._pendingUrl, themeRoot._pendingNotes);
                    themeRoot._pendingVersion = "";
                    themeRoot._pendingUrl = "";
                    themeRoot._pendingNotes = "";
                }
            }
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
