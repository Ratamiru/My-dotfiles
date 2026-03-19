import { Variable, exec, execAsync } from "astal"
import { Gtk } from "astal/gtk3"

interface VPNStatus {
    text: string
    cls: string
    tooltip: string
}

function getVPNStatus(): VPNStatus {
    try {
        const out = exec(["bash", "-c",
            "$HOME/.config/scripts/vpn.sh status"])
        return JSON.parse(out) as VPNStatus
    } catch {
        return { text: "off", cls: "disconnected", tooltip: "VPN disconnected" }
    }
}

const vpnStatus = Variable<VPNStatus>(getVPNStatus()).poll(5000, getVPNStatus)

export default function VPN() {
    return <button
        className={vpnStatus(s => `pill vpn toggle-btn ${s.cls}`)}
        onClicked={() => {
            execAsync(["bash", "-c", "$HOME/.config/scripts/vpn.sh toggle"])
        }}
    >
        <box spacing={6}>
            <box className={vpnStatus(s => `toggle-dot ${s.cls}`)} />
            <label
                label={vpnStatus(s => `󰌾 ${s.text}`)}
                tooltipText={vpnStatus(s => s.tooltip)}
            />
        </box>
    </button>
}
