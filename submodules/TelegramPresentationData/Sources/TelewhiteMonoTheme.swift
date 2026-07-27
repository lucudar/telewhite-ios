import Foundation
import UIKit
import Display
import TelegramCore
import TelegramUIPreferences

// Telewhite mod: the client's own monochrome look, applied to every theme.
//
// This replaces the previous approach of letting the user nudge individual colours
// (accent / bubble / chat background) on top of an upstream Telegram theme. Those
// knobs duplicated the stock "Appearance" screen and could never add up to a
// coherent design, so they are gone and Telewhite now simply looks like Telewhite.
//
// Implemented as a transform over a finished `PresentationTheme` rather than as a
// new built-in theme. Upstream's own themes are ~1500 lines each and are touched on
// almost every Telegram release; rewriting them would guarantee conflicts on the
// next rebase. Every theme section exposes `withUpdated(...)`, so re-colouring in
// place is both smaller and rebase-safe. This mirrors how the AMOLED mod already
// works.
//
// Light vs dark is chosen from `overallDarkAppearance`, which means the stock
// Appearance screen keeps working: picking a light or dark theme there still
// switches between the two palettes below, and no upstream settings UI is touched.
//
// AMOLED is deliberately not consulted here. `makeTelewhiteAmoledPresentationTheme`
// runs *after* this transform and flattens dark backgrounds to pure black, so
// handling it twice would only add a second source of truth.

private struct TelewhiteMonoPalette {
    // Surfaces.
    let plainBackground: UIColor
    let blocksBackground: UIColor
    let itemBackground: UIColor
    let elevatedBackground: UIColor
    let highlightedBackground: UIColor
    let separator: UIColor

    // Text.
    let primaryText: UIColor
    let secondaryText: UIColor
    let disabledText: UIColor
    let placeholderText: UIColor

    // Accent. Monochrome, so "accent" is the strongest available contrast rather
    // than a hue: near-black on light, white on dark.
    let accent: UIColor
    let accentContrast: UIColor
    let control: UIColor

    // Chat.
    let chatBackground: UIColor
    let incomingBubble: UIColor
    let incomingText: UIColor
    let outgoingBubble: UIColor
    let outgoingText: UIColor
    let serviceFill: UIColor
    let serviceText: UIColor

    // Bars.
    let barBackground: UIColor
    let barSelected: UIColor
    let barUnselected: UIColor
    let badgeFill: UIColor
    let badgeText: UIColor

    // Fields.
    let fieldBackground: UIColor
}

private let telewhiteMonoLight = TelewhiteMonoPalette(
    plainBackground: UIColor(rgb: 0xffffff),
    blocksBackground: UIColor(rgb: 0xf5f5f7),
    itemBackground: UIColor(rgb: 0xffffff),
    elevatedBackground: UIColor(rgb: 0xfafafb),
    highlightedBackground: UIColor(rgb: 0xebebed),
    separator: UIColor(rgb: 0xe3e3e6),
    primaryText: UIColor(rgb: 0x000000),
    secondaryText: UIColor(rgb: 0x8a8a8e),
    disabledText: UIColor(rgb: 0xb4b4b8),
    placeholderText: UIColor(rgb: 0xb4b4b8),
    accent: UIColor(rgb: 0x1c1c1e),
    accentContrast: UIColor(rgb: 0xffffff),
    control: UIColor(rgb: 0xb4b4b8),
    chatBackground: UIColor(rgb: 0xffffff),
    incomingBubble: UIColor(rgb: 0xf1f1f3),
    incomingText: UIColor(rgb: 0x000000),
    outgoingBubble: UIColor(rgb: 0x1c1c1e),
    outgoingText: UIColor(rgb: 0xffffff),
    serviceFill: UIColor(rgb: 0x000000, alpha: 0.08),
    serviceText: UIColor(rgb: 0x3c3c43),
    barBackground: UIColor(rgb: 0xffffff),
    barSelected: UIColor(rgb: 0x000000),
    barUnselected: UIColor(rgb: 0xb4b4b8),
    badgeFill: UIColor(rgb: 0x1c1c1e),
    badgeText: UIColor(rgb: 0xffffff),
    fieldBackground: UIColor(rgb: 0xf1f1f3)
)

