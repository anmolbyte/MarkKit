import AppKit

class MarkdownSyntaxHighlighter: NSObject, NSTextViewDelegate {
    weak var textView: NSTextView?
    var isHighlighting = false
    
    let baseFont = NSFont.systemFont(ofSize: 16)
    
    lazy var boldFont: NSFont = {
        return NSFont.boldSystemFont(ofSize: 16)
    }()
    
    lazy var italicFont: NSFont = {
        let font = NSFont.systemFont(ofSize: 16)
        let descriptor = font.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: 16) ?? font
    }()
    
    let h1Font = NSFont.boldSystemFont(ofSize: 32)
    let h2Font = NSFont.boldSystemFont(ofSize: 24)
    let h3Font = NSFont.boldSystemFont(ofSize: 20)
    let h4Font = NSFont.boldSystemFont(ofSize: 18)
    let h5Font = NSFont.boldSystemFont(ofSize: 16)
    let h6Font = NSFont.boldSystemFont(ofSize: 14)
    
    let codeFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
    
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
    
    func highlight(range: NSRange) {
        guard !isHighlighting, let textView = textView, let textStorage = textView.textStorage else { return }
        isHighlighting = true
        
        let savedSelectedRanges = textView.selectedRanges
        
        textStorage.beginEditing()
        
        textStorage.setAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.textColor
        ], range: range)
        
        let string = textStorage.string as NSString
        
        let rules: [(pattern: String, attributes: [NSAttributedString.Key: Any])] = [
            // Bold (**text**)
            (pattern: "\\*\\*[^\\*]+\\*\\*", attributes: [.font: boldFont]),
            // Italic (*text*)
            (pattern: "\\*(?!\\*)[^\\*]+\\*(?!\\*)", attributes: [.font: italicFont]),
            // Strikethrough (~~text~~)
            (pattern: "~~[^~]+~~", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]),
            // Inline Code (`code`)
            (pattern: "`[^`]+`", attributes: [
                .font: codeFont,
                .foregroundColor: NSColor.systemPink,
                .backgroundColor: NSColor.windowBackgroundColor
            ]),
            // Headers
            (pattern: "^# [^\n]+", attributes: [.font: h1Font]),
            (pattern: "^## [^\n]+", attributes: [.font: h2Font]),
            (pattern: "^### [^\n]+", attributes: [.font: h3Font]),
            (pattern: "^#### [^\n]+", attributes: [.font: h4Font]),
            (pattern: "^##### [^\n]+", attributes: [.font: h5Font]),
            (pattern: "^###### [^\n]+", attributes: [.font: h6Font])
        ]
        
        for rule in rules {
            if let regex = try? NSRegularExpression(pattern: rule.pattern, options: [.anchorsMatchLines]) {
                let matches = regex.matches(in: string as String, options: [], range: range)
                for match in matches {
                    textStorage.addAttributes(rule.attributes, range: match.range)
                }
            }
        }
        
        textStorage.endEditing()
        
        textView.selectedRanges = savedSelectedRanges
        isHighlighting = false
    }
}
