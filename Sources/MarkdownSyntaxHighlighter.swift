import AppKit

class MarkdownSyntaxHighlighter: NSObject, NSTextViewDelegate {
    weak var textView: NSTextView?
    var isHighlighting = false
    
    var baseFontSize: CGFloat = 16.0
    var fontFamily: String = "System"
    
    var baseFont: NSFont!
    var boldFont: NSFont!
    var italicFont: NSFont!
    var h1Font: NSFont!
    var h2Font: NSFont!
    var h3Font: NSFont!
    var h4Font: NSFont!
    var h5Font: NSFont!
    var h6Font: NSFont!
    var codeFont: NSFont!
    
    var imageViews: [NSImageView] = []
    
    override init() {
        super.init()
        reloadFonts()
        NotificationCenter.default.addObserver(self, selector: #selector(fontsDidChange), name: NSNotification.Name("FontSettingsChanged"), object: nil)
    }
    
    @objc func fontsDidChange() {
        reloadFonts()
        textView?.font = baseFont
        highlightAll()
    }
    
    func reloadFonts() {
        baseFontSize = CGFloat(UserDefaults.standard.double(forKey: "FontSize"))
        if baseFontSize < 10 { baseFontSize = 16.0 }
        
        fontFamily = UserDefaults.standard.string(forKey: "FontFamily") ?? "System"
        
        func createFont(size: CGFloat, bold: Bool = false, italic: Bool = false) -> NSFont {
            var font: NSFont
            if fontFamily == "System" {
                font = NSFont.systemFont(ofSize: size)
            } else {
                font = NSFont(name: fontFamily, size: size) ?? NSFont.systemFont(ofSize: size)
            }
            
            var traits: NSFontDescriptor.SymbolicTraits = []
            if bold { traits.insert(.bold) }
            if italic { traits.insert(.italic) }
            
            if !traits.isEmpty {
                let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
                font = NSFont(descriptor: descriptor, size: size) ?? font
            }
            return font
        }
        
        baseFont = createFont(size: baseFontSize)
        boldFont = createFont(size: baseFontSize, bold: true)
        italicFont = createFont(size: baseFontSize, italic: true)
        
        h1Font = createFont(size: baseFontSize * 2.0, bold: true)
        h2Font = createFont(size: baseFontSize * 1.5, bold: true)
        h3Font = createFont(size: baseFontSize * 1.25, bold: true)
        h4Font = createFont(size: baseFontSize * 1.15, bold: true)
        h5Font = createFont(size: baseFontSize * 1.0, bold: true)
        h6Font = createFont(size: baseFontSize * 0.85, bold: true)
        
        codeFont = NSFont(name: "Menlo", size: baseFontSize * 0.95) ?? NSFont.monospacedSystemFont(ofSize: baseFontSize * 0.95, weight: .regular)
    }
    
    func highlightAll() {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        highlight(range: NSRange(location: 0, length: textStorage.length))
    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        highlight(range: NSRange(location: 0, length: textStorage.length))
        
        if let window = textView.window, let doc = NSDocumentController.shared.document(for: window) {
            doc.updateChangeCount(.changeDone)
        }
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = textView, let textStorage = textView.textStorage else { return }
        guard !isHighlighting else { return }
        
        if UserDefaults.standard.bool(forKey: "HideLinks") {
            isHighlighting = true
            
            let fullRange = NSRange(location: 0, length: textStorage.length)
            let string = textStorage.string as NSString
            let cursor = textView.selectedRange()
            
            textStorage.beginEditing()
            let linkRegex = try? NSRegularExpression(pattern: "!?\\[([^\\]]+)\\]\\(([^)]+)\\)")
            if let matches = linkRegex?.matches(in: string as String, options: [], range: fullRange) {
                for match in matches {
                    let isIntersecting = NSIntersectionRange(match.range, cursor).length > 0 || (cursor.location >= match.range.location && cursor.location <= match.range.upperBound)
                    if match.numberOfRanges == 3 {
                        let urlRange = match.range(at: 2)
                        let parenRange = NSRange(location: urlRange.location - 1, length: urlRange.length + 2)
                        if !isIntersecting {
                            textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: 0.1), range: parenRange)
                            textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: parenRange)
                        } else {
                            textStorage.addAttribute(.font, value: baseFont!, range: parenRange)
                            textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: parenRange)
                        }
                    }
                }
            }
            textStorage.endEditing()
            isHighlighting = false
        }
    }
    
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacement = replacementString, replacement == "\n" else { return true }
        
        let string = textView.string as NSString
        let lineRange = string.lineRange(for: affectedCharRange)
        
        let cursorOffsetInLine = affectedCharRange.location - lineRange.location
        let textBeforeCursor = string.substring(with: NSRange(location: lineRange.location, length: cursorOffsetInLine))
        
        let indentBullets = UserDefaults.standard.bool(forKey: "DynamicListIndentBullets")
        let indentNumbers = UserDefaults.standard.bool(forKey: "DynamicListIndentNumbers")
        
        var pattern = ""
        if indentBullets && indentNumbers {
            pattern = "^([ \\t]*)([-*+]|\\d+\\.)[ \\t]+(.*)$"
        } else if indentBullets {
            pattern = "^([ \\t]*)([-*+])[ \\t]+(.*)$"
        } else if indentNumbers {
            pattern = "^([ \\t]*)(\\d+\\.)[ \\t]+(.*)$"
        }
        
        if !pattern.isEmpty {
            let regex = try? NSRegularExpression(pattern: pattern)
            if let match = regex?.firstMatch(in: textBeforeCursor, options: [], range: NSRange(location: 0, length: textBeforeCursor.count)) {
                let indent = (textBeforeCursor as NSString).substring(with: match.range(at: 1))
                let bullet = (textBeforeCursor as NSString).substring(with: match.range(at: 2))
                let content = (textBeforeCursor as NSString).substring(with: match.range(at: 3))
                
                if content.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Empty bullet point, user wants to exit list. Delete bullet, allow \n
                    let prefixRange = NSRange(location: lineRange.location, length: affectedCharRange.location - lineRange.location)
                    textView.textStorage?.replaceCharacters(in: prefixRange, with: "")
                    return true
                } else {
                    // Auto-continue bullet point
                    var nextBullet = bullet
                    if let num = Int(bullet.dropLast()) {
                        nextBullet = "\(num + 1)."
                    }
                    let insertion = "\n\(indent)\(nextBullet) "
                    textView.textStorage?.replaceCharacters(in: affectedCharRange, with: insertion)
                    return false
                }
            }
        }
        
        return true
    }
    
    func highlight(range: NSRange) {
        guard !isHighlighting, let textView = textView, let textStorage = textView.textStorage else { return }
        isHighlighting = true
        
        let savedSelectedRanges = textView.selectedRanges
        
        textStorage.beginEditing()
        
        textStorage.setAttributes([
            .font: baseFont!,
            .foregroundColor: NSColor.textColor
        ], range: range)
        
        let string = textStorage.string as NSString
        
        let rules: [(pattern: String, attributes: [NSAttributedString.Key: Any])] = [
            // Bold (**text** or __text__)
            (pattern: "(?:\\*\\*|__)[^*_]+(?:\\*\\*|__)", attributes: [.font: boldFont!]),
            // Italic (*text* or _text_)
            (pattern: "(?<!\\*)\\*(?!\\*)[^*]+\\*(?!\\*)|(?<!_)_(?!_)[^_]+_(?!_)", attributes: [.font: italicFont!]),
            // Strikethrough (~~text~~)
            (pattern: "~~[^~]+~~", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]),
            // Inline Code (`code`)
            (pattern: "`[^`\\n]+`", attributes: [
                .font: codeFont!,
                .foregroundColor: NSColor.systemPink,
                .backgroundColor: NSColor.windowBackgroundColor
            ]),
            // Multi-line Code (```\ncode\n```)
            (pattern: "(?s)```.*?```", attributes: [
                .font: codeFont!,
                .foregroundColor: NSColor.systemPink,
                .backgroundColor: NSColor.windowBackgroundColor
            ]),
            // Blockquotes
            (pattern: "(?m)^> [^\\n]+", attributes: [
                .font: italicFont!,
                .foregroundColor: NSColor.secondaryLabelColor
            ]),
            // Horizontal Rules
            (pattern: "(?m)^[-*_]{3,}[ \\t]*$", attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor
            ]),
            // Task Lists (Unchecked)
            (pattern: "(?m)^[ \\t]*[-*+] \\[[ \\]]", attributes: [
                .foregroundColor: NSColor.tertiaryLabelColor
            ]),
            // Task Lists (Checked)
            (pattern: "(?m)^[ \\t]*[-*+] \\[[xX]\\]", attributes: [
                .foregroundColor: NSColor.systemGreen
            ]),
            // Footnotes
            (pattern: "\\[\\^[^\\]]+\\]", attributes: [
                .font: NSFont.systemFont(ofSize: baseFontSize * 0.7),
                .baselineOffset: baseFontSize * 0.4,
                .foregroundColor: NSColor.systemBlue
            ]),
            // Tables (basic pipe matching)
            (pattern: "(?m)^\\|.*\\|$", attributes: [
                .font: codeFont!,
                .backgroundColor: NSColor.windowBackgroundColor.withAlphaComponent(0.5)
            ]),
            // Headers
            (pattern: "(?m)^# [^\\n]+", attributes: [.font: h1Font!]),
            (pattern: "(?m)^## [^\\n]+", attributes: [.font: h2Font!]),
            (pattern: "(?m)^### [^\\n]+", attributes: [.font: h3Font!]),
            (pattern: "(?m)^#### [^\\n]+", attributes: [.font: h4Font!]),
            (pattern: "(?m)^##### [^\\n]+", attributes: [.font: h5Font!]),
            (pattern: "(?m)^###### [^\\n]+", attributes: [.font: h6Font!])
        ]
        
        for rule in rules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: string as String, options: [], range: range)
                for match in matches {
                    textStorage.addAttributes(rule.attributes, range: match.range)
                }
            }
        }
        
        // Bare URLs
        let bareRegex = try? NSRegularExpression(pattern: "https?://[^\\s()<>]+")
        if let matches = bareRegex?.matches(in: string as String, options: [], range: range) {
            for match in matches {
                let urlString = string.substring(with: match.range)
                if let url = URL(string: urlString) {
                    if UserDefaults.standard.bool(forKey: "ClickableLinks") {
                        textStorage.addAttribute(.link, value: url, range: match.range)
                        textStorage.addAttribute(.cursor, value: NSCursor.pointingHand, range: match.range)
                    }
                    textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
                }
            }
        }
        
        let hideLinks = UserDefaults.standard.bool(forKey: "HideLinks")
        let clickableLinks = UserDefaults.standard.bool(forKey: "ClickableLinks")
        let cursor = textView.selectedRange()
        
        let linkRegex = try? NSRegularExpression(pattern: "!?\\[([^\\]]+)\\]\\(([^)]+)\\)")
        if let matches = linkRegex?.matches(in: string as String, options: [], range: range) {
            for match in matches {
                let isIntersecting = NSIntersectionRange(match.range, cursor).length > 0 || (cursor.location >= match.range.location && cursor.location <= match.range.upperBound)
                
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
                
                if match.numberOfRanges == 3 {
                    let textRange = match.range(at: 1)
                    let urlRange = match.range(at: 2)
                    let parenRange = NSRange(location: urlRange.location - 1, length: urlRange.length + 2)
                    
                    let urlString = string.substring(with: urlRange)
                    if let url = URL(string: urlString) {
                        if clickableLinks {
                            textStorage.addAttribute(.link, value: url, range: textRange)
                            textStorage.addAttribute(.cursor, value: NSCursor.pointingHand, range: textRange)
                        }
                    }
                    
                    if hideLinks && !isIntersecting {
                        textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: 0.1), range: parenRange)
                        textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: parenRange)
                    }
                }
            }
        }
        
        // Dynamic List Indent
        let indentBullets = UserDefaults.standard.bool(forKey: "DynamicListIndentBullets")
        let indentNumbers = UserDefaults.standard.bool(forKey: "DynamicListIndentNumbers")
        
        var listPattern = ""
        if indentBullets && indentNumbers {
            listPattern = "(?m)^(([ \\t]*[-*+]|\\d+\\.)[ \\t]+)([^\\n]+)"
        } else if indentBullets {
            listPattern = "(?m)^(([ \\t]*[-*+])[ \\t]+)([^\\n]+)"
        } else if indentNumbers {
            listPattern = "(?m)^((\\d+\\.)[ \\t]+)([^\\n]+)"
        }
        
        if !listPattern.isEmpty {
            let listRegex = try? NSRegularExpression(pattern: listPattern)
            if let matches = listRegex?.matches(in: string as String, options: [], range: range) {
                for match in matches {
                    let style = NSMutableParagraphStyle()
                    let prefixText = string.substring(with: match.range(at: 1))
                    let size = (prefixText as NSString).size(withAttributes: [.font: baseFont!])
                    
                    let visualIndent: CGFloat = 15.0
                    style.firstLineHeadIndent = visualIndent
                    style.headIndent = visualIndent + size.width
                    
                    textStorage.addAttribute(.paragraphStyle, value: style, range: match.range)
                }
            }
        }
        
        textStorage.endEditing()
        
        // Inline Images (Asynchronous overlay)
        if UserDefaults.standard.bool(forKey: "InlineImages") {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let textView = self.textView, let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }
                
                for view in self.imageViews { view.removeFromSuperview() }
                self.imageViews.removeAll()
                
                let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
                let imgRegex = try? NSRegularExpression(pattern: "!\\[[^\\]]*\\]\\(([^)]+)\\)")
                if let matches = imgRegex?.matches(in: textView.string, options: [], range: fullRange) {
                    for match in matches {
                        if match.numberOfRanges == 2 {
                            let path = (textView.string as NSString).substring(with: match.range(at: 1))
                            if let image = NSImage(contentsOfFile: path) {
                                let glyphRange = layoutManager.glyphRange(forCharacterRange: match.range, actualCharacterRange: nil)
                                let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                                
                                let imageView = NSImageView(frame: NSRect(x: rect.maxX + 10, y: rect.minY, width: 100, height: 100))
                                imageView.image = image
                                imageView.imageScaling = .scaleProportionallyUpOrDown
                                textView.addSubview(imageView)
                                self.imageViews.append(imageView)
                            }
                        }
                    }
                }
            }
        } else {
            for view in self.imageViews { view.removeFromSuperview() }
            self.imageViews.removeAll()
        }
        
        textView.selectedRanges = savedSelectedRanges
        isHighlighting = false
    }
}
