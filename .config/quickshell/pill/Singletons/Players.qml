pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

/**
 * Shared now-playing source. Picks the player the user last commanded, the one
 * whose play or pause state changed most recently, which is the same player
 * playerctld routes the media keys to, so the media surface and the keybinds
 * never disagree on which player they mean. The playerctld aggregator proxy is
 * dropped from the candidates and from the recency watch. Until something is
 * touched it falls back to the first playing, then the first track-bearing
 * player.
 */
Singleton {
    id: root

    /** dbusName of the player whose playback state changed most recently. */
    property string lastTouched: ""

    /** Existing players fire a state event as their delegates build; gate those out. */
    property bool ready: false
    Component.onCompleted: ready = true

    function anyOtherPlaying(self) {
        var l = root.list;
        for (var i = 0; i < l.length; i++)
            if (l[i] !== self && l[i].isPlaying)
                return true;
        return false;
    }

    /** The playerctld aggregator mirrors the others, so it must not double-count. */
    function isProxy(p) {
        return (p.dbusName || "").toLowerCase().indexOf("playerctld") >= 0;
    }

    /** Real players only, the playerctld proxy left out. */
    readonly property var list: {
        var all = Mpris.players.values;
        var out = [];
        for (var i = 0; i < all.length; i++) {
            var p = all[i];
            if (p && !isProxy(p))
                out.push(p);
        }
        return out;
    }

    /** The player to show and control. */
    readonly property var active: {
        var l = root.list;
        if (l.length === 0)
            return null;
        if (root.lastTouched) {
            for (var i = 0; i < l.length; i++)
                if (l[i].dbusName === root.lastTouched)
                    return l[i];
        }
        var withTrack = null;
        for (var j = 0; j < l.length; j++) {
            var p = l[j];
            if (p.isPlaying)
                return p;
            if (!withTrack && p.trackTitle && p.trackTitle.length > 0)
                withTrack = p;
        }
        return withTrack ? withTrack : l[0];
    }

    /**
     * Mark the last-commanded player on any play or pause. A change is ignored
     * while another player is already playing, so a background tab starting or
     * pausing can't grab the surface off the music you are on; the ready gate
     * drops the burst of events that fire as existing players' delegates build
     * at launch, leaving the startup pick to the fallback. The proxy is pinned
     * to a constant so its mirrored state never fires.
     */
    Instantiator {
        model: Mpris.players
        delegate: QtObject {
            id: watch
            required property var modelData
            readonly property int pbState: (watch.modelData && !Players.isProxy(watch.modelData)) ? watch.modelData.playbackState : -1
            onPbStateChanged: {
                var p = watch.modelData;
                if (!Players.ready || !p || Players.isProxy(p))
                    return;
                if (Players.anyOtherPlaying(p))
                    return;
                Players.lastTouched = p.dbusName;
            }
        }
    }
}
