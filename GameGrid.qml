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
    readonly property int gridMargin: Style.spacingSmall
    readonly property real availableGridWidth: width - gridMargin * 2
    property string collectionOrientation: "vertical"
    property var _orientationCache: ({})
    property bool orientationResolved: false
    readonly property var activeProfile: Style.gridLayoutProfiles[collectionOrientation] || Style.gridLayoutProfiles.vertical
    readonly property int dynamicColumns: Math.max(1, Math.floor(availableGridWidth / (activeProfile.minCardWidth + cellSpacing)))
    readonly property int effectiveTargetColumns: (Style.isNarrowScreen && activeProfile.targetColumnsNarrow !== undefined)
        ? activeProfile.targetColumnsNarrow
        : activeProfile.targetColumns
    readonly property int columns: effectiveTargetColumns > 0
        ? Math.max(1, Math.min(effectiveTargetColumns, dynamicColumns))
        : dynamicColumns

    readonly property real cardWidth: (availableGridWidth / columns) - cellSpacing
    readonly property real cardHeight: cardWidth * activeProfile.heightRatio

    onColumnsChanged: console.log("[GameGrid][DEBUG] columns cambió a " + columns + " t=" + Date.now() + " orientationResolved=" + orientationResolved + " collectionOrientation=" + collectionOrientation + " gridView.count=" + gridView.count)
    onCollectionOrientationChanged: console.log("[GameGrid][DEBUG] collectionOrientation cambió a " + collectionOrientation + " t=" + Date.now())
    onOrientationResolvedChanged: console.log("[GameGrid][DEBUG] orientationResolved cambió a " + orientationResolved + " t=" + Date.now())
    onCardWidthChanged: console.log("[GameGrid][DEBUG] cardWidth cambió a " + cardWidth.toFixed(1) + " t=" + Date.now())
    onCardHeightChanged: console.log("[GameGrid][DEBUG] cardHeight cambió a " + cardHeight.toFixed(1) + " t=" + Date.now())

    function orientationCacheKey(entry) {
        if (!entry) return "none";
        return entry.kind === "collection" ? ("col:" + entry.collectionIndex) : ("kind:" + entry.kind);
    }

    function gameAt(entry, index) {
        if (!entry) return null;
        var model = resolveModel(entry);
        if (!model || model.count <= index) return null;
        if (entry.kind === "collection") return model.get(index);
        return api.allGames.get(model.mapToSource(index));
    }

    function applyModelForCurrentEntry() {
        console.log("[GameGrid][DEBUG] applyModelForCurrentEntry t=" + Date.now() + " kind=" + (sourceEntry ? sourceEntry.kind : "null") + " orientation=" + collectionOrientation + " columns=" + columns);
        gridView.model = resolveModel(sourceEntry);
        gridView.currentIndex = 0;
    }

    function updateOrientation() {
        var key = orientationCacheKey(sourceEntry);
        console.log("[GameGrid][DEBUG] updateOrientation t=" + Date.now() + " key=" + key + " isNarrowScreen=" + Style.isNarrowScreen + " screenAspectRatio=" + Style.screenAspectRatio.toFixed(4));

        if (root._orientationCache.hasOwnProperty(key)) {
            root.collectionOrientation = root._orientationCache[key];
            root.orientationResolved = true;
            aspectProbe.source = "";
            console.log("[GameGrid][DEBUG] updateOrientation HIT de cache t=" + Date.now() + " key=" + key + " orientation=" + root.collectionOrientation);
            applyModelForCurrentEntry();
            return;
        }

        root.orientationResolved = false;
        var game = root.gameAt(sourceEntry, 0);
        var src = game ? (game.assets.boxFront !== "" ? game.assets.boxFront : game.assets.cartridge) : "";
        console.log("[GameGrid][DEBUG] updateOrientation MISS de cache t=" + Date.now() + " key=" + key + " game=" + (game ? game.title : "null") + " src=" + src);

        if (src === "") {
            root._orientationCache[key] = "vertical";
            root.collectionOrientation = "vertical";
            root.orientationResolved = true;
            aspectProbe.source = "";
            console.log("[GameGrid][DEBUG] updateOrientation sin src, fallback vertical t=" + Date.now());
            applyModelForCurrentEntry();
            return;
        }

        aspectProbe.pendingKey = key;
        aspectProbe.source = src;
        console.log("[GameGrid][DEBUG] updateOrientation disparando aspectProbe async t=" + Date.now() + " pendingKey=" + key);
    }

    AspectProbe {
        id: aspectProbe
        property string pendingKey: ""
        onResolved: {
            var currentKey = root.orientationCacheKey(root.sourceEntry);
            console.log("[GameGrid][DEBUG] aspectProbe.onResolved t=" + Date.now() + " pendingKey=" + pendingKey + " orientation=" + orientation + " currentKey=" + currentKey + " seAplica=" + (currentKey === pendingKey));
            root._orientationCache[pendingKey] = orientation;

            if (currentKey === pendingKey) {
                root.collectionOrientation = orientation;
                root.orientationResolved = true;
                root.applyModelForCurrentEntry();
            }
        }
    }

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
        console.log("[GameGrid][DEBUG] sourceEntryChanged t=" + Date.now() + " kind:", sourceEntry ? sourceEntry.kind : "null", " label:", sourceEntry ? sourceEntry.label : "null");
        root.orientationResolved = false;
        updateOrientation();
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
        onModelChanged: console.log("[GameGrid][DEBUG] gridView.model cambió t=" + Date.now() + " count=" + count + " cellWidth=" + cellWidth.toFixed(1) + " cellHeight=" + cellHeight.toFixed(1))
        onCountChanged: console.log("[GameGrid][DEBUG] gridView.count cambió a " + count + " t=" + Date.now() + " cellWidth=" + cellWidth.toFixed(1) + " cellHeight=" + cellHeight.toFixed(1))
        onCellWidthChanged: console.log("[GameGrid][DEBUG] gridView.cellWidth cambió a " + cellWidth.toFixed(1) + " t=" + Date.now())
        onCellHeightChanged: console.log("[GameGrid][DEBUG] gridView.cellHeight cambió a " + cellHeight.toFixed(1) + " t=" + Date.now())
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
