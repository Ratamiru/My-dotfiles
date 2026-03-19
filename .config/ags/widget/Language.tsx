import { Variable } from "astal"
import { getKeyboardLayout, watchNiriEvents } from "../lib/niri"

const lang = Variable(getKeyboardLayout())

watchNiriEvents((event) => {
    if (event === "KeyboardLayoutSwitched") {
        lang.set(getKeyboardLayout())
    }
})

export default function Language() {
    return <button className="pill language">
        <label label={lang(l => `  ${l}`)} />
    </button>
}
