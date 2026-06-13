import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.."

Item {
    id: monitorRoot

    implicitWidth: 32
    implicitHeight: 32

    property bool menuOpen: false

    property int cpuPercent: 0
    property int cpuTemp: 0
    property real ramUsed: 0.0
    property real ramTotal: 0.0
    property int ramPercent: 0

    property string diskUsed: "0"
    property string diskTotal: "0"
    property int diskPercent: 0

    property bool hasGpu: false
    property int gpuPercent: 0
    property int gpuTemp: 0

    property var theme: rootScope.theme

    function accentForPercent(pct) {
        if (pct >= 90)
            return "#f38ba8";
        if (pct >= 70)
            return "#f9e2af";
        return theme ? theme.theme_primary : "#89b4fa";
    }

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

    ListModel {
        id: processListModel
    }

    Process {
        id: metricsFetcher
        command: ["sh", "-c", "raw_temp=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1); temp=$((raw_temp / 1000)); while read -r m v _; do case \"$m\" in MemTotal:) t=$v ;; MemAvailable:) a=$v ;; esac; done < /proc/meminfo; read -r _ u n s i iw irq sof _ < /proc/stat; total=$((u + n + s + i + iw + irq + sof)); idle=$((i + iw)); df_out=$(df -h / | tail -n 1 | awk '{ u_val=$3; t_val=$2; sub(/[GGMK]/,\"\",u_val); sub(/[GGMK]/,\"\",t_val); print u_val\" \"t_val\" \"$5}'); g_busy=\"none\"; g_temp=0; if command -v nvidia-smi >/dev/null 2>&1; then nv_out=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null); g_busy=$(echo \"$nv_out\" | awk -F', ' '{print $1}'); g_temp=$(echo \"$nv_out\" | awk -F', ' '{print $2}'); else for card in /sys/class/drm/card*/device; do if [ -f \"$card/gpu_busy_percent\" ]; then cur_b=$(cat \"$card/gpu_busy_percent\" 2>/dev/null); if [ \"$g_busy\" = \"none\" ] || [ \"$cur_b\" -gt \"$g_busy\" ]; then g_busy=$cur_b; fi; hw_t=$(cat $card/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1); [ ! -z \"$hw_t\" ] && g_temp=$((hw_t / 1000)); fi; done; fi; echo \"$total $idle $temp $a $t $df_out $g_busy $g_temp\""]
        running: false

        stdout: StdioCollector {
            property int prevTotal: 0
            property int prevIdle: 0

            onTextChanged: {
                let cleaned = text.trim();
                if (!cleaned)
                    return;
                let parts = cleaned.split(/\s+/);
                if (parts.length < 10)
                    return;

                let curTotal = parseInt(parts[0]);
                let curIdle = parseInt(parts[1]);

                if (prevTotal !== 0) {
                    let diffTotal = curTotal - prevTotal;
                    let diffIdle = curIdle - prevIdle;
                    if (diffTotal > 0) {
                        monitorRoot.cpuPercent = Math.round(((diffTotal - diffIdle) / diffTotal) * 100);
                    }
                }
                prevTotal = curTotal;
                prevIdle = curIdle;

                monitorRoot.cpuTemp = parseInt(parts[2]);
                let availMem = parseFloat(parts[3]);
                let totalMem = parseFloat(parts[4]);

                monitorRoot.ramTotal = totalMem / 1024 / 1024;
                monitorRoot.ramUsed = (totalMem - availMem) / 1024 / 1024;
                monitorRoot.ramPercent = Math.round(((totalMem - availMem) / totalMem) * 100);

                monitorRoot.diskUsed = parts[5];
                monitorRoot.diskTotal = parts[6];
                monitorRoot.diskPercent = parseInt(parts[7].replace("%", ""));

                if (parts[8] === "none") {
                    monitorRoot.hasGpu = false;
                    monitorRoot.gpuPercent = 0;
                    monitorRoot.gpuTemp = 0;
                } else {
                    monitorRoot.hasGpu = true;
                    monitorRoot.gpuPercent = Math.min(Math.max(parseInt(parts[8]), 0), 100);
                    monitorRoot.gpuTemp = Math.max(parseInt(parts[9]), 0);
                }
            }
        }
    }

    Process {
        id: taskListFetcher
        command: ["sh", "-c", "threads=$(nproc); ps -eo comm,pcpu --sort=-pcpu | awk -v t=\"$threads\" 'NR>1 {print $1, $2/t}'"]
        running: false

        stdout: StdioCollector {
            onTextChanged: {
                let cleaned = text.trim();
                if (!cleaned)
                    return;
                let lines = cleaned.split("\n");
                processListModel.clear();
                let maxLines = Math.min(lines.length, 7);
                for (let i = 0; i < maxLines; i++) {
                    let line = lines[i].trim();
                    if (!line)
                        continue;
                    let lastSpace = line.lastIndexOf(" ");
                    if (lastSpace === -1)
                        continue;
                    let pName = line.substring(0, lastSpace).trim();
                    let pCpuRaw = parseFloat(line.substring(lastSpace + 1).trim());
                    if (pName === "ps" || pName === "sh" || pName === "awk" || pName === "quickshell")
                        continue;
                    if (pName && !isNaN(pCpuRaw)) {
                        processListModel.append({
                            "name": pName,
                            "cpu": pCpuRaw.toFixed(1)
                        });
                    }
                }
            }
        }
    }

    Timer {
        id: metricsTicker
        interval: 1000
        running: drawerTemplate.isOpen
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            metricsFetcher.running = false;
            metricsFetcher.running = true;
            taskListFetcher.running = false;
            taskListFetcher.running = true;
        }
    }

    Rectangle {
        id: sysMonitorHitbox
        anchors.fill: parent
        color: "transparent"

        Text {
            anchors.centerIn: parent
            text: "cardiology"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: iconMouseArea.containsMouse ? (monitorRoot.theme ? monitorRoot.theme.theme_primary : "#89b4fa") : (monitorRoot.theme ? monitorRoot.theme.theme_fg : "#cdd6f4")

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
        drawerHeight: monitorRoot.hasGpu ? 390 : 342
        modalToken: "sysmonitor"
        anchorTop: false

        onIsOpenChanged: {
            if (isOpen) {
                monitorRoot.menuOpen = true;
                checkUserActivity();
                mainContainerLayout.forceActiveFocus();
            } else {
                monitorRoot.menuOpen = false;
            }
        }

        MouseArea {
            id: cardHoverTracker
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: checkUserActivity()
        }

        MouseArea {
            id: preventDismiss
            anchors.fill: parent
            onPressed: mouse => {
                mouse.accepted = true;
                checkUserActivity();
            }
        }

        ColumnLayout {
            id: mainContainerLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0
            focus: true

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                spacing: 8

                Rectangle {
                    width: 3
                    height: 16
                    radius: 2
                    color: monitorRoot.theme ? monitorRoot.theme.theme_primary : "#89b4fa"
                }

                Text {
                    text: "System"
                    font.family: "Rubik"
                    font.pixelSize: 14
                    font.weight: Font.SemiBold
                    color: monitorRoot.theme ? monitorRoot.theme.theme_fg : "#cdd6f4"
                }

                Item {
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: "#a6e3a1"

                    SequentialAnimation on opacity {
                        running: drawerTemplate.isOpen
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.3
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
                    text: "Live"
                    font.family: "Rubik"
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: "#66ffffff"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#18ffffff"
                Layout.bottomMargin: 12
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        {
                            label: "CPU",
                            icon: "memory",
                            pct: monitorRoot.cpuPercent,
                            detail: monitorRoot.cpuTemp + "°  ·  " + monitorRoot.cpuPercent + "%",
                            visible: true,
                            barWidth: monitorRoot.cpuPercent / 100.0
                        },
                        {
                            label: "GPU",
                            icon: "display_settings",
                            pct: monitorRoot.gpuPercent,
                            detail: monitorRoot.gpuTemp + "°  ·  " + monitorRoot.gpuPercent + "%",
                            visible: monitorRoot.hasGpu,
                            barWidth: monitorRoot.gpuPercent / 100.0
                        },
                        {
                            label: "RAM",
                            icon: "storage",
                            pct: monitorRoot.ramPercent,
                            detail: monitorRoot.ramUsed.toFixed(1) + " / " + monitorRoot.ramTotal.toFixed(1) + " GB",
                            visible: true,
                            barWidth: monitorRoot.ramPercent / 100.0
                        },
                        {
                            label: "Disk",
                            icon: "hard_drive",
                            pct: monitorRoot.diskPercent,
                            detail: monitorRoot.diskUsed + " / " + monitorRoot.diskTotal + " GB",
                            visible: true,
                            barWidth: monitorRoot.diskPercent / 100.0
                        }
                    ]

                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: modelData.visible
                        Layout.preferredHeight: modelData.visible ? -1 : 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: modelData.icon
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 13
                                color: monitorRoot.accentForPercent(modelData.pct)
                            }

                            Text {
                                text: modelData.label
                                font.family: "Rubik"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: "#99ffffff"
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.detail
                                font.family: "Rubik"
                                font.pixelSize: 11
                                font.weight: Font.SemiBold
                                color: monitorRoot.accentForPercent(modelData.pct)
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 5

                            Rectangle {
                                anchors.fill: parent
                                color: "#14ffffff"
                                radius: 3
                            }

                            Rectangle {
                                height: parent.height
                                width: parent.width * modelData.barWidth
                                color: monitorRoot.accentForPercent(modelData.pct)
                                radius: 3

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 400
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.min(parent.width, 20)
                                    radius: 3
                                    color: "#30ffffff"
                                    visible: modelData.barWidth > 0.02
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#18ffffff"
                Layout.topMargin: 12
                Layout.bottomMargin: 10
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                spacing: 6

                Text {
                    text: "top_apps"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 13
                    color: "#55ffffff"
                }

                Text {
                    text: "Processes"
                    font.family: "Rubik"
                    font.pixelSize: 11
                    font.weight: Font.SemiBold
                    color: "#99ffffff"
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: "by cpu"
                    font.family: "Rubik"
                    font.pixelSize: 9
                    color: "#33ffffff"
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4

                ListView {
                    id: processListView
                    anchors.fill: parent
                    model: processListModel
                    spacing: 3
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: processListView.width
                        height: 28
                        color: procMouse.containsMouse ? "#0effffff" : "transparent"
                        radius: 6

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 0

                            Text {
                                text: (index + 1) + "."
                                font.family: "Rubik"
                                font.pixelSize: 10
                                color: "#33ffffff"
                                Layout.preferredWidth: 18
                            }

                            Text {
                                text: model.name
                                font.family: "Rubik"
                                font.pixelSize: 11
                                color: "#ccffffff"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: model.cpu + "%"
                                font.family: "Rubik"
                                font.pixelSize: 10
                                font.weight: Font.SemiBold
                                color: parseFloat(model.cpu) >= 15 ? "#f38ba8" : parseFloat(model.cpu) >= 5 ? "#f9e2af" : "#55ffffff"
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: procMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }
                    }
                }
            }
        }
    }
}
