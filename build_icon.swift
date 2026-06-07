import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let rect = NSRect(origin: .zero, size: size)

// Background (white squircle)
NSColor.white.setFill()
let path = NSBezierPath(roundedRect: rect, xRadius: 225, yRadius: 225)
path.fill()

// Text "M K"
let text = "M K" as NSString
let font = NSFont(name: "Georgia-Bold", size: 340) ?? NSFont.boldSystemFont(ofSize: 340)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.black
]
text.draw(at: NSPoint(x: 120, y: size.height - 420), withAttributes: attributes)

// Terminal cursor line
NSColor.black.setFill()
let cursorRect = NSRect(x: 530, y: size.height - 420, width: 160, height: 40)
let cursorPath = NSBezierPath(rect: cursorRect)
cursorPath.fill()

image.unlockFocus()

if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff), let png = bitmap.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "icon.png"))
    print("icon.png generated successfully.")
} else {
    print("Failed to generate icon.png")
}
