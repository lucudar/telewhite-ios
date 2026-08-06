import Foundation
import ImageIO
import MobileCoreServices

// Telewhite: "Strip Data From Files".
//
// A photo picked from the library is re-encoded before it is sent — even when it is sent as a
// file — so its metadata never leaves the phone. A file taken from Files, iCloud Drive, or handed
// over by another app through the share sheet is different: it is uploaded byte for byte, and an
// image carries where it was taken, on what, and when, in EXIF and GPS tags nobody thinks about
// while attaching a scan or a screenshot of a document.
//
// This rewrites the file without those tags. The picture itself is not touched: the encoded image
// is copied across as it is, so there is no quality loss and no visible difference — only the
// invisible part is dropped.

private let telewhiteStrippedMetadataKeys: [CFString] = [
    kCGImagePropertyExifDictionary,
    kCGImagePropertyExifAuxDictionary,
    kCGImagePropertyGPSDictionary,
    kCGImagePropertyIPTCDictionary,
    kCGImagePropertyMakerAppleDictionary,
    kCGImagePropertyMakerCanonDictionary,
    kCGImagePropertyMakerNikonDictionary,
    kCGImagePropertyMakerMinoltaDictionary,
    kCGImagePropertyMakerFujiDictionary,
    kCGImagePropertyMakerOlympusDictionary,
    kCGImagePropertyMakerPentaxDictionary
]

func telewhiteStripFileMetadataEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "telewhite.mods.stripFileMetadata")
}

/// Returns the path of a metadata-free copy, or nil when the file is not an image this can handle
/// — in which case the caller must send the original rather than nothing.
func telewhiteStripImageMetadata(atPath path: String) -> String? {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }
    guard let sourceType = CGImageSourceGetType(source), CGImageSourceGetCount(source) > 0 else {
        return nil
    }

    let outputPath = NSTemporaryDirectory() + "/telewhite-clean-\(Int64.random(in: 0 ..< Int64.max))-" + url.lastPathComponent
    let outputUrl = URL(fileURLWithPath: outputPath)
    guard let destination = CGImageDestinationCreateWithURL(outputUrl as CFURL, sourceType, 1, nil) else {
        return nil
    }

    // kCFNull is how ImageIO is told to drop a whole dictionary rather than rewrite it. The
    // orientation lives in the TIFF dictionary and is deliberately left alone: removing it turns
    // portrait photos sideways for whoever opens them.
    var options: [CFString: Any] = [:]
    for key in telewhiteStrippedMetadataKeys {
        options[key] = kCFNull
    }

    CGImageDestinationAddImageFromSource(destination, source, 0, options as CFDictionary)
    guard CGImageDestinationFinalize(destination) else {
        try? FileManager.default.removeItem(at: outputUrl)
        return nil
    }

    // A rewrite that produced nothing usable is worse than sending the original, so it is only
    // accepted when a real file came out of it.
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: outputPath), let size = attributes[.size] as? NSNumber, size.int64Value > 0 else {
        try? FileManager.default.removeItem(at: outputUrl)
        return nil
    }

    return outputPath
}
