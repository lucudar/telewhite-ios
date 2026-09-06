import Foundation
import AccountContext
import Display
import PresentationDataUtils
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData

private final class TelewhiteRegistrationDateCacheEntry: NSObject {
    let value: TelewhiteRegistrationDateValue?
    let expiresAt: Date

    init(value: TelewhiteRegistrationDateValue?) {
        self.value = value
        self.expiresAt = Date().addingTimeInterval(value == nil ? 30 : 3600)
    }
}

private enum TelewhiteRegistrationDateCache {
    // Only parsed data is retained, bounded and account-scoped. The Telegram
    // engine may separately cache inline results using the bot's cacheTimeout.
    static let entries: NSCache<NSString, TelewhiteRegistrationDateCacheEntry> = {
        let cache = NSCache<NSString, TelewhiteRegistrationDateCacheEntry>()
        cache.countLimit = 200
        return cache
    }()

    static func key(accountId: EnginePeer.Id, peerId: EnginePeer.Id) -> NSString {
        return "\(accountId.id._internalGetInt64Value()):\(peerId.id._internalGetInt64Value())" as NSString
    }

    static func entry(for key: NSString) -> TelewhiteRegistrationDateCacheEntry? {
        guard let entry = self.entries.object(forKey: key) else {
            return nil
        }
        guard entry.expiresAt > Date() else {
            self.entries.removeObject(forKey: key)
            return nil
        }
        return entry
    }
}

private final class TelewhiteRegistrationDateLookup {
    private let context: AccountContext
    private let peerId: EnginePeer.Id
    private weak var interaction: PeerInfoInteraction?
    private let disposable = MetaDisposable()
    private var isLoading = false

    init(context: AccountContext, peerId: EnginePeer.Id, interaction: PeerInfoInteraction) {
        self.context = context
        self.peerId = peerId
        self.interaction = interaction
    }

    deinit {
        // The profile row owns the lookup. Leaving/rebuilding the row cancels
        // pending work; subscriptions never retain the profile controller.
        self.disposable.dispose()
    }

    private var presentationData: PresentationData {
        return self.context.sharedContext.currentPresentationData.with { $0 }
    }

    private func text(_ russian: String, _ english: String) -> String {
        return self.presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru") ? russian : english
    }

