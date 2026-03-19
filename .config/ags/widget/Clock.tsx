import { Variable } from "astal"
import { Gtk } from "astal/gtk3"

const time = Variable("").poll(1000, () => {
    const now = new Date()
    const h = String(now.getHours()).padStart(2, "0")
    const m = String(now.getMinutes()).padStart(2, "0")
    return `${h}:${m}`
})

const dateStr = Variable("").poll(60000, () => {
    const now = new Date()
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return `${days[now.getDay()]}, ${now.getDate()} ${months[now.getMonth()]}`
})

let showDate = Variable(false)

export default function Clock() {
    return <button
        className="pill clock"
        onClicked={() => showDate.set(!showDate.get())}
        halign={Gtk.Align.CENTER}
    >
        <label label={Variable.derive(
            [time, dateStr, showDate],
            (t, d, sd) => sd ? `  ${d}` : `  ${t}`,
        )()} />
    </button>
}
