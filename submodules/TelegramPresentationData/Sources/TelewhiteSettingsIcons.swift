import Foundation
import UIKit
import Display
import SwiftSignalKit

// Telewhite mod: SF Symbols for the stock settings rows.
//
// The settings column used to be flat monochrome glyphs in a fixed neutral gray,
// while the Telewhite Mods menu already drew SF Symbols in the theme accent color.
// Side by side that reads as two different apps, so this maps every stock bitmap
// name onto an SF Symbol and tints it with the accent.
//
// The settings glyphs follow the same accent-driven visual language as the rest
// of the app, and the cache keeps redraws cheap.

// The accent color is written here by the presentation-data pipeline whenever the
// theme is built or rebuilt.
//
// It cannot simply be passed in as an argument: `renderSettingsIcon` is a free
// function reached from 177 call sites across 20 files, none of which hand a
// theme over. Pushing the accent here keeps every one of them untouched.
private let telewhiteSettingsAccentLock = NSLock()
private var telewhiteSettingsAccentColorValue: UIColor?

public func telewhiteSetSettingsIconAccentColor(_ color: UIColor) {
    telewhiteSettingsAccentLock.lock()
    let changed = telewhiteSettingsAccentColorValue?.argb != color.argb
    telewhiteSettingsAccentColorValue = color
    telewhiteSettingsAccentLock.unlock()

    // The rendered images are cached by symbol name + color, so a stale entry can
    // never be served under a new accent; dropping the cache only forces a redraw.
    if changed {
        telewhiteSettingsIconCacheClear()
    }
}

func telewhiteSettingsIconAccentColor() -> UIColor? {
    telewhiteSettingsAccentLock.lock()
    defer { telewhiteSettingsAccentLock.unlock() }
    return telewhiteSettingsAccentColorValue
}

