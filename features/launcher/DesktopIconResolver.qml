import QtQuick
import Quickshell

Item {
    id: resolver

    property var iconCache: ({})
    property var iconCacheKeys: []
    readonly property int maxCacheEntries: 256

    width: 0
    height: 0
    visible: false

    function fallbackIcon(app) {
        var text = app ? (app.name || app.id || "") : ""
        return text && text.length > 0 ? text.charAt(0).toUpperCase() : "?"
    }

    function addIconCandidate(candidates, icon) {
        if (!icon || icon === "") return
        for (var i = 0; i < candidates.length; i++) {
            if (candidates[i] === icon) return
        }
        candidates.push(icon)
    }

    function addIconFallbacks(candidates, app) {
        var id = (app.id || "").replace(/\.desktop$/, "")
        var name = (app.name || "").toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
        var generic = (app.genericName || "").toLowerCase()

        addIconCandidate(candidates, id)
        addIconCandidate(candidates, id.replace(/^org\.kde\./, ""))
        addIconCandidate(candidates, id.replace(/^org\.gnome\./, ""))
        addIconCandidate(candidates, name)

        if (generic.indexOf("settings") >= 0 || name.indexOf("settings") >= 0) addIconCandidate(candidates, "preferences-system")
        if (generic.indexOf("monitor") >= 0 || name.indexOf("monitor") >= 0) addIconCandidate(candidates, "utilities-system-monitor")
        if (generic.indexOf("terminal") >= 0 || name.indexOf("terminal") >= 0) addIconCandidate(candidates, "utilities-terminal")
        if (generic.indexOf("text editor") >= 0 || name.indexOf("vim") >= 0) addIconCandidate(candidates, "accessories-text-editor")
        if (name.indexOf("virtual-machine") >= 0 || name.indexOf("virt") >= 0) addIconCandidate(candidates, "virt-manager")
    }

    function usableIconPath(icon) {
        if (!icon || icon === "") return ""

        var path = ""
        if (icon.startsWith("file:")) path = icon
        else if (icon.startsWith("/")) path = "file://" + icon
        else path = Quickshell.iconPath(icon, true)

        if (path.indexOf("/Humanity/devices/48/") !== -1) return ""
        // This Breeze asset contains a path element without path data and QtSvg warns on every load.
        if (path.indexOf("/breeze/devices/64/printer.svg") !== -1) return ""
        return path
    }

    function cacheIcon(key, path) {
        if (iconCache[key] === undefined) {
            if (iconCacheKeys.length >= maxCacheEntries) delete iconCache[iconCacheKeys.shift()]
            iconCacheKeys.push(key)
        }
        iconCache[key] = path
        return path
    }

    function deepIconSearch(app, candidates) {
        var id = (app.id || "").replace(/\.desktop$/, "")
        var strippedId = id.replace(/-bin$/, "").toLowerCase()
        var allEntries = DesktopEntries.applications.values

        for (var i = 0; i < allEntries.length; i++) {
            var entry = allEntries[i]
            var entryId = (entry.id || "").toLowerCase()
            var entryName = (entry.name || "").toLowerCase()
            var entryExec = (entry.execString || "").toLowerCase()

            if (strippedId !== "" && (entryId.indexOf(strippedId) >= 0 || entryName.indexOf(strippedId) >= 0 || entryExec.indexOf(strippedId) >= 0)) {
                addIconCandidate(candidates, entry.icon)
            }
        }
    }

    function resolve(app) {
        if (!app) return ""
        var cacheKey = (app.id || app.name || "") + "|" + (app.icon || "")
        if (iconCache[cacheKey] !== undefined) return iconCache[cacheKey]

        var candidates = []
        addIconCandidate(candidates, app.icon)
        addIconFallbacks(candidates, app)

        for (var i = 0; i < candidates.length; i++) {
            var path = usableIconPath(candidates[i])
            if (path !== "") {
                return cacheIcon(cacheKey, path)
            }
        }

        var fallbackStart = candidates.length
        deepIconSearch(app, candidates)
        for (var j = fallbackStart; j < candidates.length; j++) {
            var fallbackPath = usableIconPath(candidates[j])
            if (fallbackPath !== "") {
                return cacheIcon(cacheKey, fallbackPath)
            }
        }

        return cacheIcon(cacheKey, "")
    }

}
