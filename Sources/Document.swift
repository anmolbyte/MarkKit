import AppKit

class Document: NSDocument {
    var contentString: String = ""
    
    override init() {
        super.init()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func makeWindowControllers() {
        let windowController = DocumentController()
        self.addWindowController(windowController)
        
        if let vc = windowController.contentViewController as? ViewController {
            vc.textView.string = contentString
            vc.highlighter.highlightAll()
        }
    }
    
    override func data(ofType typeName: String) throws -> Data {
        if let windowController = windowControllers.first,
           let vc = windowController.contentViewController as? ViewController {
            contentString = vc.textView.string
        }
        guard let data = contentString.data(using: .utf8) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        return data
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        if let string = String(data: data, encoding: .utf8) {
            contentString = string
        } else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }
}
