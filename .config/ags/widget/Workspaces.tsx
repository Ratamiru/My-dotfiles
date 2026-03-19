import { Variable } from "astal"
import { Gtk } from "astal/gtk3"
import { getWorkspaces, focusWorkspace, watchNiriEvents, type NiriWorkspace } from "../lib/niri"

const workspaces = Variable<NiriWorkspace[]>(getWorkspaces())

watchNiriEvents((event) => {
    if (event === "WorkspacesChanged" ||
        event === "WorkspaceActivated" ||
        event === "WorkspaceFocusChanged") {
        workspaces.set(getWorkspaces())
    }
})

export default function Workspaces() {
    return <box className="pill workspaces" halign={Gtk.Align.START}>
        {workspaces((ws) => {
            const sorted = [...ws]
                .filter(w => w.is_active || w.is_focused)
                .sort((a, b) => a.idx - b.idx)
            return sorted.map(w =>
                <button
                    className={w.is_focused ? "ws-dot focused" : "ws-dot"}
                    onClicked={() => focusWorkspace(w.idx)}
                >
                    <box />
                </button>
            )
        })}
    </box>
}
