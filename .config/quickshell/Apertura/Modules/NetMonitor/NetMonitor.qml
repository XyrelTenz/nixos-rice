import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.."

Item {
    id: netRoot
    implicitWidth: 32
    implicitHeight: 32

    property bool menuOpen: false

    property string activeIface: "None"
    property string ipAddress: "0.0.0.0"
    property string downloadSpeed: "0 B/s"
    property string uploadSpeed: "0 B/s"
    property real downloadBytes: 0
    property real uploadBytes: 0
    property real maxObservedDown: 1024
    property real maxObservedUp: 1024

    property bool isOnline: activeIface !== "None"

    property color primaryColor: rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa"
    property color fgColor: rootScope.theme ? rootScope.theme.theme_fg : "#cdd6f4"
    property color offlineColor: "#f38ba8"
    property color uploadColor: "#a6e3a1"
    property color surfaceColor: "#0dffffff"
    property color borderColor: "#18ffffff"
    property color mutedText: "#66ffffff"
    property color dimText: "#33ffffff"

    Timer {
        id: osdAutohideTimer
        interval: Config.autohideInterval
        running: false
        repeat: false
        onTriggered: closeMenu()
    }

    function toggleMenu(): void {
        drawerTemplate.isOpen = !drawerTemplate.isOpen;
    }

    function closeMenu(): void {
        drawerTemplate.isOpen = false;
    }

    function checkUserActivity() {
        if (cardHoverTracker.containsMouse) {
            osdAutohideTimer.stop();
        } else if (drawerTemplate.isOpen) {
            osdAutohideTimer.restart();
        }
    }

    Connections {
        target: rootScope
        function onActiveModalChanged() {
            if (rootScope.activeModal !== drawerTemplate.modalToken && drawerTemplate.isOpen) {
                closeMenu();
            }
        }
    }

    Process {
        id: netFetcher
        running: true
        command: ["sh", "-c", "while true; do " + "iface=$(ip route show | awk '$1 == \"default\" {print $5; exit}'); " + "if [ -z '$iface' ]; then iface=$(ip -4 link show up | awk -F': ' '$2 != \"lo\" {print $2; exit}'); fi; " + "if [ -n '$iface' ]; then " + "  ip_addr=$(ip -4 addr show dev \"$iface\" | awk '$1 == \"inet\" {split($2, a, \"/\"); print a[1]; exit}'); " + "  stats=$(awk -v d=\"$iface\" '{gsub(/[: \t]+/, \" \"); if ($1 == d) print $2\" \"$10}' /proc/net/dev); " + "  echo \"$iface $ip_addr $stats\"; " + "else " + "  echo 'None 0.0.0.0 0 0'; " + "fi; " + "sleep 3; " + "done"]

        stdout: SplitParser {
            property var prevRx: 0
            property var prevTx: 0

            onRead: text => {
                let cleaned = text.trim();
                if (!cleaned)
                    return;

                let parts = cleaned.split(" ");
                if (parts.length < 4)
                    return;

                netRoot.activeIface = parts[0];
                netRoot.ipAddress = parts[1];

                let curRx = parseInt(parts[2]);
                let curTx = parseInt(parts[3]);

                if (prevRx !== 0 && curRx >= prevRx) {
                    let rxDelta = curRx - prevRx;
                    let txDelta = curTx - prevTx;
                    netRoot.downloadBytes = rxDelta;
                    netRoot.uploadBytes = txDelta;
                    netRoot.downloadSpeed = formatBytes(rxDelta);
                    netRoot.uploadSpeed = formatBytes(txDelta);

                    if (rxDelta > netRoot.maxObservedDown)
                        netRoot.maxObservedDown = rxDelta;
                    if (txDelta > netRoot.maxObservedUp)
                        netRoot.maxObservedUp = txDelta;
                }

                prevRx = curRx;
                prevTx = curTx;
            }

            function formatBytes(bytes) {
                if (bytes === 0)
                    return "0 B/s";
                let k = 1024;
                let sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
                let i = Math.floor(Math.log(bytes) / Math.log(k));
                return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
            }
        }
    }

    Component.onCompleted: {
        netFetcher.running = true;
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: netRoot.isOnline ? "cloud_upload" : "cloud_off"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: netRoot.isOnline ? (iconMouseArea.containsMouse ? netRoot.primaryColor : netRoot.fgColor) : netRoot.offlineColor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        MouseArea {
            id: iconMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleMenu()
        }
    }

    PanelDrawer {
        id: drawerTemplate
        isOpen: false
        drawerHeight: 220
        modalToken: "netmonitor"
        anchorTop: false

        onIsOpenChanged: {
            if (isOpen) {
                netRoot.menuOpen = true;
                checkUserActivity();
                panelRoot.forceActiveFocus();
            } else {
                netRoot.menuOpen = false;
            }
        }

        MouseArea {
            id: cardHoverTracker
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: checkUserActivity()
        }

        ColumnLayout {
            id: panelRoot
            anchors.fill: parent
            spacing: 0
            focus: true

            Rectangle {
                Layout.fillWidth: true
                height: 44
                color: netRoot.surfaceColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 0
                        color: netRoot.isOnline ? Qt.rgba(netRoot.primaryColor.r, netRoot.primaryColor.g, netRoot.primaryColor.b, 0.12) : Qt.rgba(netRoot.offlineColor.r, netRoot.offlineColor.g, netRoot.offlineColor.b, 0.12)

                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: netRoot.isOnline ? "lan" : "cloud_off"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 15
                            color: netRoot.isOnline ? netRoot.primaryColor : netRoot.offlineColor

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                    }

                    // Title
                    Text {
                        text: "Network"
                        font.family: "Rubik"
                        font.pixelSize: 13
                        font.weight: Font.SemiBold
                        color: netRoot.fgColor
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        height: 20
                        width: pillRow.implicitWidth + 16
                        radius: 0
                        color: netRoot.isOnline ? "#14a6e3a1" : "#14f38ba8"

                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }

                        RowLayout {
                            id: pillRow
                            anchors.centerIn: parent
                            spacing: 5

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 2.5
                                color: netRoot.isOnline ? netRoot.uploadColor : netRoot.offlineColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }

                                SequentialAnimation on opacity {
                                    running: netRoot.isOnline && drawerTemplate.isOpen
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 0.25
                                        duration: 900
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 1.0
                                        duration: 900
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }

                            Text {
                                text: netRoot.isOnline ? "Online" : "Offline"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: netRoot.isOnline ? netRoot.uploadColor : netRoot.offlineColor

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: netRoot.borderColor
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 64
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 4

                        RowLayout {
                            spacing: 4
                            Text {
                                text: "router"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 11
                                color: netRoot.dimText
                            }
                            Text {
                                text: "Interface"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: netRoot.dimText
                            }
                        }

                        Text {
                            text: netRoot.activeIface
                            font.family: "Rubik"
                            font.pixelSize: 15
                            font.weight: Font.SemiBold
                            color: netRoot.isOnline ? netRoot.primaryColor : netRoot.offlineColor

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 64
                    color: netRoot.borderColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 64
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 4

                        RowLayout {
                            spacing: 4
                            Text {
                                text: "lan"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 11
                                color: netRoot.dimText
                            }
                            Text {
                                text: "IP Address"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: netRoot.dimText
                            }
                        }

                        Text {
                            text: netRoot.ipAddress
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.weight: Font.SemiBold
                            color: netRoot.fgColor

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: netRoot.borderColor
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 4

                        RowLayout {
                            spacing: 6

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 0
                                color: Qt.rgba(netRoot.primaryColor.r, netRoot.primaryColor.g, netRoot.primaryColor.b, 0.12)

                                Text {
                                    anchors.centerIn: parent
                                    text: "arrow_downward"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 12
                                    color: netRoot.primaryColor
                                }
                            }

                            Text {
                                text: "Download"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: netRoot.mutedText
                            }
                        }

                        Text {
                            id: downloadSpeedLabel
                            text: netRoot.downloadSpeed
                            font.family: "Rubik"
                            font.pixelSize: 14
                            font.weight: Font.SemiBold
                            color: "#eeffffff"

                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation {
                                        target: downloadSpeedLabel
                                        property: "opacity"
                                        to: 0.4
                                        duration: 120
                                    }
                                    NumberAnimation {
                                        target: downloadSpeedLabel
                                        property: "opacity"
                                        to: 1.0
                                        duration: 120
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: netRoot.borderColor
                            radius: 0

                            Rectangle {
                                width: netRoot.maxObservedDown > 0 ? Math.min(parent.width * (netRoot.downloadBytes / netRoot.maxObservedDown), parent.width) : 0
                                height: parent.height
                                color: netRoot.primaryColor
                                opacity: 0.7
                                radius: 0

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: 1
                    height: 80
                    color: netRoot.borderColor
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 4

                        RowLayout {
                            spacing: 6

                            Rectangle {
                                width: 20
                                height: 20
                                radius: 0
                                color: "#12a6e3a1"

                                Text {
                                    anchors.centerIn: parent
                                    text: "arrow_upward"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 12
                                    color: netRoot.uploadColor
                                }
                            }

                            Text {
                                text: "Upload"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: netRoot.mutedText
                            }
                        }

                        Text {
                            id: uploadSpeedLabel
                            text: netRoot.uploadSpeed
                            font.family: "Rubik"
                            font.pixelSize: 14
                            font.weight: Font.SemiBold
                            color: "#eeffffff"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 2
                            color: netRoot.borderColor
                            radius: 0

                            Rectangle {
                                width: netRoot.maxObservedUp > 0 ? Math.min(parent.width * (netRoot.uploadBytes / netRoot.maxObservedUp), parent.width) : 0
                                height: parent.height
                                color: netRoot.uploadColor
                                opacity: 0.7
                                radius: 0

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
