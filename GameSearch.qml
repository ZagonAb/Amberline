import QtQuick 2.15

FocusScope {
    id: root
    anchors.fill: parent

    signal closeRequested()
    signal gameLaunchRequested(var game)

    property real targetX: 0
    property real targetWidth: parent.width

    property int maxResults: 150
    property var resultsList: []
    property bool hasSearched: false
    property string lastQuery: ""

    function normalizeForSearch(text) {
        if (!text) return "";
        return text.toLowerCase()
            .replace(/[áàäâã]/g, "a")
            .replace(/[éèëê]/g, "e")
            .replace(/[íìïî]/g, "i")
            .replace(/[óòöôõ]/g, "o")
            .replace(/[úùüû]/g, "u")
            .replace(/[ñ]/g, "n")
            .replace(/[ç]/g, "c")
            .trim();
    }

    function cleanAndSplitGenres(genreText) {
        if (!genreText) return [];

        var separators = [",", "/", "-", "&", "|", ";"];
        var allParts = [genreText];

        for (var i = 0; i < separators.length; i++) {
            var separator = separators[i];
            var newParts = [];

            for (var j = 0; j < allParts.length; j++) {
                var part = allParts[j];
                var splitParts = part.split(separator);

                for (var k = 0; k < splitParts.length; k++) {
                    newParts.push(splitParts[k]);
                }
            }
            allParts = newParts;
        }

        var cleanedParts = [];
        for (var l = 0; l < allParts.length; l++) {
            var cleaned = allParts[l].trim();

            if (cleaned.length > 0 &&
                cleaned.toLowerCase() !== "and" &&
                cleaned.toLowerCase() !== "or" &&
                cleaned.toLowerCase() !== "game" &&
                cleaned.length > 2) {
                cleanedParts.push(cleaned);
            }
        }

        return cleanedParts;
    }

    function getFirstGenre(gameData) {
        if (!gameData || !gameData.genre) return "Unknown";
        var cleanedGenres = cleanAndSplitGenres(gameData.genre);
        return cleanedGenres.length > 0 ? cleanedGenres[0] : "Unknown";
    }

    function executeSearch() {
        var q = searchInput.text.trim();
        root.lastQuery = q;
        root.hasSearched = true;

        if (q === "") {
            root.resultsList = [];
            resultsView.currentIndex = -1;
            return;
        }

        var needle = normalizeForSearch(q);
        var out = [];
        for (var i = 0; i < api.allGames.count && out.length < root.maxResults; i++) {
            var g = api.allGames.get(i);
            if (root.matchesGame(g, needle)) out.push(g);
        }

        root.resultsList = out;
        resultsView.currentIndex = out.length > 0 ? 0 : -1;

        if (out.length > 0) {
            resultsView.forceActiveFocus();
        } else {
            searchInput.forceActiveFocus();
        }
    }

    function matchesGame(game, needle) {
        var fields = [
            game.title || "",
            game.developer || "",
            game.publisher || "",
            game.genre || "",
            getFirstGenre(game),
            game.releaseYear ? String(game.releaseYear) : "",
            Math.round((game.rating || 0) * 100) + "%"
        ];

        for (var i = 0; i < fields.length; i++) {
            var normalized = normalizeForSearch(fields[i]);
            if (normalized.indexOf(needle) !== -1) return true;
        }

        return false;
    }

    function collectionNameForGame(game) {
        if (game && game.collections && game.collections.count > 0) {
            return game.collections.get(0).name;
        }
        return "";
    }

    function launchGame(game) {
        if (!game) return;
        root.gameLaunchRequested(game);
    }

    Component.onCompleted: searchInput.forceActiveFocus()

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.65

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Column {
        id: panelColumn
        x: root.targetX + (root.targetWidth - width) / 2
        anchors.top: parent.top
        anchors.topMargin: Math.round(parent.height * 0.12)
        width: root.targetWidth * 0.9
        spacing: Style.spacingSmall

        Rectangle {
            id: searchBar
            width: parent.width
            height: Math.round(58 * Style.scale)
            radius: Style.radiusPanel * 2
            color: Style.colorPanel
            border.width: Style.borderWidth * 3
            border.color: searchInput.activeFocus ? Style.colorFocus : Style.colorBorder

            Behavior on border.color { ColorAnimation { duration: Style.animationFast } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Style.spacingMedium
                anchors.rightMargin: Style.spacingMedium
                spacing: Style.spacingMedium

                Item {
                    id: searchIconWrapper
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.fontSizeTitle
                    height: Style.fontSizeTitle

                    IconImage {
                        id: searchSvgIcon
                        anchors.fill: parent
                        iconName: "search"
                        overlayColor: searchInput.activeFocus ? Style.colorFocus : Style.colorTextSecondary
                        Behavior on overlayColor { ColorAnimation { duration: Style.animationFast } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "\u{1F50D}"
                        color: searchInput.activeFocus ? Style.colorFocus : Style.colorTextSecondary
                        font.pixelSize: Style.fontSizeTitle
                        visible: searchSvgIcon.children[0] === undefined
                              || searchSvgIcon.children[0].status !== Image.Ready
                        Behavior on color { ColorAnimation { duration: Style.animationFast } }
                    }
                }

                TextInput {
                    id: searchInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Math.round(40 * Style.scale) - Style.spacingMedium
                    color: Style.colorTextPrimary
                    font.family: Fonts.smooch
                    font.pixelSize: Style.fontSizeTitle
                    clip: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Search by title, dev, pub, year, genre..."
                        color: Style.colorTextSecondary
                        opacity: 0.6
                        font: searchInput.font
                        visible: searchInput.text.length === 0
                    }

                    Keys.onPressed: function(event) {
                        if (!event.isAutoRepeat && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || api.keys.isAccept(event))) {
                            event.accepted = true;
                            root.executeSearch();
                        } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                            if (searchInput.text.length > 0) {
                                event.accepted = false;
                            } else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                                event.accepted = true;
                                root.closeRequested();
                            } else {
                                event.accepted = false;
                            }
                        } else if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                            event.accepted = true;
                            root.closeRequested();
                        } else if (!event.isAutoRepeat && event.key === Qt.Key_Down && root.resultsList.length > 0) {
                            event.accepted = true;
                            resultsView.forceActiveFocus();
                        } else {
                            event.accepted = false;
                        }
                    }
                }
            }
        }

        Rectangle {
            id: resultsPanel
            width: parent.width
            visible: root.hasSearched
            height: visible ? Math.min(Math.round(440 * Style.scale), Math.max(Math.round(76 * Style.scale), resultsView.contentHeight + Style.spacingSmall * 2)) : 0
            radius: Style.radiusPanel * 2
            color: Style.colorPanel
            border.width: Style.borderWidth * 3
            border.color: Style.colorBorder
            clip: true

            Behavior on height { NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                visible: root.resultsList.length === 0
                text: "No results for \"" + root.lastQuery + "\""
                color: Style.colorTextSecondary
                font.family: Fonts.smooch
                font.pixelSize: Style.fontSizeLarge * 1.2
            }

            ListView {
                id: resultsView
                anchors.fill: parent
                anchors.margins: Style.spacingSmall
                clip: true
                visible: root.resultsList.length > 0
                model: root.resultsList
                currentIndex: -1
                keyNavigationWraps: false
                cacheBuffer: Math.round(400 * Style.scale)

                highlightMoveDuration: 0
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: Math.round(resultsView.height * 0.15)
                preferredHighlightEnd: Math.round(resultsView.height * 0.85)

                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain)
                }

                delegate: Rectangle {
                    width: resultsView.width
                    height: itemColumn.implicitHeight + Style.spacingMedium * 2
                    radius: Style.radiusPanel
                    color: ListView.isCurrentItem ? Style.colorAccentDim : "transparent"

                    Behavior on color { ColorAnimation { duration: Style.animationFast } }

                    Column {
                        id: rightInfo
                        anchors.right: parent.right
                        anchors.rightMargin: Style.spacingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.spacingTiny

                        Text {
                            id: yearText
                            anchors.right: parent.right
                            text: modelData.releaseYear > 0 ? String(modelData.releaseYear) : ""
                            color: Style.colorTextSecondary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.bold: true
                            visible: text.length > 0
                        }
                        Text {
                            id: ratingText
                            anchors.right: parent.right
                            text: Math.round(modelData.rating * 100) + "%"
                            color: Style.colorTextSecondary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.bold: true
                            visible: modelData.rating > 0
                        }
                    }

                    Column {
                        id: itemColumn
                        anchors.left: parent.left
                        anchors.leftMargin: Style.spacingMedium
                        anchors.right: rightInfo.left
                        anchors.rightMargin: Style.spacingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Style.spacingTiny

                        Text {
                            text: modelData.title
                            color: Style.colorTextPrimary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeTitle
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        Text {
                            text: [
                                root.collectionNameForGame(modelData),
                                modelData.developer,
                                root.getFirstGenre(modelData)
                            ].filter(function(s) { return s && s.length; }).join(" · ")
                            color: Style.colorTextSecondary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                Keys.onPressed: function(event) {
                    if (event.isAutoRepeat) return;

                    if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        var g = root.resultsList[resultsView.currentIndex];
                        if (g) root.launchGame(g);
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        searchInput.forceActiveFocus();
                    } else if (event.key === Qt.Key_Up && resultsView.currentIndex === 0) {
                        event.accepted = true;
                        searchInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    Keys.onPressed: function(event) {
        if (!event.isAutoRepeat && api.keys.isCancel(event) && !searchInput.activeFocus && !resultsView.activeFocus) {
            event.accepted = true;
            root.closeRequested();
        }
    }
}