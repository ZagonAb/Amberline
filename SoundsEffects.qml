pragma Singleton
import QtQuick 2.15
import QtMultimedia 5.15

QtObject {
    id: root

    property bool enabled: true
    property real volume: 0.6

    readonly property SoundEffect sndUp: SoundEffect {
        source: "assets/sound/up.wav"
        volume: root.volume
        property bool _pending: false
        onStatusChanged: {
            console.log("[SoundsEffects] sndUp status=" + status)
            if (status === SoundEffect.Ready && _pending) { _pending = false; play() }
        }
    }
    readonly property SoundEffect sndDown: SoundEffect {
        source: "assets/sound/down.wav"
        volume: root.volume
        property bool _pending: false
        onStatusChanged: {
            console.log("[SoundsEffects] sndDown status=" + status)
            if (status === SoundEffect.Ready && _pending) { _pending = false; play() }
        }
    }
    readonly property SoundEffect sndAccept: SoundEffect {
        source: "assets/sound/ok.wav"
        volume: root.volume
        property bool _pending: false
        onStatusChanged: {
            console.log("[SoundsEffects] sndAccept status=" + status)
            if (status === SoundEffect.Ready && _pending) { _pending = false; play() }
        }
    }
    readonly property SoundEffect sndCancel: SoundEffect {
        source: "assets/sound/cancel.wav"
        volume: root.volume
        property bool _pending: false
        onStatusChanged: {
            console.log("[SoundsEffects] sndCancel status=" + status)
            if (status === SoundEffect.Ready && _pending) { _pending = false; play() }
        }
    }
    readonly property SoundEffect sndFavorite: SoundEffect {
        source: "assets/sound/favo.wav"
        volume: root.volume
        property bool _pending: false
        onStatusChanged: {
            console.log("[SoundsEffects] sndFavorite status=" + status)
            if (status === SoundEffect.Ready && _pending) { _pending = false; play() }
        }
    }
    readonly property SoundEffect sndNotice: SoundEffect {
        source: "assets/sound/notice.wav"
        volume: root.volume
        property bool _pending: false
        onStatusChanged: {
            console.log("[SoundsEffects] sndNotice status=" + status)
            if (status === SoundEffect.Ready && _pending) { _pending = false; play() }
        }
    }

    function _play(effect) {
        if (!root.enabled) return;
        console.log("[SoundsEffects] _play source=" + effect.source + " status=" + effect.status + " playing=" + effect.playing);
        if (effect.status === SoundEffect.Ready) {
            if (effect.playing) effect.stop();
            effect.play();
        } else if (effect.status === SoundEffect.Loading) {
            console.log("[SoundsEffects] _play: aún cargando, marcando _pending");
            effect._pending = true;
        } else {
            console.log("[SoundsEffects] _play: status inesperado=" + effect.status + ", ignorando");
        }
    }

    function playUp()       { console.log("[SoundsEffects] playUp");       _play(sndUp);       }
    function playDown()     { console.log("[SoundsEffects] playDown");     _play(sndDown);     }
    function playAccept()   { console.log("[SoundsEffects] playAccept");   _play(sndAccept);   }
    function playCancel()   { console.log("[SoundsEffects] playCancel");   _play(sndCancel);   }
    function playFavorite() { console.log("[SoundsEffects] playFavorite"); _play(sndFavorite); }
    function playNotice()   { console.log("[SoundsEffects] playNotice");   _play(sndNotice);   }
}
