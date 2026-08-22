import QtQuick 2.15

Item {
    id: root

    property int currentIndex: 0
    property int count: 0
    property int columns: 1

    readonly property int totalRows: Math.max(1, Math.ceil(count / Math.max(1, columns)))
    readonly property int currentRow: Math.floor(currentIndex / Math.max(1, columns))
    readonly property real progress: totalRows <= 1 ? 0 : currentRow / (totalRows - 1)

    width: Math.round(6 * Style.scale)

    Rectangle {
        id: track
        anchors.fill: parent
        radius: width / 2
        color: Style.colorPanelAlt
        border.width: Style.borderWidth
        border.color: Style.colorBorder
    }

    Rectangle {
        id: thumb
        width: parent.width
        radius: width / 2
        color: Style.colorAccent

        readonly property real minHeightRatio: 0.08
        readonly property real heightRatio: Math.max(minHeightRatio, 1 / root.totalRows)

        height: Math.round(track.height * heightRatio)
        y: Math.round((track.height - height) * root.progress)

        Behavior on y {
            NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: Style.animationNormal }
        }
    }
}
