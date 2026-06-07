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
            (pattern: "`[^`]+`", attributes: [
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
        
        let hideLinks = UserDefaults.standard.bool(forKey: "HideLinks")
        let cursor = textView.selectedRange()
        
        let linkRegex = try? NSRegularExpression(pattern: "!?\\[([^\\]]+)\\]\\(([^)]+)\\)")
        if let matches = linkRegex?.matches(in: string as String, options: [], range: range) {
            for match in matches {
                let isIntersecting = NSIntersectionRange(match.range, cursor).length > 0 || (cursor.location >= match.range.location && cursor.location <= match.range.upperBound)
                
                textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
                
                if match.numberOfRanges == 3 {
                    let urlRange = match.range(at: 2)
                    let parenRange = NSRange(location: urlRange.location - 1, length: urlRange.length + 2)
                    
                    if hideLinks && !isIntersecting {
                        textStorage.addAttribute(.font, value: NSFont.systemFont(ofSize: 0.1), range: parenRange)
                        textStorage.addAttribute(.foregroundColor, value: NSColor.clear, range: parenRange)
                    }
                }
            }
        }
        
        textStorage.endEditing()
        
        textView.selectedRanges = savedSelectedRanges
        isHighlighting = false
    }
}
