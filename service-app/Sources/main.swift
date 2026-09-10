import Cocoa

// A tiny background agent that provides a "New File" macOS Service.
// Because it stays resident (a LaunchAgent keeps it alive), invoking the
// service is near-instant — no per-click process launch like Automator.

final class ServiceProvider: NSObject {
    // Matched to NSMessage "createNewFile" in Info.plist.
    // ObjC selector: createNewFile:userData:error:
    @objc func createNewFile(_ pboard: NSPasteboard,
                             userData: NSString?,
                             error: AutoreleasingUnsafeMutablePointer<NSString?>?) {
        let opts: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let urls = pboard.readObjects(forClasses: [NSURL.self], options: opts) as? [URL],
              let clicked = urls.first else {
            error?.pointee = "New File: no folder provided" as NSString
            return
        }

        // Create inside the clicked folder; if a file was clicked, use its parent.
        var dir = clicked
        var isDir: ObjCBool = false
        let fm = FileManager.default
        if fm.fileExists(atPath: dir.path, isDirectory: &isDir), !isDir.boolValue {
            dir = dir.deletingLastPathComponent()
        }

        var url = dir.appendingPathComponent("Untitled.txt")
        var i = 2
        while fm.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("Untitled \(i).txt")
            i += 1
        }
        if !fm.createFile(atPath: url.path, contents: Data()) {
            error?.pointee = "New File: could not create \(url.path)" as NSString
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)          // background agent, no Dock icon
let provider = ServiceProvider()
app.servicesProvider = provider
NSUpdateDynamicServices()
app.run()
