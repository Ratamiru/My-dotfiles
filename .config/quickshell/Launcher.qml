import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    anchors.fill: parent
    radius: 14
    color:  Qt.rgba(0.063, 0.031, 0.11, 0.95)

    Rectangle {
        anchors.fill: parent; radius: parent.radius; color: "transparent"
        border.color: Qt.rgba(0.71, 0.51, 1.0, 0.28); border.width: 1
    }

    property int activeTab: 0   // 0 = Main, 1 = Performance

    // ── Section label component ──────────────────────────────
    component SectionLabel: Text {
        color: Qt.rgba(0.82, 0.73, 1.0, 0.40)
        font.pixelSize: 10; font.bold: true
        leftPadding: 2
    }

    // ── Separator ────────────────────────────────────────────
    component Divider: Rectangle {
        Layout.fillWidth: true; height: 1
        color: Qt.rgba(0.71, 0.51, 1.0, 0.12)
    }

    // ── Slider component ─────────────────────────────────────
    component HSlider: Item {
        property real  value:    0.5   // 0.0 – 1.0
        property color fillFrom: "#dcc5ff"
        property color fillTo:   "#7c3fd6"
        signal moved(real newValue)

        Layout.fillWidth: true; height: 20

        Rectangle {
            id: sTrack
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 5; radius: 3
            color: Qt.rgba(1, 1, 1, 0.10)

            Rectangle {
                width: sTrack.width * parent.parent.value
                height: sTrack.height; radius: sTrack.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: parent.parent.parent.fillFrom }
                    GradientStop { position: 1.0; color: parent.parent.parent.fillTo }
                }
                Behavior on width { NumberAnimation { duration: 60 } }
            }
        }
        Rectangle {
            x: sTrack.width * parent.value - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 16; height: 16; radius: 8
            color: "#e2c8ff"
            border.color: Qt.rgba(0.49, 0.25, 0.84, 0.6); border.width: 1
            Behavior on x { NumberAnimation { duration: 60 } }
        }
        MouseArea {
            anchors { fill: parent; topMargin: -7; bottomMargin: -7 }
            cursorShape: Qt.PointingHandCursor
            onPressed:         (e) => parent.moved(Math.max(0, Math.min(1, e.x / sTrack.width)))
            onPositionChanged: (e) => { if (pressed) parent.moved(Math.max(0, Math.min(1, e.x / sTrack.width))) }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Tab bar ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.leftMargin: 12
            Layout.rightMargin: 12
            spacing: 6

            Repeater {
                model: ["Main", "Performance"]
                Rectangle {
                    required property string modelData
                    required property int    index
                    height: 28
                    Layout.fillWidth: true
                    radius: 8
                    color: activeTab === index
                           ? Qt.rgba(0.49, 0.25, 0.84, 0.50)
                           : Qt.rgba(1, 1, 1, 0.05)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: activeTab === index ? "#e2c8ff" : Qt.rgba(0.82, 0.73, 1.0, 0.45)
                        font.pixelSize: 11; font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: activeTab = index
                    }
                }
            }
        }

        // thin divider under tabs
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 8
            height: 1
            color: Qt.rgba(0.71, 0.51, 1.0, 0.12)
        }

        // ── Main tab ─────────────────────────────────────────
        ScrollView {
            visible: activeTab === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: availableWidth
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 0

                Item { height: 10 }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin:  12
                    Layout.rightMargin: 12
                    spacing: 10

                    // ── Weather ─────────────────────────────────
                    SectionLabel { text: "Weather" }

                    Rectangle {
                        Layout.fillWidth: true; height: 56; radius: 10
                        color: Qt.rgba(1, 1, 1, 0.05)

                        RowLayout {
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                            spacing: 12

                            Text {
                                text: root.weatherData.icon || ""
                                font.pixelSize: 28; color: "#e2c8ff"
                            }

                            ColumnLayout {
                                spacing: 2; Layout.fillWidth: true
                                Text {
                                    text: (root.weatherData.temp || "--") + "°C  " + (root.weatherData.desc || "")
                                    color: "#e2c8ff"; font.pixelSize: 12; font.bold: true
                                }
                                Text {
                                    text: "󰖎 " + (root.weatherData.humidity || "--") + "%   " +
                                          "󰖝 " + (root.weatherData.wind || "--") + " km/h"
                                    color: Qt.rgba(0.82, 0.73, 1.0, 0.55); font.pixelSize: 10
                                }
                            }
                        }
                    }

                    Divider {}

                    // ── Calendar ────────────────────────────────
                    SectionLabel { text: "Calendar" }

                    Item {
                        Layout.fillWidth: true
                        height: calContent.implicitHeight

                        property int calYear:  new Date().getFullYear()
                        property int calMonth: new Date().getMonth()
                        readonly property int todayDay:   new Date().getDate()
                        readonly property int todayMonth: new Date().getMonth()
                        readonly property int todayYear:  new Date().getFullYear()

                        property var calDays: calcDays()

                        function monthName(m) {
                            return ["January","February","March","April","May","June",
                                    "July","August","September","October","November","December"][m]
                        }

                        function calcDays() {
                            var first = new Date(calYear, calMonth, 1)
                            var last  = new Date(calYear, calMonth + 1, 0).getDate()
                            var dow   = first.getDay()
                            var off   = (dow === 0) ? 6 : dow - 1
                            var d = []
                            for (var i = 0; i < off;  i++) d.push(0)
                            for (var i = 1; i <= last; i++) d.push(i)
                            return d
                        }

                        ColumnLayout {
                            id: calContent
                            width: parent.width; spacing: 4

                            // Month nav
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: parent.parent.parent.monthName(parent.parent.parent.calMonth) +
                                          "  " + parent.parent.parent.calYear
                                    color: "#e2c8ff"; font.pixelSize: 12; font.bold: true
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "‹"; color: Qt.rgba(0.82,0.73,1,0.6); font.pixelSize: 14
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var c = parent.parent.parent.parent
                                            if (c.calMonth === 0) { c.calMonth = 11; c.calYear-- } else c.calMonth--
                                            c.calDays = c.calcDays()
                                        }
                                    }
                                }
                                Item { width: 6 }
                                Text {
                                    text: "›"; color: Qt.rgba(0.82,0.73,1,0.6); font.pixelSize: 14
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var c = parent.parent.parent.parent
                                            if (c.calMonth === 11) { c.calMonth = 0; c.calYear++ } else c.calMonth++
                                            c.calDays = c.calcDays()
                                        }
                                    }
                                }
                            }

                            // Day-of-week header
                            Row {
                                spacing: 0
                                Repeater {
                                    model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                                    Text {
                                        width: (parent.parent.width) / 7
                                        text: modelData
                                        color: Qt.rgba(0.82,0.73,1,0.35); font.pixelSize: 9
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            // Days
                            Grid {
                                columns: 7; width: parent.width
                                columnSpacing: 0; rowSpacing: 2

                                Repeater {
                                    model: parent.parent.parent.parent.calDays

                                    Rectangle {
                                        required property int modelData
                                        required property int index
                                        width: calContent.width / 7
                                        height: 22; radius: 5
                                        property bool isToday: modelData > 0 &&
                                            modelData === parent.parent.parent.parent.todayDay &&
                                            parent.parent.parent.parent.calMonth === parent.parent.parent.parent.todayMonth &&
                                            parent.parent.parent.parent.calYear  === parent.parent.parent.parent.todayYear
                                        color: isToday ? Qt.rgba(0.49,0.25,0.84,0.5) : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData > 0 ? modelData : ""
                                            color: isToday ? "#e2c8ff" : Qt.rgba(0.82,0.73,1,0.65)
                                            font.pixelSize: 10; font.bold: isToday
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Divider {}

                    // ── Music ────────────────────────────────────
                    SectionLabel { text: "Music" }

                    Rectangle {
                        Layout.fillWidth: true
                        height: root.player ? 72 : 40
                        radius: 10; color: Qt.rgba(1, 1, 1, 0.05)

                        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        // No player
                        Text {
                            anchors.centerIn: parent
                            visible: !root.player
                            text: "Nothing playing"
                            color: Qt.rgba(0.82, 0.73, 1.0, 0.35); font.pixelSize: 11
                        }

                        // Player info
                        ColumnLayout {
                            visible: !!root.player
                            anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: 10; bottomMargin: 10 }
                            spacing: 6

                            ColumnLayout {
                                spacing: 1; Layout.fillWidth: true
                                Text {
                                    text: root.player?.trackTitle ?? ""
                                    color: "#e2c8ff"; font.pixelSize: 12; font.bold: true
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                                Text {
                                    text: root.player?.trackArtist ?? ""
                                    color: Qt.rgba(0.82,0.73,1,0.55); font.pixelSize: 10
                                    elide: Text.ElideRight; Layout.fillWidth: true
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true; spacing: 0

                                Item { Layout.fillWidth: true }

                                Repeater {
                                    model: [
                                        { icon: "󰒮", action: "prev" },
                                        { icon: root.player?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊", action: "play" },
                                        { icon: "󰒭", action: "next" }
                                    ]
                                    Text {
                                        required property var modelData
                                        text: modelData.icon
                                        color: "#e2c8ff"; font.pixelSize: 18
                                        leftPadding: 16; rightPadding: 16
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root.player) return
                                                if (modelData.action === "prev") root.player.previous()
                                                else if (modelData.action === "play") {
                                                    if (root.player.playbackState === MprisPlaybackState.Playing)
                                                        root.player.pause()
                                                    else root.player.play()
                                                }
                                                else root.player.next()
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    Divider {}

                    // ── Power ────────────────────────────────────
                    SectionLabel { text: "Power" }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 6

                        component PowerBtn: Rectangle {
                            property string icon:   ""
                            property var    cmd:    []
                            property bool   danger: false

                            height: 36; radius: 9; Layout.fillWidth: true
                            color: pMa.containsMouse
                                   ? (danger ? Qt.rgba(0.8,0.1,0.1,0.45) : Qt.rgba(0.49,0.25,0.84,0.35))
                                   : Qt.rgba(1,1,1,0.05)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.centerIn: parent; text: parent.icon
                                color: parent.danger && pMa.containsMouse ? "#ff8080" : "#e2c8ff"
                                font.pixelSize: 16
                            }
                            MouseArea { id: pMa; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor; onClicked: root.launch(parent.cmd) }
                        }

                        PowerBtn { icon: "󰌾"; cmd: ["swaylock"] }
                        PowerBtn { icon: "󰍃"; cmd: ["niri", "msg", "action", "quit"] }
                        PowerBtn { icon: "󰤄"; cmd: ["systemctl", "suspend"] }
                        PowerBtn { icon: "󰜉"; cmd: ["systemctl", "reboot"];   danger: true }
                        PowerBtn { icon: "󰐥"; cmd: ["systemctl", "poweroff"]; danger: true }
                    }
                }

                Item { height: 12 }
            }
        }

        // ── Performance tab ──────────────────────────────────
        Item {
            visible: activeTab === 1
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ── Sparkline component ──────────────────────────
            component Sparkline: Canvas {
                property var   history:    []
                property color lineColor:  "#7c3fd6"
                property color fillColor:  Qt.rgba(0.49, 0.25, 0.84, 0.20)
                property int   currentVal: 0

                onHistoryChanged: requestPaint()
                onCurrentValChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var data = history.concat([currentVal])
                    if (data.length < 2) return

                    var maxPoints = 40
                    if (data.length > maxPoints) data = data.slice(data.length - maxPoints)

                    var n = data.length
                    var stepX = width / (maxPoints - 1)
                    var startX = width - (n - 1) * stepX

                    // fill
                    ctx.beginPath()
                    ctx.moveTo(startX, height)
                    for (var i = 0; i < n; i++) {
                        var x = startX + i * stepX
                        var y = height - (data[i] / 100) * height * 0.85 - height * 0.05
                        if (i === 0) ctx.lineTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.lineTo(startX + (n - 1) * stepX, height)
                    ctx.closePath()
                    ctx.fillStyle = fillColor
                    ctx.fill()

                    // line
                    ctx.beginPath()
                    for (var i = 0; i < n; i++) {
                        var x = startX + i * stepX
                        var y = height - (data[i] / 100) * height * 0.85 - height * 0.05
                        if (i === 0) ctx.moveTo(x, y)
                        else ctx.lineTo(x, y)
                    }
                    ctx.strokeStyle = lineColor
                    ctx.lineWidth = 1.5
                    ctx.stroke()
                }
            }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 0

                    Item { height: 10 }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 12
                        Layout.rightMargin: 12
                        spacing: 14

                        // ── CPU card ─────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true; radius: 10
                            height: 110
                            color: Qt.rgba(1, 1, 1, 0.05)

                            ColumnLayout {
                                anchors { fill: parent; margins: 12 }
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰘚"; color: Qt.rgba(0.82,0.73,1,0.6); font.pixelSize: 13 }
                                    Text {
                                        text: "CPU"
                                        color: Qt.rgba(0.82,0.73,1,0.45)
                                        font.pixelSize: 11; font.bold: true
                                        Layout.fillWidth: true
                                        leftPadding: 4
                                    }
                                    Text {
                                        text: root.cpuPercent + "%"
                                        color: root.cpuPercent > 80 ? "#f38ba8"
                                             : root.cpuPercent > 50 ? "#e2c8ff"
                                             : Qt.rgba(0.82,0.73,1,0.7)
                                        font.pixelSize: 14; font.bold: true
                                    }
                                }

                                // Progress bar
                                Rectangle {
                                    Layout.fillWidth: true; height: 4; radius: 2
                                    color: Qt.rgba(1,1,1,0.08)
                                    Rectangle {
                                        width: parent.width * (root.cpuPercent / 100)
                                        height: parent.height; radius: parent.radius
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "#dcc5ff" }
                                            GradientStop { position: 1.0; color: "#7c3fd6" }
                                        }
                                        Behavior on width { NumberAnimation { duration: 400 } }
                                    }
                                }

                                // Sparkline
                                Sparkline {
                                    Layout.fillWidth: true; height: 48
                                    history:    root.cpuHistory
                                    currentVal: root.cpuPercent
                                    lineColor:  "#7c3fd6"
                                    fillColor:  Qt.rgba(0.49, 0.25, 0.84, 0.18)
                                }
                            }
                        }

                        // ── RAM card ─────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true; radius: 10
                            height: 110
                            color: Qt.rgba(1, 1, 1, 0.05)

                            ColumnLayout {
                                anchors { fill: parent; margins: 12 }
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰍛"; color: Qt.rgba(0.82,0.73,1,0.6); font.pixelSize: 13 }
                                    ColumnLayout {
                                        spacing: 0; Layout.fillWidth: true
                                        Layout.leftMargin: 4
                                        Text {
                                            text: "RAM"
                                            color: Qt.rgba(0.82,0.73,1,0.45)
                                            font.pixelSize: 11; font.bold: true
                                        }
                                        Text {
                                            text: root.ramUsedMb + " / " + root.ramTotalMb + " MB"
                                            color: Qt.rgba(0.82,0.73,1,0.35)
                                            font.pixelSize: 9
                                        }
                                    }
                                    Text {
                                        text: root.ramPercent + "%"
                                        color: root.ramPercent > 80 ? "#f38ba8"
                                             : root.ramPercent > 50 ? "#e2c8ff"
                                             : Qt.rgba(0.82,0.73,1,0.7)
                                        font.pixelSize: 14; font.bold: true
                                    }
                                }

                                // Progress bar
                                Rectangle {
                                    Layout.fillWidth: true; height: 4; radius: 2
                                    color: Qt.rgba(1,1,1,0.08)
                                    Rectangle {
                                        width: parent.width * (root.ramPercent / 100)
                                        height: parent.height; radius: parent.radius
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "#c8e6ff" }
                                            GradientStop { position: 1.0; color: "#3fa0d6" }
                                        }
                                        Behavior on width { NumberAnimation { duration: 400 } }
                                    }
                                }

                                // Sparkline
                                Sparkline {
                                    Layout.fillWidth: true; height: 48
                                    history:    root.ramHistory
                                    currentVal: root.ramPercent
                                    lineColor:  "#3fa0d6"
                                    fillColor:  Qt.rgba(0.24, 0.63, 0.84, 0.18)
                                }
                            }
                        }

                        // ── GPU card ─────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true; radius: 10
                            height: 110
                            color: Qt.rgba(1, 1, 1, 0.05)

                            ColumnLayout {
                                anchors { fill: parent; margins: 12 }
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { text: "󰢮"; color: Qt.rgba(0.82,0.73,1,0.6); font.pixelSize: 13 }
                                    ColumnLayout {
                                        spacing: 0; Layout.fillWidth: true
                                        Layout.leftMargin: 4
                                        Text {
                                            text: "GPU · " + root.gpuTempC + "°C"
                                            color: Qt.rgba(0.82,0.73,1,0.45)
                                            font.pixelSize: 11; font.bold: true
                                        }
                                        Text {
                                            text: root.gpuVramUsed + " / " + root.gpuVramTotal + " MB VRAM"
                                            color: Qt.rgba(0.82,0.73,1,0.35)
                                            font.pixelSize: 9
                                        }
                                    }
                                    Text {
                                        text: root.gpuPercent + "%"
                                        color: root.gpuPercent > 80 ? "#f38ba8"
                                             : root.gpuPercent > 50 ? "#e2c8ff"
                                             : Qt.rgba(0.82,0.73,1,0.7)
                                        font.pixelSize: 14; font.bold: true
                                    }
                                }

                                // Progress bar
                                Rectangle {
                                    Layout.fillWidth: true; height: 4; radius: 2
                                    color: Qt.rgba(1,1,1,0.08)
                                    Rectangle {
                                        width: parent.width * (root.gpuPercent / 100)
                                        height: parent.height; radius: parent.radius
                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal
                                            GradientStop { position: 0.0; color: "#c8ffd4" }
                                            GradientStop { position: 1.0; color: "#22c55e" }
                                        }
                                        Behavior on width { NumberAnimation { duration: 400 } }
                                    }
                                }

                                // Sparkline
                                Sparkline {
                                    Layout.fillWidth: true; height: 48
                                    history:    root.gpuHistory
                                    currentVal: root.gpuPercent
                                    lineColor:  "#22c55e"
                                    fillColor:  Qt.rgba(0.13, 0.77, 0.37, 0.18)
                                }
                            }
                        }

                        // ── BTC card ─────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true; radius: 10
                            height: 46
                            color: Qt.rgba(1, 1, 1, 0.05)

                            RowLayout {
                                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                                spacing: 8
                                Text { text: "₿"; color: "#f7931a"; font.pixelSize: 16; font.bold: true }
                                Text {
                                    text: "Bitcoin"
                                    color: Qt.rgba(0.82,0.73,1,0.45); font.pixelSize: 11; font.bold: true
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "$" + root.btcPrice
                                    color: "#f7931a"; font.pixelSize: 13; font.bold: true
                                }
                            }
                        }
                    }

                    Item { height: 12 }
                }
            }
        }
    }
}
