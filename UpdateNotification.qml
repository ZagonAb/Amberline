import QtQuick 2.15

FocusScope {
    id: notification
    anchors.fill: parent
    z: 1000
    visible: false
    opacity: 0

    focus: visible

    property string latestVersion: ""
    property string releaseUrl: ""
    property string releaseNotes: ""
    property bool expanded: false

    function show(version, url, notes) {
        console.log("[UpdateNotification] show() llamado con version=" + version + ", url=" + url);
        latestVersion = version;
        releaseUrl = url;
        releaseNotes = notes || "";
        expanded = false;
        visible = true;
        opacity = 1;
        noticeTimer.restart();
        notification.forceActiveFocus();
        viewButton.forceActiveFocus();
        console.log("[UpdateNotification] Foco forzado a viewButton");
    }

    Timer {
        id: noticeTimer
        interval: 220
        repeat: false
        onTriggered: SoundsEffects.playNotice()
    }

    function hide() {
        console.log("[UpdateNotification] hide() llamado");
        opacity = 0;
        visible = false;
        console.log("[UpdateNotification] visible=" + visible + ", opacity=" + opacity);
        if (gameView) gameView.focusGames();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
            onStarted: console.log("[UpdateNotification] Animación de opacidad iniciada")
            onFinished: console.log("[UpdateNotification] Animación de opacidad terminada")
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.6
        MouseArea {
            anchors.fill: parent
            onClicked: notification.hide()
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.85, 500 * Style.scale)
        height: column.height + Style.spacingLarge * 2
        radius: Style.radiusPanel * 2
        color: Style.colorPanel
        border.color: Style.colorAccent
        border.width: Style.borderWidth * 2

        Behavior on height {
            NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutQuad }
        }

        Column {
            id: column
            anchors.centerIn: parent
            width: parent.width - Style.spacingLarge * 2
            spacing: Style.spacingMedium

            Text {
                width: parent.width
                text: "✨ New update available"
                color: Style.colorAccent
                font.family: Fonts.pixelify
                font.pixelSize: Style.fontSizeTitle * 1.2
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: "Amberline " + latestVersion + " is now available."
                color: Style.colorTextPrimary
                font.family: Fonts.smooch
                font.pixelSize: Style.fontSizeLarge
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.spacingMedium

                Rectangle {
                    id: viewButton
                    width: 120 * Style.scale
                    height: 40 * Style.scale
                    radius: Style.radiusPanel
                    color: Style.colorAccent
                    border.color: activeFocus ? Style.colorFocus : Style.colorBorder
                    border.width: activeFocus ? Style.borderWidth * 2 : Style.borderWidth
                    focus: true

                    Behavior on border.width {
                        NumberAnimation { duration: Style.animationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "View changes"
                        color: Style.colorBackground
                        font.family: Fonts.smooch
                        font.pixelSize: Style.fontSizeLarge
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("[UpdateNotification] View changes clickeado, expanded=" + !notification.expanded);
                            notification.expanded = !notification.expanded;
                        }
                    }

                    Keys.onPressed: {
                        console.log("[UpdateNotification] viewButton Keys.onPressed key=" + event.key);
                        if (api.keys.isAccept(event)) {
                            event.accepted = true;
                            SoundsEffects.playAccept();
                            console.log("[UpdateNotification] Toggle expanded a " + !notification.expanded);
                            notification.expanded = !notification.expanded;
                        } else if (api.keys.isCancel(event)) {
                            event.accepted = true;
                            SoundsEffects.playCancel();
                            notification.hide();
                        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                            event.accepted = true;
                            SoundsEffects.playDown();
                            openButton.forceActiveFocus();
                        }
                    }
                }

                Rectangle {
                    id: openButton
                    width: 140 * Style.scale
                    height: 40 * Style.scale
                    radius: Style.radiusPanel
                    color: Style.colorPanelAlt
                    border.color: activeFocus ? Style.colorFocus : Style.colorBorder
                    border.width: activeFocus ? Style.borderWidth * 2 : Style.borderWidth
                    focus: false

                    Behavior on border.width {
                        NumberAnimation { duration: Style.animationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Open on GitHub"
                        color: Style.colorTextPrimary
                        font.family: Fonts.smooch
                        font.pixelSize: Style.fontSizeLarge
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("[UpdateNotification] Open on GitHub clickeado");
                            if (notification.releaseUrl) {
                                console.log("[UpdateNotification] Abriendo URL:", notification.releaseUrl);
                                Qt.openUrlExternally(notification.releaseUrl);
                            }
                            notification.hide();
                        }
                    }

                    Keys.onPressed: {
                        console.log("[UpdateNotification] openButton Keys.onPressed key=" + event.key);
                        if (api.keys.isAccept(event)) {
                            event.accepted = true;
                            SoundsEffects.playAccept();
                            if (notification.releaseUrl) {
                                console.log("[UpdateNotification] Abriendo URL (teclado):", notification.releaseUrl);
                                Qt.openUrlExternally(notification.releaseUrl);
                            }
                            notification.hide();
                        } else if (api.keys.isCancel(event)) {
                            event.accepted = true;
                            SoundsEffects.playCancel();
                            notification.hide();
                        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                            event.accepted = true;
                            SoundsEffects.playUp();
                            viewButton.forceActiveFocus();
                        } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                            event.accepted = true;
                            SoundsEffects.playDown();
                            closeButton.forceActiveFocus();
                        }
                    }
                }

                Rectangle {
                    id: closeButton
                    width: 120 * Style.scale
                    height: 40 * Style.scale
                    radius: Style.radiusPanel
                    color: Style.colorPanelAlt
                    border.color: activeFocus ? Style.colorFocus : Style.colorBorder
                    border.width: activeFocus ? Style.borderWidth * 2 : Style.borderWidth
                    focus: false

                    Behavior on border.width {
                        NumberAnimation { duration: Style.animationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        color: Style.colorTextPrimary
                        font.family: Fonts.smooch
                        font.pixelSize: Style.fontSizeLarge
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("[UpdateNotification] Close clickeado");
                            notification.hide();
                        }
                    }

                    Keys.onPressed: {
                        console.log("[UpdateNotification] closeButton Keys.onPressed key=" + event.key);
                        if (api.keys.isAccept(event) || api.keys.isCancel(event)) {
                            event.accepted = true;
                            SoundsEffects.playCancel();
                            notification.hide();
                        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                            event.accepted = true;
                            SoundsEffects.playUp();
                            openButton.forceActiveFocus();
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: notification.expanded && notification.releaseNotes.length > 0
                text: notification.releaseNotes
                color: Style.colorTextSecondary
                font.family: Fonts.smooch
                font.pixelSize: Style.fontSizeMediumLarge
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Keys.onPressed: {
        console.log("[UpdateNotification] Keys.onPressed (FocusScope) key=" + event.key);
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            SoundsEffects.playCancel();
            console.log("[UpdateNotification] Cancel presionado, ocultando");
            hide();
        }
    }

    Component.onCompleted: {
        console.log("[UpdateNotification] Component.onCompleted");
    }
    Component.onDestruction: {
        console.log("[UpdateNotification] Component.onDestruction");
    }
}
