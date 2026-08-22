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
        onStatusChanged: console.log("[SoundsEffects] sndUp status=" + status)
    }
    readonly property SoundEffect sndDown: SoundEffect {
        source: "assets/sound/down.wav"
        volume: root.volume
        onStatusChanged: console.log("[SoundsEffects] sndDown status=" + status)
    }
    readonly property SoundEffect sndAccept: SoundEffect {
        source: "assets/sound/ok.wav"
        volume: root.volume
        onStatusChanged: console.log("[SoundsEffects] sndAccept status=" + status)
    }
    readonly property SoundEffect sndCancel: SoundEffect {
        source: "assets/sound/cancel.wav"
        volume: root.volume
        onStatusChanged: console.log("[SoundsEffects] sndCancel status=" + status)
    }
    readonly property SoundEffect sndFavorite: SoundEffect {
        source: "assets/sound/favo.wav"
        volume: root.volume
        onStatusChanged: console.log("[SoundsEffects] sndFavorite status=" + status)
    }
    readonly property SoundEffect sndNotice: SoundEffect {
        source: "assets/sound/notice.wav"
        volume: root.volume
        onStatusChanged: console.log("[SoundsEffects] sndNotice status=" + status)
    }

    function _play(effect) {
        if (!root.enabled) return;
        console.log("[SoundsEffects] _play source=" + effect.source + " status=" + effect.status + " playing=" + effect.playing);
        if (!effect.playing) {
            effect.play();
        } else {
            effect.stop();
            effect.play();
        }
    }

    function playUp() { console.log("[SoundsEffects] playUp"); _play(sndUp); }
    function playDown() { console.log("[SoundsEffects] playDown"); _play(sndDown); }
    function playAccept() { console.log("[SoundsEffects] playAccept"); _play(sndAccept); }
    function playCancel() { console.log("[SoundsEffects] playCancel"); _play(sndCancel); }
    function playFavorite() { console.log("[SoundsEffects] playFavorite"); _play(sndFavorite); }
    function playNotice() { console.log("[SoundsEffects] playNotice"); _play(sndNotice); }
}
