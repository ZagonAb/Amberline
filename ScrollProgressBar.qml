import QtQuick 2.15

// Barra de progreso vertical que indica la posición actual dentro del GridView.
// No es un scrollbar clásico (no se arrastra): simplemente refleja, con una
// animación suave, qué tan avanzado está el usuario dentro de la colección.
Item {
    id: root

    // --- API pública ---
    property int currentIndex: 0
    property int count: 0
    property int columns: 1

    // Progreso 0..1 en base a la FILA actual (no al índice de tarjeta),
    // que es lo que realmente se percibe como "avance" en un grid.
    readonly property int totalRows: Math.max(1, Math.ceil(count / Math.max(1, columns)))
    readonly property int currentRow: Math.floor(currentIndex / Math.max(1, columns))
    readonly property real progress: totalRows <= 1 ? 0 : currentRow / (totalRows - 1)

    width: Math.round(6 * Style.scale)

    // --- Riel de fondo ---
    Rectangle {
        id: track
        anchors.fill: parent
        radius: width / 2
        color: Style.colorPanelAlt
        border.width: Style.borderWidth
        border.color: Style.colorBorder
    }

    // --- Indicador de progreso ---
    Rectangle {
        id: thumb
        width: parent.width
        radius: width / 2
        color: Style.colorAccent

        // Alto proporcional a cuánto "ocupa" a la vista la colección actual,
        // con un mínimo para que siempre sea visible y fácil de leer.
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