// Bitmap name (as passed to `renderSettingsIcon`) -> SF Symbol candidates, in
// order. Every row lists a fallback: the primaries all ship in iOS 13, the app's
// minimum, and the fallback covers a symbol being renamed out from under us.
//
// Names that are deliberately absent fall through to the original bitmap:
// Backdrop / Gradient / Icons / Checkbox are plate and decoration art rather than
// row glyphs, and Ton keeps its own branded mark.
private let telewhiteSettingsIconSymbols: [String: [String]] = [
    // Main settings
    "Proxy": ["shield.lefthalf.filled", "shield"],
    "SavedMessages": ["bookmark.fill", "bookmark"],
    "Phone": ["phone.fill", "phone"],
    "Devices": ["laptopcomputer.and.iphone", "desktopcomputer"],
    "Folder": ["folder.fill", "folder"],
    "Sticker": ["face.smiling.fill", "face.smiling"],
    "Notifications": ["bell.badge.fill", "bell.fill"],
    "Privacy": ["lock.shield.fill", "lock.shield"],
    "Data": ["arrow.up.arrow.down.circle.fill", "arrow.up.arrow.down"],
    "Appearance": ["paintbrush.fill", "paintbrush"],
    "Language": ["globe", "textformat"],
    "PowerSaving": ["bolt.circle.fill", "bolt.fill"],
    "Business": ["briefcase.fill", "briefcase"],
    "Profile": ["person.circle.fill", "person.circle"],
    "Cake": ["gift.fill", "gift"],
    "AITools": ["sparkles", "wand.and.stars"],
    "Brush": ["paintbrush.pointed.fill", "paintbrush.pointed"],

    // Data & storage
    "Pie": ["chart.pie.fill", "chart.pie"],
    "Stats": ["chart.bar.fill", "chart.bar"],
    "Cellular": ["antenna.radiowaves.left.and.right", "wifi"],
    "Wifi": ["wifi", "network"],
    "Upload": ["arrow.up.circle.fill", "arrow.up"],
    "Download": ["arrow.down.circle.fill", "arrow.down"],
    "Speed": ["speedometer", "gauge"],
    "Update": ["arrow.triangle.2.circlepath", "arrow.clockwise"],

    // Peers and content types
    "Member": ["person.fill", "person"],
    "Members": ["person.2.fill", "person.2"],
    "Group": ["person.3.fill", "person.2.fill"],
    "Channel": ["megaphone.fill", "speaker.wave.2.fill"],
    "Stories": ["circle.dashed.inset.filled", "circle.dashed"],
    "Reactions": ["hand.thumbsup.fill", "hand.thumbsup"],
    "Photo": ["photo.fill", "photo"],
    "Video": ["video.fill", "play.rectangle.fill"],
    "File": ["doc.fill", "doc"],
    "Gif": ["play.rectangle.on.rectangle.fill", "film.fill"],
    "Emoji": ["smiley.fill", "smiley"],
    "ArchivedSticker": ["archivebox.fill", "archivebox"],
    "TrendingSticker": ["chart.line.uptrend.xyaxis", "arrow.up.right"],
    "Effect": ["sparkles", "wand.and.rays"],
    "MessageEffect": ["wand.and.stars", "sparkles"],
    "Multiple": ["square.on.square", "rectangle.on.rectangle"],

    // Privacy and security
    "Clock": ["clock.fill", "clock"],
    "Block": ["hand.raised.fill", "hand.raised"],
    "FaceId": ["faceid", "lock.fill"],
    "Key": ["key.fill", "key"],
    "Timer": ["timer", "hourglass"],
    "Email": ["envelope.fill", "envelope"],
    "LastSeen": ["eye.fill", "eye"],
    "View": ["eye.fill", "eye"],
    "Hand": ["hand.raised.fill", "hand.raised"],
    "LockBubble": ["lock.bubble.fill", "lock.fill"],
    "NoForward": ["arrowshape.turn.up.right.slash.fill", "arrowshape.turn.up.right.slash"],
    "NoAds": ["nosign", "eye.slash.fill"],
    "Flag": ["flag.fill", "flag"],

    // Premium, money, gifts
    "Premium": ["star.fill", "star"],
    "Stars": ["sparkles", "star.fill"],
    "Gift": ["gift.fill", "gift"],
    "Balance": ["dollarsign.circle.fill", "creditcard.fill"],
    "Affiliate": ["person.2.badge.gearshape.fill", "person.2.fill"],
    "Earn": ["arrow.up.circle.fill", "arrow.up"],

    // Help and account
    "Bot": ["cpu.fill", "cpu"],
    "Chatbot": ["cpu.fill", "cpu"],
    "Support": ["person.crop.circle.badge.questionmark", "questionmark.circle.fill"],
    "Faq": ["questionmark.circle.fill", "questionmark.circle"],
    "Tips": ["lightbulb.fill", "lightbulb"],
    "ChangePhone": ["phone.arrow.up.right.fill", "phone.fill"],
    "Delete": ["trash.fill", "trash"],
    "Intro": ["hand.wave.fill", "hand.wave"],

    // Group and channel management
    "Chat": ["message.fill", "bubble.left.fill"],
    "Messages": ["tray.fill", "tray"],
    "Topics": ["bubble.left.and.bubble.right.fill", "bubble.left.and.bubble.right"],
    "Link": ["link", "link.circle"],
    "BusinessLink": ["link.badge.plus", "link"],
    "Admin": ["crown.fill", "star.circle.fill"],
    "Settings": ["gearshape.fill", "gear"],
    "AntiSpam": ["shield.checkered", "shield.fill"],
    "Translation": ["character.bubble.fill", "globe"],
    "Status": ["face.smiling.fill", "person.crop.circle.badge.checkmark"],
    "Location": ["location.fill", "location"],
    "Play": ["play.circle.fill", "play.fill"],
    "Microphone": ["mic.fill", "mic"],
    "Add": ["plus.circle.fill", "plus"],
    "Share": ["square.and.arrow.up.fill", "square.and.arrow.up"],
    "Tag": ["tag.fill", "tag"],
    "Case": ["briefcase.fill", "briefcase"],
    "Away": ["moon.zzz.fill", "moon.fill"],
    "Shuffle": ["shuffle", "arrow.triangle.swap"],
    "Wallpaper": ["photo.on.rectangle.angled", "photo.fill"],
    "X2": ["speedometer", "gauge"]
]

