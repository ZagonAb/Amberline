pragma Singleton
import QtQuick 2.15

Item {
    id: style

    readonly property var palettes: ({
        coffee: {
            background: "#151108",
            panel: "#221f1a",
            panelAlt: "#2b271f",
            border: "#413a2d",
            accent: "#e9a633",
            accentDim: "#90641f",
            focus: "#ffc758",
            textPrimary: "#f2e8d5",
            textSecondary: "#a89c86",
            favorite: "#e9a633"
        },
        dark: {
            background: "#0e1114",
            panel: "#14161f",
            panelAlt: "#1a1d28",
            border: "#292e40",
            accent: "#4c77dc",
            accentDim: "#2e4483",
            focus: "#6c94ff",
            textPrimary: "#e6e9f5",
            textSecondary: "#9aa3c0",
            favorite: "#4c77dc"
        },
        light: {
            background: "#eef0f4",
            panel: "#ffffff",
            panelAlt: "#e2e5ec",
            border: "#c7cbd6",
            accent: "#2753cc",
            accentDim: "#88a2e7",
            focus: "#0d33a2",
            textPrimary: "#1c1f28",
            textSecondary: "#565c6e",
            favorite: "#cc7d27"
        },
        valentine: {
            background: "#1d0410",
            panel: "#2b1620",
            panelAlt: "#371c29",
            border: "#5a2c3d",
            accent: "#e96295",
            accentDim: "#903556",
            focus: "#ff8eb8",
            textPrimary: "#f5e3ea",
            textSecondary: "#c093a3",
            favorite: "#e96295"
        },
        dracula: {
            background: "#0a0c21",
            panel: "#21222f",
            panelAlt: "#2a2b3c",
            border: "#44475a",
            accent: "#b887ff",
            accentDim: "#6d4e9f",
            focus: "#d3adff",
            textPrimary: "#f2f2f7",
            textSecondary: "#a6a9c2",
            favorite: "#ff65bd"
        },
        nord: {
            background: "#061126",
            panel: "#232a37",
            panelAlt: "#2c3444",
            border: "#42506a",
            accent: "#82c5d8",
            accentDim: "#4b7785",
            focus: "#a0daeb",
            textPrimary: "#e5eaf0",
            textSecondary: "#9fabc0",
            favorite: "#f4ce82"
        },
        tokyonight: {
            background: "#090b1e",
            panel: "#1e202e",
            panelAlt: "#272939",
            border: "#3b3e57",
            accent: "#6b9aff",
            accentDim: "#3c5597",
            focus: "#9cb7ff",
            textPrimary: "#eaeef8",
            textSecondary: "#9ba3c4",
            favorite: "#ff6682"
        },
        retro: {
            background: "#1c1207",
            panel: "#2a221a",
            panelAlt: "#352b20",
            border: "#5a4630",
            accent: "#f1b894",
            accentDim: "#976b50",
            focus: "#ffcca2",
            textPrimary: "#f3e6d8",
            textSecondary: "#b8a48f",
            favorite: "#f1b894"
        },
        abyss: {
            background: "#031610",
            panel: "#15221d",
            panelAlt: "#1c2b25",
            border: "#324a3f",
            accent: "#7bc87b",
            accentDim: "#47784e",
            focus: "#a4e9a4",
            textPrimary: "#e4f0e4",
            textSecondary: "#9bb5a3",
            favorite: "#7bc87b"
        },
        cyberpunk: {
            background: "#09031a",
            panel: "#1c1626",
            panelAlt: "#251d33",
            border: "#463a5c",
            accent: "#faf027",
            accentDim: "#928a18",
            focus: "#fff980",
            textPrimary: "#f4f0fa",
            textSecondary: "#a99fc4",
            favorite: "#fa2771"
        },
        aqua: {
            background: "#001519",
            panel: "#132326",
            panelAlt: "#1a2e31",
            border: "#2f4d51",
            accent: "#00dcdc",
            accentDim: "#007f7f",
            focus: "#5bfafa",
            textPrimary: "#e0f5f5",
            textSecondary: "#8fb5b5",
            favorite: "#00dcdc"
        },
        palenight: {
            background: "#0a0e23",
            panel: "#22242f",
            panelAlt: "#2b2e3d",
            border: "#454a63",
            accent: "#7181d3",
            accentDim: "#3e4a87",
            focus: "#a6b2f1",
            textPrimary: "#eaebf5",
            textSecondary: "#a0a5c2",
            favorite: "#ca8af3"
        },
        horizon: {
            background: "#1a0912",
            panel: "#271b21",
            panelAlt: "#31232a",
            border: "#563c45",
            accent: "#e9466f",
            accentDim: "#902a4a",
            focus: "#ff789b",
            textPrimary: "#f5e6ea",
            textSecondary: "#bd97a2",
            favorite: "#e9466f"
        },
        oled: {
            background: "#000000",
            panel: "#0a0a0a",
            panelAlt: "#141414",
            border: "#2a2a2a",
            accent: "#00e5ff",
            accentDim: "#005f6b",
            focus: "#66ffff",
            textPrimary: "#f0f0f0",
            textSecondary: "#a0a0a0",
            favorite: "#00e5ff"
        }
    })

    readonly property string defaultThemeName: "coffee"
    property string currentThemeName: defaultThemeName
    readonly property var currentPalette: palettes[currentThemeName] || palettes[defaultThemeName]

    function applyTheme(themeName) {
        _setTheme(themeName);
        api.memory.set('selectedTheme', themeName);
    }

    function previewTheme(themeName) {
        _setTheme(themeName);
    }

    function _setTheme(themeName) {
        if (!palettes.hasOwnProperty(themeName)) {
            console.warn("[Style] Tema desconocido: '" + themeName + "', usando '" + defaultThemeName + "'");
            themeName = defaultThemeName;
        }
        currentThemeName = themeName;
    }

    property color colorBackground: currentPalette.background
    property color colorPanel: currentPalette.panel
    property color colorPanelAlt: currentPalette.panelAlt
    property color colorBorder: currentPalette.border
    property color colorAccent: currentPalette.accent
    property color colorAccentDim: currentPalette.accentDim
    property color colorFocus: currentPalette.focus
    property color colorTextPrimary: currentPalette.textPrimary
    property color colorTextSecondary: currentPalette.textSecondary
    property color colorFavorite: currentPalette.favorite

    Behavior on colorBackground { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorPanel { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorPanelAlt { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorBorder { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorAccent { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorAccentDim { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorFocus { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorTextPrimary { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorTextSecondary { ColorAnimation { duration: style.animationNormal } }
    Behavior on colorFavorite { ColorAnimation { duration: style.animationNormal } }

    property color colorIconMono: currentThemeName === "light" ? "#000000" : "#ffffff"
    Behavior on colorIconMono { ColorAnimation { duration: style.animationNormal } }

    property real scale: 1.0
    property real screenAspectRatio: 16 / 9
    readonly property real narrowScreenThreshold: 1.5
    readonly property bool isNarrowScreen: screenAspectRatio <= narrowScreenThreshold

    function updateScale(windowWidth, windowHeight) {
        console.log("[Style][DEBUG] updateScale llamado t=" + Date.now() + " windowWidth=" + windowWidth + " windowHeight=" + windowHeight);
        if (windowHeight <= 0) {
            console.log("[Style][DEBUG] updateScale abortado, windowHeight<=0");
            return;
        }
        scale = Math.max(0.6, Math.min(1.9, windowHeight / 600));
        if (windowWidth > 0) {
            screenAspectRatio = windowWidth / windowHeight;
        }
        console.log("[Style][DEBUG] updateScale resultado t=" + Date.now() + " screenAspectRatio=" + screenAspectRatio.toFixed(4) + " isNarrowScreen=" + isNarrowScreen + " scale=" + scale.toFixed(3));
    }

    readonly property int spacingTiny: Math.round(2 * scale)
    readonly property int spacingSmall: Math.round(6 * scale)
    readonly property int spacingMedium: Math.round(12 * scale)
    readonly property int spacingLarge: Math.round(22 * scale)

    readonly property int fontSizeTiny: Math.round(9 * scale)
    readonly property int fontSizeSmall: Math.round(11 * scale)
    readonly property int fontSizeMedium: Math.round(14 * scale)
    readonly property int fontSizeMediumLarge: Math.round(16 * scale)
    readonly property int fontSizeLarge: Math.round(19 * scale)
    readonly property int fontSizeTitle: Math.round(26 * scale)

    readonly property int radiusPanel: Math.round(4 * scale)
    readonly property int borderWidth: Math.max(1, Math.round(scale))

    readonly property int animationFast: 100
    readonly property int animationNormal: 180

    readonly property var gridLayoutProfiles: ({
        vertical: {
            minCardWidth: Math.round(120 * scale),
            heightRatio: 1.4,
            targetColumns: 0
        },
        square: {
            minCardWidth: Math.round(140 * scale),
            heightRatio: 1.0,
            targetColumns: 3
        },
        horizontal: {
            minCardWidth: Math.round(130 * scale),
            heightRatio: 0.75,
            targetColumns: 3,
            targetColumnsNarrow: 2
        },
        panoramic: {
            minCardWidth: Math.round(160 * scale),
            heightRatio: 0.45,
            targetColumns: 2
        }
    })
}
