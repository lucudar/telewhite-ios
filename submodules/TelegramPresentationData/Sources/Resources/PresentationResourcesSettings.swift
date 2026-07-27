import Foundation
import UIKit
import Display
import AppBundle

private let gradientImage = UIImage(bundleImageName: "Item List/Icons/Gradient")
private let backdropImage = UIImage(bundleImageName: "Item List/Icons/Backdrop")
// Telewhite mod: settings rows use flat monochrome glyphs instead of the stock
// colored rounded plates.
//
// This is the single place every `PresentationResourcesSettings` entry goes through,
// so restyling here converts the whole app (main settings, privacy, data & storage,
// notifications, sticker screens) in one move and stays compatible with upstream —
// the `backgroundColors` argument is still accepted at every call site, it is just
// no longer painted, so no call site had to be edited.
//
// The tint is a fixed neutral gray rather than a theme color on purpose: these are
// `static let` constants evaluated once at first access, so they cannot react to a
// theme change. A mid gray is the one value that keeps acceptable contrast on both
// the light and the dark background.
private let telewhiteSettingsIconColor = UIColor(rgb: 0x9A9AA0)

public func renderSettingsIcon(name: String, scaleFactor: CGFloat = 1.0, backgroundColors: [UIColor]? = nil) -> UIImage? {
    return generateImage(CGSize(width: 30.0, height: 30.0), contextGenerator: { size, context in
        let bounds = CGRect(origin: CGPoint(), size: size)
        context.clear(bounds)
        
        guard let image = UIImage(bundleImageName: name), let maskImage = image.cgImage else {
            return
        }
        
        // Without a plate behind it the glyph can occupy a bit more of the row, which
        // keeps the icon column visually as strong as before. Clamped so a glyph that
        // is already full bleed cannot overflow the 30x30 box.
        let glyphScale = min(scaleFactor * 1.15, size.width / max(image.size.width, 1.0))
        let imageSize = CGSize(width: image.size.width * glyphScale, height: image.size.height * glyphScale)
        let imageRect = CGRect(origin: CGPoint(x: (bounds.width - imageSize.width) * 0.5, y: (bounds.height - imageSize.height) * 0.5), size: imageSize)
        
        context.saveGState()
        context.clip(to: imageRect, mask: maskImage)
        context.setFillColor(telewhiteSettingsIconColor.cgColor)
        context.fill(imageRect)
        context.restoreGState()
    })
}

public func renderAttachAppIcon(iconImage: UIImage?) -> UIImage? {
    return generateImage(CGSize(width: 30.0, height: 30.0), contextGenerator: { size, context in
        let bounds = CGRect(origin: CGPoint(), size: size)
        context.clear(bounds)
                
        if let iconImage, let cgImage = iconImage.cgImage {
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        }

        if let gradientImage, let cgImage = gradientImage.cgImage {
            context.saveGState()
            context.setBlendMode(.plusLighter)
            context.draw(cgImage, in: CGRect(origin: .zero, size: size))
            context.restoreGState()
        }
        
        if let backdropImage, let cgImage = backdropImage.cgImage {
            context.saveGState()
            context.setBlendMode(.overlay)
            context.draw(cgImage, in: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size))
            context.restoreGState()
        }
        
        let outerPath = UIBezierPath(rect: CGRect(origin: .zero, size: size))
        let innerPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 8.0)
        outerPath.append(innerPath)

        context.saveGState()
        outerPath.usesEvenOddFillRule = true
        context.addPath(outerPath.cgPath)
        context.clip(using: .evenOdd)

        context.setBlendMode(.clear)
        context.fill(CGRect(origin: .zero, size: size))
        context.restoreGState()
    })
}

