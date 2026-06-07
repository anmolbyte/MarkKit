import AppKit

class ViewController: NSViewController {
    let scrollView = NSScrollView()
    let textView = MarkdownTextView()
    let highlighter = MarkdownSyntaxHighlighter()
    let visualEffectView = NSVisualEffectView()
    var topConstraint: NSLayoutConstraint!
    
    override func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        self.view = container
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        
        textView.autoresizingMask = [.width]
        scrollView.documentView = textView
        
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .withinWindow
        visualEffectView.state = .followsWindowActiveState
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(scrollView)
        container.addSubview(visualEffectView)
        
        topConstraint = scrollView.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor)
        
        NSLayoutConstraint.activate([
            topConstraint,
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            visualEffectView.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor)
        ])
        
        // Attach highlighter
        highlighter.textView = textView
        textView.delegate = highlighter
        
        highlighter.fontsDidChange()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateFrostedGlass), name: NSNotification.Name("FrostedGlassChanged"), object: nil)
        updateFrostedGlass()
    }
    
    @objc func updateFrostedGlass() {
        let isEnabled = UserDefaults.standard.bool(forKey: "FrostedGlass")
        visualEffectView.isHidden = !isEnabled
        
        topConstraint.isActive = false
        if isEnabled {
            topConstraint = scrollView.topAnchor.constraint(equalTo: self.view.topAnchor)
            scrollView.automaticallyAdjustsContentInsets = true
        } else {
            topConstraint = scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor)
            scrollView.automaticallyAdjustsContentInsets = false
            scrollView.contentInsets = NSEdgeInsetsZero
        }
        topConstraint.isActive = true
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.makeFirstResponder(textView)
    }
}
