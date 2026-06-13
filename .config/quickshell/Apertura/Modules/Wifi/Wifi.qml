import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../.."

Item {
    id: wifiRoot

    property bool hasWifiCard: false
    implicitWidth: hasWifiCard ? 32 : 0
    implicitHeight: hasWifiCard ? 32 : 0
    visible: hasWifiCard

    property int signalStrength: 0
    property string ssid: "Disconnected"
    property bool enteringPassword: false
    property bool showingForgetConfirm: false
    property string selectedSsid: ""
    property bool wifiEnabled: true

    Process {
        id: hardwareCheck
        command: ["sh", "-c", "if [ -d /sys/class/net ] && expr \"$(ls -d /sys/class/net/*/wireless 2>/dev/null)\" : '.*wireless' >/dev/null; then exit 0; else exit 1; fi"]
        running: true
        onExited: code => {
            if (code === 0) {
                wifiRoot.hasWifiCard = true;
                statusWatcher.running = true;
            } else {
                wifiRoot.hasWifiCard = false;
                statusWatcher.running = false;
            }
        }
    }

    Process {
        id: statusWatcher
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL,SSID", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!wifiRoot.hasWifiCard)
                    return;
                let lines = text.split('\n');
                let foundActive = false;
                for (let line of lines) {
                    let parts = line.split(':');
                    if (parts.length >= 3 && parts[0] === "yes") {
                        wifiRoot.signalStrength = parseInt(parts[1]) || 0;
                        wifiRoot.ssid = parts[2];
                        foundActive = true;
                        break;
                    }
                }
                if (!foundActive) {
                    wifiRoot.signalStrength = 0;
                    wifiRoot.ssid = "Disconnected";
                }
            }
        }
    }

    ListModel {
        id: wifiNetworksModel
    }

    Process {
        id: networkScanner
        command: ["nmcli", "-t", "-f", "SSID,SECURITY,BARS,ACTIVE", "dev", "wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (!wifiRoot.hasWifiCard)
                    return;
                wifiNetworksModel.clear();
                let lines = text.split('\n');
                let seenSsids = new Set();
                for (let line of lines) {
                    if (!line.trim())
                        continue;
                    let parts = line.split(':');
                    if (parts.length >= 4 && parts[0].length > 0) {
                        let ssidName = parts[0];
                        let isActive = parts[3] === "yes";
                        if (seenSsids.has(ssidName) && !isActive)
                            continue;
                        if (isActive && seenSsids.has(ssidName)) {
                            for (let i = 0; i < wifiNetworksModel.count; i++) {
                                if (wifiNetworksModel.get(i).ssidName === ssidName) {
                                    wifiNetworksModel.remove(i);
                                    break;
                                }
                            }
                        }
                        seenSsids.add(ssidName);
                        wifiNetworksModel.append({
                            "ssidName": ssidName,
                            "secured": parts[1] !== "" && parts[1] !== "--",
                            "bars": parts[2],
                            "isActive": isActive
                        });
                    }
                }
            }
        }
    }

    Process {
        id: nmcActionExecutor
        command: []
        running: false
    }

    function barsToInt(b) {
        if (b === "▂▄▆█")
            return 4;
        if (b === "▂▄▆_")
            return 3;
        if (b === "▂▄__")
            return 2;
        return 1;
    }

    function triggerScan() {
        if (!wifiRoot.wifiEnabled || !wifiRoot.hasWifiCard)
            return;
        networkScanner.running = true;
        statusWatcher.running = true;
    }

    function forgetNetwork(targetSsid) {
        nmcActionExecutor.command = ["nmcli", "connection", "delete", targetSsid];
        nmcActionExecutor.running = true;
        wifiRoot.showingForgetConfirm = false;
        triggerScan();
    }

    function connectToNetwork(targetSsid, password) {
        nmcActionExecutor.command = password !== "" ? ["nmcli", "dev", "wifi", "connect", targetSsid, "password", password] : ["nmcli", "dev", "wifi", "connect", targetSsid];
        nmcActionExecutor.running = true;
        wifiRoot.enteringPassword = false;
        drawerTemplate.isOpen = false;
        triggerScan();
    }

    component SignalBars: Row {
        property int strength: 0
        property color activeColor: "#1D9E75"
        spacing: 2

        Repeater {
            model: 4
            delegate: Rectangle {
                width: 3
                height: 4 + index * 3
                radius: 1
                anchors.bottom: parent ? parent.bottom : undefined
                color: (index < Math.ceil(strength / 25)) ? activeColor : Qt.rgba(1, 1, 1, 0.15)
            }
        }
    }

    component NetworkRow: Rectangle {
        id: netRow
        implicitHeight: netRowContent.implicitHeight + 18
        radius: 8
        color: netRowHover.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"

        property string ssidName: ""
        property bool secured: false
        property string bars: ""
        property bool isActive: false

        signal connectRequested(string ssid, bool needsPassword)
        signal forgetRequested(string ssid)

        RowLayout {
            id: netRowContent
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: 8
            }
            spacing: 10

            SignalBars {
                strength: wifiRoot.barsToInt(netRow.bars) * 25
                activeColor: netRow.isActive ? "#1D9E75" : wifiRoot.barsToInt(netRow.bars) >= 3 ? "#1D9E75" : wifiRoot.barsToInt(netRow.bars) === 2 ? "#EF9F27" : "#E24B4A"
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: netRow.ssidName
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: netRow.isActive ? "#1D9E75" : Qt.rgba(1, 1, 1, 0.85)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    text: netRow.secured ? "Secured" : "Open"
                    font.pixelSize: 11
                    color: Qt.rgba(1, 1, 1, 0.35)
                }
            }

            Text {
                text: netRow.secured ? "󰌾" : ""
                font.pixelSize: 13
                font.family: "JetBrainsMono Nerd Font"
                color: Qt.rgba(1, 1, 1, 0.25)
            }
        }

        MouseArea {
            id: netRowHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton && netRow.isActive) {
                    netRow.forgetRequested(netRow.ssidName);
                } else {
                    netRow.connectRequested(netRow.ssidName, netRow.secured);
                }
            }
        }
    }

    component FooterButton: Rectangle {
        property string iconText: ""
        property string label: ""
        signal clicked

        implicitHeight: footerBtnRow.implicitHeight + 24
        color: footerBtnHover.containsMouse ? Qt.rgba(1, 1, 1, 0.04) : "transparent"

        RowLayout {
            id: footerBtnRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: parent.parent.iconText
                font.pixelSize: 14
                font.family: "JetBrainsMono Nerd Font"
                color: Qt.rgba(1, 1, 1, 0.45)
            }
            Text {
                text: parent.parent.label
                font.pixelSize: 13
                color: Qt.rgba(1, 1, 1, 0.55)
            }
        }

        MouseArea {
            id: footerBtnHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
        }
    }

    component ActionButton: Rectangle {
        property string label: ""
        property bool accent: false
        property bool danger: false
        signal clicked

        implicitHeight: 34
        radius: 8
        color: accent ? Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.2) : danger ? Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.15) : Qt.rgba(1, 1, 1, 0.06)
        border.color: accent ? Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.35) : danger ? Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.3) : Qt.rgba(1, 1, 1, 0.1)
        border.width: 0.5

        Text {
            anchors.centerIn: parent
            text: parent.label
            font.pixelSize: 13
            color: parent.accent ? "#378ADD" : parent.danger ? "#E24B4A" : Qt.rgba(1, 1, 1, 0.7)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    // Tray icon
    Rectangle {
        id: trayButton
        width: 32
        height: 32
        radius: 8
        color: drawerTemplate.isOpen ? Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.15) : "transparent"

        Text {
            anchors.centerIn: parent
            text: wifiRoot.wifiEnabled ? (wifiRoot.signalStrength > 66 ? "󰤨" : wifiRoot.signalStrength > 33 ? "󰤥" : "󰤢") : "󰤭"
            font.pixelSize: 18
            font.family: "JetBrainsMono Nerd Font"
            color: wifiRoot.ssid !== "Disconnected" ? "#378ADD" : Qt.rgba(1, 1, 1, 0.5)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: drawerTemplate.isOpen = !drawerTemplate.isOpen
        }
    }

    PanelDrawer {
        id: drawerTemplate
        isOpen: false
        drawerHeight: 450
        modalToken: "wifi"
        anchorTop: false

        onIsOpenChanged: {
            if (isOpen) {
                triggerScan();
            } else {
                wifiRoot.enteringPassword = false;
                wifiRoot.showingForgetConfirm = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            clip: true

            StackLayout {
                anchors.fill: parent
                currentIndex: wifiRoot.enteringPassword ? 1 : (wifiRoot.showingForgetConfirm ? 2 : 0)

                // ── View 0: Main network list ──────────────────────────────
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        Layout.topMargin: 18
                        Layout.bottomMargin: 14
                        spacing: 12

                        RowLayout {
                            spacing: 8

                            Text {
                                text: "󰖩"
                                font.pixelSize: 17
                                font.family: "JetBrainsMono Nerd Font"
                                color: "#378ADD"
                            }
                            Text {
                                text: "Wi-Fi"
                                font.pixelSize: 15
                                font.weight: Font.Medium
                                color: Qt.rgba(1, 1, 1, 0.9)
                            }
                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 38
                                height: 22
                                radius: 11
                                color: wifiRoot.wifiEnabled ? "#378ADD" : Qt.rgba(1, 1, 1, 0.15)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 180
                                    }
                                }

                                Rectangle {
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "white"
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: wifiRoot.wifiEnabled ? parent.width - width - 3 : 3
                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 180
                                            easing.type: Easing.InOutQuad
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        wifiRoot.wifiEnabled = !wifiRoot.wifiEnabled;
                                        if (wifiRoot.wifiEnabled)
                                            triggerScan();
                                        else
                                            wifiNetworksModel.clear();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: activePillRow.implicitHeight + 20
                            radius: 10
                            color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.12)
                            border.color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.25)
                            border.width: 0.5
                            visible: wifiRoot.ssid !== "Disconnected"

                            RowLayout {
                                id: activePillRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 12
                                }
                                spacing: 8

                                SignalBars {
                                    strength: wifiRoot.signalStrength
                                    activeColor: "#378ADD"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: wifiRoot.ssid
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: "#378ADD"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Connected · " + wifiRoot.signalStrength + "%"
                                        font.pixelSize: 11
                                        color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.7)
                                    }
                                }

                                Text {
                                    text: "›"
                                    font.pixelSize: 16
                                    color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.6)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 0.5
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }

                    Text {
                        text: "Available networks"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Qt.rgba(1, 1, 1, 0.35)
                        font.letterSpacing: 0.5
                        Layout.leftMargin: 16
                        Layout.topMargin: 10
                        Layout.bottomMargin: 4
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        ColumnLayout {
                            width: parent.width
                            spacing: 0

                            Repeater {
                                model: wifiNetworksModel
                                delegate: NetworkRow {
                                    Layout.fillWidth: true
                                    ssidName: model.ssidName
                                    secured: model.secured
                                    bars: model.bars
                                    isActive: model.isActive
                                    onConnectRequested: (ssid, needsPassword) => {
                                        if (needsPassword) {
                                            wifiRoot.selectedSsid = ssid;
                                            wifiRoot.enteringPassword = true;
                                        } else {
                                            connectToNetwork(ssid, "");
                                        }
                                    }
                                    onForgetRequested: ssid => {
                                        wifiRoot.selectedSsid = ssid;
                                        wifiRoot.showingForgetConfirm = true;
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                height: 40
                                visible: wifiNetworksModel.count === 0

                                Text {
                                    anchors.centerIn: parent
                                    text: wifiRoot.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
                                    font.pixelSize: 13
                                    color: Qt.rgba(1, 1, 1, 0.3)
                                }
                            }
                        }
                    }

                    Item {
                        implicitHeight: 8
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 0.5
                        color: Qt.rgba(1, 1, 1, 0.07)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        FooterButton {
                            Layout.fillWidth: true
                            iconText: "󰑓"
                            label: "Scan"
                            onClicked: triggerScan()
                        }

                        Rectangle {
                            width: 0.5
                            height: parent.height
                            color: Qt.rgba(1, 1, 1, 0.07)
                        }

                        FooterButton {
                            Layout.fillWidth: true
                            iconText: "󰒓"
                            label: "Settings"
                            onClicked: Qt.openUrlExternally("nm-connection-editor")
                        }
                    }
                }

                // ── View 1: Password prompt ────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Back header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 16
                        Layout.bottomMargin: 0
                        spacing: 8

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 8
                            color: backHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 0.5

                            Text {
                                anchors.centerIn: parent
                                text: "󰁍"
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                color: Qt.rgba(1, 1, 1, 0.6)
                            }

                            MouseArea {
                                id: backHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    wifiRoot.enteringPassword = false;
                                    passwordField.text = "";
                                }
                            }
                        }

                        Text {
                            text: "Connect to network"
                            font.pixelSize: 13
                            color: Qt.rgba(1, 1, 1, 0.4)
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 16
                        Layout.topMargin: 20
                        spacing: 16

                        // Network identity card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: networkCardRow.implicitHeight + 24
                            radius: 12
                            color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.08)
                            border.color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.18)
                            border.width: 0.5

                            RowLayout {
                                id: networkCardRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 14
                                }
                                spacing: 12

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.15)
                                    border.color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.25)
                                    border.width: 0.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰖩"
                                        font.pixelSize: 16
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: "#378ADD"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: wifiRoot.selectedSsid
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: Qt.rgba(1, 1, 1, 0.9)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    RowLayout {
                                        spacing: 4
                                        Text {
                                            text: "󰌾"
                                            font.pixelSize: 10
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Qt.rgba(1, 1, 1, 0.3)
                                        }
                                        Text {
                                            text: "Password required"
                                            font.pixelSize: 11
                                            color: Qt.rgba(1, 1, 1, 0.35)
                                        }
                                    }
                                }
                            }
                        }

                        // Password field
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Password"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.letterSpacing: 0.4
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 40
                                radius: 10
                                color: passwordField.activeFocus ? Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.08) : Qt.rgba(1, 1, 1, 0.05)
                                border.color: passwordField.activeFocus ? Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.45) : Qt.rgba(1, 1, 1, 0.1)
                                border.width: 0.5

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                RowLayout {
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 12
                                        rightMargin: 8
                                    }
                                    spacing: 8

                                    TextField {
                                        id: passwordField
                                        Layout.fillWidth: true
                                        placeholderText: "Enter password"
                                        echoMode: showPw.checked ? TextInput.Normal : TextInput.Password
                                        font.pixelSize: 13
                                        color: Qt.rgba(1, 1, 1, 0.9)
                                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.25)
                                        background: Item {}
                                        padding: 0
                                        leftPadding: 0
                                        rightPadding: 0
                                        topPadding: 0
                                        bottomPadding: 0
                                        onAccepted: {
                                            connectToNetwork(wifiRoot.selectedSsid, text);
                                            text = "";
                                        }
                                    }

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 6
                                        color: showPwHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

                                        CheckBox {
                                            id: showPw
                                            anchors.fill: parent
                                            checked: false
                                            indicator: Item {}
                                            background: Item {}
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: showPw.checked ? "󰛓" : "󰛑"
                                            font.pixelSize: 13
                                            font.family: "JetBrainsMono Nerd Font"
                                            color: Qt.rgba(1, 1, 1, 0.35)
                                        }

                                        MouseArea {
                                            id: showPwHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: showPw.checked = !showPw.checked
                                        }
                                    }
                                }
                            }
                        }

                        // Action buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ActionButton {
                                Layout.fillWidth: true
                                label: "Cancel"
                                onClicked: {
                                    wifiRoot.enteringPassword = false;
                                    passwordField.text = "";
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: 8
                                color: connectHover.containsMouse ? Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.35) : Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.25)
                                border.color: Qt.rgba(55 / 255, 138 / 255, 221 / 255, 0.5)
                                border.width: 0.5
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰖩"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: "#378ADD"
                                    }
                                    Text {
                                        text: "Connect"
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: "#378ADD"
                                    }
                                }

                                MouseArea {
                                    id: connectHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        connectToNetwork(wifiRoot.selectedSsid, passwordField.text);
                                        passwordField.text = "";
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Forget Confirm
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    // Back header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.margins: 16
                        Layout.bottomMargin: 0
                        spacing: 8

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 8
                            color: forgetBackHover.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04)
                            border.color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 0.5

                            Text {
                                anchors.centerIn: parent
                                text: "󰁍"
                                font.pixelSize: 14
                                font.family: "JetBrainsMono Nerd Font"
                                color: Qt.rgba(1, 1, 1, 0.6)
                            }

                            MouseArea {
                                id: forgetBackHover
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: wifiRoot.showingForgetConfirm = false
                            }
                        }

                        Text {
                            text: "Forget network"
                            font.pixelSize: 13
                            color: Qt.rgba(1, 1, 1, 0.4)
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: 16
                        Layout.topMargin: 20
                        spacing: 16

                        // Network identity card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: forgetCardRow.implicitHeight + 24
                            radius: 12
                            color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.08)
                            border.color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.18)
                            border.width: 0.5

                            RowLayout {
                                id: forgetCardRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 14
                                }
                                spacing: 12

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 10
                                    color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.15)
                                    border.color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.25)
                                    border.width: 0.5

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰖩"
                                        font.pixelSize: 16
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: "#E24B4A"
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: wifiRoot.selectedSsid
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: Qt.rgba(1, 1, 1, 0.9)
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: "Will be removed from saved networks"
                                        font.pixelSize: 11
                                        color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.6)
                                    }
                                }
                            }
                        }

                        // Warning text
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: warningRow.implicitHeight + 16
                            radius: 8
                            color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.05)
                            border.color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.12)
                            border.width: 0.5

                            RowLayout {
                                id: warningRow
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    margins: 12
                                }
                                spacing: 8

                                Text {
                                    text: "󰀦"
                                    font.pixelSize: 14
                                    font.family: "JetBrainsMono Nerd Font"
                                    color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.7)
                                    Layout.alignment: Qt.AlignTop
                                }
                                Text {
                                    text: "You'll need to enter the password again to reconnect to this network."
                                    font.pixelSize: 12
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ActionButton {
                                Layout.fillWidth: true
                                label: "Cancel"
                                onClicked: wifiRoot.showingForgetConfirm = false
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
                                radius: 8
                                color: forgetConfirmHover.containsMouse ? Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.3) : Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.18)
                                border.color: Qt.rgba(226 / 255, 75 / 255, 74 / 255, 0.45)
                                border.width: 0.5
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰺝"
                                        font.pixelSize: 13
                                        font.family: "JetBrainsMono Nerd Font"
                                        color: "#E24B4A"
                                    }
                                    Text {
                                        text: "Forget"
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        color: "#E24B4A"
                                    }
                                }

                                MouseArea {
                                    id: forgetConfirmHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: forgetNetwork(wifiRoot.selectedSsid)
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
