import QtQuick 2.15

FocusScope {
    id: root
    focus: true

    readonly property var currentGame: gameGrid.currentGame
    readonly property int currentCollectionIndex: collectionBar.currentIndex
    readonly property alias collectionBar: collectionBar
    readonly property alias gameGrid: gameGrid
    readonly property bool restoreComplete: _restoreComplete
    readonly property bool gridOrientationResolved: gameGrid.orientationResolved
    property bool _restoreComplete: false

    function restoreCollectionIndex(index) { collectionBar.setCurrentIndex(index); }
    function focusGames() { gameGrid.focusGrid(); }

    property var _pendingRestore: null

    function restoreState(collectionKind, collectionName, gameTitle) {
        console.log("[GameView] restoreState: collectionKind=" + collectionKind + ", collectionName=" + collectionName + ", gameTitle=" + gameTitle);
        _pendingRestore = { kind: collectionKind, name: collectionName, title: gameTitle };
        if (collectionBar.modelReady) {
            applyRestore();
        } else {
            console.log("[GameView] Esperando a que CollectionBar esté lista...");
        }
    }

    function applyRestore() {
        if (!_pendingRestore) return;
        var data = _pendingRestore;
        _pendingRestore = null;

        if (data.kind && data.name) {
            collectionBar.setCurrentByKindAndName(data.kind, data.name);
        } else {
            console.warn("[GameView] No hay datos de colección, usando Last Played");
            collectionBar.setCurrentByKindAndName("lastplayed", "Last Played");
        }

        if (data.title) {
            function applyGame() {
                if (gameGrid.gameCount > 0) {
                    gameGrid.selectGameByTitle(data.title);
                    root._restoreComplete = true;
                } else {
                    Qt.callLater(applyGame);
                }
            }
            applyGame();
        } else {
            console.warn("[GameView] No hay título de juego para restaurar");
            root._restoreComplete = true;
        }
    }

    Component.onCompleted: {
        collectionBar.ready.connect(applyRestore);
    }

    property bool blurActive: false

    function openColorSetting() {
        colorSetting.iconCenterX = colorIcon.x + colorIcon.width / 2;
        root.blurActive = true;
        openColorSettingTimer.restart();
        console.log("[GameView] Overlay activado, esperando fade-in para abrir ColorSetting");
    }

    Timer {
        id: openColorSettingTimer
        interval: Style.animationNormal
        onTriggered: {
            colorSetting.visible = true;
            colorSetting.forceActiveFocus();
            console.log("[GameView] ColorSetting abierto");
        }
    }

    function closeColorSetting() {
        openColorSettingTimer.stop();
        colorSetting.visible = false;
        colorSetting.focus = false;
        root.blurActive = false;
        gameGrid.focusGrid();
        console.log("[GameView] ColorSetting cerrado, foco en índice 0");
    }

    function openSearch() {
        root.blurActive = true;
        searchLoader.active = true;
    }

    function closeSearch() {
        searchLoader.active = false;
        root.blurActive = false;
        gameGrid.focusGrid();
    }

    function launchGame(game) {
        var entry = collectionBar.currentEntry;
        var kind  = entry ? entry.kind  : "lastplayed";
        var name  = entry ? entry.label : "Last Played";
        var title = game.title;
        console.log("[GameView] Lanzando juego, guardando kind=" + kind + ", name=" + name + ", title=" + title);
        api.memory.set('collectionKind', kind);
        api.memory.set('collectionName', name);
        api.memory.set('gameTitle', title);

        var collectionName = "";
        if (game.collections && game.collections.count > 0) {
            collectionName = game.collections.get(0).name;
        }
        if (collectionName === "") {
            collectionName = name;
        }

        launchOverlay.show(title, collectionName);
        launchDelayTimer.gameToLaunch = game;
        launchDelayTimer.restart();
    }

    Keys.onPressed: {
        if (searchLoader.active) {
            return;
        }

        if (colorSetting.visible) {
            if (api.keys.isPrevPage(event) || api.keys.isNextPage(event)) {
                event.accepted = true;
            }
            return;
        }

        if (api.keys.isNextPage(event)) {
            event.accepted = true;
            if (!gameDetails.raPanelOpen) {
                collectionBar.next();
            }
        } else if (api.keys.isPrevPage(event)) {
            event.accepted = true;
            if (!gameDetails.raPanelOpen) {
                if (collectionBar.currentIndex === 0) {
                    openColorSetting();
                } else {
                    collectionBar.prev();
                }
            }
        } else if ((event.key === Qt.Key_F1 || api.keys.isMenu(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            gameDetails.toggleRAPanel();
        }
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Style.spacingLarge
        spacing: Style.spacingMedium

        Row {
            id: barRow
            width:   parent.width
            height:  collectionBar.height
            spacing: Style.spacingSmall

            Item {
                id: colorIcon
                width:  collectionBar.itemHeight
                height: collectionBar.itemHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusPanel
                    color:  Style.colorPanel
                    border.width: colorSetting.visible ? Style.borderWidth * 2 : Style.borderWidth
                    border.color: colorSetting.visible ? Style.colorFocus : Style.colorBorder

                    Behavior on border.color {
                        ColorAnimation { duration: Style.animationFast }
                    }
                }

                IconImage {
                    iconName: "color"
                    overlayColor: Style.colorAccent
                    width:    Math.round(25 * Style.scale)
                    height:   width
                    anchors.centerIn: parent
                }

                scale: colorSetting.visible ? 1.04 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutQuad }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (colorSetting.visible) {
                            closeColorSetting();
                        } else {
                            openColorSetting();
                        }
                    }
                }
            }

            CollectionBar {
                id: collectionBar
                width: parent.width - colorIcon.width - parent.spacing
                onCollectionSelected: {
                    console.log("[GameView] onCollectionSelected, kind:", entry.kind, "label:", entry.label);
                    gameGrid.sourceEntry = entry;
                }
            }
        }

        Row {
            width:   parent.width
            height:  parent.height - barRow.height - Style.spacingMedium
            spacing: Style.spacingMedium

            GameGrid {
                id: gameGrid
                width: parent.width * 0.62 - scrollProgressBar.width - parent.spacing
                height: parent.height
                blurActive: root.blurActive

                onGameActivated: {
                    root.launchGame(game);
                }
                onCycleImageRequested: {
                    gameDetails.cycleAsset();
                }
                onSearchRequested: {
                    root.openSearch();
                }
            }

            ScrollProgressBar {
                id: scrollProgressBar
                height: gameDetails.height
                anchors.verticalCenter: parent.verticalCenter
                currentIndex: gameGrid.currentGameIndex
                count: gameGrid.gameCount
                columns: gameGrid.columns
            }

            GameDetails {
                id: gameDetails
                width:  parent.width * 0.38 - Style.spacingMedium
                height: parent.height
                game: root.currentGame
                onRaPanelClosed: {
                    gameGrid.focusGrid();
                }
            }
        }
    }

    LaunchOverlay {
        id: launchOverlay
        visible: false
    }

    Timer {
        id: launchDelayTimer
        interval: 2000
        repeat: false
        property var gameToLaunch: null
        onTriggered: {
            if (gameToLaunch) {
                gameToLaunch.launch();
                gameToLaunch = null;
                hideOverlayTimer.start();
            }
        }
    }

    Timer {
        id: hideOverlayTimer
        interval: 500
        repeat: false
        onTriggered: {
            launchOverlay.hide();
        }
    }

    ColorSetting {
        id: colorSetting
        x: mainColumn.x
        y: mainColumn.y + barRow.height + Style.spacingMedium
        z: 10

        onCloseMenu: closeColorSetting()

        onThemeSelected: {
            Style.applyTheme(themeName);
        }
    }

    Loader {
        id: searchLoader
        anchors.fill: parent
        z: 50
        active: false
        source: "GameSearch.qml"

        onLoaded: {
            item.targetX = Qt.binding(function() { return gameGrid.mapToItem(root, 0, 0).x; });
            item.targetWidth = Qt.binding(function() { return gameGrid.width; });
            item.closeRequested.connect(root.closeSearch);
            item.gameLaunchRequested.connect(function(game) {
                root.closeSearch();
                root.launchGame(game);
            });
        }
    }
}
