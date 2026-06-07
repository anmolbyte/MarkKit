import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "FontFamily": "System",
            "FontSize": 16.0,
            "Theme": "System"
        ])
        
        applyTheme(UserDefaults.standard.string(forKey: "Theme") ?? "System")
        setupMenu()
    }
    
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applyTheme(_ theme: String) {
        switch theme {
        case "Light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "Dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
    
    func setupMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "Quit MarkKit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu
        fileMenu.addItem(NSMenuItem(title: "New", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "Open...", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o"))
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileMenu.addItem(NSMenuItem(title: "Save", action: #selector(NSDocument.save(_:)), keyEquivalent: "s"))
        fileMenu.addItem(NSMenuItem(title: "Save As...", action: #selector(NSDocument.saveAs(_:)), keyEquivalent: "S"))
        
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        
        let settingsMenuItem = NSMenuItem()
        mainMenu.addItem(settingsMenuItem)
        let settingsMenu = NSMenu(title: "Settings")
        settingsMenuItem.submenu = settingsMenu
        
        let fontMenuItem = NSMenuItem(title: "Font", action: nil, keyEquivalent: "")
        settingsMenu.addItem(fontMenuItem)
        let fontMenu = NSMenu(title: "Font")
        fontMenuItem.submenu = fontMenu
        
        let fonts = ["System", "Helvetica", "Arial", "Courier", "Menlo", "Georgia", "Times New Roman"]
        for font in fonts {
            let item = NSMenuItem(title: font, action: #selector(changeFontFamily(_:)), keyEquivalent: "")
            item.target = self
            fontMenu.addItem(item)
        }
        
        let fontSizeMenuItem = NSMenuItem(title: "Font Size", action: nil, keyEquivalent: "")
        settingsMenu.addItem(fontSizeMenuItem)
        let fontSizeMenu = NSMenu(title: "Font Size")
        fontSizeMenuItem.submenu = fontSizeMenu
        
        for size in 10...100 {
            let item = NSMenuItem(title: "\(size)", action: #selector(changeFontSize(_:)), keyEquivalent: "")
            item.target = self
            item.tag = size
            fontSizeMenu.addItem(item)
        }
        
        let themeMenuItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        settingsMenu.addItem(themeMenuItem)
        let themeMenu = NSMenu(title: "Theme")
        themeMenuItem.submenu = themeMenu
        
        for theme in ["Light", "Dark", "System"] {
            let item = NSMenuItem(title: theme, action: #selector(changeTheme(_:)), keyEquivalent: "")
            item.target = self
            themeMenu.addItem(item)
        }
    }
    
    @objc func changeFontFamily(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "FontFamily")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func changeFontSize(_ sender: NSMenuItem) {
        UserDefaults.standard.set(Double(sender.tag), forKey: "FontSize")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func changeTheme(_ sender: NSMenuItem) {
        UserDefaults.standard.set(sender.title, forKey: "Theme")
        applyTheme(sender.title)
    }
    
    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(changeFontFamily(_:)) {
            let currentFont = UserDefaults.standard.string(forKey: "FontFamily") ?? "System"
            menuItem.state = (menuItem.title == currentFont) ? .on : .off
            return true
        }
        if menuItem.action == #selector(changeFontSize(_:)) {
            let currentSize = Int(UserDefaults.standard.double(forKey: "FontSize"))
            menuItem.state = (menuItem.tag == currentSize) ? .on : .off
            return true
        }
        if menuItem.action == #selector(changeTheme(_:)) {
            let currentTheme = UserDefaults.standard.string(forKey: "Theme") ?? "System"
            menuItem.state = (menuItem.title == currentTheme) ? .on : .off
            return true
        }
        return true
    }
}
