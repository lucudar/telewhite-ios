import Foundation
import AccountContext
import TelegramCore
import TelegramPresentationData

// A passive row: opening or tapping it cannot start a lookup, create a
// subscription, present an alert, or trigger an asynchronous profile update.
func telewhiteRegistrationDateItem(
    id: AnyHashable,
    peerId _: EnginePeer.Id,
    telegramMonth: String?,
    context _: AccountContext,
    presentationData: PresentationData,
    interaction: PeerInfoInteraction
) -> PeerInfoScreenLabeledValueItem {
    let value = TelewhiteRegistrationDateValue.telegramMonth(telegramMonth)
    let languageCode = presentationData.strings.baseLanguageCode
    let unavailable = languageCode.lowercased().hasPrefix("ru") ? "Нет данных" : "No data"
    return PeerInfoScreenLabeledValueItem(
        id: id,
        label: presentationData.strings.Chat_NonContactUser_Registration,
        rightLabel: value == nil ? nil : "Telegram",
        text: value?.formatted(languageCode: languageCode) ?? unavailable,
        textColor: .primary,
        action: nil,
        longTapAction: nil,
        requestLayout: { [weak interaction] animated in
            interaction?.requestLayout(animated)
        }
    )
}
