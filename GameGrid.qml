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

    property bool favoriteConfirmVisible: false
    property int favoriteConfirmFocusIndex: 0

    readonly property bool letterFilterEnabled: sourceEntry
    && sourceEntry.kind !== "favorites"
    && sourceEntry.kind !== "lastplayed"
    property bool letterScrollActive: false
    property string letterScrollLetter: ""
    property int letterScrollCount: 0
    property int letterHoldDirection: 1
    property var letterIndex: ({})
    property var letterOrder: []

    signal gameActivated(var game)
    signal cycleImageRequested()
    signal searchRequested()

    function focusGrid() { gridView.forceActiveFocus(); }

    function buildLetterIndex() {
        var index = {};
        var order = [];
        for (var i = 0; i < gridView.count; i++) {
            var g = root.gameAt(root.sourceEntry, i);
            if (!g || !g.title) continue;
            var ch = g.title.trim().charAt(0).toUpperCase();
            var isDigit = ch >= "0" && ch <= "9";
            var isLetter = ch >= "A" && ch <= "Z";
            if (!isDigit && !isLetter) continue;
            if (!index[ch]) {
                index[ch] = { count: 0, firstIndex: i };
                order.push(ch);
            }
            index[ch].count++;
        }
        order.sort();
        root.letterIndex = index;
        root.letterOrder = order;
    }

    function jumpToLetter(letter) {
        var entry = root.letterIndex[letter];
        if (!entry) return;
        gridView.currentIndex = entry.firstIndex;
        gridView.positionViewAtIndex(entry.firstIndex, GridView.Center);
    }

    function activateLetterScroll() {
        if (!root.letterFilterEnabled || gridView.count === 0) return;
        root.buildLetterIndex();
        if (root.letterOrder.length === 0) return;

        var startLetter = "";
        var current = root.gameAt(root.sourceEntry, gridView.currentIndex);
        if (current && current.title) {
            var ch = current.title.trim().charAt(0).toUpperCase();
            if (root.letterIndex[ch]) startLetter = ch;
        }
        if (!startLetter) startLetter = root.letterOrder[0];

        root.letterScrollLetter = startLetter;
        root.letterScrollCount = root.letterIndex[startLetter].count;
        root.letterScrollActive = true;
        root.jumpToLetter(startLetter);
        letterStepTimer.start();
    }

    function advanceLetterFilter() {
        if (root.letterOrder.length === 0) return;
        var idx = root.letterOrder.indexOf(root.letterScrollLetter);
        if (idx === -1) idx = 0;
        idx = (idx + root.letterHoldDirection + root.letterOrder.length) % root.letterOrder.length;
        var letter = root.letterOrder[idx];
        root.letterScrollLetter = letter;
        root.letterScrollCount = root.letterIndex[letter].count;
        root.jumpToLetter(letter);
    }

    function deactivateLetterScroll() {
        root.letterScrollActive = false;
        letterHoldTimer.stop();
        letterStepTimer.stop();
    }

    Timer {
        id: letterHoldTimer
        interval: 500
        repeat: false
        onTriggered: root.activateLetterScroll()
    }

    Timer {
        id: letterStepTimer
        interval: 380
        repeat: true
        onTriggered: root.advanceLetterFilter()
    }

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
        if (root.letterScrollActive) root.deactivateLetterScroll();
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

    function requestFavoriteRemoval() {
        if (!root.currentGame) return;
        root.favoriteConfirmFocusIndex = 0;
        root.favoriteConfirmVisible = true;
        favoriteConfirmPopup.forceActiveFocus();
    }

    function closeFavoriteConfirm() {
        root.favoriteConfirmVisible = false;
        gridView.forceActiveFocus();
    }

    function confirmFavoriteRemoval() {
        root.toggleCurrentFavorite();
        root.closeFavoriteConfirm();
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
            blurActive: root.blurActive || root.letterScrollActive
            sourceKind: root.sourceEntry ? root.sourceEntry.kind : ""
        }

        Keys.onPressed: {
            if (count === 0) return;
            if (root.letterScrollActive && (event.key === Qt.Key_Down || event.key === Qt.Key_Up)) {
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Up && !event.isAutoRepeat && Math.floor(currentIndex / columns) === 0) {
                event.accepted = true;
                root.searchRequested();
                return;
            }

            if ((event.key === Qt.Key_Down || event.key === Qt.Key_Up) && !event.isAutoRepeat && root.letterFilterEnabled) {
                root.letterHoldDirection = (event.key === Qt.Key_Down) ? 1 : -1;
                letterHoldTimer.restart();
            }

            if (event.key === Qt.Key_Left && currentIndex === 0) {
                event.accepted = true;
                currentIndex = count - 1;
                return;
            }

            if (event.key === Qt.Key_Down) {
                var lastRow = Math.floor((count - 1) / columns);
                var currentRow = Math.floor(currentIndex / columns);
                if (currentRow === lastRow) {
                    event.accepted = true;
                    currentIndex = 0;
                    return;
                }
            }

            if (event.key === Qt.Key_Right && currentIndex === count - 1) {
                event.accepted = true;
                currentIndex = 0;
                return;
            }
        }

        Keys.onReleased: {
            if (event.isAutoRepeat) return;
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                if (root.letterScrollActive) {
                    root.deactivateLetterScroll();
                } else {
                    letterHoldTimer.stop();
                }
            }
        }

        onCurrentIndexChanged: {
            console.log("[GameGrid] currentIndex cambió a:", currentIndex);
        }
        onModelChanged: {
            console.log("[GameGrid][DEBUG] gridView.model cambió t=" + Date.now() + " count=" + count + " cellWidth=" + cellWidth.toFixed(1) + " cellHeight=" + cellHeight.toFixed(1));
            if (root.letterScrollActive) root.deactivateLetterScroll();
            if (root.letterFilterEnabled) {
                root.buildLetterIndex();
            } else {
                root.letterIndex = {};
                root.letterOrder = [];
            }
        }
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

    Item {
        id: letterOverlay
        anchors.centerIn: parent
        width: overlayCard.width
        height: overlayCard.height
        z: 50
        visible: root.letterFilterEnabled
        opacity: root.letterScrollActive ? 1 : 0
        scale: root.letterScrollActive ? 1 : 0.92

        Behavior on opacity { NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic } }

        Rectangle {
            id: overlayCard
            readonly property real baseSize: Math.min(gridView.width, gridView.height) * 0.55
            width: Math.round(Math.max(240 * Style.scale, Math.min(420 * Style.scale, baseSize)))
            height: width
            radius: Style.radiusPanel * 3
            color: Style.colorPanel
            opacity: 0.94
            border.width: Style.borderWidth * 2
            border.color: Style.colorAccent

            Column {
                anchors.centerIn: parent
                spacing: Style.spacingMedium

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.letterScrollLetter
                    color: Style.colorTextPrimary
                    font.family: Fonts.pixelify
                    font.pixelSize: Math.round(overlayCard.width * 0.42)
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.letterScrollCount + (root.letterScrollCount === 1 ? " game" : " games")
                    color: Style.colorTextSecondary
                    font.family: Fonts.smooch
                    font.pixelSize: Style.fontSizeLarge
                }
            }
        }
    }

    Keys.onPressed: {
        if (root.favoriteConfirmVisible) return;

        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
            event.accepted = true;
            if (root.currentGame) root.gameActivated(root.currentGame);
        } else if (api.keys.isDetails(event)) {
            event.accepted = true;
            if (root.sourceEntry && root.sourceEntry.kind === "favorites") {
                root.requestFavoriteRemoval();
            } else {
                root.toggleCurrentFavorite();
            }
        } else if (api.keys.isFilters(event)) {
            event.accepted = true;
            root.cycleImageRequested();
        }
    }

    FocusScope {
        id: favoriteConfirmPopup
        anchors.fill: parent
        z: 500
        visible: root.favoriteConfirmVisible
        enabled: visible

        Keys.onPressed: function(event) {
            if (event.isAutoRepeat) return;
            event.accepted = true;

            if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                root.favoriteConfirmFocusIndex = root.favoriteConfirmFocusIndex === 0 ? 1 : 0;
            } else if (api.keys.isCancel(event)) {
                root.closeFavoriteConfirm();
            } else if (api.keys.isAccept(event)) {
                if (root.favoriteConfirmFocusIndex === 1) {
                    root.confirmFavoriteRemoval();
                } else {
                    root.closeFavoriteConfirm();
                }
            } else if (api.keys.isNextPage(event) || api.keys.isPrevPage(event)) {
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.6
        }

        Rectangle {
            id: confirmCard
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.82, vpx(420))
            height: confirmColumn.height + Style.spacingLarge * 2
            radius: Style.radiusPanel * 2
            color: Style.colorPanel
            border.width: Style.borderWidth * 3
            border.color: Style.colorFocus

            Column {
                id: confirmColumn
                anchors.centerIn: parent
                width: parent.width - Style.spacingLarge * 2
                spacing: Style.spacingLarge

                Text {
                    width: parent.width
                    text: "Remove \"" + root.currentGame.title + "\" from your favorites?"
                    color: Style.colorTextPrimary
                    font.family: Fonts.smooch
                    font.pixelSize: Style.fontSizeTitle
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Style.spacingLarge

                    Rectangle {
                        id: cancelButton
                        width: vpx(120)
                        height: vpx(46)
                        radius: Style.radiusPanel
                        color: root.favoriteConfirmFocusIndex === 0 ? Style.colorAccent : Style.colorPanelAlt
                        border.width: root.favoriteConfirmFocusIndex === 0 ? Style.borderWidth * 2 : Style.borderWidth
                        border.color: root.favoriteConfirmFocusIndex === 0 ? Style.colorFocus : Style.colorBorder

                        Behavior on color { ColorAnimation { duration: Style.animationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: root.favoriteConfirmFocusIndex === 0 ? Style.colorBackground : Style.colorTextPrimary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.bold: root.favoriteConfirmFocusIndex === 0
                        }
                    }

                    Rectangle {
                        id: okButton
                        width: vpx(120)
                        height: vpx(46)
                        radius: Style.radiusPanel
                        color: root.favoriteConfirmFocusIndex === 1 ? Style.colorAccent : Style.colorPanelAlt
                        border.width: root.favoriteConfirmFocusIndex === 1 ? Style.borderWidth * 2 : Style.borderWidth
                        border.color: root.favoriteConfirmFocusIndex === 1 ? Style.colorFocus : Style.colorBorder

                        Behavior on color { ColorAnimation { duration: Style.animationFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "OK"
                            color: root.favoriteConfirmFocusIndex === 1 ? Style.colorBackground : Style.colorTextPrimary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.bold: root.favoriteConfirmFocusIndex === 1
                        }
                    }
                }
            }
        }
    }
}
