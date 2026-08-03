import Foundation
import UIKit

// Telewhite: how tightly the chat list is packed.
//
// This replaces the old "Compact Chat List" switch, which only shaved 8 points off the
// row and left the avatar at full size — the row got shorter while everything inside it
// stayed put, which reads as cramped rather than compact.
//
// Density scales the avatar instead, and the row follows. That works because the stock
// layout derives the text column's left inset from the avatar (`avatarLeftInset =
// 24 + avatarDiameter` in ChatListItem), so a smaller avatar slides the whole text
// column left on its own. One number therefore tightens the row in both directions
// without touching the layout arithmetic.
public enum TelewhiteChatListDensity {
    public static var level: Int {
        let raw = (UserDefaults.standard.object(forKey: "telewhite.mods.chatListDensity") as? NSNumber)?.intValue ?? 0
        return max(0, min(3, raw))
    }

    // The stock diameter is itself derived from the user's text size, so this scales
    // that value rather than replacing it — the accessibility text sizes keep working.
    public static func avatarDiameter(_ value: CGFloat) -> CGFloat {
        switch self.level {
        case 1:
            return floor(value * 0.9)
        case 2:
            return floor(value * 0.8)
        case 3:
            return floor(value * 0.7)
        default:
            return value
        }
    }

    public static func itemHeight(_ value: CGFloat, avatarDiameter: CGFloat) -> CGFloat {
        let reduced: CGFloat
        switch self.level {
        case 1:
            reduced = value - 6.0
        case 2:
            reduced = value - 12.0
        case 3:
            reduced = value - 18.0
        default:
            reduced = value
        }
        // The avatar is centred with `floor((itemHeight - avatarDiameter) / 2)`, which
        // goes negative — and hangs the avatar out of its row — the moment the row is
        // shorter than the avatar. Keep a margin so that can never happen, whatever the
        // text size and row count combine to.
        return max(reduced, avatarDiameter + 8.0)
    }
}
