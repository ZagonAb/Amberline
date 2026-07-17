pragma Singleton
import QtQuick 2.15

QtObject {
    id: fonts

    readonly property FontLoader jerseyLoader: FontLoader {
        source: "assets/fonts/jersey/jersey.ttf"
    }
    readonly property string jersey: jerseyLoader.name

    readonly property FontLoader pixelifyLoader: FontLoader {
        source: "assets/fonts/pixelify/pixelify.ttf"
    }
    readonly property string pixelify: pixelifyLoader.name

    readonly property FontLoader castoroLoader: FontLoader {
        source: "assets/fonts/castoro/castoro.ttf"
    }
    readonly property string castoro: castoroLoader.name

    readonly property FontLoader sekuyaLoader: FontLoader {
        source: "assets/fonts/sekuya/sekuya.ttf"
    }
    readonly property string sekuya: sekuyaLoader.name

    readonly property FontLoader smoochLoader: FontLoader {
        source: "assets/fonts/smooch/smooch.ttf"
    }
    readonly property string smooch: smoochLoader.name
}
