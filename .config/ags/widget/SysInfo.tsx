import { Variable, exec } from "astal"
import { Gtk } from "astal/gtk3"
import GLib from "gi://GLib"

interface SysStats {
    cpu: string
    mem: string
}

const stats = Variable<SysStats>({ cpu: "0", mem: "0" }).poll(5000, (): SysStats => {
    try {
        const [, memBytes] = GLib.file_get_contents("/proc/meminfo")
        const memText = new TextDecoder().decode(memBytes)
        const memTotal = parseInt(memText.match(/MemTotal:\s+(\d+)/)![1])
        const memAvail = parseInt(memText.match(/MemAvailable:\s+(\d+)/)![1])
        const memPercent = Math.round(((memTotal - memAvail) / memTotal) * 100)

        const cpuOut = exec(["bash", "-c",
            "head -1 /proc/stat; sleep 0.2; head -1 /proc/stat"])
        const lines = cpuOut.trim().split("\n")
        const parse = (line: string) => line.split(/\s+/).slice(1).map(Number)
        const a = parse(lines[0])
        const b = parse(lines[1])
        const idleDiff = b[3] - a[3]
        const totalDiff = b.reduce((s, v) => s + v, 0) - a.reduce((s, v) => s + v, 0)
        const cpuPercent = totalDiff > 0 ? Math.round(((totalDiff - idleDiff) / totalDiff) * 100) : 0

        return { cpu: String(cpuPercent), mem: String(memPercent) }
    } catch {
        return { cpu: "0", mem: "0" }
    }
})

function fillIcon(pct: number): string {
    if (pct < 20) return "○"
    if (pct < 40) return "◔"
    if (pct < 60) return "◑"
    if (pct < 80) return "◕"
    return "●"
}

function levelClass(pct: number): string {
    if (pct < 40) return "level-low"
    if (pct < 65) return "level-mid"
    if (pct < 85) return "level-high"
    return "level-crit"
}

export function CPU() {
    return <box
        className={stats(s => `pill cpu ${levelClass(parseInt(s.cpu))}`)}
        halign={Gtk.Align.CENTER}
    >
        <label label={stats(s => {
            const pct = parseInt(s.cpu)
            return `󰍛 ${fillIcon(pct)} ${s.cpu}%`
        })} />
    </box>
}

export function Memory() {
    return <box
        className={stats(s => `pill memory ${levelClass(parseInt(s.mem))}`)}
        halign={Gtk.Align.CENTER}
    >
        <label label={stats(s => {
            const pct = parseInt(s.mem)
            return `󰡱 ${fillIcon(pct)} ${s.mem}%`
        })} />
    </box>
}
