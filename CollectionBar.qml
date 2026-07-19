import QtQuick 2.15

Item {
    id: root

    readonly property int currentIndex: listView.currentIndex
    readonly property var currentEntry: getEntryAt(currentIndex)
    readonly property int itemWidth: Math.round(150 * Style.scale)
    readonly property int itemHeight: Math.round(34 * Style.scale)

    signal collectionSelected(var entry)
    signal ready()   // Nueva señal: modelo listo

    height: itemHeight

    function next() { listView.incrementCurrentIndex(); Qt.callLater(ensureCurrentVisible); }
    function prev() { listView.decrementCurrentIndex(); Qt.callLater(ensureCurrentVisible); }

    function setCurrentIndex(index) {
        if (entries.count === 0) return;
        var newIdx = Math.max(0, Math.min(index, entries.count - 1));
        console.log("[CollectionBar] setCurrentIndex:", index, "->", newIdx);
        listView.currentIndex = newIdx;
        ensureCurrentVisible();
    }

    function ensureCurrentVisible() {
        if (listView.count > 0 && listView.currentIndex >= 0) {
            listView.positionViewAtIndex(listView.currentIndex, ListView.Center);
        }
    }

    function findEntryByKindAndName(kind, name) {
        console.log("[CollectionBar] findEntryByKindAndName: kind=" + kind + ", name=" + name);
        if (!kind || !name) {
            console.warn("[CollectionBar] kind o name vacío");
            return -1;
        }
        var nameTrim = name.trim();
        for (var i = 0; i < entries.count; i++) {
            var e = entries.get(i);
            if (e.kind !== kind) continue;
            if (kind === "lastplayed" && nameTrim === "Last Played") return i;
            if (kind === "favorites" && nameTrim === "Favorites") return i;
            if (kind === "collection" && e.label.trim() === nameTrim) return i;
        }
        console.warn("[CollectionBar] No encontrado");
        return -1;
    }

    // Obtener entrada por índice
    function getEntryAt(index) {
        if (index < 0 || index >= entries.count) return null;
        var item = entries.get(index);
        return { kind: item.kind, collectionIndex: item.collectionIndex, label: item.label };
    }

    function setCurrentByKindAndName(kind, name) {
        console.log("[CollectionBar] setCurrentByKindAndName: kind=" + kind + ", name=" + name);
        var idx = findEntryByKindAndName(kind, name);
        if (idx >= 0) {
            var alreadyCurrent = (listView.currentIndex === idx);
            console.log("[CollectionBar][DEBUG] antes de asignar currentIndex t=" + Date.now() + " idx=" + idx + " currentItem=" + listView.currentItem + " alreadyCurrent=" + alreadyCurrent);
            listView.currentIndex = idx;
            console.log("[CollectionBar][DEBUG] después de asignar currentIndex t=" + Date.now() + " currentItem=" + listView.currentItem + " currentEntry=" + JSON.stringify(currentEntry));
            ensureCurrentVisible();
            if (alreadyCurrent) {
                if (currentEntry) {
                    root.collectionSelected(currentEntry);
                    console.log("[CollectionBar][DEBUG] collectionSelected EMITIDO manualmente (index sin cambios) t=" + Date.now());
                } else {
                    console.warn("[CollectionBar][DEBUG] collectionSelected NO emitido: currentEntry es null t=" + Date.now());
                }
            } else {
                console.log("[CollectionBar][DEBUG] currentIndex cambió, onCurrentIndexChanged emite collectionSelected (sin duplicar) t=" + Date.now());
            }
        } else {
            console.warn("[CollectionBar] No se pudo establecer, usando índice 0");
            listView.currentIndex = 0;
            ensureCurrentVisible();
        }
    }

    ListModel { id: entries }

    clip: true
    property bool modelReady: false

    Component.onCompleted: {
        entries.append({ label: "Last Played", kind: "lastplayed", collectionIndex: -1 });
        entries.append({ label: "Favorites", kind: "favorites", collectionIndex: -1 });
        for (var i = 0; i < api.collections.count; i++) {
            var c = api.collections.get(i);
            entries.append({ label: c.name, kind: "collection", collectionIndex: i });
        }
        modelReady = true;
        Qt.callLater(function() {
            root.ready();
        });
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.leftMargin: Style.spacingSmall
        anchors.rightMargin: Style.spacingSmall
        clip: false
        orientation: ListView.Horizontal
        spacing: Style.spacingSmall
        highlightMoveDuration: Style.animationFast
        model: entries

        onCurrentIndexChanged: {
            console.log("[CollectionBar] currentIndex cambió a:", currentIndex);
            var entry = root.getEntryAt(currentIndex);
            if (entry) {
                root.collectionSelected(entry);
            } else {
                console.warn("[CollectionBar][DEBUG] onCurrentIndexChanged: getEntryAt(" + currentIndex + ") devolvió null t=" + Date.now());
            }
            ensureCurrentVisible();
        }

        delegate: FocusableItem {
            id: delegateRoot
            width: itemWidth
            height: itemHeight
            isCurrent: ListView.isCurrentItem

            property var entryData: ({ kind: model.kind, collectionIndex: model.collectionIndex, label: model.label })

            Rectangle {
                anchors.fill: parent
                radius: Style.radiusPanel
                color: Style.colorPanel
                z: -1
            }

            Item {
                id: marqueeContainer
                anchors.centerIn: parent
                width: parent.width - Style.spacingSmall * 2
                height: marqueeText1.height
                clip: true

                property bool isActive: delegateRoot.isCurrent
                property bool needsScroll: marqueeText1.implicitWidth > marqueeContainer.width
                property real scrollOffset: 0
                property real cycleWidth: marqueeText1.implicitWidth + marqueeSep.implicitWidth
                property color textColor: delegateRoot.isCurrent ? Style.colorAccent : Style.colorTextPrimary
                property int scrollStartDelay: 1000

                Text {
                    id: marqueeText1
                    text: model.label
                    color: marqueeContainer.textColor
                    font.family: Fonts.pixelify
                    font.pixelSize: Style.fontSizeLarge
                    elide: marqueeContainer.isActive ? Text.ElideNone : Text.ElideRight
                    width: marqueeContainer.isActive ? implicitWidth : marqueeContainer.width
                    horizontalAlignment: Text.AlignHCenter
                    x: marqueeContainer.needsScroll ? -marqueeContainer.scrollOffset : (marqueeContainer.width - width) / 2
                    y: 0
                }

                Text {
                    id: marqueeSep
                    text: "  •  "
                    color: marqueeContainer.textColor
                    font.family: Fonts.pixelify
                    font.pixelSize: Style.fontSizeLarge
                    elide: Text.ElideNone
                    x: marqueeText1.implicitWidth - marqueeContainer.scrollOffset
                    y: 0
                    visible: marqueeContainer.needsScroll && marqueeContainer.isActive
                }

                Text {
                    id: marqueeText2
                    text: model.label
                    color: marqueeContainer.textColor
                    font.family: Fonts.pixelify
                    font.pixelSize: Style.fontSizeLarge
                    elide: Text.ElideNone
                    x: marqueeText1.implicitWidth + marqueeSep.implicitWidth - marqueeContainer.scrollOffset
                    y: 0
                    visible: marqueeContainer.needsScroll && marqueeContainer.isActive
                }

                NumberAnimation {
                    id: marqueeAnim
                    target: marqueeContainer
                    property: "scrollOffset"
                    from: 0
                    to: marqueeContainer.cycleWidth
                    duration: marqueeContainer.cycleWidth * 22
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                    running: false
                }

                Timer {
                    id: marqueeStartDelay
                    interval: marqueeContainer.scrollStartDelay
                    repeat: false
                    onTriggered: marqueeAnim.start()
                }

                onIsActiveChanged: {
                    scrollOffset = 0;
                    marqueeAnim.stop();
                    marqueeStartDelay.stop();
                    if (isActive && needsScroll) {
                        marqueeStartDelay.restart();
                    }
                }

                onNeedsScrollChanged: {
                    marqueeStartDelay.stop();
                    if (isActive && needsScroll) {
                        scrollOffset = 0;
                        marqueeStartDelay.restart();
                    } else {
                        marqueeAnim.stop();
                        scrollOffset = 0;
                    }
                }
            }
        }
    }
}