let colorRed = UIColor(rgb: 0xFF453A)
let colorGreen = UIColor(rgb: 0x34C759)
let colorBlue = UIColor(rgb: 0x0079ff)
let colorLightBlue = UIColor(rgb: 0x32ADE6)
let colorTeal = UIColor(rgb: 0x00c7be)
let colorOrange = UIColor(rgb: 0xFF9F0A)
let colorPurple = UIColor(rgb: 0xAF52DE)
let colorGray = UIColor(rgb: 0x8E8E93)
let colorViolet = UIColor(rgb: 0x5E5CE6)

public struct PresentationResourcesSettings {
    public static let proxy = renderSettingsIcon(name: "Item List/Icons/Proxy", backgroundColors: [colorGreen])
    public static let savedMessages = renderSettingsIcon(name: "Item List/Icons/SavedMessages", backgroundColors: [colorBlue])
    public static let recentCalls = renderSettingsIcon(name: "Item List/Icons/Phone", backgroundColors: [colorGreen])
    public static let devices = renderSettingsIcon(name: "Item List/Icons/Devices", backgroundColors: [colorOrange])
    public static let chatFolders = renderSettingsIcon(name: "Item List/Icons/Folder", backgroundColors: [colorLightBlue])
    public static let stickers = renderSettingsIcon(name: "Item List/Icons/Sticker", backgroundColors: [colorOrange])
    public static let notifications = renderSettingsIcon(name: "Item List/Icons/Notifications", backgroundColors: [colorRed])
    public static let security = renderSettingsIcon(name: "Item List/Icons/Privacy", backgroundColors: [colorGray])
    public static let dataAndStorage = renderSettingsIcon(name: "Item List/Icons/Data", backgroundColors: [colorGreen])
    public static let appearance = renderSettingsIcon(name: "Item List/Icons/Appearance", backgroundColors: [colorLightBlue])
    public static let language = renderSettingsIcon(name: "Item List/Icons/Language", backgroundColors: [colorPurple])
    public static let powerSaving = renderSettingsIcon(name: "Item List/Icons/PowerSaving", backgroundColors: [colorOrange])
    public static let business = renderSettingsIcon(name: "Item List/Icons/Business", backgroundColors: [UIColor(rgb: 0xA95CE3), UIColor(rgb: 0xF16B80)])
    public static let myProfile = renderSettingsIcon(name: "Item List/Icons/Profile", backgroundColors: [colorRed])
    
    public static let birthday = renderSettingsIcon(name: "Item List/Icons/Cake", backgroundColors: [colorBlue])
    public static let aiTools = renderSettingsIcon(name: "Item List/Icons/AITools", backgroundColors: [colorPurple])
    public static let yourColor = renderSettingsIcon(name: "Item List/Icons/Brush", backgroundColors: [colorLightBlue])
    
    public static let storageUsage = renderSettingsIcon(name: "Item List/Icons/Pie", backgroundColors: [colorOrange])
    public static let dataUsage = renderSettingsIcon(name: "Item List/Icons/Stats", backgroundColors: [colorPurple])
    
    public static let cellular = renderSettingsIcon(name: "Item List/Icons/Cellular", backgroundColors: [colorGreen])
    public static let wifi = renderSettingsIcon(name: "Item List/Icons/Wifi", backgroundColors: [colorBlue])
    
    public static let privateChats = renderSettingsIcon(name: "Item List/Icons/Member", backgroundColors: [colorBlue])
    public static let groups = renderSettingsIcon(name: "Item List/Icons/Group", backgroundColors: [colorGreen])
    public static let channels = renderSettingsIcon(name: "Item List/Icons/Channel", backgroundColors: [colorOrange])
    public static let stories = renderSettingsIcon(name: "Item List/Icons/Stories", backgroundColors: [colorViolet])
    public static let reactions = renderSettingsIcon(name: "Item List/Icons/Reactions", backgroundColors: [UIColor(rgb: 0xFF2D55)])
    
