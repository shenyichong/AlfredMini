import Cocoa

func generateIcon(size: Int, scale: Int, filename: String) {
    let pixelSize = size * scale
    
    // 1. Create an explicit bitmap representation with exact pixel dimensions
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return }
    
    // IMPORTANT: Set size in points to match pixelSize so we draw 1:1 in the context
    rep.size = NSSize(width: pixelSize, height: pixelSize)
    
    // 2. Draw into the bitmap context
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    
    let rect = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    
    // --- Drawing Logic ---
    
    // Background: Modern macOS Squircle
    let path = NSBezierPath(roundedRect: rect, xRadius: CGFloat(pixelSize) * 0.22, yRadius: CGFloat(pixelSize) * 0.22)
    path.addClip()
    
    // Gradient
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let colors = [
        NSColor(red: 0.2, green: 0.2, blue: 0.8, alpha: 1.0).cgColor,
        NSColor(red: 0.6, green: 0.2, blue: 0.9, alpha: 1.0).cgColor,
        NSColor(red: 0.2, green: 0.8, blue: 0.9, alpha: 1.0).cgColor
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.5, 1.0]
    
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: CGFloat(pixelSize), y: CGFloat(pixelSize)), options: [])
    }
    
    // Symbol
    let symbolRect = rect.insetBy(dx: CGFloat(pixelSize) * 0.25, dy: CGFloat(pixelSize) * 0.25)
    context.setShadow(offset: CGSize(width: 0, height: -CGFloat(pixelSize) * 0.05), blur: CGFloat(pixelSize) * 0.05, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    
    let paperPath = NSBezierPath(roundedRect: symbolRect, xRadius: CGFloat(pixelSize) * 0.05, yRadius: CGFloat(pixelSize) * 0.05)
    NSColor.white.withAlphaComponent(0.9).setFill()
    paperPath.fill()
    
    NSColor.black.withAlphaComponent(0.1).setFill()
    let lineH = CGFloat(pixelSize) * 0.04
    let lineW = symbolRect.width * 0.6
    let lineX = symbolRect.minX + (symbolRect.width - lineW) / 2
    
    for i in 0..<3 {
        let y = symbolRect.minY + symbolRect.height * 0.3 + CGFloat(i) * (lineH * 2.5)
        let lineRect = CGRect(x: lineX, y: y, width: lineW, height: lineH)
        let linePath = NSBezierPath(roundedRect: lineRect, xRadius: lineH/2, yRadius: lineH/2)
        linePath.fill()
    }
    
    // --- End Drawing Logic ---
    
    NSGraphicsContext.restoreGraphicsState()
    
    // 3. Save to PNG
    if let pngData = rep.representation(using: .png, properties: [:]) {
        let url = URL(fileURLWithPath: filename)
        try? pngData.write(to: url)
    }
}

let targetDir = "AlfredMini/Assets.xcassets/AppIcon.appiconset"

// Specific sizes required by macOS AppIcon set
let specs: [(size: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for spec in specs {
    let filename = "\(targetDir)/icon_\(spec.size)x\(spec.size)\(spec.scale == 2 ? "@2x" : "").png"
    generateIcon(size: spec.size, scale: spec.scale, filename: filename)
}

print("✅ Icons generated in \(targetDir)")

