import AppKit

class MarkdownTextView: NSTextView {
    let customTextStorage: NSTextStorage
    
    init() {
        let textStorage = NSTextStorage()
        self.customTextStorage = textStorage
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(containerSize: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)
        
        super.init(frame: NSRect(x: 0, y: 0, width: 800, height: 600), textContainer: textContainer)
        
        self.minSize = NSSize(width: 0, height: 0)
        self.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        self.isVerticallyResizable = true
        self.isHorizontallyResizable = false
        self.autoresizingMask = [.width]
        
        self.isEditable = true
        self.isSelectable = true
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
