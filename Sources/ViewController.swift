import AppKit

class ViewController: NSViewController {
    let scrollView = NSScrollView()
    let textView = MarkdownTextView()
    let highlighter = MarkdownSyntaxHighlighter()
    
    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = container
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        textView.autoresizingMask = [.width]
        scrollView.documentView = textView
        
        container.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: container.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        // Attach highlighter
        highlighter.textView = textView
        textView.delegate = highlighter
        
        highlighter.fontsDidChange()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(textView)
    }
}