    func show(_ value: TelewhiteRegistrationDateValue, progress: Promise<Bool>?, canRefresh: Bool = true) {
        let presentationData = self.presentationData
        let description: String
        var actions: [TextAlertAction] = []
        if value.kind == .telegramMonth {
            description = self.text(
                "Месяц регистрации получен от Telegram. Точный день не указан.",
                "Registration month supplied by Telegram. An exact day was not provided."
            )
        } else {
            description = self.text(
                "Источник: @ayugrambot. Это оценка стороннего сервиса, а не подтверждённая Telegram дата. «Раньше» и «Позже» означают границу, а не точный день регистрации.",
                "Source: @ayugrambot. This is a third-party estimate, not a date confirmed by Telegram. Before and After indicate a bound, not the exact registration day."
            )
            if canRefresh {
                actions.append(TextAlertAction(type: .genericAction, title: self.text("Обновить", "Refresh"), action: { [weak self] in
                    self?.confirm(progress: progress)
                }))
            }
        }
        actions.append(TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {}))
        self.interaction?.getController()?.present(textAlertController(
            context: self.context,
            title: presentationData.strings.Chat_NonContactUser_Registration,
            text: value.formatted(languageCode: presentationData.strings.baseLanguageCode) + "\n\n" + description,
            actions: actions
        ), in: .window(.root))
    }

    func confirm(progress: Promise<Bool>?) {
        guard !self.isLoading else {
            return
        }
        let presentationData = self.presentationData
        let id = self.peerId.id._internalGetInt64Value()
        let disclosure = self.text(
            "Отправить ID \(id) стороннему боту @ayugrambot? Бот также может видеть Telegram ID и публичные данные аккаунта, с которого выполняется запрос.\n\nПереписка, номер телефона и геопозиция в запрос не добавляются. Сообщение в чат не отправляется. Ответ может быть приблизительным или отсутствовать.",
            "Send ID \(id) to the third-party bot @ayugrambot? The bot may also see the Telegram ID and public profile information of the account making the request.\n\nChat history, phone number and location are not added to the query. No chat message is sent. The answer may be approximate or unavailable."
        )
        self.interaction?.getController()?.present(textAlertController(
            context: self.context,
            title: self.text("Запрос через AyuGram", "Query via AyuGram"),
            text: disclosure,
            actions: [
                TextAlertAction(type: .genericAction, title: presentationData.strings.Common_Cancel, action: {}),
                TextAlertAction(type: .defaultAction, title: self.text("Запросить", "Request"), action: { [weak self] in
                    self?.request(progress: progress)
                })
            ]
        ), in: .window(.root))
    }

    // This is the only network entry point, called only by the consent action.
    private func request(progress: Promise<Bool>?) {
        guard !self.isLoading, self.interaction?.getController() != nil else {
            return
        }
        let userId = self.peerId.id._internalGetInt64Value()
        guard userId > 0 else {
            return
        }
        self.isLoading = true
        progress?.set(.single(true))
        let context = self.context
        let signal: Signal<TelewhiteRegistrationDateValue?, NoError> = context.engine.peers.resolvePeerByName(name: "ayugrambot", referrer: nil)
        |> mapToSignal { result -> Signal<TelewhiteRegistrationDateValue?, NoError> in
            guard case let .result(peer) = result else {
                return .complete()
            }
            // Pin the provider by ID as AyuGram does; a reassigned username must
            // never redirect the approved lookup to a different account.
            guard let peer = peer, case let .user(bot) = peer,
                  bot.botInfo != nil, bot.id.id._internalGetInt64Value() == 6247153446 else {
                return .single(nil)
            }
            return context.engine.messages.requestChatContextResults(
                botId: bot.id,
                // Do not use the inspected person's chat as inline context.
                peerId: context.account.peerId,
                query: "regdate \(userId)",
                location: .single(nil),
                offset: ""
            )
            |> map { response -> TelewhiteRegistrationDateValue? in
                guard let response = response else {
                    return nil
                }
                for result in response.results.results {
                    if case let .text(text, _, _, _, _, _) = result.message,
                       let value = TelewhiteRegistrationDateValue.ayuResponse(text) {
                        return value
                    }
                }
                return nil
            }
            |> `catch` { _ -> Signal<TelewhiteRegistrationDateValue?, NoError> in
                return .single(nil)
            }
        }
        self.disposable.set((signal
        |> timeout(15.0, queue: Queue.mainQueue(), alternate: .single(nil))
        |> take(1)
        |> deliverOnMainQueue
        |> afterDisposed {
            Queue.mainQueue().async {
                progress?.set(.single(false))
            }
        }).start(next: { [weak self] value in
            guard let self = self else {
                return
            }
            self.isLoading = false
            let key = TelewhiteRegistrationDateCache.key(accountId: context.account.peerId, peerId: self.peerId)
            TelewhiteRegistrationDateCache.entries.setObject(TelewhiteRegistrationDateCacheEntry(value: value), forKey: key)
            // Show the result before relayout can replace the row/lookup owner.
            if let value = value {
                self.show(value, progress: progress, canRefresh: false)
            } else {
                let presentationData = self.presentationData
                self.interaction?.getController()?.present(textAlertController(
                    context: context,
                    title: self.text("Нет данных", "No data"),
                    text: self.text(
                        "Бот не вернул корректную дату или запрос не завершился вовремя. Можно попробовать ещё раз. Telewhite не будет подставлять дату по ID.",
                        "The bot did not return a valid date, or the request timed out. You can retry. Telewhite will not invent a date from the user ID."
                    ),
                    actions: [TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_OK, action: {})]
                ), in: .window(.root))
            }
            self.interaction?.requestLayout(false)
        }))
    }
}

func telewhiteRegistrationDateItem(
    id: AnyHashable,
    peerId: EnginePeer.Id,
    telegramMonth: String?,
    context: AccountContext,
    presentationData: PresentationData,
    interaction: PeerInfoInteraction
) -> PeerInfoScreenLabeledValueItem {
    let key = TelewhiteRegistrationDateCache.key(accountId: context.account.peerId, peerId: peerId)
    let entry = TelewhiteRegistrationDateCache.entry(for: key)
    let value = TelewhiteRegistrationDateValue.preferred(telegramMonth: telegramMonth, botValue: entry?.value)
    let isRussian = presentationData.strings.baseLanguageCode.lowercased().hasPrefix("ru")
    let text: String
    if let value = value {
        text = value.formatted(languageCode: presentationData.strings.baseLanguageCode)
    } else if entry != nil {
        text = isRussian ? "Нет данных — повторить" : "No data — retry"
    } else {
        text = isRussian ? "Узнать через AyuGram" : "Check via AyuGram"
    }
    let lookup = TelewhiteRegistrationDateLookup(context: context, peerId: peerId, interaction: interaction)
    return PeerInfoScreenLabeledValueItem(
        id: id,
        label: presentationData.strings.Chat_NonContactUser_Registration,
        rightLabel: value.map { $0.kind == .telegramMonth ? "Telegram" : "AyuGram" },
        text: text,
        textColor: value == nil ? .accent : .primary,
        action: { _, progress in
            if let value = value {
                lookup.show(value, progress: progress)
            } else {
                lookup.confirm(progress: progress)
            }
        },
        requestLayout: { [weak interaction] animated in
            interaction?.requestLayout(animated)
        }
    )
}
