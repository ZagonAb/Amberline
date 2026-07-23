import QtQuick 2.15

Item {
    id: colorSetting
    property real iconCenterX: 0

    signal closeMenu()
    signal themeSelected(string themeName)

    readonly property var themes: [
        { name: "dark", dotColor: "#0e1114", ringColor: "#4c77dc" },
        { name: "light", dotColor: "#eef0f4", ringColor: "#2753cc" },
        { name: "valentine", dotColor: "#1d0410", ringColor: "#e96295" },
        { name: "dracula", dotColor: "#0a0c21", ringColor: "#b887ff" },
        { name: "nord", dotColor: "#061126", ringColor: "#82c5d8" },
        { name: "coffee", dotColor: "#151108", ringColor: "#e9a633" },
        { name: "tokyonight", dotColor: "#090b1e", ringColor: "#6b9aff" },
        { name: "retro", dotColor: "#1c1207", ringColor: "#f1b894" },
        { name: "abyss", dotColor: "#031610", ringColor: "#7bc87b" },
        { name: "cyberpunk", dotColor: "#09031a", ringColor: "#faf027" },
        { name: "aqua", dotColor: "#001519", ringColor: "#00dcdc" },
        { name: "palenight", dotColor: "#0a0e23", ringColor: "#7181d3" },
        { name: "horizon", dotColor: "#1a0912", ringColor: "#e9466f" },
        { name: "oled", dotColor: "#000000", ringColor: "#00e5ff" }
    ]

    property int highlightIndex: 5

    function _indexForTheme(themeName) {
        for (var i = 0; i < themes.length; i++) {
            if (themes[i].name === themeName) return i;
        }
        return highlightIndex;
    }

    onVisibleChanged: {
        if (visible) {
            highlightIndex = colorSetting._indexForTheme(Style.currentThemeName);
        } else {
            _previewTimer.stop();
            var t = colorSetting.themes[colorSetting.highlightIndex];
            colorSetting.themeSelected(t.name);
        }
    }

    readonly property int _previewDelay: 140

    onHighlightIndexChanged: _previewTimer.restart()

    Timer {
        id: _previewTimer
        interval: colorSetting._previewDelay
        repeat: false
        onTriggered: {
            var t = colorSetting.themes[colorSetting.highlightIndex];
            Style.previewTheme(t.name);
        }
    }

    readonly property int _circleSize: vpx(38)
    readonly property int _itemWidth: vpx(48)
    readonly property int _hPad: vpx(10)
    readonly property int _vPad: vpx(10)

    width: themes.length * _itemWidth + _hPad * 2
    height: tail.height + bubble.height

    visible: false
    focus: false

    Canvas {
        id: tail
        width: vpx(26)
        height: vpx(18)
        x: Math.max(0, Math.min(
            colorSetting.iconCenterX - width / 2,
            colorSetting.width - width
        ))
        anchors.top: parent.top
        z: 2

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = Style.colorPanel;
            ctx.beginPath();
            ctx.moveTo(0, height);
            ctx.lineTo(width / 2, 0);
            ctx.lineTo(width, height);
            ctx.closePath();
            ctx.fill();
        }

        Connections {
            target: Style
            function onColorPanelChanged() { tail.requestPaint(); }
        }
    }

    Rectangle {
        id: bubble
        anchors.top: tail.bottom
        anchors.topMargin: vpx(-1)
        width: parent.width
        height: circlesRow.height + _vPad * 4
        color: Style.colorPanel
        radius: Style.radiusPanel

        Row {
            id: circlesRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: colorSetting._hPad
            spacing: 0

            Repeater {
                model: colorSetting.themes

                delegate: Item {
                    id: themeItem
                    width: colorSetting._itemWidth
                    height: colorSetting._circleSize

                    readonly property bool isCurrent: colorSetting.highlightIndex === index
                    readonly property int _ringWidth: vpx(2)

                    Rectangle {
                        id: dot
                        width: colorSetting._circleSize
                        height: colorSetting._circleSize
                        radius: width / 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: modelData.dotColor
                        border.width: themeItem.isCurrent ? vpx(3) : themeItem._ringWidth
                        border.color: themeItem.isCurrent ? Style.colorFocus : modelData.ringColor

                        Behavior on border.width {
                            NumberAnimation { duration: Style.animationFast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Style.animationFast }
                        }

                        scale: themeItem.isCurrent ? 1.18 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: Style.animationFast
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: function(event) {
        if ((api.keys.isCancel(event) || api.keys.isAccept(event)) && !event.isAutoRepeat) {
            event.accepted = true;
            colorSetting.closeMenu();

        } else if (event.key === Qt.Key_Left && !event.isAutoRepeat) {
            event.accepted = true;
            colorSetting.highlightIndex = Math.max(0, colorSetting.highlightIndex - 1);

        } else if (event.key === Qt.Key_Right && !event.isAutoRepeat) {
            event.accepted = true;
            colorSetting.highlightIndex = Math.min(
                colorSetting.themes.length - 1,
                colorSetting.highlightIndex + 1
            );

        } else if (api.keys.isPrevPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            colorSetting.highlightIndex = Math.max(0, colorSetting.highlightIndex - 1);

        } else if (api.keys.isNextPage(event) && !event.isAutoRepeat) {
            event.accepted = true;
            colorSetting.highlightIndex = Math.min(
                colorSetting.themes.length - 1,
                colorSetting.highlightIndex + 1
            );
        }
    }
}