// The outgoing bubble is dark grey rather than white: a white bubble on a black
// background glares in a long conversation, and incoming vs outgoing still reads
// clearly from the lighter incoming grey.
private let telewhiteMonoDark = TelewhiteMonoPalette(
    plainBackground: UIColor(rgb: 0x0e0e10),
    blocksBackground: UIColor(rgb: 0x0e0e10),
    itemBackground: UIColor(rgb: 0x17171a),
    elevatedBackground: UIColor(rgb: 0x1f1f23),
    highlightedBackground: UIColor(rgb: 0x26262a),
    separator: UIColor(rgb: 0x26262a),
    primaryText: UIColor(rgb: 0xffffff),
    secondaryText: UIColor(rgb: 0x8e8e93),
    disabledText: UIColor(rgb: 0x5c5c61),
    placeholderText: UIColor(rgb: 0x5c5c61),
    accent: UIColor(rgb: 0xffffff),
    accentContrast: UIColor(rgb: 0x000000),
    control: UIColor(rgb: 0x5c5c61),
    chatBackground: UIColor(rgb: 0x0e0e10),
    incomingBubble: UIColor(rgb: 0x1a1a1d),
    incomingText: UIColor(rgb: 0xffffff),
    outgoingBubble: UIColor(rgb: 0x2e2e33),
    outgoingText: UIColor(rgb: 0xffffff),
    serviceFill: UIColor(rgb: 0xffffff, alpha: 0.1),
    serviceText: UIColor(rgb: 0xebebf5),
    barBackground: UIColor(rgb: 0x0e0e10),
    barSelected: UIColor(rgb: 0xffffff),
    barUnselected: UIColor(rgb: 0x5c5c61),
    badgeFill: UIColor(rgb: 0xffffff),
    badgeText: UIColor(rgb: 0x000000),
    fieldBackground: UIColor(rgb: 0x1f1f23)
)

// Converts an arbitrary colour to grey while preserving perceived lightness and
// alpha. Used for the handful of nested values that carry a hue but have no place
// in the palette above (poll bars, sticker placeholders, archive avatars), so a
// stray upstream blue cannot survive in a corner of the UI.
private func telewhiteMonoDesaturate(_ color: UIColor) -> UIColor {
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        return color
    }
    let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
    return UIColor(red: luminance, green: luminance, blue: luminance, alpha: alpha)
}

private func telewhiteMonoBubbleComponents(_ components: PresentationThemeBubbleColorComponents, fill: UIColor, palette: TelewhiteMonoPalette, reactionForeground: UIColor) -> PresentationThemeBubbleColorComponents {
    return components.withUpdated(
        fill: [fill],
        highlightedFill: fill.mixedWith(palette.primaryText, alpha: 0.1),
        stroke: fill,
        reactionInactiveBackground: reactionForeground.withMultipliedAlpha(0.12),
        reactionInactiveForeground: reactionForeground,
        reactionActiveBackground: reactionForeground,
        reactionActiveForeground: fill,
        reactionStarsInactiveBackground: reactionForeground.withMultipliedAlpha(0.12),
        reactionStarsInactiveForeground: reactionForeground,
        reactionStarsActiveBackground: reactionForeground,
        reactionStarsActiveForeground: fill,
        reactionInactiveMediaPlaceholder: reactionForeground.withMultipliedAlpha(0.12),
        reactionActiveMediaPlaceholder: reactionForeground.withMultipliedAlpha(0.12)
    )
}

// `scamColor` is intentionally left untouched here: it is a safety warning, and the
// same reasoning applies to every destructive colour skipped further down.
private func telewhiteMonoPartedColors(_ colors: PresentationThemePartedColors, bubbleFill: UIColor, textColor: UIColor, palette: TelewhiteMonoPalette) -> PresentationThemePartedColors {
    let secondary = textColor.withMultipliedAlpha(0.55)
    let control = textColor.withMultipliedAlpha(0.75)

    return colors.withUpdated(
        bubble: colors.bubble.withUpdated(
            withWallpaper: telewhiteMonoBubbleComponents(colors.bubble.withWallpaper, fill: bubbleFill, palette: palette, reactionForeground: textColor),
            withoutWallpaper: telewhiteMonoBubbleComponents(colors.bubble.withoutWallpaper, fill: bubbleFill, palette: palette, reactionForeground: textColor)
        ),
        primaryTextColor: textColor,
        secondaryTextColor: secondary,
        linkTextColor: textColor,
        linkHighlightColor: textColor.withMultipliedAlpha(0.2),
        textHighlightColor: textColor.withMultipliedAlpha(0.2),
        accentTextColor: textColor,
        accentControlColor: control,
        accentControlDisabledColor: textColor.withMultipliedAlpha(0.4),
        mediaActiveControlColor: control,
        mediaInactiveControlColor: textColor.withMultipliedAlpha(0.3),
        mediaControlInnerBackgroundColor: bubbleFill,
        pendingActivityColor: secondary,
        fileTitleColor: textColor,
        fileDescriptionColor: secondary,
        fileDurationColor: secondary,
        mediaPlaceholderColor: bubbleFill.mixedWith(textColor, alpha: 0.08),
        polls: colors.polls.withUpdated(
            radioButton: textColor.withMultipliedAlpha(0.4),
            radioProgress: control,
            highlight: textColor.withMultipliedAlpha(0.1),
            separator: textColor.withMultipliedAlpha(0.15),
            bar: control,
            barIconForeground: bubbleFill,
            barPositive: control,
            barNegative: textColor.withMultipliedAlpha(0.4)
        ),
        actionButtonsFillColor: PresentationThemeVariableColor(color: bubbleFill),
        actionButtonsStrokeColor: PresentationThemeVariableColor(color: textColor.withMultipliedAlpha(0.2)),
        actionButtonsTextColor: PresentationThemeVariableColor(color: textColor),
        textSelectionColor: textColor.withMultipliedAlpha(0.25),
        textSelectionKnobColor: textColor
    )
}

