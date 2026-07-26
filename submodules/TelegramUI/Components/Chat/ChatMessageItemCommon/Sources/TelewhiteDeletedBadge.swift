import Foundation
import UIKit
import Display

// Telewhite: badge marking a message the sender deleted while "Keep Deleted
// Messages" preserved it locally.
//
// Fading the content alone did not communicate deletion: a translucent photo over
// a dark wallpaper still reads as a normal photo, and a dimmed text bubble reads as
// a theme quirk. The badge states it outright, which also lets the content stay
// readable — the whole point of preserving a deleted message is being able to read
// it — so callers pair this with a mild fade instead of a heavy one.
//
// The badge is rendered as a single flattened image so callers can hang it off an
// ASImageNode overlay: it never joins the measured layout and therefore cannot
// disturb the size a content node just reported.

private final class TelewhiteDeletedBadgeCache {
    static let shared = TelewhiteDeletedBadgeCache()

    private let lock = NSLock()
    private var images: [String: UIImage] = [:]

    func image(for text: String, _ generate: () -> UIImage?) -> UIImage? {
        let key = "\(text)-\(UIScreen.main.scale)"
        self.lock.lock()
        if let existing = self.images[key] {
            self.lock.unlock()
            return existing
        }
        self.lock.unlock()

        guard let image = generate() else {
            return nil
        }
        self.lock.lock()
        self.images[key] = image
        self.lock.unlock()
        return image
    }
}

/// Opacity for the content of a preserved-deleted message. Mild on purpose — the
/// badge carries the signal, so the content stays legible.
public let telewhiteDeletedContentAlpha: CGFloat = 0.6

/// Label shown inside the badge, in the chat's language.
public func telewhiteDeletedBadgeTitle(isRussian: Bool) -> String {
    return isRussian ? "Удалено" : "Deleted"
}

/// A dark translucent pill with a trash glyph and `text`, legible over both message
/// bubbles and photos. Cached per (text, screen scale).
public func telewhiteDeletedBadgeImage(text: String) -> UIImage? {
    return TelewhiteDeletedBadgeCache.shared.image(for: text) {
        let font = Font.semibold(11.0)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.boundingRect(with: CGSize(width: 200.0, height: 100.0), options: [.usesLineFragmentOrigin], context: nil).size

        let glyphSize = CGSize(width: 9.0, height: 10.0)
        let leftInset: CGFloat = 6.0
        let glyphSpacing: CGFloat = 4.0
        let rightInset: CGFloat = 7.0
        let height: CGFloat = 17.0
        let width = leftInset + glyphSize.width + glyphSpacing + ceil(textSize.width) + rightInset

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext

            let bounds = CGRect(origin: CGPoint(), size: CGSize(width: width, height: height))
            context.setFillColor(UIColor(white: 0.0, alpha: 0.75).cgColor)
            UIBezierPath(roundedRect: bounds, cornerRadius: height * 0.5).fill()

            // Trash glyph: lid, handle bump, tapered body.
            let glyphOrigin = CGPoint(x: leftInset, y: floor((height - glyphSize.height) * 0.5))
            context.setStrokeColor(UIColor.white.cgColor)
            context.setLineWidth(1.0)
            context.setLineCap(.round)

            let lid = UIBezierPath()
            lid.move(to: CGPoint(x: glyphOrigin.x, y: glyphOrigin.y + 2.5))
            lid.addLine(to: CGPoint(x: glyphOrigin.x + glyphSize.width, y: glyphOrigin.y + 2.5))
            lid.stroke()

            let handle = UIBezierPath()
            handle.move(to: CGPoint(x: glyphOrigin.x + 3.0, y: glyphOrigin.y + 2.0))
            handle.addLine(to: CGPoint(x: glyphOrigin.x + 3.0, y: glyphOrigin.y + 0.75))
            handle.addLine(to: CGPoint(x: glyphOrigin.x + 6.0, y: glyphOrigin.y + 0.75))
            handle.addLine(to: CGPoint(x: glyphOrigin.x + 6.0, y: glyphOrigin.y + 2.0))
            handle.stroke()

            let body = UIBezierPath()
            body.move(to: CGPoint(x: glyphOrigin.x + 1.25, y: glyphOrigin.y + 3.75))
            body.addLine(to: CGPoint(x: glyphOrigin.x + 2.0, y: glyphOrigin.y + glyphSize.height - 0.5))
            body.addLine(to: CGPoint(x: glyphOrigin.x + glyphSize.width - 2.0, y: glyphOrigin.y + glyphSize.height - 0.5))
            body.addLine(to: CGPoint(x: glyphOrigin.x + glyphSize.width - 1.25, y: glyphOrigin.y + 3.75))
            body.lineJoinStyle = .round
            body.stroke()

            let textOrigin = CGPoint(
                x: leftInset + glyphSize.width + glyphSpacing,
                y: floor((height - textSize.height) * 0.5)
            )
            attributedText.draw(at: textOrigin)
        }
    }
}

/// Places a badge of `badgeSize` in the free gutter beside `contentFrame` — right of
/// incoming content, left of outgoing — so it does not cover the message.
///
/// `containerWidth` must already have the safe-area inset taken off, and
/// `reservedGutterWidth` the width of anything the layout puts in that gutter (the share
/// and summarize buttons, a video note's reply/forward header). Otherwise the badge is
/// drawn under the rounded corner in landscape, or the share button lands on top of it.
///
/// When the gutter cannot hold the badge it moves inside the content, to the **bottom**
/// leading corner. Not the top one: that corner holds the sender's name, the forward and
/// reply headers and the media duration pill, so the badge covered exactly the
/// information that says whose deleted message this was. Bottom-leading is the one inside
/// corner Telegram leaves free — the timestamp and delivery ticks sit bottom-trailing.
/// `preferInsideBottom` skips the gutter entirely. Video notes pass it when the message
/// carries a reply or forward header: those headers are right-aligned into the very gutter
/// the badge wants, and a round video's bounding-box corner is transparent anyway, so
/// inside-bottom is free space there rather than a compromise.
public func telewhiteDeletedBadgeFrame(badgeSize: CGSize, contentFrame: CGRect, containerWidth: CGFloat, isIncoming: Bool, reservedGutterWidth: CGFloat = 0.0, preferInsideBottom: Bool = false) -> CGRect {
    let spacing: CGFloat = 6.0
    let edgeInset: CGFloat = 4.0

    let insideBottom = CGPoint(
        x: isIncoming ? contentFrame.minX + spacing : contentFrame.maxX - spacing - badgeSize.width,
        y: contentFrame.maxY - 4.0 - badgeSize.height
    )
    if preferInsideBottom {
        return CGRect(origin: insideBottom, size: badgeSize)
    }

    var origin = CGPoint(x: 0.0, y: contentFrame.minY + 4.0)
    if isIncoming {
        origin.x = contentFrame.maxX + spacing + reservedGutterWidth
        if origin.x + badgeSize.width > containerWidth - edgeInset {
            origin = insideBottom
        }
    } else {
        origin.x = contentFrame.minX - spacing - reservedGutterWidth - badgeSize.width
        if origin.x < edgeInset {
            origin = insideBottom
        }
    }
    return CGRect(origin: origin, size: badgeSize)
}
