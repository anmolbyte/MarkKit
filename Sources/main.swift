import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let delegate = AppDelegate()
app.delegate = delegate

app.activate(ignoringOtherApps: true)

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
