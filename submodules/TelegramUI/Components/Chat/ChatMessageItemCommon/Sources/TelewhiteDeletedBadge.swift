import Foundation
import UIKit
import Display
import TelegramCore

// Telewhite: badge marking a message the sender deleted while "Keep Deleted
// Messages" preserved it locally.
//
// Fading the content alone did not communicate deletion: a translucent photo over
// a dark wallpaper still reads as a normal photo, and a dimmed text bubble reads as
// a theme quirk. The trash glyph states it outright, which also lets the content stay
// readable — the whole point of preserving a deleted message is being able to read
// it — so callers pair this with a mild fade instead of a heavy one.
//
// The badge is rendered as a single flattened image so callers can hang it off an
// ASImageNode overlay: it never joins the measured layout and therefore cannot
// disturb the size a content node just reported.

private final class TelewhiteDeletedBadgeCache {
    static let shared = TelewhiteDeletedBadgeCache()

    private let lock = NSLock()
    private var images: [CGFloat: UIImage] = [:]

    func image(_ generate: () -> UIImage?) -> UIImage? {
        let key = UIScreen.main.scale
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

/// Whether a message was deleted by its sender and kept by "Keep Deleted Messages".
///
/// One owner for the check: every item node needs it, and hand-rolling the attribute loop
/// per node is how one of them ends up testing a different condition than the rest.
/// Takes the attribute array rather than the message so this module does not need Postbox —
/// `EngineMessage.Attribute` is a typealias of `MessageAttribute`, so call sites pass
/// `item.message.attributes` unchanged.
public func telewhiteIsDeletedPreserved(attributes: [EngineMessage.Attribute]) -> Bool {
    for attribute in attributes {
        if attribute is TelewhiteDeletedMessageAttribute {
            return true
        }
    }
    return false
}

/// A dark translucent circle holding just a trash glyph, legible over both message
/// bubbles and photos. Cached per screen scale.
///
/// Telewhite: this used to be a pill reading "Удалено"/"Deleted". The word made the badge
/// roughly five times wider, which was the whole problem: at that width it no longer fit
/// the gutter beside a wide bubble, so `telewhiteDeletedBadgeFrame` fell back to drawing
/// it inside the message and it covered the last line of long texts. A glyph-only circle
/// fits the gutter in almost every layout, so the badge now sits beside the message
/// instead of on top of it — and the trash icon alone already reads as "deleted".
public func telewhiteDeletedBadgeImage() -> UIImage? {
    return TelewhiteDeletedBadgeCache.shared.image {
        let glyphSize = CGSize(width: 9.0, height: 10.0)
        let diameter: CGFloat = 18.0

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext

            let bounds = CGRect(origin: CGPoint(), size: CGSize(width: diameter, height: diameter))
            context.setFillColor(UIColor(white: 0.0, alpha: 0.75).cgColor)
            UIBezierPath(ovalIn: bounds).fill()

            // Trash glyph: lid, handle bump, tapered body. Centred in the circle.
            let glyphOrigin = CGPoint(
                x: floor((diameter - glyphSize.width) * 0.5),
                y: floor((diameter - glyphSize.height) * 0.5)
            )
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
        }
    }
}

/// Places a badge of `badgeSize` **inside** `contentFrame`, in the bottom leading corner.
///
/// Not the top one: that corner holds the sender's name, the forward and reply headers and
/// the media duration pill, so a badge there covered exactly the information that says whose
/// deleted message this was. Bottom-leading is the one inside corner Telegram leaves free —
/// the timestamp and delivery ticks sit bottom-trailing.
///
/// This used to prefer the gutter beside the message and only fall inside when the gutter was
/// too narrow. That existed because the badge was once a pill reading "Удалено"/"Deleted",
/// wide enough to cover the last line of a long text. It is an 18pt circle now, so inside is
/// no longer a compromise — and the gutter placement had its own costs: it sat under the
/// rounded corner in landscape, lost the z-order fight with right-aligned reply headers, and
/// put the mark far enough from the content to read as unrelated chrome.
///
/// `containerWidth`, `reservedGutterWidth` and `preferInsideBottom` are vestigial: every
/// placement is now inside, so nothing is measured against the gutter. They are kept only so
/// this change does not have to touch every call site at once; removing them is a follow-up
/// that edits call sites and nothing else.
public func telewhiteDeletedBadgeFrame(badgeSize: CGSize, contentFrame: CGRect, containerWidth: CGFloat, isIncoming: Bool, reservedGutterWidth: CGFloat = 0.0, preferInsideBottom: Bool = false) -> CGRect {
    let spacing: CGFloat = 6.0
    let origin = CGPoint(
        x: isIncoming ? contentFrame.minX + spacing : contentFrame.maxX - spacing - badgeSize.width,
        y: contentFrame.maxY - 4.0 - badgeSize.height
    )
    return CGRect(origin: origin, size: badgeSize)
}
