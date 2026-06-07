# MarkKit

MarkKit is an ultra-lightweight, standalone macOS text editor built in Swift using AppKit. It is designed to be a fully writable, real-time Markdown editor offering a blank canvas experience—no sidebars, no proprietary databases, just your text.

## Features

- **Inline Partial-WYSIWYG:** As you type, Markdown characters (like `##`, `**`, `>`) remain visible, but the text dynamically formats itself in real-time. For instance, typing `##` leaves the hashes visible while instantly scaling the text to an H2 font size and weight.
- **Comprehensive Markdown Support:** Real-time formatting natively supports headings, bold/italic variations (`**`, `__`, `*`, `_`), strikethrough (`~~`), inline code, multi-line fenced code blocks, blockquotes, and horizontal rules!
- **Interactive Link Hiding:** Type out a link like `[Apple](https://apple.com)` and watch the URL instantly shrink and vanish to keep your text clean! Need to edit it? Just move your cursor or click on the link, and the URL will instantaneously expand back into view.
- **Deep Customization:** A built-in Settings menu lets you easily configure your typographic preferences (curated font families and standard sizes).
- **Native Theming & Frosted Glass:** Supports Light, Dark, and System modes. Enable the "Frosted Glass Titlebar" to let your text seamlessly blur behind the macOS traffic lights as you scroll.
- **Cursor Safeguard:** Text updates are managed precisely to prevent the insertion point (cursor) from jumping to the end of the line during real-time formatting.
- **Standalone Document App:** Built as an `NSDocument`-based application, it opens, edits, and saves `.md` and `.txt` files directly to/from the macOS Finder natively.
- **No Xcode Project Required:** The project is compiled simply via a `Makefile` that constructs the `.app` bundle, avoiding bloated configurations and keeping the source code perfectly transparent.

## Building and Running

You can compile MarkKit natively on your Mac using the provided `Makefile`.

1. Open your terminal.
2. Navigate to the project directory:
   ```bash
   cd /path/to/MarkKit
   ```
3. Run the make command:
   ```bash
   make
   ```
4. Launch the application:
   ```bash
   open MarkKit.app
   ```

## Development

The project consists of plain Swift files compiled with `swiftc`. The core editor logic lives in `MarkdownSyntaxHighlighter.swift` which safely processes real-time syntax highlighting on an `NSTextView` while strictly preserving the `selectedRanges`.