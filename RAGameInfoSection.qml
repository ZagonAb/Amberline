import QtQuick 2.15
import QtGraphicalEffects 1.12

FocusScope {
    id: root

    focus: true

    property var gameData: null
    property var themeColors: ({})
    property bool isDarkTheme: true
    property var soundManager: null

    readonly property var game: gameData
    readonly property bool lightTheme: !isDarkTheme

    readonly property color _textPrimary: Style.colorTextPrimary
    readonly property color _textSecondary: Style.colorTextSecondary
    readonly property color _textMuted: Style.colorTextSecondary
    readonly property color _bgCard: Style.colorPanelAlt
    readonly property color _bgHighlight: Style.colorPanelAlt
    readonly property color _progressBg: Style.colorBorder
    readonly property color _progressFill: Style.colorAccent
    readonly property color _progressFull: Style.colorFocus
    readonly property color _borderColor: Style.colorBorder
    readonly property color _buttonBg: Style.colorPanelAlt
    readonly property color _buttonBorder: Style.colorBorder

    readonly property int _achCellSize: Math.round(72 * Style.scale)

    signal closeRequested()
    signal openCredentialsRequested()

    property string _apiKey: api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
    property string _apiUser: api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
    readonly property string _base: "https://retroachievements.org/API/"
    readonly property string _media: "https://media.retroachievements.org"

    readonly property bool _hasCredentials: _apiKey !== "" && _apiUser !== ""
    property bool _searching: false
    property bool _loading: false
    property bool _notFound: false
    property bool _noAchievementsYet: false

    property string _errorMsg: ""
    property string _debugLog: ""
    property string _raGameId: ""
    property string _raTitle: ""
    property string _raConsole: ""
    property string _raImgIcon: ""

    property int _raNumAch: 0
    property int _raPoints: 0
    property int _raPointsEarned: 0
    property int _numEarned: 0
    property var _achievements: []
    property int _selIdx: 0
    property int _raPlayers: 0

    property bool _logoutPopupVisible: false

    function _log(msg) {
        root._debugLog = root._debugLog + "\n" + msg;
    }

    function _apiUrl(endpoint, params) {
        var url = _base + endpoint + "?y=" + _apiKey;
        for (var k in params) url += "&" + k + "=" + encodeURIComponent(params[k]);
        return url;
    }

    function _get(url, cb) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)); }
                catch(e) { cb("JSON parse error: " + e, null); }
            } else {
                cb("HTTP " + xhr.status, null);
            }
        };
        xhr.send();
    }

    function _romanToArabic(str) {
        var map = {
            "xv": "15", "xiv": "14", "xiii": "13", "xii": "12", "xi": "11",
            "x": "10", "ix": "9", "viii": "8", "vii": "7", "vi": "6",
            "v": "5", "iv": "4", "iii": "3", "ii": "2", "i": "1"
        };
        return str.replace(/\b(x(?:iv|v|i{1,3})?|i{1,3}|iv|vi{0,3}|vi{0,3}|viii|ix)\b/g, function(m) {
            return map[m] || m;
        });
    }

    function _normalize(str) {
        if (!str) return "";
        return _romanToArabic(str.toLowerCase())
        .replace(/\b(the|a|an)\b\s*/g, "")
        .replace(/[:\-\u2013_',\.\!?®™©\(\)\[\]\/\\]/g, " ")
        .replace(/\s+/g, " ")
        .trim();
    }

    function _words(norm) {
        return norm.split(" ").filter(function(w){ return w.length >= 1; });
    }

    function _matchScore(pegTitle, raTitle) {
        var pNorm = _normalize(pegTitle);
        var rNorm = _normalize(raTitle);

        if (pNorm === rNorm) return 2.0;

        var pWords = _words(pNorm);
        var rWords = _words(rNorm);
        if (pWords.length === 0) return 0.0;

        var hitsP = 0;
        for (var i = 0; i < pWords.length; i++) {
            if (rNorm.indexOf(pWords[i]) !== -1) hitsP++;
        }
        var precision = hitsP / pWords.length;

        var hitsR = 0;
        for (var j = 0; j < rWords.length; j++) {
            if (pNorm.indexOf(rWords[j]) !== -1) hitsR++;
        }
        var recall = rWords.length > 0 ? hitsR / rWords.length : 0;

        if (precision + recall === 0) return 0.0;
        var f1 = 2.0 * precision * recall / (precision + recall);

        var extraInRA  = rWords.length - hitsR;
        var extraInPeg = pWords.length - hitsP;
        if (extraInRA > 0)  f1 = Math.max(0.0, f1 - (extraInRA  / rWords.length) * 0.5);
        if (extraInPeg > 0) f1 = Math.max(0.0, f1 - (extraInPeg / pWords.length) * 0.5);

        return f1;
    }

    readonly property var _consoleMappings: ({
        "snes": ["SNES/Super Famicom"],
        "superfamicom": ["SNES/Super Famicom"],
        "nes": ["NES/Famicom"],
        "famicom": ["NES/Famicom"],
        "fds": ["Famicom Disk System"],
        "famicomdisksystem": ["Famicom Disk System"],
        "n64": ["Nintendo 64"],
        "nintendo64": ["Nintendo 64"],
        "gb": ["Game Boy"],
        "gameboy": ["Game Boy"],
        "gbc": ["Game Boy Color"],
        "gameboycolor": ["Game Boy Color"],
        "gba": ["Game Boy Advance"],
        "gameboyadvance": ["Game Boy Advance"],
        "nds": ["Nintendo DS"],
        "nintendods": ["Nintendo DS"],
        "ndsi": ["Nintendo DSi"],
        "nintendodsi": ["Nintendo DSi"],
        "3ds": ["Nintendo 3DS"],
        "nintendo3ds": ["Nintendo 3DS"],
        "gamecube": ["GameCube"],
        "gc": ["GameCube"],
        "wii": ["Wii"],
        "wiiu": ["Wii U"],
        "virtualboy": ["Virtual Boy"],
        "pokemini": ["Pokemon Mini"],
        "genesis": ["Genesis/Mega Drive"],
        "megadrive": ["Genesis/Mega Drive"],
        "mastersystem": ["Master System"],
        "sms": ["Master System"],
        "gamegear": ["Game Gear"],
        "gg": ["Game Gear"],
        "saturn": ["Saturn"],
        "dreamcast": ["Dreamcast"],
        "segacd": ["Sega CD"],
        "megacd": ["Sega CD"],
        "32x": ["32X"],
        "sega32x": ["32X"],
        "segapico": ["Sega Pico"],
        "sg1000": ["SG-1000"],
        "psx": ["PlayStation"],
        "ps1": ["PlayStation"],
        "playstation": ["PlayStation"],
        "ps2": ["PlayStation 2"],
        "playstation2": ["PlayStation 2"],
        "psp": ["PlayStation Portable"],
        "atari2600": ["Atari 2600"],
        "atari5200": ["Atari 5200"],
        "atari7800": ["Atari 7800"],
        "lynx": ["Atari Lynx"],
        "atarilynx": ["Atari Lynx"],
        "jaguar": ["Atari Jaguar"],
        "atarijaguar": ["Atari Jaguar"],
        "jaguarcd": ["Atari Jaguar CD"],
        "atarijaguarcd": ["Atari Jaguar CD"],
        "atarist": ["Atari ST"],
        "pcengine": ["PC Engine/TurboGrafx-16"],
        "turbografx": ["PC Engine/TurboGrafx-16"],
        "tg16": ["PC Engine/TurboGrafx-16"],
        "pcenginecd": ["PC Engine CD/TurboGrafx-CD"],
        "turbografxcd": ["PC Engine CD/TurboGrafx-CD"],
        "pcfx": ["PC-FX"],
        "pc8800": ["PC-8000/8800"],
        "pc9800": ["PC-9800"],
        "pc6000": ["PC-6000"],
        "ngp": ["Neo Geo Pocket"],
        "neogeopocket": ["Neo Geo Pocket"],
        "neogeocd": ["Neo Geo CD"],
        "arcade": ["Arcade"],
        "mame": ["Arcade"],
        "wonderswan": ["WonderSwan"],
        "msx": ["MSX"],
        "colecovision": ["ColecoVision"],
        "intellivision": ["Intellivision"],
        "vectrex": ["Vectrex"],
        "3do": ["3DO Interactive Multiplayer"],
        "amiga": ["Amiga"],
        "amstradcpc": ["Amstrad CPC"],
        "appleii": ["Apple II"],
        "c64": ["Commodore 64"],
        "commodore64": ["Commodore 64"],
        "dos": ["DOS"],
        "vic20": ["VIC-20"],
        "zxspectrum": ["ZX Spectrum"],
        "zx81": ["ZX81"],
        "fmtowns": ["FM Towns"],
        "sharpx1": ["Sharp X1"],
        "sharpx68000": ["Sharp X68000"],
        "x68000": ["Sharp X68000"],
        "philipscdi": ["Philips CD-i"],
        "cdi": ["Philips CD-i"],
        "thomsonto8": ["Thomson TO8"],
        "oric": ["Oric"],
        "nokiangage": ["Nokia N-Gage"],
        "ngage": ["Nokia N-Gage"],
        "gameandwatch": ["Game & Watch"],
        "uzebox": ["Uzebox"],
        "arduboy": ["Arduboy"],
        "ti83": ["TI-83"],
        "tic80": ["TIC-80"],
        "wasm4": ["WASM-4"],
        "watarasupervision": ["Watara Supervision"],
        "supervision": ["Watara Supervision"],
        "megaduck": ["Mega Duck"],
        "zeebo": ["Zeebo"],
        "xbox": ["Xbox"]
    })

    readonly property var _consoleIds: ({
        "snes": 3, "superfamicom": 3,
        "nes": 7, "famicom": 7,
        "fds": 81, "famicomdisksystem": 81,
        "n64": 2, "nintendo64": 2,
        "gb": 4, "gameboy": 4,
        "gbc": 6, "gameboycolor": 6,
        "gba": 5, "gameboyadvance": 5,
        "nds": 18, "nintendods": 18,
        "ndsi": 78, "nintendodsi": 78,
        "3ds": 62, "nintendo3ds": 62,
        "gamecube": 16, "gc": 16,
        "wii": 19,
        "wiiu": 20,
        "virtualboy": 28,
        "pokemini": 24,
        "genesis": 1, "megadrive": 1,
        "mastersystem": 11, "sms": 11,
        "gamegear": 15, "gg": 15,
        "saturn": 39,
        "dreamcast": 40,
        "segacd": 9, "megacd": 9,
        "32x": 10, "sega32x": 10,
        "segapico": 68,
        "sg1000": 33,
        "psx": 12, "ps1": 12, "playstation": 12,
        "ps2": 21, "playstation2": 21,
        "psp": 41,
        "atari2600": 25,
        "atari5200": 50,
        "atari7800": 51,
        "lynx": 13, "atarilynx": 13,
        "jaguar": 17, "atarijaguar": 17,
        "jaguarcd": 77, "atarijaguarcd": 77,
        "atarist": 36,
        "pcengine": 8, "turbografx": 8, "tg16": 8,
        "pcenginecd": 76, "turbografxcd": 76,
        "pcfx": 49,
        "pc8800": 47,
        "pc9800": 48,
        "pc6000": 67,
        "ngp": 14, "neogeopocket": 14,
        "neogeocd": 56,
        "arcade": 27, "mame": 27,
        "wonderswan": 53,
        "msx": 29,
        "colecovision": 44,
        "intellivision": 45,
        "vectrex": 46,
        "3do": 43,
        "amiga": 35,
        "amstradcpc": 37,
        "appleii": 38,
        "c64": 30, "commodore64": 30,
        "dos": 26,
        "vic20": 34,
        "zxspectrum": 59,
        "zx81": 31,
        "fmtowns": 58,
        "sharpx1": 64,
        "sharpx68000": 52, "x68000": 52,
        "philipscdi": 42, "cdi": 42,
        "thomsonto8": 66,
        "oric": 32,
        "nokiangage": 61, "ngage": 61,
        "gameandwatch": 60,
        "uzebox": 80,
        "arduboy": 71,
        "ti83": 79,
        "tic80": 65,
        "wasm4": 72,
        "watarasupervision": 63, "supervision": 63,
        "megaduck": 69,
        "zeebo": 70,
        "xbox": 22
    })

    function _getCollectionShortName() {
        if (!game) return "";
        try {
            if (game.collections && game.collections.count > 0) {
                var col = game.collections.get(0);
                var name = col.name || "";
                var shortName = col.shortName || "";
                _log("Collection[0] name='" + name + "'  shortName='" + shortName + "'");
                var sn = shortName !== ""
                ? shortName.toLowerCase().replace(/[\s\-_]/g, "")
                : name.toLowerCase().replace(/[\s\-_]/g, "");
                return sn;
            } else {
                _log("game.collections: empty or unavailable");
            }
        } catch(e) {
            _log("game.collections read error: " + e);
        }
        return "";
    }

    function load() {
        _logoutPopupVisible = false
        _apiKey = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : "";
        _apiUser = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : "";

        _raGameId = ""; _raTitle = ""; _raConsole = ""; _raImgIcon = "";
        _raNumAch = 0; _raPoints = 0; _raPointsEarned = 0; _numEarned = 0;
        _achievements = []; _selIdx = 0;
        _notFound = false;
        _noAchievementsYet = false;
        _errorMsg = ""; _debugLog = "";
        _searching = false; _loading = false;

        _log("=== load() ===");
        console.log("[RA:load] ==========================================");
        console.log("[RA:load] game.title =", game ? (game.title || "(sin título)") : "NULL — gameData no llegó");

        if (!game) {
            _log("ERROR: game is null");
            _errorMsg = "No game selected.";
            return;
        }

        _log("game.title       = '" + (game.title || "") + "'");
        _log("game.developer   = '" + (game.developer || "") + "'");
        _log("game.publisher   = '" + (game.publisher || "") + "'");
        _log("game.genre       = '" + (game.genre || "") + "'");
        _log("game.releaseYear = '" + (game.releaseYear || "") + "'");

        var directId = "";
        try {
            if (typeof game.extraData !== "undefined" && game.extraData) {
                directId = game.extraData["x-id"]
                || game.extraData["ra_id"]
                || game.extraData["ra_game_id"]
                || game.extraData["retroachievements_id"]
                || "";
                _log("game.extraData ra_id = '" + directId + "'");
            } else {
                _log("game.extraData: not available");
            }
        } catch(e) {
            _log("game.extraData error: " + e);
        }

        var colShort = _getCollectionShortName();

        console.log("[RA:load] colShort =", colShort, "| directId =", directId !== "" ? directId : "(ninguno — irá a búsqueda)");

        if (!_hasCredentials) {
            _log("No credentials (ra_api_key / ra_api_user missing)");
            _errorMsg = "Connect your RetroAchievements account\nto see your progress here.";
            return;
        }
        _log("Credentials OK: user='" + _apiUser + "', key=" + _apiKey.substring(0,4) + "****");

        if (directId !== "") {
            _log("Using direct RA ID from extraData: " + directId);
            _raGameId = directId;
            _fetchProgress(directId);
        } else {
            _searchForGame(colShort);
        }
    }

    function _searchForGame(colShort) {
        _searching = true;
        _log("Fetching API_GetUserCompletionProgress (c=500)...");

        var url = _apiUrl("API_GetUserCompletionProgress.php",
                          { u: _apiUser, c: 500, o: 0 });
        _get(url, function(err, data) {
            _searching = false;

            if (err || !data) {
                _log("API error: " + (err || "empty response"));
                _errorMsg = "Could not reach RetroAchievements.\n(" + (err || "empty") + ")";
                return;
            }

            var list = data.Results || (Array.isArray(data) ? data : []);
            _log("Received " + list.length + " games in user library");

            var pegTitle = game ? (game.title || "") : "";
            var pegNorm = _normalize(pegTitle);
            var raConsoles = _consoleMappings[colShort] || [];

            console.log("[RA:search] pegTitle (raw) =", pegTitle);
            console.log("[RA:search] pegTitle (normalizado) =", pegNorm);
            console.log("[RA:search] colShort =", colShort, "| raConsoles =", JSON.stringify(raConsoles));
            console.log("[RA:search] total juegos en librería RA =", list.length);

            _log("Pegasus title (raw):        '" + pegTitle + "'");
            _log("Pegasus title (normalized): '" + pegNorm + "'");
            _log("Collection shortName key:   '" + colShort + "'");
            _log("Expected RA consoles:       " + JSON.stringify(raConsoles));

            var scored = [];
            for (var i = 0; i < list.length; i++) {
                var g = list[i];
                var sc = _matchScore(pegTitle, g.Title || "");

                if (raConsoles.length > 0 && (g.ConsoleName || "") !== "") {
                    var consoleMatch = false;
                    for (var ci = 0; ci < raConsoles.length; ci++) {
                        if ((g.ConsoleName || "").indexOf(raConsoles[ci]) !== -1) {
                            consoleMatch = true;
                            break;
                        }
                    }
                    sc = consoleMatch ? sc + 0.5 : sc - 0.2;
                }
                scored.push({ g: g, score: sc });
            }

            scored.sort(function(a, b){ return b.score - a.score; });

            _log("--- Top 8 candidates ---");
            for (var ti = 0; ti < Math.min(8, scored.length); ti++) {
                var s = scored[ti];
                _log("  [" + s.score.toFixed(3) + "] '" + (s.g.Title || "?")
                + "' | " + (s.g.ConsoleName || "?")
                + " | ID=" + (s.g.GameID || "?"));
                console.log("[RA:top8] #" + (ti+1),
                            "score=" + s.score.toFixed(3),
                            "| title='" + (s.g.Title || "?") + "'",
                            "| console='" + (s.g.ConsoleName || "?") + "'",
                            "| ID=" + (s.g.GameID || "?"));
            }
            _log("------------------------");

            var best = scored.length > 0 ? scored[0] : null;
            var bestF1Base = best ? _matchScore(pegTitle, best.g.Title || "") : 0;
            var THRESHOLD = 0.60;

            var bestConsoleMatch = false;
            if (best && raConsoles.length > 0 && (best.g.ConsoleName || "") !== "") {
                for (var cj = 0; cj < raConsoles.length; cj++) {
                    if ((best.g.ConsoleName || "").indexOf(raConsoles[cj]) !== -1) {
                        bestConsoleMatch = true;
                        break;
                    }
                }
            }
            var consoleCheckRequired = raConsoles.length > 0;
            var consoleOk = !consoleCheckRequired || bestConsoleMatch;

            var F1_MIN = 0.70;
            var accepted = best
            && bestF1Base >= F1_MIN
            && best.score >= THRESHOLD
            && consoleOk;

            _log("Acceptance check: f1=" + bestF1Base.toFixed(3)
            + " total=" + (best ? best.score.toFixed(3) : "n/a")
            + " f1Min=" + F1_MIN
            + " consoleOk=" + consoleOk
            + " consoleCheckRequired=" + consoleCheckRequired
            + " bestConsoleMatch=" + bestConsoleMatch);

            console.log("[RA:accept] best.title =", best ? ("'" + best.g.Title + "'") : "NULL",
                        "| f1 =", bestF1Base.toFixed(3),
                        "| total =", best ? best.score.toFixed(3) : "n/a",
                        "| consoleOk =", consoleOk,
                        "| ACCEPTED =", accepted);

            if (accepted) {
                _log("MATCH ACCEPTED: f1=" + bestF1Base.toFixed(3)
                + " total=" + best.score.toFixed(3)
                + " title='" + best.g.Title + "' ID=" + best.g.GameID);
                _raGameId = String(best.g.GameID || "");
                _fetchProgress(_raGameId);
            } else {
                if (best) {
                    _log("MATCH REJECTED: f1=" + bestF1Base.toFixed(3)
                    + " total=" + best.score.toFixed(3)
                    + " consoleOk=" + consoleOk
                    + "  title='" + best.g.Title + "' console='" + (best.g.ConsoleName||"") + "'");
                } else {
                    _log("MATCH REJECTED: list was empty");
                }
                _log("Trying GetGameList fallback...");
                _searchByGameList(pegTitle, colShort);
            }
        });
    }

    function _searchByGameList(pegTitle, colShort) {
        var cid = _consoleIds[colShort] || 0;
        if (cid === 0) {
            _log("No console ID mapping for '" + colShort + "' – cannot use GetGameList");
            _showNotFound(pegTitle);
            return;
        }

        _log("Fetching API_GetGameList consoleId=" + cid + " ('" + colShort + "')...");
        var url = _apiUrl("API_GetGameList.php", { i: cid });
        _get(url, function(err, data) {
            if (err || !Array.isArray(data)) {
                _log("GetGameList error: " + (err || "not an array"));
                _showNotFound(pegTitle);
                return;
            }
            _log("GetGameList returned " + data.length + " games");

            var scored = [];
            for (var i = 0; i < data.length; i++) {
                var g = data[i];
                var sc = _matchScore(pegTitle, g.Title || "");
                scored.push({ g: g, score: sc });
            }
            scored.sort(function(a,b){ return b.score - a.score; });

            _log("--- GetGameList Top 8 ---");
            for (var ti = 0; ti < Math.min(8, scored.length); ti++) {
                var s = scored[ti];
                _log("  [" + s.score.toFixed(3) + "] '" + (s.g.Title || "?")
                + "' ID=" + (s.g.ID || s.g.GameID || "?"));
                console.log("[RA:fallback:top8] #" + (ti+1),
                            "score=" + s.score.toFixed(3),
                            "| title='" + (s.g.Title || "?") + "'",
                            "| ID=" + (s.g.ID || s.g.GameID || "?"));
            }
            _log("------------------------");

            var THRESHOLD = 0.55;
            var best = scored.length > 0 ? scored[0] : null;

            if (best && best.score >= THRESHOLD) {
                var gid = String(best.g.ID || best.g.GameID || "");
                _log("FALLBACK MATCH ACCEPTED: '" + best.g.Title + "' ID=" + gid);
                _raGameId = gid;
                _fetchProgress(gid);
            } else {
                _log("FALLBACK MATCH REJECTED"
                + (best ? ": best=" + best.score.toFixed(3) + " '" + best.g.Title + "'" : ""));
                _showNotFound(pegTitle);
            }
        });
    }

    function _showNotFound(pegTitle) {
        _log("=== NOT FOUND: '" + pegTitle + "' ===");
        _notFound = true;
    }

    function _fetchProgress(gid) {
        _loading = true;
        _log("Fetching API_GetGameInfoAndUserProgress ID=" + gid + " user=" + _apiUser + "...");
        console.log("[RA:fetchProgress] ► Solicitando game ID =", gid, "— este es el juego que se va a mostrar");

        var url = _apiUrl("API_GetGameInfoAndUserProgress.php",
                          { u: _apiUser, g: gid });
        _get(url, function(err, data) {
            _loading = false;

            if (err || !data) {
                _log("GetGameInfoAndUserProgress error: " + (err || "empty"));
                _errorMsg = "Could not load game data.\n(" + (err || "empty") + ")";
                return;
            }

            _raTitle = data.Title || "";
            _raConsole = data.ConsoleName || "";
            _raImgIcon = data.ImageIcon ? (_media + data.ImageIcon) : "";
            _raNumAch = parseInt(data.NumAchievements) || 0;
            _numEarned = parseInt(data.NumAwardedToUser) || 0;
            _raPlayers = parseInt(data.NumDistinctPlayersCasual) || 0;

            _log("Loaded: '" + _raTitle + "' / " + _raConsole);
            console.log("[RA:fetchProgress] ✔ CARGADO:", _raTitle, "| consola:", _raConsole, "| ID solicitado:", gid);

            var ach = [];
            var achMap = data.Achievements || {};
            var totalPoints = 0;
            var earnedPoints = 0;
            for (var id in achMap) {
                var a = achMap[id];
                var earned = (a.DateEarned && a.DateEarned !== "");
                var aPoints = parseInt(a.Points) || 0;
                totalPoints += aPoints;
                if (earned) earnedPoints += aPoints;
                ach.push({
                    id: id,
                    title: a.Title || "",
                    description: a.Description || "",
                    points: aPoints,
                    badgeUrl: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + ".png") : "",
                         badgeLocked: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + "_lock.png") : "",
                         earned: earned,
                         dateEarned: earned ? a.DateEarned : "",
                         numAwarded: parseInt(a.NumAwarded) || 0,
                         trueRatio: parseInt(a.TrueRatio) || 0,
                         displayOrder: parseInt(a.DisplayOrder) || parseInt(id) || 0
                });
            }
            ach.sort(function(a, b) {
                if (a.earned !== b.earned) return a.earned ? -1 : 1;
                return a.displayOrder - b.displayOrder;
            });
            _achievements = ach;
            _raPoints = totalPoints;
            _raPointsEarned = earnedPoints;
            _log("Achievements: " + _numEarned + "/" + _raNumAch + "  Points: " + _raPointsEarned + "/" + _raPoints);
            console.log("[RA:fetchProgress] logros:", _numEarned + "/" + _raNumAch, "| puntos:", _raPointsEarned + "/" + _raPoints);
            _earnedIdx = 0;
            _lockedIdx = 0;
            _activeSection = _earnedList.length > 0 ? "earned" : "locked";
            _log("Done. " + ach.length + " achievements loaded.");
            if (_raNumAch === 0) _noAchievementsYet = true;
        });
    }

    Component.onCompleted: load()
    onGameChanged: load()
    onGameDataChanged: {
        console.log("[RA:onGameDataChanged] ► gameData cambió — nuevo title =",
                    gameData ? (gameData.title || "(sin título)") : "NULL");
        load();
    }

    readonly property var _earnedList: {
        var r = []
        for (var i = 0; i < _achievements.length; i++)
            if (_achievements[i].earned) r.push(_achievements[i])
                return r
    }
    readonly property var _lockedList: {
        var r = []
        for (var i = 0; i < _achievements.length; i++)
            if (!_achievements[i].earned) r.push(_achievements[i])
                return r
    }

    property string _activeSection: "locked"
    property int _earnedIdx: 0
    property int _lockedIdx: 0

    readonly property var _activeAch: {
        if (_activeSection === "earned" && _earnedList.length > 0)
            return _earnedList[_earnedIdx]
            if (_lockedList.length > 0)
                return _lockedList[_lockedIdx]
                return {}
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colorPanel
        radius: Style.radiusPanel
        border.width: Style.borderWidth
        border.color: Style.colorBorder
    }

    on_LogoutPopupVisibleChanged: {
        if (_logoutPopupVisible) SoundsEffects.playDown()
    }

    Keys.onPressed: function(event) {
        console.log("[RA] Keys.onPressed (root) event.key=" + event.key + " isDetails=" + api.keys.isDetails(event) + " isAutoRepeat=" + event.isAutoRepeat + " _hasCredentials=" + _hasCredentials + " _errorMsg='" + _errorMsg + "' _logoutPopupVisible=" + _logoutPopupVisible)

        if (_logoutPopupVisible) {
            event.accepted = true
            return
        }
    }

    Item {
        id: _mainContainer
        anchors.fill: parent
        anchors.margins: Style.spacingMedium

        Item {
            id: _errorState
            anchors.fill: parent
            visible: !_searching && !_loading && _errorMsg !== ""

            onVisibleChanged: {
                if (visible && root._hasCredentials) {
                    Qt.callLater(function() { _retryBtn.forceActiveFocus() })
                }
            }

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Style.spacingMedium

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    iconName: "ra"
                    overlayColor: Qt.rgba(Style.colorIconMono.r, Style.colorIconMono.g, Style.colorIconMono.b, 0.4)
                    width: Math.round(40 * Style.scale)
                    height: width
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root._errorMsg
                    color: _textMuted
                    font.family: Fonts.smooch
                    font.pixelSize: Style.fontSizeTitle
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                Item {
                    id: _retryBtn
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(96 * Style.scale)
                    height: Math.round(30 * Style.scale)
                    visible: root._hasCredentials
                    focus: true

                    Keys.onPressed: function(event) {
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true
                            SoundsEffects.playAccept()
                            root.load()
                        } else if (api.keys.isCancel(event)) {
                            event.accepted = true
                            SoundsEffects.playCancel()
                            root.closeRequested()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Style.radiusPanel
                        color: _retryBtn.activeFocus ? _progressFill : _buttonBg
                        border.color: _retryBtn.activeFocus ? _progressFill : _buttonBorder
                        border.width: _retryBtn.activeFocus ? Style.borderWidth * 2 : Style.borderWidth
                        Behavior on color        { ColorAnimation { duration: Style.animationNormal } }
                        Behavior on border.color  { ColorAnimation { duration: Style.animationNormal } }

                        Text {
                            anchors.centerIn: parent
                            text: "Retry"
                            color: _retryBtn.activeFocus ? Style.colorBackground : _textSecondary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.bold: true
                            Behavior on color { ColorAnimation { duration: Style.animationNormal } }
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: (_searching || _loading) && _errorMsg === ""

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Style.spacingMedium

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    iconName: "ra"
                    overlayColor: Style.colorIconMono
                    width: Math.round(48 * Style.scale)
                    height: width

                    SequentialAnimation on scale {
                        running: _searching || _loading
                        loops: Animation.Infinite
                        NumberAnimation { to: 1.2; duration: 400; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.85; duration: 400; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: _searching ? "Searching\u2026" : "Loading achievements\u2026"
                    color: _textSecondary
                    font.family: Fonts.smooch
                    font.pixelSize: Style.fontSizeTitle
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: !_searching && !_loading && _errorMsg === ""
            && (_notFound || _noAchievementsYet
            || (!_notFound && _raGameId !== "" && _raNumAch === 0 && !_noAchievementsYet))

            Column {
                anchors.centerIn: parent
                width: parent.width
                spacing: Style.spacingSmall

                IconImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    iconName: "ra"
                    overlayColor: Qt.rgba(Style.colorIconMono.r, Style.colorIconMono.g, Style.colorIconMono.b, 0.35)
                    width: Math.round(48 * Style.scale)
                    height: width
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: _notFound
                    ? "This game was not found on RetroAchievements"
                    : "No achievements available for this game yet"
                    color: _textMuted
                    font.family: Fonts.smooch
                    font.pixelSize: Style.fontSizeTitle
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
            }
        }

        Item {
            id: _dataState
            anchors.fill: parent
            visible: !_searching && !_loading && _errorMsg === ""
            && !_notFound && _raNumAch > 0

            readonly property var _selAch: {
                var idx = _achGrid.currentIndex
                if (idx < 0 || idx >= _achGrid.model) return {}
                if (idx < root._earnedList.length)
                    return root._earnedList[idx] || {}
                    return root._lockedList[idx - root._earnedList.length] || {}
            }

            onVisibleChanged: {
                if (visible) {
                    Qt.callLater(function() {
                        _achGrid.forceActiveFocus()
                        console.log("[RA] _achGrid focused")
                    })
                }
            }

            Column {
                id: _header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                spacing: Style.spacingSmall

                Row {
                    width: parent.width
                    spacing: Style.spacingSmall

                    Item {
                        id: _headerIconBox
                        width: Math.round(56 * Style.scale); height: width
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: Style.radiusPanel
                            color: _bgCard
                            border.color: _borderColor
                            border.width: Style.borderWidth
                            visible: _headerIcon.status !== Image.Ready
                        }
                        Image {
                            id: _headerIcon
                            anchors.fill: parent
                            source: root._raImgIcon
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            mipmap: true
                        }
                    }

                    Text {
                        width: parent.width - _headerIconBox.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        text: root._raTitle || (root.gameData ? root.gameData.title : "")
                        color: _textPrimary
                        font.family: Fonts.sekuya
                        font.pixelSize: Style.fontSizeMedium
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }

                Flow {
                    width: parent.width
                    spacing: Style.spacingSmall

                    Rectangle {
                        height: _progressBadgeText.implicitHeight + Style.spacingMedium
                        width: _progressBadgeText.implicitWidth + Style.spacingLarge
                        radius: Style.radiusPanel
                        color: root._numEarned === root._raNumAch ? _progressFull : _progressFill

                        Text {
                            id: _progressBadgeText
                            anchors.centerIn: parent
                            text: root._numEarned + "/" + root._raNumAch + " \u2022 " + root._raPointsEarned + " pts"
                            color: Style.colorBackground
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeMedium
                            font.bold: true
                        }
                    }

                    Rectangle {
                        visible: root._raConsole !== ""
                        height: _consoleBadgeText.implicitHeight + Style.spacingMedium
                        width: _consoleBadgeText.implicitWidth + Style.spacingLarge
                        radius: Style.radiusPanel
                        color: root._numEarned === root._raNumAch ? _progressFull : _progressFill

                        Text {
                            id: _consoleBadgeText
                            anchors.centerIn: parent
                            text: root._raConsole
                            color: Style.colorBackground
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeMedium
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.round(2 * Style.radiusPanel)

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: _progressBg
                    }
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        radius: height / 2
                        color: root._numEarned === root._raNumAch ? _progressFull : _progressFill
                        width: root._raNumAch > 0
                        ? parent.width * root._numEarned / root._raNumAch : 0
                        Behavior on width { NumberAnimation { duration: 800; easing.type: Easing.OutQuad } }
                        Behavior on color { ColorAnimation { duration: Style.animationNormal } }
                    }
                }
            }

            Rectangle {
                id: _infoPanel
                anchors {
                    top: _header.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: Style.spacingMedium
                }
                height: _descText.lineCount > 1 ? Math.round(66 * Style.scale) : Math.round(46 * Style.scale)
                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                radius: Style.radiusPanel
                color: _bgCard
                border.color: _borderColor
                border.width: Style.borderWidth

                Row {
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Style.spacingSmall; rightMargin: Style.spacingSmall
                    }
                    spacing: Style.spacingTiny

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - _infoMeta.width - Style.spacingSmall
                        spacing: Math.round(Style.scale)

                        Text {
                            width: parent.width
                            text: _dataState._selAch.title || "\u2014"
                            color: _textPrimary
                            font.family: Fonts.sekuya
                            font.pixelSize: Style.fontSizeTiny
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            id: _descText
                            width: parent.width
                            text: _dataState._selAch.description || ""
                            color: _textSecondary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeMedium
                            wrapMode: Text.WordWrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            visible: text !== ""
                        }
                    }

                    Column {
                        id: _infoMeta
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Math.round(2 * Style.scale)

                        Text {
                            anchors.right: parent.right
                            visible: (_dataState._selAch.points || 0) > 0
                            text: (_dataState._selAch.points || 0) + " pts"
                            color: _progressFull
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            font.bold: true
                        }
                    }
                }
            }

            GridView {
                id: _achGrid
                anchors {
                    top: _infoPanel.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    topMargin: Style.spacingMedium
                    leftMargin: Math.floor((parent.width % root._achCellSize) / 2)
                    rightMargin: Math.floor((parent.width % root._achCellSize) / 2)
                }
                clip: true
                focus: true
                keyNavigationWraps: false

                model: root._achievements.length

                cellWidth: root._achCellSize
                cellHeight: root._achCellSize

                Keys.forwardTo: [root]

                property string _pendingNavSound: ""
                readonly property int _cols: cellWidth > 0 ? Math.max(1, Math.floor(width / cellWidth)) : 1

                Keys.onPressed: function(event) {
                    console.log("[RA] _achGrid Keys.onPressed event.key=" + event.key + " isDetails=" + api.keys.isDetails(event) + " isCancel=" + api.keys.isCancel(event))

                    if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                        event.accepted = true
                        SoundsEffects.playCancel()
                        root.closeRequested()
                        return
                    }

                    if (!event.isAutoRepeat && api.keys.isFilters(event)) {
                        event.accepted = true
                        SoundsEffects.playUp()
                        root.load()
                        return
                    }

                    if (!event.isAutoRepeat && api.keys.isDetails(event) && root._hasCredentials && root._errorMsg === "") {
                        event.accepted = true
                        root._logoutPopupVisible = true
                        _logoutPopup.forceActiveFocus()
                        _cancelBtn.forceActiveFocus()
                        return
                    }

                    var idx   = _achGrid.currentIndex
                    var total = _achGrid.model
                    var cols  = _achGrid._cols

                    if (event.key === Qt.Key_Left) {
                        if (idx % cols === 0) {
                            SoundsEffects.playCancel()
                        } else {
                            _achGrid._pendingNavSound = "down"
                        }
                    } else if (event.key === Qt.Key_Right) {
                        var isLastInRow = (idx % cols === cols - 1)
                        var isLastItem  = (idx === total - 1)
                        if (isLastInRow || isLastItem) {
                            SoundsEffects.playCancel()
                        } else {
                            _achGrid._pendingNavSound = "up"
                        }
                    } else if (event.key === Qt.Key_Up) {
                        if (idx < cols) {
                            SoundsEffects.playCancel()
                        } else {
                            _achGrid._pendingNavSound = "up"
                        }
                    } else if (event.key === Qt.Key_Down) {
                        var lastRowStart = total - (total % cols === 0 ? cols : total % cols)
                        if (idx >= lastRowStart) {
                            SoundsEffects.playCancel()
                        } else {
                            _achGrid._pendingNavSound = "down"
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (_achGrid._pendingNavSound !== "") {
                        if (_achGrid._pendingNavSound === "up") {
                            SoundsEffects.playUp();
                        } else {
                            SoundsEffects.playDown();
                        }
                        _achGrid._pendingNavSound = "";
                    }
                }

                delegate: Item {
                    id: _cell
                    width: _achGrid.cellWidth
                    height: _achGrid.cellHeight

                    readonly property var _ach: root._achievements[index] || {}
                    readonly property bool _isEarned: _ach.earned || false
                    readonly property bool _selected: _achGrid.currentIndex === index

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Math.round(4 * Style.scale)
                        radius: Style.radiusPanel
                        color: _cell._selected ? _bgHighlight : "transparent"
                        border.color: {
                            if (_cell._selected) return Style.colorFocus
                                if (_cell._isEarned) return _progressFill
                                    return _borderColor
                        }
                        border.width: _cell._selected ? Style.borderWidth * 2 : Style.borderWidth
                        Behavior on border.color { ColorAnimation { duration: Style.animationNormal } }
                        Behavior on color        { ColorAnimation { duration: Style.animationNormal } }

                        Item {
                            anchors.fill: parent
                            anchors.margins: Style.spacingSmall

                            Image {
                                id: _badgeImg
                                anchors.fill: parent
                                source: _cell._isEarned
                                ? (_cell._ach.badgeUrl    || "")
                                : (_cell._ach.badgeLocked || "")
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                mipmap: true

                                layer.enabled: !_cell._isEarned
                                layer.effect: Desaturate { desaturation: 0.9 }

                                Rectangle {
                                    anchors.fill: parent
                                    color: _bgCard
                                    visible: parent.status !== Image.Ready
                                    Behavior on color { ColorAnimation { duration: Style.animationNormal } }
                                }
                            }
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.margins: Math.round(3 * Style.scale)
                            visible: _cell._isEarned && (_cell._ach.points || 0) > 0
                            width: _ptsTxt.implicitWidth + Style.spacingMedium
                            height: _ptsTxt.implicitHeight + Math.round(2 * Style.scale)
                            radius: Style.radiusPanel
                            color: Style.colorBackground

                            Text {
                                id: _ptsTxt
                                anchors.centerIn: parent
                                text: (_cell._ach.points || 0) + "pts"
                                color: _progressFull
                                font.family: Fonts.smooch
                                font.pixelSize: Style.fontSizeSmall
                                font.bold: true
                                font.letterSpacing: 2
                            }
                        }
                    }
                }
            }

            Item {
                id: _logoutPopup
                anchors.fill: parent
                visible: root._logoutPopupVisible
                z: 50
                focus: true

                Rectangle {
                    anchors.fill: parent
                    color: "#F2000000"
                }

                Rectangle {
                    id: logoutDialog
                    anchors.centerIn: parent
                    width: Math.min(_achGrid.width, 450 * Style.scale)
                    height: Math.min(parent.height - Style.spacingLarge * 4, 200 * Style.scale)
                    radius: Style.radiusPanel * 2
                    color: Style.colorPanel
                    border.color: Style.colorBorder
                    border.width: Style.borderWidth

                    Column {
                        anchors.fill: parent
                        anchors.margins: Style.spacingLarge
                        spacing: Style.spacingMedium

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            text: "You're about to sign out of your RetroAchievements account in Amberline.\nAre you sure you want to continue?"
                            color: Style.colorTextPrimary
                            font.family: Fonts.smooch
                            font.pixelSize: Style.fontSizeLarge
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Style.spacingMedium

                            Item {
                                id: _okBtn
                                width: Math.round(80 * Style.scale)
                                height: Math.round(30 * Style.scale)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Style.radiusPanel
                                    color: _okBtn.activeFocus ? Style.colorAccent : Style.colorPanelAlt
                                    border.color: _okBtn.activeFocus ? Style.colorFocus : Style.colorBorder
                                    border.width: Style.borderWidth
                                    Behavior on color { ColorAnimation { duration: Style.animationNormal } }
                                    Behavior on border.color { ColorAnimation { duration: Style.animationNormal } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "Ok"
                                    color: _okBtn.activeFocus ? Style.colorBackground : Style.colorTextPrimary
                                    font.family: Fonts.smooch
                                    font.pixelSize: Style.fontSizeLarge
                                    font.bold: true
                                }

                                Keys.onPressed: function(event) {
                                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                                        event.accepted = true
                                        SoundsEffects.playAccept()
                                        console.log("[RA] Logging out: unsetting credentials")
                                        api.memory.unset("ra_api_key")
                                        api.memory.unset("ra_api_user")
                                        root._logoutPopupVisible = false
                                        root.load()
                                        root.openCredentialsRequested()
                                    } else if ((event.key === Qt.Key_Right || event.key === Qt.Key_Left) && !event.isAutoRepeat) {
                                        event.accepted = true
                                        SoundsEffects.playUp()
                                        _cancelBtn.forceActiveFocus()
                                    }
                                }
                            }

                            Item {
                                id: _cancelBtn
                                width: Math.round(80 * Style.scale)
                                height: Math.round(30 * Style.scale)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Style.radiusPanel
                                    color: _cancelBtn.activeFocus ? "#C62828" : Style.colorPanelAlt
                                    border.color: _cancelBtn.activeFocus ? "#E53935" : Style.colorBorder
                                    border.width: Style.borderWidth
                                    Behavior on color { ColorAnimation { duration: Style.animationNormal } }
                                    Behavior on border.color { ColorAnimation { duration: Style.animationNormal } }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: _cancelBtn.activeFocus ? "#efcdcd" : Style.colorTextPrimary
                                    font.family: Fonts.smooch
                                    font.pixelSize: Style.fontSizeLarge
                                    font.bold: true
                                }

                                Keys.onPressed: function(event) {
                                    if (api.keys.isAccept(event) && !event.isAutoRepeat) {
                                        event.accepted = true
                                        SoundsEffects.playCancel()
                                        root._logoutPopupVisible = false
                                        _achGrid.forceActiveFocus()
                                    } else if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                                        event.accepted = true
                                        SoundsEffects.playCancel()
                                        root._logoutPopupVisible = false
                                        _achGrid.forceActiveFocus()
                                    } else if ((event.key === Qt.Key_Right || event.key === Qt.Key_Left) && !event.isAutoRepeat) {
                                        event.accepted = true
                                        SoundsEffects.playDown()
                                        _okBtn.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }

                Keys.onPressed: function(event) {
                    if (api.keys.isCancel(event) && !event.isAutoRepeat) {
                        event.accepted = true
                        SoundsEffects.playCancel()
                        root._logoutPopupVisible = false
                        _achGrid.forceActiveFocus()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root._logoutPopupVisible = false
                        _achGrid.forceActiveFocus()
                    }
                    propagateComposedEvents: true
                    onPressed: function(mouse) {
                        if (mouse.target === parent) {
                            root._logoutPopupVisible = false
                            _achGrid.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }
}
