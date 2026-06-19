pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Singletons"

/*TODO:
 * /home/xyreltenz/Ricelin
 * observe this folder i clone and what's wrong is my implementation why my lockscreen not working when i type. Also check the latest change on
 * it for battery and apply the changes to my config and remove not used folder like topbar. Change the pill time format into 12am-12pm instead
 * of 24 hour format. Also when i click sidebar icon on pill nothing happen.
 */

ShellRoot {
    id: root

    readonly property string currentUser: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
        function onReloadFailed(errorString) { Quickshell.inhibitReloadPopup(); }
    }

    Auth {
        id: pamAuth
        user: root.currentUser
        onSucceeded: {
            sessionLock.locked = false;
            Cava.enabled = false;
            Pw.text = "";
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

            LockSurface {
                anchors.fill: parent
                s: lockSurface.screen ? lockSurface.screen.height / 1080 : 1
                screenName: lockSurface.screen ? lockSurface.screen.name : ""
                auth: pamAuth
            }
        }
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            Pw.text = "";
            sessionLock.locked = true;
            Cava.enabled = true;
        }
        function reload(): void { Quickshell.reload(false); }
    }
}