public func makeTelewhiteMonoPresentationTheme(_ theme: PresentationTheme) -> PresentationTheme {
    let palette = theme.overallDarkAppearance ? telewhiteMonoDark : telewhiteMonoLight

    let rootController = theme.rootController.withUpdated(
        tabBar: theme.rootController.tabBar.withUpdated(
            backgroundColor: palette.barBackground,
            separatorColor: palette.separator,
            iconColor: palette.barUnselected,
            selectedIconColor: palette.barSelected,
            textColor: palette.barUnselected,
            selectedTextColor: palette.barSelected,
            badgeBackgroundColor: palette.badgeFill,
            badgeStrokeColor: palette.badgeFill,
            badgeTextColor: palette.badgeText
        ),
        navigationBar: theme.rootController.navigationBar.withUpdated(
            buttonColor: palette.accent,
            disabledButtonColor: palette.disabledText,
            primaryTextColor: palette.primaryText,
            secondaryTextColor: palette.secondaryText,
            controlColor: palette.control,
            accentTextColor: palette.accent,
            blurredBackgroundColor: palette.barBackground,
            opaqueBackgroundColor: palette.barBackground,
            separatorColor: palette.separator,
            badgeBackgroundColor: palette.badgeFill,
            badgeStrokeColor: palette.badgeFill,
            badgeTextColor: palette.badgeText,
            segmentedBackgroundColor: palette.fieldBackground,
            segmentedForegroundColor: palette.itemBackground,
            segmentedTextColor: palette.primaryText,
            segmentedDividerColor: palette.separator,
            clearButtonBackgroundColor: palette.fieldBackground,
            clearButtonForegroundColor: palette.secondaryText
        ),
        navigationSearchBar: theme.rootController.navigationSearchBar.withUpdated(
            backgroundColor: palette.barBackground,
            accentColor: palette.accent,
            inputFillColor: palette.fieldBackground,
            inputTextColor: palette.primaryText,
            inputPlaceholderTextColor: palette.placeholderText,
            inputIconColor: palette.secondaryText,
            inputClearButtonColor: palette.secondaryText,
            separatorColor: palette.separator
        )
    )

    // `itemDestructiveColor`, `freeTextErrorColor`, the destructive swipe action and
    // the switch's negative colour keep their upstream red: they mark irreversible
    // actions, and a grey "Delete" is how people tap the wrong row.
    let list = theme.list.withUpdated(
        blocksBackgroundColor: palette.blocksBackground,
        modalBlocksBackgroundColor: palette.blocksBackground,
        plainBackgroundColor: palette.plainBackground,
        modalPlainBackgroundColor: palette.plainBackground,
        itemPrimaryTextColor: palette.primaryText,
        itemSecondaryTextColor: palette.secondaryText,
        itemDisabledTextColor: palette.disabledText,
        itemAccentColor: palette.accent,
        itemHighlightedColor: palette.accent,
        itemPlaceholderTextColor: palette.placeholderText,
        itemBlocksBackgroundColor: palette.itemBackground,
        itemModalBlocksBackgroundColor: palette.itemBackground,
        itemHighlightedBackgroundColor: palette.highlightedBackground,
        itemBlocksSeparatorColor: palette.separator,
        itemPlainSeparatorColor: palette.separator,
        disclosureArrowColor: palette.control,
        sectionHeaderTextColor: palette.secondaryText,
        freeTextColor: palette.secondaryText,
        freeTextSuccessColor: palette.secondaryText,
        freeMonoIconColor: palette.secondaryText,
        itemSwitchColors: theme.list.itemSwitchColors.withUpdated(
            frameColor: palette.separator,
            handleColor: palette.itemBackground,
            contentColor: palette.accentContrast,
            positiveColor: palette.accent
        ),
        itemDisclosureActions: theme.list.itemDisclosureActions.withUpdated(
            neutral1: theme.list.itemDisclosureActions.neutral1.withUpdated(fillColor: palette.control, foregroundColor: palette.plainBackground),
            neutral2: theme.list.itemDisclosureActions.neutral2.withUpdated(fillColor: palette.secondaryText, foregroundColor: palette.plainBackground),
            constructive: theme.list.itemDisclosureActions.constructive.withUpdated(fillColor: palette.accent, foregroundColor: palette.accentContrast),
            accent: theme.list.itemDisclosureActions.accent.withUpdated(fillColor: palette.accent, foregroundColor: palette.accentContrast),
            warning: theme.list.itemDisclosureActions.warning.withUpdated(fillColor: palette.secondaryText, foregroundColor: palette.plainBackground),
            inactive: theme.list.itemDisclosureActions.inactive.withUpdated(fillColor: palette.control, foregroundColor: palette.plainBackground)
        ),
        itemCheckColors: theme.list.itemCheckColors.withUpdated(
            fillColor: palette.accent,
            strokeColor: palette.control,
            foregroundColor: palette.accentContrast
        ),
        controlSecondaryColor: palette.control,
        freeInputField: theme.list.freeInputField.withUpdated(
            backgroundColor: palette.fieldBackground,
            strokeColor: palette.separator,
            placeholderColor: palette.placeholderText,
            primaryColor: palette.primaryText,
            controlColor: palette.control
        ),
        freePlainInputField: theme.list.freePlainInputField.withUpdated(
            backgroundColor: palette.fieldBackground,
            strokeColor: palette.separator,
            placeholderColor: palette.placeholderText,
            primaryColor: palette.primaryText,
            controlColor: palette.control
        ),
        mediaPlaceholderColor: palette.highlightedBackground,
        scrollIndicatorColor: palette.control.withMultipliedAlpha(0.5),
        pageIndicatorInactiveColor: palette.control,
        inputClearButtonColor: palette.secondaryText
    )

    // `failedFillColor` / `failedForegroundColor` stay red: they report a message
    // that did not send, which the user needs to notice.
    let chatList = theme.chatList.withUpdated(
        backgroundColor: palette.plainBackground,
        itemSeparatorColor: palette.separator,
        itemBackgroundColor: palette.plainBackground,
        pinnedItemBackgroundColor: palette.blocksBackground,
        itemHighlightedBackgroundColor: palette.highlightedBackground,
        pinnedItemHighlightedBackgroundColor: palette.highlightedBackground,
        itemSelectedBackgroundColor: palette.highlightedBackground,
        titleColor: palette.primaryText,
        secretTitleColor: palette.primaryText,
        dateTextColor: palette.secondaryText,
        authorNameColor: palette.primaryText,
        messageTextColor: palette.secondaryText,
        messageHighlightedTextColor: palette.primaryText,
        messageDraftTextColor: palette.secondaryText,
        checkmarkColor: palette.accent,
        pendingIndicatorColor: palette.secondaryText,
        muteIconColor: palette.control,
        unreadBadgeActiveBackgroundColor: palette.badgeFill,
        unreadBadgeActiveTextColor: palette.badgeText,
        unreadBadgeInactiveBackgroundColor: palette.control,
        unreadBadgeInactiveTextColor: palette.plainBackground,
        reactionBadgeActiveBackgroundColor: palette.badgeFill,
        pinnedBadgeColor: palette.control,
        pinnedSearchBarColor: palette.fieldBackground,
        regularSearchBarColor: palette.fieldBackground,
        sectionHeaderFillColor: palette.blocksBackground,
        sectionHeaderTextColor: palette.secondaryText,
        verifiedIconFillColor: palette.accent,
        verifiedIconForegroundColor: palette.accentContrast,
        secretIconColor: palette.secondaryText,
        pinnedArchiveAvatarColor: theme.chatList.pinnedArchiveAvatarColor.withUpdated(
            foregroundColor: telewhiteMonoDesaturate(theme.chatList.pinnedArchiveAvatarColor.foregroundColor)
        ),
        unpinnedArchiveAvatarColor: theme.chatList.unpinnedArchiveAvatarColor.withUpdated(
            foregroundColor: telewhiteMonoDesaturate(theme.chatList.unpinnedArchiveAvatarColor.foregroundColor)
        )
    )

    // `deliveryFailedColors` keeps its red for the same reason as the chat list's
    // failed indicator.
    let message = theme.chat.message.withUpdated(
        incoming: telewhiteMonoPartedColors(theme.chat.message.incoming, bubbleFill: palette.incomingBubble, textColor: palette.incomingText, palette: palette),
        outgoing: telewhiteMonoPartedColors(theme.chat.message.outgoing, bubbleFill: palette.outgoingBubble, textColor: palette.outgoingText, palette: palette),
        freeform: theme.chat.message.freeform.withUpdated(
            withWallpaper: telewhiteMonoBubbleComponents(theme.chat.message.freeform.withWallpaper, fill: palette.incomingBubble, palette: palette, reactionForeground: palette.incomingText),
            withoutWallpaper: telewhiteMonoBubbleComponents(theme.chat.message.freeform.withoutWallpaper, fill: palette.incomingBubble, palette: palette, reactionForeground: palette.incomingText)
        ),
        infoPrimaryTextColor: palette.primaryText,
        infoLinkTextColor: palette.primaryText,
        outgoingCheckColor: palette.outgoingText,
        mediaDateAndStatusFillColor: UIColor(rgb: 0x000000, alpha: 0.5),
        mediaDateAndStatusTextColor: UIColor(rgb: 0xffffff),
        shareButtonFillColor: PresentationThemeVariableColor(color: palette.serviceFill),
        shareButtonStrokeColor: PresentationThemeVariableColor(color: palette.separator),
        shareButtonForegroundColor: PresentationThemeVariableColor(color: palette.primaryText),
        mediaOverlayControlColors: theme.chat.message.mediaOverlayControlColors.withUpdated(
            fillColor: UIColor(rgb: 0x000000, alpha: 0.6),
            foregroundColor: UIColor(rgb: 0xffffff)
        ),
        selectionControlColors: theme.chat.message.selectionControlColors.withUpdated(
            fillColor: palette.accent,
            strokeColor: palette.control,
            foregroundColor: palette.accentContrast
        ),
        mediaHighlightOverlayColor: UIColor(rgb: 0xffffff, alpha: 0.6),
        stickerPlaceholderColor: PresentationThemeVariableColor(color: palette.serviceFill),
        stickerPlaceholderShimmerColor: PresentationThemeVariableColor(color: palette.primaryText.withMultipliedAlpha(0.1))
    )

    let serviceComponents = theme.chat.serviceMessage.components.withDefaultWallpaper.withUpdated(
        fill: palette.serviceFill,
        primaryText: palette.serviceText,
        linkHighlight: palette.primaryText.withMultipliedAlpha(0.2),
        dateFillStatic: palette.serviceFill,
        dateFillFloating: palette.serviceFill
    )
    let serviceMessage = theme.chat.serviceMessage.withUpdated(
        components: theme.chat.serviceMessage.components.withUpdated(
            withDefaultWallpaper: serviceComponents,
            withCustomWallpaper: serviceComponents
        ),
        unreadBarFillColor: palette.itemBackground,
        unreadBarStrokeColor: palette.separator,
        unreadBarTextColor: palette.secondaryText,
        dateTextColor: PresentationThemeVariableColor(color: palette.serviceText)
    )

    // `panelControlDestructiveColor` keeps its red: it is the cancel-recording and
    // delete affordance inside the input panel.
    let inputPanel = theme.chat.inputPanel.withUpdated(
        panelBackgroundColor: palette.barBackground,
        panelBackgroundColorNoWallpaper: palette.barBackground,
        panelSeparatorColor: palette.separator,
        panelControlAccentColor: palette.accent,
        panelControlColor: palette.control,
        panelControlDisabledColor: palette.disabledText,
        inputBackgroundColor: palette.fieldBackground,
        inputStrokeColor: palette.separator,
        inputPlaceholderColor: palette.placeholderText,
        inputTextColor: palette.primaryText,
        inputControlColor: palette.control,
        actionControlFillColor: palette.accent,
        actionControlForegroundColor: palette.accentContrast,
        primaryTextColor: palette.primaryText,
        secondaryTextColor: palette.secondaryText,
        mediaRecordingControl: theme.chat.inputPanel.mediaRecordingControl.withUpdated(
            buttonColor: palette.accent,
            micLevelColor: palette.accent.withMultipliedAlpha(0.2),
            activeIconColor: palette.accentContrast
        )
    )

    let inputMediaPanel = theme.chat.inputMediaPanel.withUpdated(
        panelSeparatorColor: palette.separator,
        panelIconColor: palette.control,
        panelHighlightedIconBackgroundColor: palette.highlightedBackground,
        panelHighlightedIconColor: palette.primaryText,
        stickersBackgroundColor: palette.plainBackground,
        stickersSectionTextColor: palette.secondaryText,
        stickersSearchBackgroundColor: palette.fieldBackground,
        stickersSearchPlaceholderColor: palette.placeholderText,
        stickersSearchPrimaryColor: palette.primaryText,
        stickersSearchControlColor: palette.control
    )

    let inputButtonPanel = theme.chat.inputButtonPanel.withUpdated(
        panelSeparatorColor: palette.separator,
        panelBackgroundColor: palette.barBackground,
        buttonFillColor: palette.itemBackground,
        buttonHighlightColor: palette.highlightedBackground,
        buttonStrokeColor: palette.separator,
        buttonHighlightedFillColor: palette.highlightedBackground,
        buttonHighlightedStrokeColor: palette.separator,
        buttonTextColor: palette.primaryText
    )

    let historyNavigation = theme.chat.historyNavigation.withUpdated(
        fillColor: palette.itemBackground,
        strokeColor: palette.separator,
        foregroundColor: palette.primaryText,
        badgeBackgroundColor: palette.badgeFill,
        badgeStrokeColor: palette.badgeFill,
        badgeTextColor: palette.badgeText
    )

    let chat = theme.chat.withUpdated(
        defaultWallpaper: .color(palette.chatBackground.rgb),
        animateMessageColors: false,
        message: message,
        serviceMessage: serviceMessage,
        inputPanel: inputPanel,
        inputMediaPanel: inputMediaPanel,
        inputButtonPanel: inputButtonPanel,
        historyNavigation: historyNavigation
    )

    // `destructiveActionTextColor` is skipped here and `destructiveColor` in the
    // context menu below, for the same reason as the list's destructive colour.
    let actionSheet = theme.actionSheet.withUpdated(
        opaqueItemBackgroundColor: palette.itemBackground,
        itemBackgroundColor: palette.itemBackground.withMultipliedAlpha(0.85),
        opaqueItemHighlightedBackgroundColor: palette.highlightedBackground,
        itemHighlightedBackgroundColor: palette.highlightedBackground.withMultipliedAlpha(0.85),
        opaqueItemSeparatorColor: palette.separator,
        standardActionTextColor: palette.accent,
        disabledActionTextColor: palette.disabledText,
        primaryTextColor: palette.primaryText,
        secondaryTextColor: palette.secondaryText,
        controlAccentColor: palette.accent,
        inputBackgroundColor: palette.fieldBackground,
        inputHollowBackgroundColor: palette.fieldBackground,
        inputBorderColor: palette.separator,
        inputPlaceholderColor: palette.placeholderText,
        inputTextColor: palette.primaryText,
        inputClearButtonColor: palette.secondaryText,
        checkContentColor: palette.accentContrast
    )

    let contextMenu = theme.contextMenu.withUpdated(
        backgroundColor: palette.elevatedBackground,
        itemSeparatorColor: palette.separator,
        sectionSeparatorColor: palette.separator,
        itemBackgroundColor: UIColor(rgb: 0x000000, alpha: 0.0),
        itemHighlightedBackgroundColor: palette.highlightedBackground,
        primaryColor: palette.primaryText,
        secondaryColor: palette.secondaryText
    )

    let inAppNotification = theme.inAppNotification.withUpdated(
        fillColor: palette.elevatedBackground,
        primaryTextColor: palette.primaryText
    )

    let result = PresentationTheme(
        name: theme.name,
        index: theme.index,
        referenceTheme: theme.referenceTheme,
        overallDarkAppearance: theme.overallDarkAppearance,
        intro: theme.intro,
        passcode: theme.passcode,
        rootController: rootController,
        list: list,
        chatList: chatList,
        chat: chat,
        actionSheet: actionSheet,
        contextMenu: contextMenu,
        inAppNotification: inAppNotification,
        chart: theme.chart,
        preview: theme.preview
    )
    result.forceSync = theme.forceSync
    result.starGift = theme.starGift
    return result
}
