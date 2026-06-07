import AppKit

class MarkdownTextView: NSTextView {
    init() {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(containerSize: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        super.init(frame: .zero, textContainer: textContainer)
        
        self.isRichText = false
        self.allowsUndo = true
        self.font = NSFont.systemFont(ofSize: 16)
        self.textColor = NSColor.textColor
        self.insertionPointColor = NSColor.textColor
        self.backgroundColor = NSColor.textBackgroundColor
        self.textContainerInset = NSSize(width: 40, height: 40)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
