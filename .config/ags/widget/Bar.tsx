import { App, Astal, Gtk, Gdk } from "astal/gtk3"
import Workspaces from "./Workspaces"
import Clock from "./Clock"
import { CPU, Memory } from "./SysInfo"
import Language from "./Language"
import Volume from "./Volume"
import Bluetooth from "./Bluetooth"
import VPN from "./VPN"
import Network from "./Network"

function Separator() {
    return <box className="separator" />
}

export default function Bar(gdkmonitor: Gdk.Monitor) {
    const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

    return <window
        className="Bar"
        gdkmonitor={gdkmonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | LEFT | RIGHT}
        application={App}
    >
        <centerbox className="bar-inner">
            <box halign={Gtk.Align.START} className="bar-left">
                <Workspaces />
            </box>
            <box halign={Gtk.Align.CENTER} className="bar-center">
                <Clock />
            </box>
            <box halign={Gtk.Align.END} className="bar-right" spacing={4}>
                <box className="widget-group" spacing={2}>
                    <CPU />
                    <Memory />
                </box>
                <Separator />
                <Language />
                <Volume />
                <Separator />
                <box className="widget-group" spacing={2}>
                    <Bluetooth />
                    <VPN />
                    <Network />
                </box>
            </box>
        </centerbox>
    </window>
}
