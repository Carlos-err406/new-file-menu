import Cocoa

// Minimal host app. Its only job is to contain the FinderSync extension so
// the system can discover and register it. It shows a small info window.
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let rect = NSRect(x: 0, y: 0, width: 460, height: 200)
        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable],
                          backing: .buffered, defer: false)
        window.title = "New File Menu"
        window.center()

        let label = NSTextField(wrappingLabelWithString:
            "New File Menu is installed.\n\n" +
            "Enable it under System Settings → General → Login Items & Extensions " +
            "→ Finder Extensions, then right-click empty space in any Finder folder " +
            "and choose “New File”.")
        label.frame = NSRect(x: 20, y: 20, width: 420, height: 160)
        label.font = NSFont.systemFont(ofSize: 13)
        window.contentView?.addSubview(label)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
