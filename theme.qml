import QtQuick 2.15

FocusScope {
    id: themeRoot
    focus: true

    Rectangle {
        anchors.fill: parent
        color: Style.colorBackground
    }

    GameView {
        id: gameView
        anchors.fill: parent
    }

    onWidthChanged: Style.updateScale(height)
    onHeightChanged: Style.updateScale(height)

    Component.onCompleted: {
        Style.updateScale(height);

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
        gameView.focusGames();
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
}
