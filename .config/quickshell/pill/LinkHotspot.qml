pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Networking
import "Singletons"

/**
 * Hotspot subview for the link surface. Displays editable network name and WPA2
 * password (with hide/unhide toggle), AP band selector (2.4G vs 5G), and lists
 * currently connected client devices retrieved from NetworkManager DHCP leases.
 */
Item {
    id: root

    property real s: 1
    property bool active: false
    property bool visibleActive: false

    signal back()

    readonly property var devices: (typeof Networking !== "undefined" && Networking && Networking.devices) ? Networking.devices.values : []
    readonly property var wifiDev: devices.find(function(d) { return d && d.type === DeviceType.Wifi }) || null
    readonly property string hsCon: "RicelinHotspot"
    readonly property string hsIface: wifiDev ? (wifiDev.name || "wlo1") : "wlo1"

    property string hsName: "Ricelin"
    property string hsPw: ""
    property string hsBand: "bg" // "bg" = 2.4 GHz, "a" = 5 GHz
    property bool hsActive: false
    property bool hsBusy: false
    property string hsEdit: ""
    property string hsDraft: ""
    property bool showPassword: false

    property var connectedDevices: []

    implicitHeight: hsCol.y + hsCol.height

    function refresh() {
        hsStateProc.running = true;
        hsReadProc.running = true;
        refreshConnectedDevices();
    }

    function refreshConnectedDevices() {
        if (hsActive && active) {
            leasesProc.running = true;
        } else {
            connectedDevices = [];
        }
    }

    function applyHotspot() {
        if (hsBusy || hsPw.length < 8)
            return;
        hsBusy = true;
        hsApplyProc.command = ["sh", "-c",
            'c="' + hsCon + '"; '
            + 'if nmcli -t connection show "$c" >/dev/null 2>&1; then '
            +   'nmcli connection modify "$c" 802-11-wireless.ssid "$1" 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk "$2" 802-11-wireless.band "$4"; '
            + 'else '
            +   'nmcli connection add type wifi ifname "$3" con-name "$c" autoconnect no 802-11-wireless.ssid "$1" 802-11-wireless.mode ap 802-11-wireless-security.key-mgmt wpa-psk 802-11-wireless-security.psk "$2" 802-11-wireless.band "$4" ipv4.method shared; '
            + 'fi; '
            + 'nmcli connection up "$c"',
            "sh", hsName, hsPw, hsIface, hsBand];
        hsApplyProc.running = true;
    }

    function stopHotspot() {
        if (hsBusy)
            return;
        hsBusy = true;
        hsDownProc.running = true;
    }

    function commitHotspotEdit() {
        if (hsEdit === "name") {
            if (hsDraft.length)
                hsName = hsDraft;
        } else if (hsEdit === "pw") {
            if (hsDraft.length >= 8)
                hsPw = hsDraft;
        }
        hsEdit = "";
        if (hsActive)
            applyHotspot();
    }

    function generatePw() {
        var cs = "abcdefghijkmnpqrstuvwxyz23456789";
        var s = "";
        for (var i = 0; i < 8; i++)
            s += cs.charAt(Math.floor(Math.random() * cs.length));
        return s;
    }

    onActiveChanged: {
        if (active) {
            refresh();
            leaseTimer.start();
        } else {
            leaseTimer.stop();
            hsEdit = "";
            showPassword = false;
        }
    }

    onVisibleActiveChanged: {
        if (visibleActive) {
            hsStateProc.running = true;
            hsReadProc.running = true;
        }
    }

    Timer {
        id: leaseTimer
        interval: 3000
        repeat: true
        running: false
        onTriggered: root.refreshConnectedDevices()
    }

    Process {
        id: hsApplyProc
        onExited: {
            root.hsBusy = false;
            root.refresh();
        }
    }

    Process {
        id: hsDownProc
        command: ["nmcli", "connection", "down", root.hsCon]
        onExited: {
            root.hsBusy = false;
            root.refresh();
        }
    }

    Process {
        id: hsStateProc
        command: ["sh", "-c", "nmcli -t -f NAME connection show --active | grep -qx " + root.hsCon + " && echo on || echo off"]
        stdout: StdioCollector {
            onStreamFinished: {
                var wasActive = root.hsActive;
                root.hsActive = this.text.trim() === "on";
                if (wasActive !== root.hsActive)
                    root.refreshConnectedDevices();
            }
        }
    }

    Process {
        id: hsReadProc
        command: ["nmcli", "-t", "-s", "-g", "802-11-wireless.ssid,802-11-wireless-security.psk,802-11-wireless.band", "connection", "show", root.hsCon]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                if (lines.length >= 1 && lines[0].length)
                    root.hsName = lines[0];
                if (lines.length >= 2 && lines[1].length)
                    root.hsPw = lines[1];
                if (lines.length >= 3 && lines[2].length) {
                    var band = lines[2].trim();
                    root.hsBand = (band === "a") ? "a" : "bg";
                }
            }
        }
    }

    Process {
        id: leasesProc
        command: ["sh", "-c", "cat /var/lib/NetworkManager/dnsmasq-*.leases 2>/dev/null | awk '{print \"{\\\"ip\\\":\\\"\"$3\"\\\",\\\"mac\\\":\\\"\"$2\"\\\",\\\"name\\\":\\\"\"$4\"\\\"}\"}' | jq -s '.'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.connectedDevices = JSON.parse(this.text.trim());
                } catch(e) {
                    root.connectedDevices = [];
                }
            }
        }
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 24 * root.s

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8 * root.s

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 17 * root.s
                height: 17 * root.s

                GlyphIcon {
                    anchors.fill: parent
                    name: "chevron-left"
                    color: backArea.containsMouse ? Theme.cream : Theme.iconDim
                    stroke: 1.8
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.back()
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "HOTSPOT"
                color: Theme.subtle
                font.family: Theme.font
                font.pixelSize: 10 * root.s
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.6 * root.s
            }
        }
    }

    Rectangle {
        id: divider
        anchors.top: header.bottom
        anchors.topMargin: 9 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hair
    }

    Column {
        id: hsCol
        anchors.top: divider.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 6 * root.s

        Rectangle {
            width: parent.width
            height: 38 * root.s
            radius: 10 * root.s
            color: root.hsActive ? Qt.rgba(Theme.verm.r, Theme.verm.g, Theme.verm.b, 0.14)
                : (hsRowHover.containsMouse ? Theme.frameBg : "transparent")

            MouseArea {
                id: hsRowHover
                anchors.fill: parent
                hoverEnabled: true
            }

            GlyphIcon {
                id: hsGlyph
                anchors.left: parent.left
                anchors.leftMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 17 * root.s
                height: 17 * root.s
                name: "hotspot"
                color: root.hsActive ? Theme.vermLit : Theme.iconDim
                stroke: 1.7
            }

            Column {
                anchors.left: hsGlyph.right
                anchors.leftMargin: 11 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1 * root.s

                Text {
                    text: "Broadcasting"
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.weight: Font.DemiBold
                }
                Text {
                    text: root.hsBusy ? "…" : (root.hsActive ? "Active" : "Off")
                    color: root.hsActive ? Theme.vermLit : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 9.5 * root.s
                    font.weight: Font.Medium
                }
            }

            LinkToggle {
                s: root.s
                anchors.right: parent.right
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                on: root.hsActive
                onToggled: {
                    if (root.hsActive) {
                        root.stopHotspot();
                    } else {
                        if (root.hsPw.length < 8)
                            root.hsPw = root.generatePw();
                        root.applyHotspot();
                    }
                }
            }
        }

        component CredRow: Item {
            id: cr
            property string field: ""
            property string label: ""
            property string value: ""
            property bool secret: false
            readonly property bool editing: root.hsEdit === cr.field
            width: parent ? parent.width : 0
            height: 26 * root.s

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: cr.label
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1 * root.s
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                Text {
                    visible: !cr.editing
                    anchors.verticalCenter: parent.verticalCenter
                    text: cr.value.length ? (cr.secret && !root.showPassword ? "••••••••" : cr.value) : "tap to set"
                    color: cr.value.length ? Theme.cream : Theme.faint
                    font.family: Theme.font
                    font.pixelSize: 11.5 * root.s
                    font.weight: Font.Medium

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6 * root.s
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.hsDraft = cr.value;
                            root.hsEdit = cr.field;
                            Qt.callLater(crField.forceActiveFocus);
                        }
                    }
                }

                Text {
                    visible: cr.secret && !cr.editing
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.showPassword ? "󰈉" : "󰈈"
                    font.pixelSize: 14 * root.s
                    color: eyeArea.containsMouse ? Theme.cream : Theme.dim

                    MouseArea {
                        id: eyeArea
                        anchors.fill: parent
                        anchors.margins: -6 * root.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showPassword = !root.showPassword
                    }
                }
            }

            TextField {
                id: crField
                visible: cr.editing
                anchors.right: parent.right
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                width: 150 * root.s
                horizontalAlignment: TextInput.AlignRight
                background: null
                padding: 0
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 11.5 * root.s
                placeholderText: cr.field === "pw" ? "8+ characters" : "Name"
                placeholderTextColor: Theme.faint
                selectByMouse: true
                selectionColor: Theme.verm
                text: cr.editing ? root.hsDraft : ""
                echoMode: (cr.secret && !root.showPassword) ? TextInput.Password : TextInput.Normal
                onTextEdited: root.hsDraft = text
                onAccepted: root.commitHotspotEdit()
                onActiveFocusChanged: if (!activeFocus && cr.editing) root.commitHotspotEdit()
            }
        }

        CredRow {
            field: "name"
            label: "Name"
            value: root.hsName
        }

        CredRow {
            field: "pw"
            label: "Password"
            value: root.hsPw
            secret: true
        }

        Item {
            width: parent.width
            height: 26 * root.s

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "AP Band"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Bold
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1 * root.s
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * root.s

                Rectangle {
                    width: 48 * root.s
                    height: 18 * root.s
                    radius: 4 * root.s
                    color: root.hsBand === "bg" ? Theme.verm : Theme.frameBg
                    border.width: 1
                    border.color: root.hsBand === "bg" ? "transparent" : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "2.4G"
                        color: root.hsBand === "bg" ? Theme.cream : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.hsBand !== "bg") {
                                root.hsBand = "bg";
                                if (root.hsActive) root.applyHotspot();
                            }
                        }
                    }
                }

                Rectangle {
                    width: 48 * root.s
                    height: 18 * root.s
                    radius: 4 * root.s
                    color: root.hsBand === "a" ? Theme.verm : Theme.frameBg
                    border.width: 1
                    border.color: root.hsBand === "a" ? "transparent" : Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: "5G"
                        color: root.hsBand === "a" ? Theme.cream : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 10 * root.s
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.hsBand !== "a") {
                                root.hsBand = "a";
                                if (root.hsActive) root.applyHotspot();
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hair
        }

        Item {
            width: parent.width
            height: 20 * root.s

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "CONNECTED DEVICES"
                color: Theme.faint
                font.family: Theme.font
                font.pixelSize: 9 * root.s
                font.weight: Font.Bold
                font.letterSpacing: 1.2 * root.s
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: root.connectedDevices.length
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10 * root.s
                font.weight: Font.Bold
            }
        }

        Column {
            width: parent.width
            spacing: 2 * root.s

            Repeater {
                model: root.connectedDevices

                Rectangle {
                    id: deviceRow
                    width: parent.width
                    height: 34 * root.s
                    radius: 8 * root.s
                    color: devHover.hovered ? Theme.frameBg : "transparent"

                    HoverHandler { id: devHover }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 10 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1 * root.s

                        Text {
                            text: (modelData.name && modelData.name !== "*") ? modelData.name : "Unknown Device"
                            color: Theme.cream
                            font.family: Theme.font
                            font.pixelSize: 11 * root.s
                            font.weight: Font.Medium
                        }
                        Text {
                            text: modelData.ip + " · " + modelData.mac.toUpperCase()
                            color: Theme.faint
                            font.family: Theme.font
                            font.pixelSize: 8.5 * root.s
                        }
                    }
                }
            }

            Text {
                visible: root.connectedDevices.length === 0
                leftPadding: 10 * root.s
                topPadding: 2 * root.s
                text: "No devices connected"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 10.5 * root.s
            }
        }
    }
}
