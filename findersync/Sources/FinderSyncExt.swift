import Cocoa
import FinderSync

class NewFileFinderSync: FIFinderSync {

    override init() {
        super.init()
        // Observe real directories (FinderSync rejects the root "/").
        // "/Users" covers every user folder recursively; "/Volumes" covers
        // external/mounted drives.
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/Users"),
            URL(fileURLWithPath: "/Volumes")
        ]
        NSLog("NEWFILE_INIT observing /Users and /Volumes")
    }

    // MARK: - Contextual menu

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        NSLog("NEWFILE_MENU kind=\(menuKind.rawValue)")
        let menu = NSMenu(title: "")
        // .contextualMenuForContainer == right-click on empty space in a folder
        // .contextualMenuForItems     == right-click on a selected item
        switch menuKind {
        case .contextualMenuForContainer, .contextualMenuForItems:
            let item = NSMenuItem(title: "New File",
                                  action: #selector(newFileClicked(_:)),
                                  keyEquivalent: "")
            item.target = self
            item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
            menu.addItem(item)
        default:
            break
        }
        return menu
    }

    // MARK: - Action

    private func dbg(_ s: String) {
        let logURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nf.log")
        let line = "\(Date()): \(s)\n"
        if let h = try? FileHandle(forWritingTo: logURL) {
            h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); try? h.close()
        } else {
            try? line.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }

    @objc func newFileClicked(_ sender: AnyObject?) {
        let controller = FIFinderSyncController.default()
        let target = controller.targetedURL()?.path ?? "nil"
        let selected = (controller.selectedItemURLs() ?? []).map { $0.path }
        dbg("clicked. targeted=\(target) selected=\(selected)")

        guard let dir = destinationDirectory(controller) else {
            dbg("no destination directory")
            return
        }

        let fm = FileManager.default
        var url = dir.appendingPathComponent("Untitled.txt")
        var i = 2
        while fm.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("Untitled \(i).txt")
            i += 1
        }

        let created = fm.createFile(atPath: url.path, contents: Data())
        dbg("createFile at \(url.path) -> \(created)")

        if created {
            revealAndRename(url)
        }
    }

    /// Where to create the file:
    /// - a single selected folder  -> inside that folder
    /// - otherwise (empty space, or a file selected) -> the folder being viewed
    private func destinationDirectory(_ controller: FIFinderSyncController) -> URL? {
        if let items = controller.selectedItemURLs(), items.count == 1 {
            let item = items[0]
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir),
               isDir.boolValue {
                return item
            }
        }
        return controller.targetedURL()
    }

    /// Select the new file in Finder and drop into inline-rename mode.
    private func revealAndRename(_ url: URL) {
        let path = url.path.replacingOccurrences(of: "\"", with: "\\\"")
        let source = """
        tell application "Finder"
            activate
            reveal (POSIX file "\(path)" as alias)
        end tell
        delay 0.25
        tell application "System Events" to key code 36
        """
        DispatchQueue.global(qos: .userInitiated).async {
            if let script = NSAppleScript(source: source) {
                var err: NSDictionary?
                script.executeAndReturnError(&err)
                if let err = err { NSLog("NewFileMenu: applescript error \(err)") }
            }
        }
    }
}
