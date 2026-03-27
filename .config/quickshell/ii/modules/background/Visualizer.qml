pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property list<real> visualizerPoints: []
    readonly property int barCount: visualizerPoints.length
    readonly property real spacing: Config.options.background.visualizer.spacing
    readonly property real barWidth: barCount > 0
        ? Math.max(1, (width - spacing * (barCount - 1)) / barCount)
        : 4
    readonly property real maxBarHeight: height
    readonly property real barOpacity: Config.options.background.visualizer.opacity

    opacity: Config.options.background.visualizer.enable ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    Process {
        id: cavaProc
        running: Config.options.background.visualizer.enable
        onRunningChanged: {
            if (!running)
                root.visualizerPoints = [];
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                const points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                if (points.length > 0)
                    root.visualizerPoints = points;
            }
        }
    }

    Repeater {
        model: root.barCount

        Rectangle {
            required property int index

            readonly property real normalizedValue: root.visualizerPoints[index] / 1000

            width: root.barWidth
            height: normalizedValue * root.maxBarHeight
            x: index * (root.barWidth + root.spacing)
            anchors.bottom: parent.bottom
            radius: Math.min(root.barWidth / 2, 4)
            opacity: root.barOpacity

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Appearance.colors.colPrimary
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(
                        Appearance.colors.colPrimary.r,
                        Appearance.colors.colPrimary.g,
                        Appearance.colors.colPrimary.b,
                        0.3
                    )
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 80
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on gradient {
                enabled: false
            }
        }
    }
}
