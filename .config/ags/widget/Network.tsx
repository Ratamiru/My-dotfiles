import NM from "gi://AstalNetwork"
import { Variable } from "astal"

const network = NM.get_default()!

interface NetInfo {
    text: string
    tooltip: string
}

function getNetInfo(): NetInfo {
    const wifi = network.wifi
    if (wifi && wifi.enabled && wifi.ssid) {
        return { text: `  ${wifi.strength}%`, tooltip: wifi.ssid }
    }
    const wired = network.wired
    if (wired && wired.speed > 0) {
        return { text: "  wired", tooltip: "Ethernet" }
    }
    return { text: "  off", tooltip: "Disconnected" }
}

const netInfo = Variable<NetInfo>(getNetInfo())

// Re-read on network changes
network.connect("notify", () => netInfo.set(getNetInfo()))

export default function Network() {
    return <button className="pill network">
        <label
            label={netInfo(n => n.text)}
            tooltipText={netInfo(n => n.tooltip)}
        />
    </button>
}
