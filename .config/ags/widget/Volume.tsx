import Wp from "gi://AstalWp"
import { bind, Variable } from "astal"
import { Astal, Gtk } from "astal/gtk3"

const wp = Wp.get_default()!

function volumeIcon(vol: number, muted: boolean): string {
    if (muted) return "󰖁"
    if (vol > 0.66) return "󰕾"
    if (vol > 0.33) return "󰖀"
    return "󰕿"
}

export default function Volume() {
    const speaker = wp.audio.default_speaker!

    const icon = Variable.derive(
        [bind(speaker, "volume"), bind(speaker, "mute")],
        (vol: number, muted: boolean) => volumeIcon(vol, muted),
    )

    return <eventbox
        className="pill volume"
        onScroll={(_, evt) => {
            const step = 0.05
            const dir = typeof evt === "object" ? evt.direction : evt
            if (dir === 0) // UP
                speaker.volume = Math.min(1, speaker.volume + step)
            else if (dir === 1) // DOWN
                speaker.volume = Math.max(0, speaker.volume - step)
        }}
    >
        <box spacing={4}>
            <button
                className="vol-mute-btn"
                onClicked={() => { speaker.mute = !speaker.mute }}
            >
                <label label={icon()} />
            </button>
            <slider
                className="volume-slider"
                hexpand
                widthRequest={80}
                value={bind(speaker, "volume")}
                onDragged={(self) => { speaker.volume = self.value }}
            />
            <label
                className="vol-pct"
                label={bind(speaker, "volume").as(v => `${Math.round(v * 100)}%`)}
            />
        </box>
    </eventbox>
}
