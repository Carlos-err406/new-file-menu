# New File Menu

Add a **"New File"** action to Finder's right-click menu on macOS — the thing
macOS inexplicably doesn't ship.

Two implementations live here:

| | Where it appears | Reliability | Signing |
|---|---|---|---|
| **`quick-action/`** ✅ recommended | Right-click a folder → **Quick Actions › New File** | Works | None needed |
| **`findersync/`** 🧪 experimental | Top-level right-click item | Blocked on macOS 26 (see below) | Needs a real code-signing identity |

## quick-action/ — the working one

A plain Automator Quick Action (a `.workflow` service). Right-click a folder and
it drops an `Untitled.txt` **inside that folder**.

```sh
./quick-action/install.sh      # install + register + restart Finder
./quick-action/uninstall.sh    # remove
```

Then: **right-click any folder → Quick Actions › New File**.

Notes:
- The clicked folder arrives to the shell script as `$1` (Finder's `selection`
  and stdin are unreliable for services — the argument is the source of truth).
- It creates the file **silently, with no window change**. It does *not* enter
  inline-rename, because macOS can only inline-rename a file it is currently
  showing, which would mean opening/navigating into the folder. That trade-off
  was chosen deliberately: no surprise windows. To rename, open the folder and
  hit Return on the new file.

### Tweaks
Edit `quick-action/New File.workflow/Contents/document.wflow`, the
`COMMAND_STRING` block:
- Change `Untitled.txt` to `Untitled.md` (or drop the extension) for a different
  default.
- Duplicate the workflow with a different `NSMenuItem` name for a second type.
Re-run `install.sh` after editing.

## findersync/ — the "proper" top-level version (experimental)

A real [FinderSync](https://developer.apple.com/documentation/findersync)
extension (host app + `.appex`) that would put **"New File"** at the top level of
the right-click menu, like the paid App Store apps. The code is correct and
builds with only the Command Line Tools:

```sh
./findersync/build.sh    # compile + ad-hoc sign into ./findersync/build/
./findersync/deploy.sh   # + install to /Applications, register, enable
```

### Why it's not the default: the macOS 26 signing wall
With **ad-hoc signing** (`codesign -s -`, i.e. no Apple Developer identity),
macOS 26 registers the extension and even provisions its sandbox container, but
Finder **won't reliably load its menu** — the OS intermittently miscategorizes it
as a "File Provider" extension instead of a Finder extension, and it never gets
invoked. It worked exactly once, when it happened to land under
**System Settings › Login Items & Extensions › (By Category) Finder** and was
enabled there.

Things learned the hard way:
- Observe real directories (`/Users`, `/Volumes`) — **`directoryURLs = ["/"]` is
  silently rejected**, leaving nothing observed.
- `temporary-exception.*` entitlements (files / apple-events) **break loading**
  under ad-hoc signing — keep entitlements minimal (`app-sandbox` +
  `files.user-selected.read-write`).
- Each rebuild changes the code hash, which **resets the Finder-extension
  consent**, so it must be re-enabled in System Settings every time. A stable
  signing identity would fix this (and likely the loading issue too).

**To finish this path:** sign with a real identity — a free Apple ID "Personal
Team" development certificate (via Xcode) is enough to load FinderSync locally;
a Developer ID + notarization is needed to distribute it. Replace the `-` in
`build.sh`'s `codesign --sign -` with the identity, then `deploy.sh`.

## Layout
```
quick-action/
  New File.workflow/   the Automator service (the working tool)
  install.sh  uninstall.sh
findersync/
  Sources/             FinderSyncExt.swift, HostMain.swift
  ext-Info.plist  host-Info.plist  ext.entitlements
  build.sh  deploy.sh
```
