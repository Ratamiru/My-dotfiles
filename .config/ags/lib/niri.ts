import { exec, subprocess } from "astal"

export interface NiriWorkspace {
    id: number
    idx: number
    name: string | null
    output: string
    is_active: boolean
    is_focused: boolean
    active_window_id: number | null
}

export function getWorkspaces(): NiriWorkspace[] {
    try {
        const out = exec("niri msg --json workspaces")
        return JSON.parse(out)
    } catch {
        return []
    }
}

export function focusWorkspace(idx: number) {
    exec(`niri msg action focus-workspace ${idx}`)
}

export function watchNiriEvents(callback: (event: string, data: any) => void) {
    return subprocess({
        cmd: ["niri", "msg", "--json", "event-stream"],
        out: (line) => {
            try {
                const parsed = JSON.parse(line)
                for (const [event, data] of Object.entries(parsed)) {
                    callback(event, data)
                }
            } catch {}
        },
    })
}

export function getKeyboardLayout(): string {
    try {
        const out = exec("niri msg --json keyboard-layouts")
        const data = JSON.parse(out)
        const names: string[] = data.names ?? []
        const idx: number = data.current_idx ?? 0
        const layout = names[idx] ?? ""
        if (layout.toLowerCase().startsWith("english")) return "EN"
        if (layout.toLowerCase().startsWith("russian")) return "RU"
        return layout.substring(0, 2).toUpperCase()
    } catch {
        return "??"
    }
}
