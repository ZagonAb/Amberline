import QtQuick 2.15

Item {
    id: probe

    property url source: ""
    property int thumbnailSize: 32

    property var categoryThresholds: [
        { name: "vertical", maxRatio: 0.90 },
        { name: "square",  maxRatio: 1.10 },
        { name: "horizontal", maxRatio: 1.65 },
        { name: "panoramic", maxRatio: Infinity }
    ]

    readonly property string orientation: _orientation
    readonly property bool ready: _hasResult

    signal resolved(string orientation)

    property string _orientation: "vertical"
    property bool _hasResult: false

    onSourceChanged: _hasResult = false

    Image {
        id: probeImage
        source: probe.source
        asynchronous: true
        cache: true
        visible: false
        sourceSize.width: probe.thumbnailSize

        onStatusChanged: {
            if (status === Image.Ready) {
                probe._resolve(implicitWidth, implicitHeight)
            } else if (status === Image.Error) {
                probe._resolve(0, 0)
            }
        }
    }

    function classify(ratio) {
        for (var i = 0; i < categoryThresholds.length; i++) {
            if (ratio <= categoryThresholds[i].maxRatio) {
                return categoryThresholds[i].name;
            }
        }
        return "vertical";
    }

    function _resolve(w, h) {
        var category = (w > 0 && h > 0) ? classify(w / h) : "vertical";
        _orientation = category
        _hasResult = true
        resolved(category)
    }
}
