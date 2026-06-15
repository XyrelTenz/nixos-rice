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

    property string connectionIcon: activeIface === "None" ? "cloud_off" : "cloud_upload"

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
                    netRoot.downloadSpeed = formatBytes(curRx - prevRx);
                    netRoot.uploadSpeed = formatBytes(curTx - prevTx);
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

    Timer {
        id: netTicker
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netFetcher.running = false;
            netFetcher.running = true;
        }
    }

    Component.onCompleted: {
        netFetcher.running = true;
    }

    Rectangle {
        id: netHitbox
        anchors.fill: parent
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: netRoot.connectionIcon
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: netRoot.activeIface === "None" ? "#f38ba8" : (iconMouseArea.containsMouse ? (rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa") : (rootScope.theme ? rootScope.theme.theme_fg : "#cdd6f4"))

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
        drawerHeight: 192
        modalToken: "netmonitor"
        anchorTop: false

        onIsOpenChanged: {
            if (isOpen) {
                netRoot.menuOpen = true;
                checkUserActivity();
                mainContainerLayout.forceActiveFocus();
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
            id: mainContainerLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0
            focus: true

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                spacing: 8

                Rectangle {
                    width: 3
                    height: 14
                    radius: 0
                    color: netRoot.activeIface === "None" ? "#f38ba8" : (rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa")

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }
                }

                Text {
                    text: "Network"
                    font.family: "Rubik"
                    font.pixelSize: 14
                    font.weight: Font.SemiBold
                    color: rootScope.theme ? rootScope.theme.theme_fg : "#cdd6f4"
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: statusDot.implicitWidth + statusLabel.implicitWidth + 14
                    height: 18
                    radius: 0
                    color: netRoot.activeIface === "None" ? "#25f38ba8" : "#1ca6e3a1"

                    Behavior on color {
                        ColorAnimation {
                            duration: 300
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            id: statusDot
                            width: 5
                            height: 5
                            radius: 0
                            color: netRoot.activeIface === "None" ? "#f38ba8" : "#a6e3a1"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }

                            SequentialAnimation on opacity {
                                running: netRoot.activeIface !== "None" && drawerTemplate.isOpen
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.3
                                    duration: 800
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 1.0
                                    duration: 800
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }

                        Text {
                            id: statusLabel
                            text: netRoot.activeIface === "None" ? "Offline" : "Online"
                            font.family: "Rubik"
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: netRoot.activeIface === "None" ? "#f38ba8" : "#a6e3a1"

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
                color: "#18ffffff"
                Layout.bottomMargin: 14
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 72
                    color: "transparent"
                    border.color: "#14ffffff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            spacing: 5
                            Text {
                                text: "router"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 12
                                color: "#44ffffff"
                            }
                            Text {
                                text: "Interface"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: "#44ffffff"
                            }
                        }

                        Text {
                            text: netRoot.activeIface
                            font.family: "Rubik"
                            font.pixelSize: 15
                            font.weight: Font.SemiBold
                            color: netRoot.activeIface === "None" ? "#f38ba8" : (rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa")

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: netRoot.activeIface === "None" ? "#f38ba8" : (rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa")
                        opacity: 0.6

                        Behavior on color {
                            ColorAnimation {
                                duration: 300
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 72
                    color: "transparent"
                    border.color: "#14ffffff"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        RowLayout {
                            spacing: 5
                            Text {
                                text: "lan"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 12
                                color: "#44ffffff"
                            }
                            Text {
                                text: "IP Address"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: "#44ffffff"
                            }
                        }

                        Text {
                            text: netRoot.ipAddress
                            font.family: "Rubik"
                            font.pixelSize: 13
                            font.weight: Font.SemiBold
                            color: "#ccffffff"
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: "#40ffffff"
                        opacity: 0.6
                    }
                }
            }

            Item {
                height: 10
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "transparent"
                    border.color: "#14ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 0
                            color: "#1589b4fa"

                            Text {
                                anchors.centerIn: parent
                                text: "arrow_downward"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa"
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "Download"
                                font.family: "Rubik"
                                font.pixelSize: 9
                                color: "#44ffffff"
                            }
                            Text {
                                text: netRoot.downloadSpeed
                                font.family: "Rubik"
                                font.pixelSize: 13
                                font.weight: Font.SemiBold
                                color: "#ddffffff"
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: rootScope.theme ? rootScope.theme.theme_primary : "#89b4fa"
                        opacity: 0.5
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "transparent"
                    border.color: "#14ffffff"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 0
                            color: "#18a6e3a1"

                            Text {
                                anchors.centerIn: parent
                                text: "arrow_upward"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: "#a6e3a1"
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: "Upload"
                                font.family: "Rubik"
                                font.pixelSize: 9
                                color: "#44ffffff"
                            }
                            Text {
                                text: netRoot.uploadSpeed
                                font.family: "Rubik"
                                font.pixelSize: 13
                                font.weight: Font.SemiBold
                                color: "#ddffffff"
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 2
                        color: "#a6e3a1"
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
