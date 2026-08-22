import QtQuick 2.15
import QtGraphicalEffects 1.12

FocusScope {
    id: root

    property bool isOpen: false
    readonly property bool buttonFocused: _okBtn.activeFocus || _cancelBtn.activeFocus
    readonly property bool credentialsHasText: _userInput.text.length > 0 || _keyInput.text.length > 0

    signal credentialsSaved()
    signal popupClosed()
    signal userInputActivated()
    signal keyInputActivated()

    readonly property color _popupBg: Style.colorPanel
    readonly property color _borderColor: Style.colorBorder
    readonly property color _titleText: Style.colorTextPrimary
    readonly property color _labelText: Style.colorTextSecondary
    readonly property color _inputBg: Style.colorPanelAlt
    readonly property color _inputBgActive: Style.colorPanelAlt
    readonly property color _inputBorder: Style.colorBorder
    readonly property color _inputBorderActive: Style.colorFocus
    readonly property color _inputText: Style.colorTextPrimary
    readonly property color _placeholderText: Style.colorTextSecondary
    readonly property color _cursorColor: Style.colorTextPrimary
    readonly property color _separator: Style.colorBorder
    readonly property color _msgBgTesting: Style.colorPanelAlt
    readonly property color _msgBgSuccess: "#2E7D32"
    readonly property color _msgBgError: "#C62828"
    readonly property color _msgTextTesting: Style.colorTextSecondary
    readonly property color _msgTextSuccess: "#efcdcd"
    readonly property color _msgTextError: "#efcdcd"
    readonly property color _okBtnBg: Style.colorPanelAlt
    readonly property color _okBtnBgFocus: Style.colorAccent
    readonly property color _okBtnText: Style.colorTextPrimary
    readonly property color _okBtnTextFocus: Style.colorBackground
    readonly property color _cancelBtnBg: Style.colorPanelAlt
    readonly property color _cancelBtnBgFocus: "#C62828"
    readonly property color _cancelBtnBorder: Style.colorBorder
    readonly property color _cancelBtnBorderFocus: "#E53935"
    readonly property color _cancelBtnText: Style.colorTextSecondary
    readonly property color _cancelBtnTextFocus: "#efcdcd"

    property string _testState: "idle"
    property string _testMsg: ""
    property string _activeField: "none"

    function appendToUser(ch) {
        if (_testState !== "testing") _userInput.text += ch
    }
    function backspaceUser() {
        if (_testState !== "testing" && _userInput.text.length > 0)
            _userInput.text = _userInput.text.slice(0, -1)
    }
    function appendToKey(ch) {
        if (_testState !== "testing") _keyInput.text += ch
    }
    function backspaceKey() {
        if (_testState !== "testing" && _keyInput.text.length > 0)
            _keyInput.text = _keyInput.text.slice(0, -1)
    }

    function focusFieldSafe(field) {
        if (field === "key") _keyFieldScope.forceActiveFocus()
            else _userFieldScope.forceActiveFocus()
    }

    function _activateField(field) {
        root._activeField = field
        if (field === "key") {
            _keyFieldScope.forceActiveFocus()
            _keyInput.forceActiveFocus()
            root.keyInputActivated()
        } else {
            _userFieldScope.forceActiveFocus()
            _userInput.forceActiveFocus()
            root.userInputActivated()
        }
    }

    function open() {
        _userInput.text = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
        _keyInput.text = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
        _testState = "idle"
        _testMsg = ""
        isOpen = true
        _focusTimer.start()
    }

    function close() {
        isOpen = false
        root._activeField = "none"
        root.popupClosed()
    }

    function _save() {
        var u = _userInput.text.trim()
        var k = _keyInput.text.trim()
        if (u === "" || k === "") {
            _testState = "error"
            _testMsg = "Both fields are required."
            return
        }
        api.memory.set("ra_api_user", u)
        api.memory.set("ra_api_key", k)
        _testState = "testing"
        _testMsg = ""
        _testConnection(u, k)
    }

    function _testConnection(user, key) {
        var url = "https://retroachievements.org/API/API_GetUserSummary.php"
        + "?y=" + encodeURIComponent(key)
        + "&u=" + encodeURIComponent(user)
        + "&g=1"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data && (data.User || data.Username || data.MemberSince)) {
                            var displayName = data.User || data.Username || user
                            _testState = "success"
                            _testMsg = "Connected as " + displayName
                            _closeTimer.start()
                        } else {
                            _testState = "error"
                            _testMsg = "Invalid credentials. Check your API User and Key."
                        }
                    } catch(e) {
                        _testState = "error"
                        _testMsg = "Could not parse server response."
                    }
                } else if (xhr.status === 0) {
                    _testState = "success"
                    _testMsg = "Saved. (No network — could not verify)"
                    _closeTimer.start()
                } else {
                    _testState = "error"
                    _testMsg = "Server error: HTTP " + xhr.status
                }
        }
        xhr.send()
    }

    Timer {
        id: _closeTimer
        interval: 1400
        onTriggered: {
            isOpen = false
            root.credentialsSaved()
        }
    }

    Timer {
        id: _focusTimer
        interval: 30
        onTriggered: {
            root._activateField("user")
        }
    }

    property real _panelOpacity: isOpen ? 1.0 : 0.0
    Behavior on _panelOpacity { NumberAnimation { duration: 210; easing.type: Easing.InOutQuad } }

    visible: _panelOpacity > 0.001
    opacity: _panelOpacity

    Keys.onPressed: function(event) {
        if (api.keys.isCancel(event) && root._testState !== "testing") {
            event.accepted = true
            SoundsEffects.playCancel()
            root.close()
        }
    }

    Rectangle {
        id: _panel

        property real _slideOffset: root.isOpen ? 0 : Math.round(-8 * Style.scale)
        Behavior on _slideOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        anchors.fill: parent
        y: _slideOffset

        color: _popupBg
        radius: Style.radiusPanel
        border.width: Style.borderWidth
        border.color: _borderColor
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        Column {
            id: _col
            anchors {
                top: parent.top; topMargin: Style.spacingLarge * 2
                left: parent.left; leftMargin: Style.spacingLarge
                right: parent.right; rightMargin: Style.spacingLarge
            }
            spacing: Style.spacingMedium

            Item {
                id: _raLogoBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(280 * Style.scale)
                height: Math.round(150 * Style.scale)

                Image {
                    id: _raLogo
                    anchors.fill: parent
                    source: "assets/images/icons/ra.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    sourceSize.width: width
                    sourceSize.height: height
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: _raLogo
                    source: _raLogo
                    color: Style.colorIconMono
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Enter your credentials here."
                font.pixelSize: Style.fontSizeTitle; font.family: Fonts.smooch
                font.bold: true; color: _titleText
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Rectangle { width: parent.width; height: Style.borderWidth; color: _separator; Behavior on color { ColorAnimation { duration: 200 } } }

            FocusScope {
                id: _userFieldScope
                width: parent.width
                height: _userFieldCol.implicitHeight

                readonly property bool _highlighted: activeFocus || root._activeField === "user"

                Keys.onPressed: {
                    if (root._testState === "testing") { event.accepted = true; return }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true
                        root._activateField("user")
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        SoundsEffects.playCancel()
                        root.close()
                        return
                    }
                    if (root._activeField === "user" && !event.isAutoRepeat) {
                        if (event.key === Qt.Key_Right) {
                            SoundsEffects.playUp()
                        } else if (event.key === Qt.Key_Left) {
                            SoundsEffects.playDown()
                        }
                    }
                }
                Keys.onDownPressed: { event.accepted = true; SoundsEffects.playDown(); _keyFieldScope.forceActiveFocus() }
                Keys.onTabPressed: {
                    event.accepted = true
                    if (root._testState === "testing") return
                    root._activateField("key")
                }
                Keys.onBacktabPressed: {
                    event.accepted = true
                    if (root._testState === "testing") return
                    root._activeField = "none"
                    _cancelBtn.forceActiveFocus()
                }

                Column {
                    id: _userFieldCol
                    width: parent.width
                    spacing: Math.round(5 * Style.scale)

                    Text {
                        text: "USER NAME:"
                        font.pixelSize: Style.fontSizeLarge; font.family: Fonts.smooch
                        font.letterSpacing: 0.6; color: _labelText
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: _userRect
                        width: parent.width; height: Math.round(32 * Style.scale); radius: Style.radiusPanel
                        color: _userFieldScope._highlighted ? _inputBgActive : _inputBg
                        border.color: _userFieldScope._highlighted ? _inputBorderActive : _inputBorder
                        border.width: Style.borderWidth
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: _userInput
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Math.round(10 * Style.scale); rightMargin: Math.round(10 * Style.scale)
                            }
                            color: _inputText; font.pixelSize: Style.fontSizeMediumLarge
                            font.family: Fonts.smooch
                            font.letterSpacing: 2
                            selectionColor: "#2a6496"; selectedTextColor: "#ffffff"
                            clip: true
                            readOnly: root._activeField !== "user" || root._testState === "testing"
                            activeFocusOnPress: false
                            selectByMouse: true
                            persistentSelection: true
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            | Qt.ImhSensitiveData | Qt.ImhMultiLine

                            cursorDelegate: Rectangle {
                                id: _userCursor
                                width: Math.round(2 * Style.scale)
                                height: Math.round(16 * Style.scale)
                                color: _cursorColor
                                visible: root._activeField === "user" && root._testState !== "testing"
                                SequentialAnimation on opacity {
                                    running: _userCursor.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 0 }
                                    NumberAnimation { to: 1; duration: 480 }
                                    NumberAnimation { to: 0; duration: 0 }
                                    NumberAnimation { to: 0; duration: 480 }
                                }
                                onVisibleChanged: if (!visible) opacity = 1
                            }

                            Text {
                                anchors.fill: parent
                                text: "your username"
                                color: _placeholderText
                                font: _userInput.font
                                visible: _userInput.text.length === 0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            enabled: root._activeField !== "user"
                            onClicked: {
                                if (root._testState !== "testing")
                                    root._activateField("user")
                            }
                        }
                    }
                }
            }

            FocusScope {
                id: _keyFieldScope
                width: parent.width
                height: _keyFieldCol.implicitHeight

                readonly property bool _highlighted: activeFocus || root._activeField === "key"

                Keys.onPressed: {
                    if (root._testState === "testing") { event.accepted = true; return }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true
                        root._activateField("key")
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        SoundsEffects.playCancel()
                        root.close()
                        return
                    }
                    if (root._activeField === "key" && !event.isAutoRepeat) {
                        if (event.key === Qt.Key_Right) {
                            SoundsEffects.playUp()
                        } else if (event.key === Qt.Key_Left) {
                            SoundsEffects.playDown()
                        }
                    }
                }
                Keys.onUpPressed: { event.accepted = true; SoundsEffects.playUp(); _userFieldScope.forceActiveFocus() }
                Keys.onDownPressed: { event.accepted = true; SoundsEffects.playDown(); _okBtn.forceActiveFocus() }
                Keys.onTabPressed: {
                    event.accepted = true
                    if (root._testState === "testing") return
                    root._activeField = "none"
                    _okBtn.forceActiveFocus()
                }
                Keys.onBacktabPressed: {
                    event.accepted = true
                    if (root._testState === "testing") return
                    root._activateField("user")
                }

                Column {
                    id: _keyFieldCol
                    width: parent.width
                    spacing: Math.round(5 * Style.scale)

                    Text {
                        text: "API KEY:"
                        font.pixelSize: Style.fontSizeLarge; font.family: Fonts.smooch
                        font.letterSpacing: 0.6; color: _labelText
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: _keyRect
                        width: parent.width; height: Math.round(32 * Style.scale); radius: Style.radiusPanel
                        color: _keyFieldScope._highlighted ? _inputBgActive : _inputBg
                        border.color: _keyFieldScope._highlighted ? _inputBorderActive : _inputBorder
                        border.width: Style.borderWidth
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: _keyInput
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: Math.round(10 * Style.scale); rightMargin: Math.round(10 * Style.scale)
                            }
                            color: _inputText; font.pixelSize: Style.fontSizeMediumLarge
                            font.family: Fonts.smooch
                            font.letterSpacing: 2
                            selectionColor: "#2a6496"; selectedTextColor: "#ffffff"
                            clip: true
                            readOnly: root._activeField !== "key" || root._testState === "testing"
                            activeFocusOnPress: false
                            selectByMouse: true
                            persistentSelection: true
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            | Qt.ImhSensitiveData | Qt.ImhMultiLine

                            cursorDelegate: Rectangle {
                                id: _keyCursor
                                width: Math.round(2 * Style.scale)
                                height: Math.round(16 * Style.scale)
                                color: _cursorColor
                                visible: root._activeField === "key" && root._testState !== "testing"
                                SequentialAnimation on opacity {
                                    running: _keyCursor.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 0 }
                                    NumberAnimation { to: 1; duration: 480 }
                                    NumberAnimation { to: 0; duration: 0 }
                                    NumberAnimation { to: 0; duration: 480 }
                                }
                                onVisibleChanged: if (!visible) opacity = 1
                            }

                            Text {
                                anchors.fill: parent
                                text: "your API key"
                                color: _placeholderText
                                font: _keyInput.font
                                visible: _keyInput.text.length === 0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            enabled: root._activeField !== "key"
                            onClicked: {
                                if (root._testState !== "testing")
                                    root._activateField("key")
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: root._testState !== "idle" ? Math.round(34 * Style.scale) : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

                Rectangle {
                    anchors { fill: parent; topMargin: Style.spacingTiny }
                    radius: Style.radiusPanel
                    color: {
                        if (root._testState === "testing") return _msgBgTesting
                            if (root._testState === "success") return _msgBgSuccess
                                return _msgBgError
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Row {
                        anchors {
                            left: parent.left; leftMargin: Math.round(10 * Style.scale)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: Math.round(8 * Style.scale)

                        Item {
                            width: Math.round(16 * Style.scale); height: Math.round(16 * Style.scale)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root._testState === "testing"
                            Rectangle {
                                anchors.fill: parent; radius: width / 2
                                color: "transparent"
                                border.width: Style.borderWidth * 2; border.color: _msgTextTesting
                                Rectangle {
                                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                                    width: Math.round(2 * Style.scale); height: Math.round(5 * Style.scale); color: _msgTextTesting; radius: Math.round(1 * Style.scale)
                                }
                                RotationAnimator on rotation {
                                    running: root._testState === "testing"
                                    loops: Animation.Infinite; from: 0; to: 360; duration: 900
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root._testState === "success" || root._testState === "error"
                            text: root._testState === "success" ? "✔" : "✘"
                            color: root._testState === "success" ? _msgTextSuccess : _msgTextError
                            font.pixelSize: Style.fontSizeMedium; font.bold: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (root._testState === "testing") return "Verifying credentials…"
                                    return root._testMsg
                            }
                            color: {
                                if (root._testState === "testing") return _msgTextTesting
                                    if (root._testState === "success") return _msgTextSuccess
                                        return _msgTextError
                            }
                            font.pixelSize: Style.fontSizeMediumLarge; font.family: Fonts.smooch
                            elide: Text.ElideRight; width: Math.round(370 * Style.scale)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.spacingMedium

                Item {
                    id: _okBtn
                    width: Math.round(90 * Style.scale); height: Math.round(32 * Style.scale)
                    readonly property bool _busy: root._testState === "testing"

                    Rectangle {
                        anchors.fill: parent; radius: Math.round(15 * Style.scale)
                        color: {
                            if (_okBtn._busy) return _msgBgTesting
                                if (_okBtn.activeFocus) return _okBtnBgFocus
                                    return _okBtnBg
                        }
                        border.color: (_okBtn.activeFocus && !_okBtn._busy) ? _inputBorderActive : _inputBorder
                        border.width: Style.borderWidth
                        opacity: _okBtn._busy ? 0.5 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.pixelSize: Style.fontSizeMediumLarge; font.family: Fonts.smooch; font.bold: true
                        font.letterSpacing: 2
                        color: (_okBtn.activeFocus && !_okBtn._busy) ? _okBtnTextFocus : _okBtnText
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Keys.onUpPressed: { event.accepted = true; SoundsEffects.playUp(); _keyFieldScope.forceActiveFocus() }
                    Keys.onRightPressed: { event.accepted = true; SoundsEffects.playDown(); _cancelBtn.forceActiveFocus() }
                    Keys.onTabPressed: {
                        event.accepted = true
                        if (root._testState === "testing") return
                        SoundsEffects.playDown()
                        _cancelBtn.forceActiveFocus()
                    }
                    Keys.onBacktabPressed: {
                        event.accepted = true
                        if (root._testState === "testing") return
                        SoundsEffects.playUp()
                        root._activateField("key")
                    }
                    Keys.onPressed: {
                        if (_okBtn._busy) { event.accepted = true; return }
                        if (api.keys.isCancel(event)) { event.accepted = true; SoundsEffects.playCancel(); root.close(); return }
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true; SoundsEffects.playAccept(); root._save(); return
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true; SoundsEffects.playAccept(); root._save()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!_okBtn._busy) { root._save() } }
                    }
                }

                Item {
                    id: _cancelBtn
                    width: Math.round(90 * Style.scale); height: Math.round(32 * Style.scale)

                    Rectangle {
                        anchors.fill: parent; radius: Math.round(15 * Style.scale)
                        color: _cancelBtn.activeFocus ? _cancelBtnBgFocus : _cancelBtnBg
                        border.color: _cancelBtn.activeFocus ? _cancelBtnBorderFocus : _cancelBtnBorder
                        border.width: Style.borderWidth
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Style.fontSizeMediumLarge; font.family: Fonts.smooch; font.bold: true
                        font.letterSpacing: 2
                        color: _cancelBtn.activeFocus ? _cancelBtnTextFocus : _cancelBtnText
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Keys.onUpPressed: { event.accepted = true; SoundsEffects.playUp(); _keyFieldScope.forceActiveFocus() }
                    Keys.onLeftPressed: { event.accepted = true; SoundsEffects.playUp(); _okBtn.forceActiveFocus() }
                    Keys.onTabPressed: {
                        event.accepted = true
                        if (root._testState === "testing") return
                        SoundsEffects.playDown()
                        root._activateField("user")
                    }
                    Keys.onBacktabPressed: {
                        event.accepted = true
                        if (root._testState === "testing") return
                        SoundsEffects.playUp()
                        _okBtn.forceActiveFocus()
                    }
                    Keys.onPressed: {
                        if (root._testState === "testing") { event.accepted = true; return }
                        if (api.keys.isCancel(event) || api.keys.isAccept(event)
                            || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true; SoundsEffects.playCancel(); root.close()
                            }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (root._testState !== "testing") root.close() }
                    }
                }
            }

            Item { width: 1; height: Math.round(4 * Style.scale) }
        }
    }
}