    public static let photos = renderSettingsIcon(name: "Item List/Icons/Photo", backgroundColors: [colorOrange])
    public static let videos = renderSettingsIcon(name: "Item List/Icons/Video", backgroundColors: [colorRed])
    public static let files = renderSettingsIcon(name: "Item List/Icons/File", backgroundColors: [colorBlue])
    public static let gifs = renderSettingsIcon(name: "Item List/Icons/Gif", backgroundColors: [colorOrange])
    public static let stickersGreen = renderSettingsIcon(name: "Item List/Icons/Sticker", backgroundColors: [colorGreen])
    public static let emoji = renderSettingsIcon(name: "Item List/Icons/Emoji", backgroundColors: [colorLightBlue])
    public static let emojiTeal = renderSettingsIcon(name: "Item List/Icons/Emoji", backgroundColors: [colorTeal])
    public static let archivedSticker = renderSettingsIcon(name: "Item List/Icons/ArchivedSticker", backgroundColors: [colorGreen])
    public static let trendingSticker = renderSettingsIcon(name: "Item List/Icons/TrendingSticker", backgroundColors: [colorOrange])
    public static let effects = renderSettingsIcon(name: "Item List/Icons/Effect", backgroundColors: [colorLightBlue])
    public static let photosBlue = renderSettingsIcon(name: "Item List/Icons/Photo", backgroundColors: [colorBlue])
    public static let clock = renderSettingsIcon(name: "Item List/Icons/Clock", backgroundColors: [colorPurple])
    public static let photosLightBlue = renderSettingsIcon(name: "Item List/Icons/Photo", backgroundColors: [colorLightBlue])
    public static let videosBlue = renderSettingsIcon(name: "Item List/Icons/Video", backgroundColors: [colorBlue])
    
    public static let block = renderSettingsIcon(name: "Item List/Icons/Block", backgroundColors: [colorRed])
    public static let activeSessions = renderSettingsIcon(name: "Item List/Icons/Language", backgroundColors: [colorBlue])
    public static let faceId = renderSettingsIcon(name: "Item List/Icons/FaceId", backgroundColors: [colorGreen])
    public static let lockOrange = renderSettingsIcon(name: "Item List/Icons/Privacy", backgroundColors: [colorOrange])
    public static let passkeys = renderSettingsIcon(name: "Item List/Icons/Key", backgroundColors: [colorViolet])
    public static let timer = renderSettingsIcon(name: "Item List/Icons/Timer", backgroundColors: [colorPurple])
    public static let email = renderSettingsIcon(name: "Item List/Icons/Email", backgroundColors: [colorViolet])
        
    // Telewhite mod: Premium, Stars and Gift used to be hand-drawn gradient plates.
    // Routed through renderSettingsIcon so they match the rest of the monochrome column.
    public static let premium = renderSettingsIcon(name: "Item List/Icons/Premium")
    
    public static let ton = renderSettingsIcon(name: "Ads/TonAbout", backgroundColors: [UIColor(rgb: 0x32ade6)])
 
    public static let stars = renderSettingsIcon(name: "Item List/Icons/Stars")
    
    public static let premiumGift = renderSettingsIcon(name: "Item List/Icons/Gift")
    
    public static let bot = renderSettingsIcon(name: "Item List/Icons/Bot", backgroundColors: [colorBlue])

    public static let passport = renderAttachAppIcon(iconImage: UIImage(bundleImageName: "Settings/Menu/Passport"))
    public static let watch = renderAttachAppIcon(iconImage: UIImage(bundleImageName: "Settings/Menu/Watch"))
    
    public static let support = renderSettingsIcon(name: "Item List/Icons/Support", backgroundColors: [colorOrange])
    public static let faq = renderSettingsIcon(name: "Item List/Icons/Faq", backgroundColors: [colorLightBlue])
    public static let tips = renderSettingsIcon(name: "Item List/Icons/Tips", backgroundColors: [UIColor(rgb: 0xffcc02)])
        
