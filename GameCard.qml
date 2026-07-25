import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusableItem {
    id: root

    property var game: null
    property bool blurActive: false

    function collectionShortName(g) {
        if (!g || !g.collections || g.collections.count === 0) return ""
        var collection = g.collections.get(0)
        return collection ? collection.shortName : ""
    }

    Image {
        id: art
        anchors.fill: parent
        anchors.margins: Style.spacingSmall
        source: {
            if (!game) return "";
            if (game.assets.boxFront !== "") return game.assets.boxFront;
            return game.assets.cartridge;
        }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: source !== "" && status === Image.Ready
    }

    Image {
        id: systemArt
        anchors.fill: parent
        anchors.margins: Style.spacingSmall
        source: {
            if (!game || art.visible) return "";
            var shortName = root.collectionShortName(game);
            return shortName !== "" ? "assets/images/systems/" + shortName + ".png" : "";
        }
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        visible: !art.visible && source !== "" && status === Image.Ready
    }

    Item {
        id: reflectionContainer
        anchors.fill: parent
        anchors.margins: Style.spacingSmall
        z: 6

        property bool showReflection: root.isCurrent && (art.visible || systemArt.visible)

        opacity: showReflection ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onShowReflectionChanged: {
            if (showReflection) {
                reflectionEffect.reflectionProgress = -0.5
                reflectionAnim.restart()
            } else {
                reflectionAnim.stop()
            }
        }

        ShaderEffect {
            id: reflectionEffect
            anchors.fill: parent
            visible: false

            property real reflectionProgress: -0.5
            property real reflectionWidth:    0.42
            property real intensity:          0.45
            property color reflectionColor:   "#FFFFFF"

            NumberAnimation {
                id: reflectionAnim
                target: reflectionEffect
                property: "reflectionProgress"
                from: -0.5
                to: 1.5
                duration: 1400
                easing.type: Easing.InOutSine
            }

            vertexShader: "
                uniform highp mat4 qt_Matrix;
                attribute highp vec4 qt_Vertex;
                attribute highp vec2 qt_MultiTexCoord0;
                varying highp vec2 coord;
                void main() {
                    coord = qt_MultiTexCoord0;
                    gl_Position = qt_Matrix * qt_Vertex;
                }
            "

            fragmentShader: "
                varying highp vec2 coord;
                uniform lowp float qt_Opacity;
                uniform lowp float reflectionProgress;
                uniform lowp float reflectionWidth;
                uniform lowp float intensity;
                uniform lowp vec4 reflectionColor;

                void main() {
                    if (reflectionProgress >= 1.5) {
                        gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
                        return;
                    }

                    highp vec2 uv = coord;
                    highp float diag = (uv.x + uv.y) * 0.5;
                    highp float moving = reflectionProgress - diag;
                    highp float dist = abs(moving);
                    highp float grad = 0.0;

                    if (dist < reflectionWidth) {
                        grad = 1.0 - (dist / reflectionWidth);
                        grad = smoothstep(0.0, 1.0, grad);
                    }

                    highp float alpha = grad * intensity * reflectionColor.a * qt_Opacity;
                    highp vec3 color = reflectionColor.rgb * alpha;
                    gl_FragColor = vec4(color, alpha);
                }
            "
        }

        OpacityMask {
            anchors.fill: reflectionEffect
            source: reflectionEffect
            maskSource: Rectangle {
                width: reflectionEffect.width
                height: reflectionEffect.height
                radius: Style.radiusPanel
            }
        }
    }

    ShaderEffect {
        id: rimShader
        anchors.fill: parent
        anchors.margins: Style.spacingSmall
        z: 5

        visible: root.isCurrent && (art.visible || systemArt.visible)
        opacity: root.isCurrent ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: Style.animationFast; easing.type: Easing.OutQuad }
        }

        vertexShader: "
            uniform highp mat4 qt_Matrix;
            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;
            varying highp vec2 coord;
            void main() {
                coord = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }
        "

        fragmentShader: "
            varying highp vec2 coord;
            uniform lowp float qt_Opacity;

            void main() {
                highp vec2 uv = coord;
                highp float rimW = 0.045;
                highp float ex = min(uv.x, 1.0 - uv.x);
                highp float ey = min(uv.y, 1.0 - uv.y);
                highp float rim = 1.0 - smoothstep(0.0, rimW, min(ex, ey));

                // Borde superior e izquierdo mas brillante (luz desde arriba)
                highp float rimTop = (1.0 - uv.y) * (1.0 - uv.x);
                rim = rim * (0.35 + rimTop * 0.65);

                highp vec3 color = vec3(0.72, 0.91, 1.0);
                gl_FragColor = vec4(color * rim, rim * 0.70) * qt_Opacity;
            }
        "
    }

    Rectangle {
        id: favoriteBadge
        visible: !!(game && game.favorite)
        width: Math.round(26 * Style.scale)
        height: width
        radius: width / 2
        color: Style.colorAccent
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Style.spacingSmall

        IconImage {
            iconName: "favorite"
            overlayColor: Style.colorBackground
            anchors.centerIn: parent
            width: Math.round(20 * Style.scale)
            height: width
        }
    }

    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Style.spacingSmall
        text: game ? game.title : ""
        color: Style.colorTextPrimary
        font.family: global.fonts.condensed
        font.pixelSize: Style.fontSizeSmall
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        visible: !art.visible
    }

    Rectangle {
        id: cardOverlay
        anchors.fill: parent
        color: "#F2000000"
        radius: Style.radiusPanel
        opacity: root.blurActive ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.InOutQuad
            }
        }
    }
}