// Rendered symbols are cached by name + color. NSCache is thread-safe and evicts
// itself under memory pressure, and the key carries the color so a theme or accent
// change can never serve a stale tint.
private let telewhiteSettingsIconCache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 200
    return cache
}()

func telewhiteSettingsIconCacheClear() {
    telewhiteSettingsIconCache.removeAllObjects()
}

// `name` arrives as the full bundle path, e.g. "Item List/Icons/Proxy".
private func telewhiteSettingsIconSymbolNames(bundleImageName name: String) -> [String]? {
    guard let last = name.split(separator: "/").last else {
        return nil
    }
    return telewhiteSettingsIconSymbols[String(last)]
}

// Returns nil when the name has no mapping or the symbol is missing on this OS — every one of those falls back to the original bitmap, so a
// gap shows the old glyph rather than an empty row.
func telewhiteRenderSettingsSymbolIcon(name: String, size: CGSize) -> UIImage? {
    guard let symbolNames = telewhiteSettingsIconSymbolNames(bundleImageName: name) else {
        return nil
    }

    let color = telewhiteSettingsIconAccentColor() ?? UIColor(rgb: 0x9A9AA0)
    let cacheKey = "\(name)-\(color.argb)" as NSString
    if let cached = telewhiteSettingsIconCache.object(forKey: cacheKey) {
        return cached
    }

    // 20pt on the 30x30 canvas the settings rows use. The Mods menu uses 19pt on a
    // 29x29 canvas, which is the same optical weight.
    let configuration = UIImage.SymbolConfiguration(pointSize: 20.0, weight: .regular)
    var symbol: UIImage?
    for symbolName in symbolNames {
        if let candidate = UIImage(systemName: symbolName, withConfiguration: configuration) {
            symbol = candidate
            break
        }
    }
    guard let symbol else {
        return nil
    }

    // Centre the glyph on the fixed canvas: symbol widths differ, and the icon
    // column has to stay aligned down the list.
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { _ in
        let tinted = symbol.withTintColor(color, renderingMode: .alwaysOriginal)
        tinted.draw(in: CGRect(
            x: floor((size.width - tinted.size.width) * 0.5),
            y: floor((size.height - tinted.size.height) * 0.5),
            width: tinted.size.width,
            height: tinted.size.height
        ))
    }
    telewhiteSettingsIconCache.setObject(image, forKey: cacheKey)
    return image
}

// The bitmap path is cached too. Every `PresentationResourcesSettings` entry is a
// computed property now (a `static let` is evaluated once and could never react to
// the switch), so without this the glyph would be re-rasterised on every row draw —
// a regression on every settings screen.
private let telewhiteSettingsBitmapCache: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.countLimit = 200
    return cache
}()

func telewhiteCachedSettingsBitmapIcon(name: String, scaleFactor: CGFloat, generate: () -> UIImage?) -> UIImage? {
    let cacheKey = "\(name)-\(scaleFactor)" as NSString
    if let cached = telewhiteSettingsBitmapCache.object(forKey: cacheKey) {
        return cached
    }
    guard let image = generate() else {
        return nil
    }
    telewhiteSettingsBitmapCache.setObject(image, forKey: cacheKey)
    return image
}

// Emits whenever a mod that the presentation theme depends on changes, so the theme
// is rebuilt and the settings rows are redrawn the moment a switch is flipped.
// Covers AMOLED mode and the settings icon style; `distinctUntilChanged` keeps
// unrelated mod toggles from rebuilding the theme.
//
// The notification name mirrors `TelewhiteModsSettings.didChangeNotification` from
// the SettingsUI module, duplicated as a string because SettingsUI depends on
// TelegramPresentationData and importing it would be circular.
public func telewhiteThemeModsUpdated() -> Signal<[Bool], NoError> {
    return (Signal<[Bool], NoError> { subscriber in
        let flags: () -> [Bool] = {
            return [telewhiteAmoledModeEnabled()]
        }
        subscriber.putNext(flags())
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name("TelewhiteModsSettingsDidChange"), object: nil, queue: .main, using: { _ in
            subscriber.putNext(flags())
        })
        return ActionDisposable {
            NotificationCenter.default.removeObserver(observer)
        }
    })
    |> distinctUntilChanged
}
