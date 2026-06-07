import AppKit

class DocumentController: NSWindowController {
    
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        self.init(window: window)
        
        let vc = ViewController()
        self.contentViewController = vc
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    }
}
