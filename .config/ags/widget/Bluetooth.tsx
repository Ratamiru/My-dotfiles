import { Variable, exec, execAsync } from "astal"
import { Gtk } from "astal/gtk3"

interface BTStatus {
    text: string
    cls: string
    tooltip: string
}

function getBTStatus(): BTStatus {
    try {
        const out = exec(["bash", "-c",
            "$HOME/.config/scripts/bluetooth.sh status"])
        return JSON.parse(out) as BTStatus
    } catch {
        return { text: "off", cls: "off", tooltip: "Bluetooth off" }
    }
}

const btStatus = Variable<BTStatus>(getBTStatus()).poll(5000, getBTStatus)

export default function Bluetooth() {
    return <button
        className={btStatus(s => `pill bluetooth toggle-btn ${s.cls}`)}
        onClicked={() => {
            execAsync(["bash", "-c", "$HOME/.config/scripts/bluetooth.sh toggle"])
        }}
    >
        <box spacing={6}>
            <box className={btStatus(s => `toggle-dot ${s.cls}`)} />
            <label
                label={btStatus(s => `󰂯 ${s.text}`)}
                tooltipText={btStatus(s => s.tooltip)}
            />
        </box>
    </button>
}
