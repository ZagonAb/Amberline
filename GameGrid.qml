import QtQuick 2.15
import SortFilterProxyModel 0.2

FocusScope {
    id: root
    clip: true

    property var sourceEntry: null
    readonly property var currentGame: gridView.count > 0 && gridView.currentItem
        ? gridView.currentItem.game
        : null
    readonly property int currentGameIndex: gridView.currentIndex
    readonly property int gameCount: gridView.count

    property bool blurActive: false

    signal gameActivated(var game)
    signal cycleImageRequested()

    function focusGrid() { gridView.forceActiveFocus(); }

    function selectGameByTitle(title) {
        console.log("[GameGrid] selectGameByTitle: buscando '" + title + "'");
        if (!title || gridView.count === 0) {
            console.warn("[GameGrid] Título vacío o grid vacío");
            return;
        }

        var isCollection = root.sourceEntry && root.sourceEntry.kind === "collection";
        for (var i = 0; i < gridView.count; i++) {
            var game;
            if (isCollection) {
                game = gridView.model.get(i);
            } else {
                var idx = gridView.model.mapToSource(i);
                game = api.allGames.get(idx);
            }
            if (game && game.title === title) {
                console.log("[GameGrid] Encontrado juego en índice", i);
                gridView.currentIndex = i;
                return;
            }
        }
        console.warn("[GameGrid] No se encontró el juego '" + title + "'");
    }

    readonly property int cellSpacing: Style.spacingMedium
    readonly property int minCardWidth: Math.round(120 * Style.scale)
    readonly property int gridMargin: Style.spacingSmall
    readonly property real availableGridWidth: width - gridMargin * 2
    readonly property int columns: Math.max(1, Math.floor(availableGridWidth / (minCardWidth + cellSpacing)))
    readonly property real cardWidth: (availableGridWidth / columns) - cellSpacing
    readonly property real cardHeight: cardWidth * 1.4

    SortFilterProxyModel {
        id: favoritesModel
        sourceModel: api.allGames
        filters: ValueFilter { roleName: "favorite"; value: true }
        sorters: RoleSorter { roleName: "title" }
    }

    SortFilterProxyModel {
        id: lastPlayedModel
        sourceModel: api.allGames
        filters: ValueFilter { roleName: "playCount"; value: 0; inverted: true }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }

    function resolveModel(entry) {
        if (!entry) return null;
        switch (entry.kind) {
            case "favorites": return favoritesModel;
            case "lastplayed": return lastPlayedModel;
            case "collection": return api.collections.get(entry.collectionIndex).games;
            default: return null;
        }
    }

    onSourceEntryChanged: {
        console.log("[GameGrid] sourceEntryChanged, kind:", sourceEntry ? sourceEntry.kind : "null");
        gridView.model = resolveModel(sourceEntry);
        gridView.currentIndex = 0;
    }

    function toggleCurrentFavorite() {
        var game = root.currentGame;
        if (!game) return;
        var idx = gridView.currentIndex;
        game.favorite = !game.favorite;
        Qt.callLater(function() {
            if (gridView.count === 0) return;
            gridView.currentIndex = Math.min(idx, gridView.count - 1);
        });
    }

    GridView {
        id: gridView
        anchors.fill: parent
        anchors.leftMargin: gridMargin
        anchors.rightMargin: gridMargin
        anchors.topMargin: gridMargin
        clip: false
        focus: true
        keyNavigationEnabled: true
        keyNavigationWraps: false
        cellWidth: cardWidth + cellSpacing
        cellHeight: cardHeight + cellSpacing
        cacheBuffer: cellHeight * 4

        delegate: GameCard {
            width: cardWidth
            height: cardHeight
            game: modelData
            isCurrent: GridView.isCurrentItem
            blurActive: root.blurActive
        }

        onCurrentIndexChanged: {
            console.log("[GameGrid] currentIndex cambió a:", currentIndex);
        }
    }

    Text {
        anchors.centerIn: parent
        width: gridView.width * 0.7
        visible: gridView.count === 0
        text: root.sourceEntry && root.sourceEntry.kind === "favorites"
        ? "Every favorite begins with a great game. Mark the ones you love and they'll appear here."
        : (root.sourceEntry && root.sourceEntry.kind === "lastplayed" ? "Your adventure hasn't begun yet. Launch a game and your recent journey will appear here." : "")
        color: Style.colorTextSecondary
        font.family: Fonts.smooch
        font.pixelSize: Style.fontSizeTitle
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }

    Keys.onPressed: {
        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
            event.accepted = true;
            if (root.currentGame) root.gameActivated(root.currentGame);
        } else if (api.keys.isDetails(event)) {
            event.accepted = true;
            root.toggleCurrentFavorite();
        } else if (api.keys.isFilters(event)) {
            event.accepted = true;
            root.cycleImageRequested();
        }
    }
}
