import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "FontFamily": "System",
            "FontSize": 16.0,
            "Theme": "System",
            "FrostedGlass": false,
            "HideLinks": true,
            "DynamicListIndentBullets": false,
            "DynamicListIndentNumbers": false,
            "InlineImages": false,
            "ClickableLinks": true
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
        
        let standardSizes = [10, 11, 12, 13, 14, 16, 18, 20, 24, 28, 32, 36, 48, 64, 72, 96]
        for size in standardSizes {
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
        
        settingsMenu.addItem(NSMenuItem.separator())
        let hideLinksItem = NSMenuItem(title: "Hide URLs in Links", action: #selector(toggleHideLinks(_:)), keyEquivalent: "")
        hideLinksItem.target = self
        settingsMenu.addItem(hideLinksItem)
        
        let clickableLinksItem = NSMenuItem(title: "Clickable Links", action: #selector(toggleClickableLinks(_:)), keyEquivalent: "")
        clickableLinksItem.target = self
        settingsMenu.addItem(clickableLinksItem)
        
        let dynamicIndentItem = NSMenuItem(title: "Dynamic List Indent", action: nil, keyEquivalent: "")
        let dynamicIndentMenu = NSMenu()
        
        let indentBulletsItem = NSMenuItem(title: "Bullets", action: #selector(toggleIndentBullets(_:)), keyEquivalent: "")
        indentBulletsItem.target = self
        dynamicIndentMenu.addItem(indentBulletsItem)
        
        let indentNumbersItem = NSMenuItem(title: "Numbers", action: #selector(toggleIndentNumbers(_:)), keyEquivalent: "")
        indentNumbersItem.target = self
        dynamicIndentMenu.addItem(indentNumbersItem)
        
        dynamicIndentItem.submenu = dynamicIndentMenu
        settingsMenu.addItem(dynamicIndentItem)
        
        let inlineImagesItem = NSMenuItem(title: "Inline Images", action: #selector(toggleInlineImages(_:)), keyEquivalent: "")
        inlineImagesItem.target = self
        settingsMenu.addItem(inlineImagesItem)
        
        let frostedGlassItem = NSMenuItem(title: "Frosted Glass Titlebar", action: #selector(toggleFrostedGlass(_:)), keyEquivalent: "")
        frostedGlassItem.target = self
        settingsMenu.addItem(frostedGlassItem)
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
    
    @objc func toggleFrostedGlass(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "FrostedGlass")
        UserDefaults.standard.set(!current, forKey: "FrostedGlass")
        NotificationCenter.default.post(name: NSNotification.Name("FrostedGlassChanged"), object: nil)
    }
    
    @objc func toggleHideLinks(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "HideLinks")
        UserDefaults.standard.set(!current, forKey: "HideLinks")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func toggleClickableLinks(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "ClickableLinks")
        UserDefaults.standard.set(!current, forKey: "ClickableLinks")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func toggleIndentBullets(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "DynamicListIndentBullets")
        UserDefaults.standard.set(!current, forKey: "DynamicListIndentBullets")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func toggleIndentNumbers(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "DynamicListIndentNumbers")
        UserDefaults.standard.set(!current, forKey: "DynamicListIndentNumbers")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func toggleInlineImages(_ sender: NSMenuItem) {
        let current = UserDefaults.standard.bool(forKey: "InlineImages")
        UserDefaults.standard.set(!current, forKey: "InlineImages")
        NotificationCenter.default.post(name: NSNotification.Name("FontSettingsChanged"), object: nil)
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
        if menuItem.action == #selector(toggleFrostedGlass(_:)) {
            menuItem.state = UserDefaults.standard.bool(forKey: "FrostedGlass") ? .on : .off
            return true
        }
        if menuItem.action == #selector(toggleHideLinks(_:)) {
            menuItem.state = UserDefaults.standard.bool(forKey: "HideLinks") ? .on : .off
            return true
        }
        if menuItem.action == #selector(toggleClickableLinks(_:)) {
            menuItem.state = UserDefaults.standard.bool(forKey: "ClickableLinks") ? .on : .off
            return true
        }
        if menuItem.action == #selector(toggleIndentBullets(_:)) {
            menuItem.state = UserDefaults.standard.bool(forKey: "DynamicListIndentBullets") ? .on : .off
            return true
        }
        if menuItem.action == #selector(toggleIndentNumbers(_:)) {
            menuItem.state = UserDefaults.standard.bool(forKey: "DynamicListIndentNumbers") ? .on : .off
            return true
        }
        if menuItem.action == #selector(toggleInlineImages(_:)) {
            menuItem.state = UserDefaults.standard.bool(forKey: "InlineImages") ? .on : .off
            return true
        }
        return true
    }
}
