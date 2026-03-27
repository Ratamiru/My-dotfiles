import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

ShellRoot {
    id: root

    // ── Workspaces (400ms poll) ──────────────────────────
    property var workspaces: []

    Process {
        id: wsProc
        command: ["niri", "msg", "-j", "workspaces"]
        stdout: StdioCollector { id: wsOut }
        onExited: {
            try { root.workspaces = JSON.parse(wsOut.text) } catch(e) {}
            wsTimer.start()
        }
    }
    Timer { id: wsTimer; interval: 400; repeat: false; running: true
        onTriggered: wsProc.running = true }

    // ── Audio — reactive via Pipewire ────────────────────
    property var  audioSink: Pipewire.defaultAudioSink

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property real volume: {
        var v = audioSink?.audio?.volume ?? 0
        return isNaN(v) ? 0 : v
    }
    property bool muted: audioSink?.audio?.muted ?? false


    function volumeIcon() {
        if (muted || volume === 0) return "󰝟"
        if (volume < 0.35)         return "󰕿"
        if (volume < 0.70)         return "󰖀"
        return "󰕾"
    }

    function setVolume(delta) {
        if (!audioSink?.ready || !audioSink?.audio) return
        audioSink.audio.volume = Math.max(0, Math.min(1, volume + delta))
    }

    function setAbsoluteVolume(v) {
        if (!audioSink?.ready || !audioSink?.audio) return
        audioSink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute() {
        if (audioSink?.ready && audioSink?.audio) audioSink.audio.muted = !muted
    }

    // ── Sinks list (3s poll) ─────────────────────────────
    property var sinksList: []

    Process {
        id: sinksProc
        command: ["pactl", "list", "sinks", "short"]
        stdout: StdioCollector { id: sinksOut }
        onExited: {
            var sinks = []
            var lines = sinksOut.text.trim().split("\n")
            for (var i = 0; i < lines.length; i++) {
                var parts = lines[i].trim().split("\t")
                if (parts.length >= 2 && parts[1].trim() !== "") sinks.push(parts[1].trim())
            }
            root.sinksList = sinks
            sinksTimer.start()
        }
    }
    Timer { id: sinksTimer; interval: 3000; repeat: false; running: true
        onTriggered: sinksProc.running = true }

    function currentSinkIcon() {
        var name = (audioSink?.name ?? "").toLowerCase()
        if (name.indexOf("usb") >= 0) return "󰋋"
        if (name.indexOf("hdmi") >= 0) return "󰍹"
        return "󰕾"
    }

    function currentSinkShortName() {
        var name = (audioSink?.name ?? "").toLowerCase()
        if (name.indexOf("usb") >= 0) return "USB"
        if (name.indexOf("hdmi") >= 0) return "HDMI"
        return "OUT"
    }

    function cycleSink() {
        if (sinksList.length < 2) return
        var currentName = audioSink?.name ?? ""
        var idx = -1
        for (var i = 0; i < sinksList.length; i++) {
            if (sinksList[i] === currentName) { idx = i; break }
        }
        var nextName = sinksList[(idx + 1) % sinksList.length]
        Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["pactl", "set-default-sink", "' + nextName + '"] }',
            root)
        Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ["bash", "-c", "pactl list sink-inputs short | awk \'NR>0{print $1}\' | xargs -r -I{} pactl move-sink-input {} ' + nextName + '"] }',
            root)
    }

    // ── VPN (2s poll) ────────────────────────────────────
    property bool   vpnConnected:  false
    property string vpnActiveName: ""
    property string vpnFirstName:  ""   // first available VPN to connect

    Process {
        id: vpnProc
        command: ["bash", "-c",
            "echo 'ACTIVE:'; nmcli -g TYPE,NAME con show --active 2>/dev/null;" +
            "echo 'ALL:'; nmcli -g TYPE,NAME con show 2>/dev/null"]
        stdout: StdioCollector { id: vpnOut }
        onExited: {
            var lines = vpnOut.text.split("\n")
            var section = ""
            var activeName = ""
            var firstName = ""
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i].trim()
                if (l === "ACTIVE:") { section = "active"; continue }
                if (l === "ALL:")    { section = "all";    continue }
                if (l.startsWith("vpn:")) {
                    var name = l.substring(4)
                    if (section === "active" && activeName === "") activeName = name
                    if (section === "all"    && firstName === "")  firstName  = name
                }
            }
            root.vpnActiveName  = activeName
            root.vpnConnected   = activeName !== ""
            root.vpnFirstName   = firstName
            vpnTimer.start()
        }
    }
    Timer { id: vpnTimer; interval: 2000; repeat: false; running: true
        onTriggered: vpnProc.running = true }

    function toggleVpn() {
        if (vpnConnected) {
            Qt.createQmlObject(
                'import Quickshell.Io; Process{running:true;command:["nmcli","con","down","' + vpnActiveName + '"]}',
                root)
        } else if (vpnFirstName !== "") {
            Qt.createQmlObject(
                'import Quickshell.Io; Process{running:true;command:["nmcli","con","up","' + vpnFirstName + '"]}',
                root)
        }
    }

    // ── CPU (2s poll) ────────────────────────────────────
    property int cpuPercent: 0
    property var cpuHistory: []

    Process {
        id: cpuProc
        command: ["bash", "-c",
            "awk '/^cpu /{t=0;for(i=2;i<=NF;i++)t+=$i; idle=$5+$6;" +
            "if(p_t){printf \"%d\\n\",int(100*(1-(idle-p_i)/(t-p_t)))};" +
            "p_t=t;p_i=idle}' <(cat /proc/stat;sleep 0.8;cat /proc/stat)"]
        stdout: StdioCollector { id: cpuOut }
        onExited: {
            root.cpuPercent = parseInt(cpuOut.text.trim()) || 0
            var ch = root.cpuHistory.slice(-39); ch.push(root.cpuPercent); root.cpuHistory = ch
            cpuTimer.start()
        }
    }
    Timer { id: cpuTimer; interval: 1200; repeat: false; running: true
        onTriggered: cpuProc.running = true }

    // ── RAM (2s poll) ────────────────────────────────────
    property int   ramPercent: 0
    property int   ramUsedMb:  0
    property int   ramTotalMb: 0
    property var   ramHistory: []

    Process {
        id: ramProc
        command: ["awk",
            "/MemTotal/{t=$2}/MemAvailable/{a=$2}END{print int((t-a)/1024), int(t/1024), int((t-a)/t*100)}",
            "/proc/meminfo"]
        stdout: StdioCollector { id: ramOut }
        onExited: {
            var parts = ramOut.text.trim().split(" ")
            root.ramUsedMb  = parseInt(parts[0]) || 0
            root.ramTotalMb = parseInt(parts[1]) || 0
            root.ramPercent = parseInt(parts[2]) || 0
            var rh = root.ramHistory.slice(-39); rh.push(root.ramPercent); root.ramHistory = rh
            ramTimer.start()
        }
    }
    Timer { id: ramTimer; interval: 2000; repeat: false; running: true
        onTriggered: ramProc.running = true }

    property bool audioPopupOpen:    false
    property bool launcherOpen:      false

    function launch(cmd) {
        launcherOpen = false
        Qt.createQmlObject(
            'import Quickshell.Io; Process { running: true; command: ' + JSON.stringify(cmd) + ' }',
            root)
    }

    // ── MPRIS ─────────────────────────────────────────────
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    // ── Weather (reuse eww script + its cache) ─────────────
    property var weatherData: ({ temp: "--", desc: "...", icon: "", humidity: "--", wind: "--" })

    Process {
        id: weatherProc
        command: ["/home/ratamiru/.config/eww/scripts/weather.sh"]
        stdout: StdioCollector { id: weatherOut }
        onExited: {
            try { root.weatherData = JSON.parse(weatherOut.text) } catch(e) {}
            weatherTimer.start()
        }
    }
    Timer { id: weatherTimer; interval: 500; repeat: false; running: true
        onTriggered: {
            weatherTimer.interval = 600000
            weatherProc.running = true
        }
    }


    // ── GPU (nvidia-smi, 2s poll) ─────────────────────────
    property int gpuPercent:  0
    property int gpuTempC:    0
    property int gpuVramUsed: 0
    property int gpuVramTotal: 0
    property var gpuHistory: []

    Process {
        id: gpuProc
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total",
                  "--format=csv,noheader,nounits"]
        stdout: StdioCollector { id: gpuOut }
        onExited: {
            var parts = gpuOut.text.trim().split(/,\s*/)
            root.gpuPercent   = parseInt(parts[0]) || 0
            root.gpuTempC     = parseInt(parts[1]) || 0
            root.gpuVramUsed  = parseInt(parts[2]) || 0
            root.gpuVramTotal = parseInt(parts[3]) || 0
            var gh = root.gpuHistory.slice(-39); gh.push(root.gpuPercent); root.gpuHistory = gh
            gpuTimer.start()
        }
    }
    Timer { id: gpuTimer; interval: 2000; repeat: false; running: true
        onTriggered: gpuProc.running = true }

    // ── Bitcoin price (Binance, 30s poll) ──────────────────
    property string btcPrice: "..."

    Process {
        id: btcProc
        command: ["bash", "-c",
            "curl -sf 'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT' | jq -r '.price | tonumber | floor | tostring'"]
        stdout: StdioCollector { id: btcOut }
        onExited: {
            var p = btcOut.text.trim()
            if (p !== "" && p !== "null") {
                var n = parseInt(p)
                root.btcPrice = n.toLocaleString("en-US")
            }
            btcTimer.start()
        }
    }
    Timer { id: btcTimer; interval: 500; repeat: false; running: true
        onTriggered: { btcTimer.interval = 30000; btcProc.running = true }
    }


    // ── Volume popup per monitor ──────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors { top: true; right: true }
            margins { top: 58; right: 8 }
            implicitWidth:  264
            implicitHeight: 80
            color:          "transparent"
            visible:        root.audioPopupOpen
            exclusionMode:  ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-vol"
            WlrLayershell.layer:     WlrLayer.Overlay

            Rectangle {
                anchors.fill: parent
                radius:       12
                color:        Qt.rgba(0.063, 0.031, 0.11, 0.95)
                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "transparent"
                    border.color: Qt.rgba(0.71, 0.51, 1.0, 0.28); border.width: 1
                }
                ColumnLayout {
                    anchors { fill: parent; margins: 14 }
                    spacing: 10
                    // Header
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Text {
                            text: root.muted || root.volume === 0 ? "󰝟"
                                : root.volume < 0.35 ? "󰕿"
                                : root.volume < 0.70 ? "󰖀" : "󰕾"
                            color: "#e2c8ff"; font.pixelSize: 14
                        }
                        Text {
                            text: "Volume"; color: Qt.rgba(0.82, 0.73, 1.0, 0.65)
                            font.pixelSize: 11; font.bold: true; Layout.fillWidth: true
                        }
                        Text {
                            text: root.muted ? "muted" : Math.round(root.volume * 100) + "%"
                            color: root.muted ? Qt.rgba(0.82, 0.73, 1.0, 0.35) : "#e2c8ff"
                            font.pixelSize: 12; font.bold: true
                        }
                    }
                    // Slider
                    Item {
                        Layout.fillWidth: true; height: 20
                        Rectangle {
                            id: volTrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 5; radius: 3
                            color: Qt.rgba(1, 1, 1, 0.10)
                            Rectangle {
                                width: volTrack.width * root.volume
                                height: volTrack.height; radius: volTrack.radius
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#dcc5ff" }
                                    GradientStop { position: 1.0; color: "#7c3fd6" }
                                }
                                opacity: root.muted ? 0.3 : 1.0
                                Behavior on width   { NumberAnimation { duration: 60 } }
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                            }
                        }
                        Rectangle {
                            x: volTrack.width * root.volume - width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16; height: 16; radius: 8
                            color: "#e2c8ff"
                            border.color: Qt.rgba(0.49, 0.25, 0.84, 0.6); border.width: 1
                            opacity: root.muted ? 0.3 : 1.0
                            Behavior on x       { NumberAnimation { duration: 60 } }
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }
                        MouseArea {
                            anchors { fill: parent; topMargin: -7; bottomMargin: -7 }
                            cursorShape: Qt.PointingHandCursor
                            onPressed:         (e) => root.setAbsoluteVolume(e.x / volTrack.width)
                            onPositionChanged: (e) => { if (pressed) root.setAbsoluteVolume(e.x / volTrack.width) }
                        }
                    }
                }
            }
        }
    }

    // ── Launcher popup per monitor ───────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: launcherPw
            required property var modelData
            screen: modelData

            property real fullH: Math.min(screen.height - 70, 720)

            anchors { top: true; left: true }
            margins { top: 58; left: 8 }
            implicitWidth:  300
            implicitHeight: fullH
            color:          "transparent"
            visible:        openAnim > 0.005
            exclusionMode:  ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell-launcher"
            WlrLayershell.layer:     WlrLayer.Overlay

            // 0 = closed, 1 = open
            property real openAnim: root.launcherOpen ? 1.0 : 0.0
            Behavior on openAnim {
                NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
            }

            // ── Clip container: wipes panel top→bottom ────────
            Item {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: launcherPw.fullH * launcherPw.openAnim
                clip: true

                Launcher {
                    width: launcherPw.implicitWidth
                    height: launcherPw.fullH
                    // slight scale-from-top gives depth to the reveal
                    scale: 0.96 + 0.04 * launcherPw.openAnim
                    transformOrigin: Item.Top
                    opacity: Math.min(launcherPw.openAnim * 2.5, 1.0)  // fades in during first 40%
                }

                // ── Soft gradient edge riding the reveal front ─
                Rectangle {
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 48
                    visible: launcherPw.openAnim > 0.01 && launcherPw.openAnim < 0.98
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0.063, 0.031, 0.11, 0.96) }
                    }
                }
            }
        }
    }

    // ── Bar per monitor ──────────────────────────────────
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors { top: true; left: true; right: true }
            margins { top: 8; left: 8; right: 8 }
            implicitHeight: 42
            color:         "transparent"
            WlrLayershell.namespace: "quickshell-bar"

            Rectangle {
                anchors.fill: parent
                radius:       14
                color:        Qt.rgba(0.063, 0.031, 0.11, 0.90)

                Rectangle {
                    anchors.fill: parent; radius: parent.radius; color: "transparent"
                    border.color: Qt.rgba(0.71, 0.51, 1.0, 0.22); border.width: 1
                }

                Item {
                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }

                    // ── Left: start button + workspaces ───────────
                    Row {
                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                        spacing: 4

                        // Start button
                        Rectangle {
                            width: 30; height: 30; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.launcherOpen
                                   ? Qt.rgba(0.49, 0.25, 0.84, 0.55)
                                   : Qt.rgba(1, 1, 1, 0.06)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            scale: startMa.pressed ? 0.88 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                            Text {
                                anchors.centerIn: parent
                                text: "󰘔"; color: "#e2c8ff"; font.pixelSize: 15
                            }
                            MouseArea {
                                id: startMa
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.launcherOpen = !root.launcherOpen
                            }
                        }

                        // Workspaces
                        Row {
                            spacing: 3
                            anchors.verticalCenter: parent.verticalCenter
                            Repeater {
                                model: root.workspaces
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    width:  modelData.is_focused ? 30 : 22; height: 26; radius: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    color:  modelData.is_focused
                                            ? Qt.rgba(0.49, 0.25, 0.84, 0.50)
                                            : Qt.rgba(1, 1, 1, 0.06)
                                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation  { duration: 150 } }
                                    scale: wsMa.pressed ? 0.85 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                                    Text {
                                        anchors.centerIn: parent
                                        text:  modelData.name !== null ? modelData.name : modelData.idx
                                        color: modelData.is_focused ? "#e2c8ff" : Qt.rgba(0.82, 0.73, 1.0, 0.38)
                                        font.pixelSize: 11; font.bold: true
                                    }
                                    MouseArea {
                                        id: wsMa
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.createQmlObject(
                                            'import Quickshell.Io;Process{running:true;command:["niri","msg","action","focus-workspace","' + modelData.idx + '"]}',
                                            root)
                                    }
                                }
                            }
                        }
                    }

                    // ── Center: clocks ─────────────────────────────
                    Row {
                        anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                        spacing: 8

                        // Moscow
                        Row {
                            spacing: 4; anchors.verticalCenter: parent.verticalCenter
                            Text { text: "МСК"; color: Qt.rgba(0.82,0.73,1.0,0.45); font.pixelSize: 9; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                id: clockMsk
                                color: Qt.rgba(0.82,0.73,1.0,0.7); font.pixelSize: 12; font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                function refresh() {
                                    var d = new Date(new Date().getTime() - 4 * 3600000)
                                    text = Qt.formatDateTime(d, "HH:mm")
                                }
                                Component.onCompleted: refresh()
                                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockMsk.refresh() }
                            }
                        }

                        Rectangle { width: 1; height: 16; color: Qt.rgba(0.71,0.51,1.0,0.2); anchors.verticalCenter: parent.verticalCenter }

                        // Local (Tomsk UTC+7)
                        Text {
                            id: clock
                            color: "#e2c8ff"; font.pixelSize: 14; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                            function refresh() { text = Qt.formatDateTime(new Date(), "HH:mm") }
                            Component.onCompleted: refresh()
                            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.refresh() }
                        }

                        Rectangle { width: 1; height: 16; color: Qt.rgba(0.71,0.51,1.0,0.2); anchors.verticalCenter: parent.verticalCenter }

                        // New York
                        Row {
                            spacing: 4; anchors.verticalCenter: parent.verticalCenter
                            Text { text: "NY"; color: Qt.rgba(0.82,0.73,1.0,0.45); font.pixelSize: 9; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                id: clockNy
                                color: Qt.rgba(0.82,0.73,1.0,0.7); font.pixelSize: 12; font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                                function isDST() {
                                    var now = new Date()
                                    var y = now.getUTCFullYear()
                                    var marchSecondSun = new Date(Date.UTC(y, 2, 8 + (7 - new Date(Date.UTC(y,2,8)).getUTCDay()) % 7, 7))
                                    var novFirstSun   = new Date(Date.UTC(y, 10, 1 + (7 - new Date(Date.UTC(y,10,1)).getUTCDay()) % 7, 6))
                                    return now >= marchSecondSun && now < novFirstSun
                                }
                                function refresh() {
                                    var offset = isDST() ? -11 : -12
                                    var d = new Date(new Date().getTime() + offset * 3600000)
                                    text = Qt.formatDateTime(d, "HH:mm")
                                }
                                Component.onCompleted: refresh()
                                Timer { interval: 1000; running: true; repeat: true; onTriggered: clockNy.refresh() }
                            }
                        }
                    }

                    // ── Right: BTC + VPN + audio ───────────────────
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: 4

                        // BTC
                        Rectangle {
                            height: 28; radius: 8; color: Qt.rgba(1, 1, 1, 0.06)
                            anchors.verticalCenter: parent.verticalCenter
                            width: btcRow.implicitWidth + 16
                            Row {
                                id: btcRow
                                anchors.centerIn: parent; spacing: 4
                                Text { text: "₿"; color: "#f7931a"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: {
                                        var n = parseInt(root.btcPrice.replace(/,/g, ""))
                                        return isNaN(n) ? root.btcPrice : (n >= 1000 ? (n/1000).toFixed(1) + "k" : n)
                                    }
                                    color: "#e2c8ff"; font.pixelSize: 11; font.bold: true
                                }
                            }
                        }

                        // VPN
                        Rectangle {
                            height: 28; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.vpnConnected ? Qt.rgba(0.49, 0.25, 0.84, 0.40) : Qt.rgba(1, 1, 1, 0.06)
                            width: vpnRow.implicitWidth + 16
                            Behavior on color { ColorAnimation { duration: 200 } }
                            scale: vpnMa.pressed ? 0.90 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                            Row {
                                id: vpnRow
                                anchors.centerIn: parent; spacing: 4
                                Text {
                                    text: root.vpnConnected ? "󰒃" : "󰒄"
                                    color: root.vpnConnected ? "#e2c8ff" : Qt.rgba(0.82, 0.73, 1.0, 0.45)
                                    font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "VPN"
                                    color: root.vpnConnected ? "#e2c8ff" : Qt.rgba(0.82, 0.73, 1.0, 0.45)
                                    font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: vpnMa
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.toggleVpn()
                            }
                        }

                        // Sink switcher
                        Rectangle {
                            height: 28; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(1, 1, 1, 0.06)
                            width: sinkSwitchRow.implicitWidth + 16
                            visible: root.sinksList.length > 1
                            scale: sinkMa.pressed ? 0.90 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                            Row {
                                id: sinkSwitchRow
                                anchors.centerIn: parent; spacing: 4
                                Text {
                                    text: root.currentSinkIcon()
                                    color: "#e2c8ff"; font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.currentSinkShortName()
                                    color: "#e2c8ff"; font.pixelSize: 11; font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: sinkMa
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.cycleSink()
                            }
                        }

                        // Audio
                        Rectangle {
                            height: 28; radius: 8; color: Qt.rgba(1, 1, 1, 0.06)
                            anchors.verticalCenter: parent.verticalCenter
                            width: audioRow.implicitWidth + 16
                            scale: audioMa.pressed ? 0.90 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                            Row {
                                id: audioRow
                                anchors.centerIn: parent; spacing: 4
                                Text {
                                    text: root.volumeIcon()
                                    color: root.muted ? Qt.rgba(0.82, 0.73, 1.0, 0.35) : "#e2c8ff"
                                    font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: root.muted ? "mute" : Math.round(root.volume * 100) + "%"
                                    color: root.muted ? Qt.rgba(0.82, 0.73, 1.0, 0.35) : "#e2c8ff"
                                    font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            MouseArea {
                                id: audioMa
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.audioPopupOpen = !root.audioPopupOpen
                            }
                        }
                    }
                }
            }
        }
    }
}
