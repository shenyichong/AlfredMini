import Cocoa

func generateMenuBarIcon() {
    // Menu bar icons are usually 18x18 pt (often 22x22 canvas)
    let size = 22
    let scale = 2 // @2x for Retina
    let finalSize = size * scale
    
    let image = NSImage(size: NSSize(width: finalSize, height: finalSize))
    image.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    
    // Clear background (transparent)
    context.clear(CGRect(x: 0, y: 0, width: finalSize, height: finalSize))
    
    // Draw in Black (macOS treats this as a template/mask automatically)
    NSColor.black.setFill()
    NSColor.black.setStroke()
    
    let lineWidth = 2.0 * CGFloat(scale)
    let rect = CGRect(x: 4 * scale, y: 4 * scale, width: 14 * scale, height: 14 * scale)
    
    // Clipboard body
    let path = NSBezierPath(roundedRect: rect, xRadius: 2 * CGFloat(scale), yRadius: 2 * CGFloat(scale))
    path.lineWidth = lineWidth
    path.stroke()
    
    // Clip top (the paper holder part)
    let clipRect = CGRect(x: 8 * scale, y: 15 * scale, width: 6 * scale, height: 4 * scale)
    let clipPath = NSBezierPath(roundedRect: clipRect, xRadius: 1 * CGFloat(scale), yRadius: 1 * CGFloat(scale))
    clipPath.fill()
    
    image.unlockFocus()
    
    // Save as template image
    let targetDir = "AlfredMini/Assets.xcassets/MenuBarIcon.imageset"
    try? FileManager.default.createDirectory(atPath: targetDir, withIntermediateDirectories: true)
    
    if let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) {
        if let pngData = bitmap.representation(using: .png, properties: [:]) {
            let url = URL(fileURLWithPath: "\(targetDir)/icon_22x22@2x.png")
            try? pngData.write(to: url)
        }
    }
    
    // Write Contents.json
    let json = """
    {
      "images" : [
        {
          "idiom" : "universal",
          "scale" : "1x"
        },
        {
          "idiom" : "universal",
          "filename" : "icon_22x22@2x.png",
          "scale" : "2x"
        },
        {
          "idiom" : "universal",
          "scale" : "3x"
        }
      ],
      "info" : {
        "version" : 1,
        "author" : "xcode"
      },
      "properties" : {
        "template-rendering-intent" : "template"
      }
    }
    """
    try? json.write(to: URL(fileURLWithPath: "\(targetDir)/Contents.json"), atomically: true, encoding: .utf8)
}

generateMenuBarIcon()
print("✅ Menu Bar Icon generated.")