    public static let changePhoneNumber = renderSettingsIcon(name: "Item List/Icons/ChangePhone", backgroundColors: [colorPurple])
    public static let deleteAddAccount = renderSettingsIcon(name: "Item List/Icons/Member", backgroundColors: [colorBlue])
    public static let deleteSetTwoStepAuth = renderSettingsIcon(name: "Item List/Icons/Key", backgroundColors: [colorViolet])
    public static let deleteChats = renderSettingsIcon(name: "Item List/Icons/Delete", backgroundColors: [colorRed])
    public static let clearSynced = renderSettingsIcon(name: "Item List/Icons/Group", backgroundColors: [colorOrange])
    
    public static let groupType = renderSettingsIcon(name: "Item List/Icons/Members", backgroundColors: [colorBlue])
    public static let channelType = renderSettingsIcon(name: "Item List/Icons/Channel", backgroundColors: [colorBlue])
    public static let chatHistory = renderSettingsIcon(name: "Item List/Icons/Chat", backgroundColors: [colorGreen])
    public static let topics = renderSettingsIcon(name: "Item List/Icons/Topics", backgroundColors: [colorLightBlue])
    public static let links = renderSettingsIcon(name: "Item List/Icons/Link", backgroundColors: [colorOrange])
    public static let chatAppearance = renderSettingsIcon(name: "Item List/Icons/Brush", backgroundColors: [colorOrange])
    public static let admins = renderSettingsIcon(name: "Item List/Icons/Admin", backgroundColors: [colorGreen])
    public static let subscribers = renderSettingsIcon(name: "Item List/Icons/Group", backgroundColors: [colorBlue])
    public static let stats = renderSettingsIcon(name: "Item List/Icons/Stats", backgroundColors: [colorViolet])
    public static let balance = renderSettingsIcon(name: "Item List/Icons/Balance", backgroundColors: [colorGreen])
    public static let affiliateProgram = renderSettingsIcon(name: "Item List/Icons/Affiliate", backgroundColors: [colorViolet])
    public static let earnStars = renderSettingsIcon(name: "Item List/Icons/Earn", backgroundColors: [colorGreen])
    public static let channelMessages = renderSettingsIcon(name: "Item List/Icons/Messages", backgroundColors: [colorViolet])
    public static let settings = renderSettingsIcon(name: "Item List/Icons/Settings", backgroundColors: [colorOrange])
    public static let antiSpam = renderSettingsIcon(name: "Item List/Icons/AntiSpam", backgroundColors: [colorGreen])
    public static let recentActions = renderSettingsIcon(name: "Item List/Icons/View", backgroundColors: [colorOrange])
    public static let permissions = renderSettingsIcon(name: "Item List/Icons/Key", backgroundColors: [colorGray])
    public static let autoTranslate = renderSettingsIcon(name: "Item List/Icons/Translation", backgroundColors: [colorPurple])
    public static let emojiStatus = renderSettingsIcon(name: "Item List/Icons/Status", backgroundColors: [colorBlue])
    public static let location = renderSettingsIcon(name: "Item List/Icons/Location", backgroundColors: [colorLightBlue])
    public static let groupRequests = renderAttachAppIcon(iconImage: UIImage(bundleImageName: "Chat/Info/GroupRequestsIcon"))
    
    public static let calls = renderSettingsIcon(name: "Item List/Icons/Phone", backgroundColors: [colorOrange])
    public static let messages = renderSettingsIcon(name: "Item List/Icons/Chat", backgroundColors: [colorViolet])
    public static let filesGreen = renderSettingsIcon(name: "Item List/Icons/File", backgroundColors: [colorGreen])
    public static let stickersYellow = renderSettingsIcon(name: "Item List/Icons/Sticker", backgroundColors: [colorOrange])
    public static let music = renderSettingsIcon(name: "Item List/Icons/Play", backgroundColors: [colorRed])
    public static let voices = renderSettingsIcon(name: "Item List/Icons/Microphone", backgroundColors: [colorPurple])
    public static let upload = renderSettingsIcon(name: "Item List/Icons/Upload", backgroundColors: [colorBlue])
    public static let download = renderSettingsIcon(name: "Item List/Icons/Download", backgroundColors: [colorGreen])
}
