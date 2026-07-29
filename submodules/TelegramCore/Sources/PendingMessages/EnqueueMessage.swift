import Foundation
import Postbox
import TelegramApi
import SwiftSignalKit
import Emoji

public enum EnqueueMessageGrouping {
    case none
    case auto
}

public enum EngineMessageReplyInnerSubject: Codable, Equatable {
    case todoItem(Int32)
    case pollOption(Data)

    private enum CodingKeys: String, CodingKey {
        case type = "t"
        case value = "v"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(Int32.self, forKey: .type)
        switch type {
        case 0:
            self = .todoItem(try container.decode(Int32.self, forKey: .value))
        case 1:
            self = .pollOption(try container.decode(Data.self, forKey: .value))
        default:
            self = .todoItem(try container.decode(Int32.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .todoItem(id):
            try container.encode(Int32(0), forKey: .type)
            try container.encode(id, forKey: .value)
        case let .pollOption(data):
            try container.encode(Int32(1), forKey: .type)
            try container.encode(data, forKey: .value)
        }
    }
}

public struct EngineMessageReplyQuote: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case text = "t"
        case entities = "e"
        case media = "m"
        case offset = "o"
    }
    
    public var text: String
    public var offset: Int?
    public var entities: [MessageTextEntity]
    public var media: Media?
    
    public init(text: String, offset: Int?, entities: [MessageTextEntity], media: Media?) {
        self.text = text
        self.offset = offset
        self.entities = entities
        self.media = media
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.text = try container.decode(String.self, forKey: .text)
        self.offset = (try container.decodeIfPresent(Int32.self, forKey: .offset)).flatMap(Int.init)
        self.entities = try container.decode([MessageTextEntity].self, forKey: .entities)
        
        if let mediaData = try container.decodeIfPresent(Data.self, forKey: .media) {
            self.media = PostboxDecoder(buffer: MemoryBuffer(data: mediaData)).decodeRootObject() as? Media
        } else {
            self.media = nil
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.text, forKey: .text)
        try container.encodeIfPresent(self.offset.flatMap(Int32.init(clamping:)), forKey: .offset)
        try container.encode(self.entities, forKey: .entities)
        if let media = self.media {
            let mediaEncoder = PostboxEncoder()
            mediaEncoder.encodeRootObject(media)
            try container.encode(mediaEncoder.makeData(), forKey: .media)
        }
    }
    
    public static func ==(lhs: EngineMessageReplyQuote, rhs: EngineMessageReplyQuote) -> Bool {
        if lhs.text != rhs.text {
            return false
        }
        if lhs.offset != rhs.offset {
            return false
        }
        if lhs.entities != rhs.entities {
            return false
        }
        if let lhsMedia = lhs.media, let rhsMedia = rhs.media {
            if !lhsMedia.isEqual(to: rhsMedia) {
                return false
            }
        } else {
            if (lhs.media == nil) != (rhs.media == nil) {
                return false
            }
        }
        return true
    }
}

public struct EngineMessageReplySubject: Codable, Equatable {
    public var messageId: EngineMessage.Id
    public var quote: EngineMessageReplyQuote?
    public var innerSubject: EngineMessageReplyInnerSubject?
    
    public init(messageId: EngineMessage.Id, quote: EngineMessageReplyQuote?, innerSubject: EngineMessageReplyInnerSubject?) {
        self.messageId = messageId
        self.quote = quote
        self.innerSubject = innerSubject
    }
}

public enum EnqueueMessage {
    case message(text: String, attributes: [MessageAttribute], inlineStickers: [MediaId: Media], mediaReference: AnyMediaReference?, threadId: Int64?, replyToMessageId: EngineMessageReplySubject?, replyToStoryId: StoryId?, localGroupingKey: Int64?, correlationId: Int64?, bubbleUpEmojiOrStickersets: [ItemCollectionId])
    case forward(source: MessageId, threadId: Int64?, grouping: EnqueueMessageGrouping, attributes: [MessageAttribute], correlationId: Int64?)
    
    public func withUpdatedReplyToMessageId(_ replyToMessageId: EngineMessageReplySubject?) -> EnqueueMessage {
        switch self {
        case let .message(text, attributes, inlineStickers, mediaReference, threadId, _, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets):
            return .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
        case .forward:
            return self
        }
    }
    
    public func withUpdatedReplyToStoryId(_ replyToStoryId: StoryId?) -> EnqueueMessage {
        switch self {
        case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, _, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets):
            return .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
        case .forward:
            return self
        }
    }
    
    public func withUpdatedAttributes(_ f: ([MessageAttribute]) -> [MessageAttribute]) -> EnqueueMessage {
        switch self {
        case let .message(text, attributes, inlineStickers, mediaReference, threadId: threadId, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets):
            return .message(text: text, attributes: f(attributes), inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
        case let .forward(source, threadId, grouping, attributes, correlationId):
            return .forward(source: source, threadId: threadId, grouping: grouping, attributes: f(attributes), correlationId: correlationId)
        }
    }
    
    public func withUpdatedGroupingKey(_ f: (Int64?) -> Int64?) -> EnqueueMessage {
        switch self {
        case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets):
            return .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: f(localGroupingKey), correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
        case .forward:
            return self
        }
    }

    public func withUpdatedCorrelationId(_ value: Int64?) -> EnqueueMessage {
        switch self {
        case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, _, bubbleUpEmojiOrStickersets):
            return .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: value, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
        case let .forward(source, threadId, grouping, attributes, _):
            return .forward(source: source, threadId: threadId, grouping: grouping, attributes: attributes, correlationId: value)
        }
    }
    
    public func withUpdatedThreadId(_ threadId: Int64?) -> EnqueueMessage {
        switch self {
        case let .message(text, attributes, inlineStickers, mediaReference, _, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets):
            return .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets)
        case let .forward(source, _, grouping, attributes, correlationId):
            return .forward(source: source, threadId: threadId, grouping: grouping, attributes: attributes, correlationId: correlationId)
        }
    }
    
    public var groupingKey: Int64? {
        if case let .message(_, _, _, _, _, _, _, localGroupingKey, _, _) = self {
            return localGroupingKey
        } else {
            return nil
        }
    }
    
    public var attributes: [MessageAttribute] {
        switch self {
        case let .message(_, attributes, _, _, _, _, _, _, _, _):
            return attributes
        case let .forward(_, _, _, attributes, _):
            return attributes
        }
    }
}

private extension EnqueueMessage {
    var correlationId: Int64? {
        switch self {
        case let .message(_, _, _, _, _, _, _, _, correlationId, _):
            return correlationId
        case let .forward(_, _, _, _, correlationId):
            return correlationId
        }
    }
    
    var bubbleUpEmojiOrStickersets: [ItemCollectionId] {
        switch self {
        case let .message(_, _, _, _, _, _, _, _, _, bubbleUpEmojiOrStickersets):
            return bubbleUpEmojiOrStickersets
        case .forward:
            return []
        }
    }
}

func augmentMediaWithReference(_ mediaReference: AnyMediaReference) -> Media {
    if let file = mediaReference.media as? TelegramMediaFile {
        if file.partialReference != nil {
            return file
        } else {
            return file.withUpdatedPartialReference(mediaReference.partial)
        }
    } else if let image = mediaReference.media as? TelegramMediaImage {
        if image.partialReference != nil {
            return image
        } else {
            return image.withUpdatedPartialReference(mediaReference.partial)
        }
    } else {
        return mediaReference.media
    }
}

// Telewhite: the mod toggle lives in UserDefaults, matching how every other Telewhite mod in
// this fork reads its state. Kept as a function rather than a cached constant so toggling the
// switch in Settings takes effect immediately, without an app restart.
func telewhiteContentRestrictionBypassEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "telewhite.mods.contentRestrictionBypass")
}

// Telewhite: rebuild a copy-protected source message as a set of fresh outgoing
// messages so the server treats them as new uploads instead of a rejected
// forward. Each media item is cloned into the Local namespace, and wherever the
// bytes are already in the media cache the clone is pointed straight at that file.
// That takes the pending-message uploader past its "re-send by reference" shortcut
// into a genuine byte upload, dropping the copy-protection lineage entirely, while
// still leaving the media fetchable — an earlier version instead blanked out the
// cloud file reference, which produced a resource nothing could ever download.
// Returns nil when the message carries no re-sendable media (caller sends text).
private func telewhiteStrippedResendableMedia(_ media: Media, mediaBox: MediaBox) -> Media? {
    if let image = media as? TelegramMediaImage {
        // Only the largest representation is what actually gets uploaded, so that is the one
        // worth repointing at the cached bytes; the smaller ones stay as they are, since they
        // serve as local thumbnails and are never sent.
        var representations = image.representations
        if let largest = largestImageRepresentation(representations), let index = representations.firstIndex(where: { $0.resource.id == largest.resource.id }), let path = mediaBox.completedResourcePath(largest.resource), let size = fileSize(path) {
            // progressiveSizes is dropped along with the cloud resource: it describes how to
            // fetch that cloud photo progressively and means nothing for a local file.
            representations[index] = TelegramMediaImageRepresentation(dimensions: largest.dimensions, resource: LocalFileReferenceMediaResource(localFilePath: path, randomId: Int64.random(in: Int64.min ... Int64.max), isUniquelyReferencedTemporaryFile: false, size: size), progressiveSizes: [], immediateThumbnailData: largest.immediateThumbnailData, hasVideo: largest.hasVideo, isPersonal: largest.isPersonal)
        }
        return TelegramMediaImage(imageId: MediaId(namespace: Namespaces.Media.LocalImage, id: Int64.random(in: Int64.min ... Int64.max)), representations: representations, immediateThumbnailData: image.immediateThumbnailData, reference: nil, partialReference: nil, flags: [])
    } else if let file = media as? TelegramMediaFile {
        let strippedResource: TelegramMediaResource
        // Kept in sync with the resource actually being uploaded: a size that disagrees with the
        // bytes on disk makes the server reject the assembled upload.
        var strippedSize = file.size
        if let cloud = file.resource as? CloudDocumentMediaResource {
            if let path = mediaBox.completedResourcePath(cloud), let size = fileSize(path) {
                strippedSize = size
                // The bytes are already in the local cache, so hand the uploader a purely local
                // resource. It then uploads real bytes, carries no cloud lineage, and — unlike a
                // cloud resource with its reference removed — needs no file reference to fetch
                // anything. isUniquelyReferencedTemporaryFile stays false on purpose: this path
                // is the shared media cache, and letting the uploader move or delete it would
                // break the copy still shown in the original chat.
                strippedResource = LocalFileReferenceMediaResource(localFilePath: path, randomId: Int64.random(in: Int64.min ... Int64.max), isUniquelyReferencedTemporaryFile: false, size: size)
            } else {
                // Not fully cached yet — protected videos are usually only streamed, so this is
                // the common case. Keep the original reference intact: dropping it (as this code
                // used to do) leaves a resource nothing can ever download, and the send fails
                // outright instead of fetching the missing bytes first.
                strippedResource = cloud
            }
        } else {
            strippedResource = file.resource
        }
        return TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: nil, resource: strippedResource, previewRepresentations: file.previewRepresentations, videoThumbnails: file.videoThumbnails, immediateThumbnailData: file.immediateThumbnailData, mimeType: file.mimeType, size: strippedSize, attributes: file.attributes, alternativeRepresentations: [])
    } else if let contact = media as? TelegramMediaContact {
        // Contacts, locations and polls carry no uploaded bytes at all, so re-sending them is only
        // a matter of describing the same thing again. Previously they fell through to the `nil`
        // below, which handed the whole message back to the regular forward path — the very path
        // the server rejects in a copy-protected chat.
        return TelegramMediaContact(firstName: contact.firstName, lastName: contact.lastName, phoneNumber: contact.phoneNumber, peerId: contact.peerId, vCardData: contact.vCardData)
    } else if let map = media as? TelegramMediaMap {
        // A live location is deliberately flattened into a static pin: live sharing belongs to the
        // original sender and only they can keep updating it, so a "live" copy sent by us would be
        // a location that silently never moves again.
        return TelegramMediaMap(latitude: map.latitude, longitude: map.longitude, heading: map.heading, accuracyRadius: map.accuracyRadius, venue: map.venue, address: map.address, liveBroadcastingTimeout: nil, liveProximityNotificationRadius: nil)
    } else if let poll = media as? TelegramMediaPoll {
        // Recreated as a brand new open poll owned by us. Votes are intentionally not carried
        // over: they belong to the original poll, and copying the tallies would show results
        // nobody in the destination chat actually voted for. deadlineDate is dropped as well,
        // since it is an absolute timestamp that may already be in the past.
        return TelegramMediaPoll(pollId: MediaId(namespace: Namespaces.Media.LocalPoll, id: Int64.random(in: Int64.min ... Int64.max)), publicity: poll.publicity, kind: poll.kind, text: poll.text, textEntities: poll.textEntities, options: poll.options, correctAnswers: poll.correctAnswers, results: TelegramMediaPollResults(voters: nil, totalVoters: nil, recentVoters: [], solution: poll.results.solution.flatMap { solution in
            // Keep the quiz explanation text, but drop any media attached to it: that media is a
            // cloud reference owned by the protected source and would not survive the re-send.
            return TelegramMediaPollResults.Solution(text: solution.text, entities: solution.entities, media: nil)
        }, hasUnseenVotes: nil, canViewStats: false), isClosed: false, deadlineTimeout: poll.deadlineTimeout, deadlineDate: nil, pollHash: 0, openAnswers: poll.openAnswers, revotingDisabled: poll.revotingDisabled, shuffleAnswers: poll.shuffleAnswers, hideResultsUntilClose: poll.hideResultsUntilClose, isCreator: true, attachedMedia: nil, restrictToSubscribers: false, countries: poll.countries)
    } else {
        return nil
    }
}

private func telewhiteResendableMessagesFromProtectedSource(_ message: Message, mediaBox: MediaBox) -> [EnqueueMessage]? {
    var resendableMedia: [Media] = []
    for media in message.media {
        if media is TelegramMediaImage || media is TelegramMediaFile || media is TelegramMediaContact || media is TelegramMediaMap || media is TelegramMediaPoll {
            guard let stripped = telewhiteStrippedResendableMedia(media, mediaBox: mediaBox) else {
                return nil
            }
            resendableMedia.append(stripped)
        } else if media is TelegramMediaWebpage || media is TelegramMediaAction {
            // A webpage is only a preview of a link that is already part of the text, and an
            // action is a service event that cannot be authored by us. Both are skipped rather
            // than aborting, so a message that also carries real media still goes through.
            continue
        } else {
            return nil
        }
    }

    let text = message.text
    var textAttributes: [MessageAttribute] = []
    if let entities = message.textEntitiesAttribute {
        textAttributes.append(TextEntitiesMessageAttribute(entities: entities.entities))
    }
    if let spoiler = message.attributes.first(where: { $0 is MediaSpoilerMessageAttribute }) {
        textAttributes.append(spoiler)
    }

    if resendableMedia.isEmpty {
        if text.isEmpty {
            return nil
        }
        return [.message(text: text, attributes: textAttributes, inlineStickers: [:], mediaReference: nil, threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])]
    }

    // Only photos and files can travel as one album. Polls, contacts and locations must each be
    // their own message — putting them under a shared grouping key would produce an album the
    // server refuses to accept, so the whole re-send would fail.
    let groupableCount = resendableMedia.filter { $0 is TelegramMediaImage || $0 is TelegramMediaFile }.count
    let groupingKey: Int64? = groupableCount > 1 ? Int64.random(in: Int64.min ... Int64.max) : nil

    // The caption has to ride along with an item that can actually display one. Polls carry their
    // own question text and contacts/locations have no caption field, so attaching it to such an
    // item would silently drop the original text. Pick the first item that can hold it instead.
    let captionIndex = resendableMedia.firstIndex { $0 is TelegramMediaImage || $0 is TelegramMediaFile }

    var result: [EnqueueMessage] = []
    var pendingStandaloneText: String? = nil
    if captionIndex == nil && !text.isEmpty {
        pendingStandaloneText = text
    }

    for (index, media) in resendableMedia.enumerated() {
        let carriesCaption = index == captionIndex
        let itemText = carriesCaption ? text : ""
        let itemAttributes = carriesCaption ? textAttributes : []
        let isGroupable = media is TelegramMediaImage || media is TelegramMediaFile
        result.append(.message(text: itemText, attributes: itemAttributes, inlineStickers: [:], mediaReference: .standalone(media: media), threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: isGroupable ? groupingKey : nil, correlationId: nil, bubbleUpEmojiOrStickersets: []))
    }

    // Nothing in the message could hold the caption, so send it as its own message rather than
    // losing it.
    if let pendingStandaloneText {
        result.insert(.message(text: pendingStandaloneText, attributes: textAttributes, inlineStickers: [:], mediaReference: nil, threadId: nil, replyToMessageId: nil, replyToStoryId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: []), at: 0)
    }

    return result
}

private func convertForwardedMediaForSecretChat(_ media: Media) -> Media {
    if let file = media as? TelegramMediaFile {
        return TelegramMediaFile(fileId: MediaId(namespace: Namespaces.Media.LocalFile, id: Int64.random(in: Int64.min ... Int64.max)), partialReference: file.partialReference, resource: file.resource, previewRepresentations: file.previewRepresentations, videoThumbnails: file.videoThumbnails, immediateThumbnailData: file.immediateThumbnailData, mimeType: file.mimeType, size: file.size, attributes: file.attributes, alternativeRepresentations: [])
    } else if let image = media as? TelegramMediaImage {
        return TelegramMediaImage(imageId: MediaId(namespace: Namespaces.Media.LocalImage, id: Int64.random(in: Int64.min ... Int64.max)), representations: image.representations, immediateThumbnailData: image.immediateThumbnailData, reference: image.reference, partialReference: image.partialReference, flags: [])
    } else {
        return media
    }
}

private func filterMessageAttributesForOutgoingMessage(_ attributes: [MessageAttribute]) -> [MessageAttribute] {
    return attributes.filter { attribute in
        switch attribute {
        case _ as TextEntitiesMessageAttribute:
            return true
        case _ as RichTextMessageAttribute:
            return true
        case _ as InlineBotMessageAttribute:
            return true
        case _ as OutgoingMessageInfoAttribute:
            return false
        case _ as OutgoingContentInfoMessageAttribute:
            return true
        case _ as ReplyMarkupMessageAttribute:
            return true
        case _ as OutgoingChatContextResultMessageAttribute:
            return true
        case _ as AutoremoveTimeoutMessageAttribute:
            return true
        case _ as NotificationInfoMessageAttribute:
            return true
        case _ as OutgoingScheduleInfoMessageAttribute:
            return true
        case _ as OutgoingQuickReplyMessageAttribute:
            return true
        case _ as EmbeddedMediaStickersMessageAttribute:
            return true
        case _ as EmojiSearchQueryMessageAttribute:
            return true
        case _ as ForwardOptionsMessageAttribute:
            return true
        case _ as SendAsMessageAttribute:
            return true
        case _ as MediaSpoilerMessageAttribute:
            return true
        case _ as WebpagePreviewMessageAttribute:
            return true
        case _ as InvertMediaMessageAttribute:
            return true
        case _ as EffectMessageAttribute:
            return true
        case _ as ForwardVideoTimestampAttribute:
            return true
        case _ as PaidStarsMessageAttribute:
            return true
        case _ as SuggestedPostMessageAttribute:
            return true
        default:
            return false
        }
    }
}

private func filterMessageAttributesForForwardedMessage(_ attributes: [MessageAttribute], forwardedMessageIds: Set<MessageId>? = nil) -> [MessageAttribute] {
    return attributes.filter { attribute in
        switch attribute {
            case _ as TextEntitiesMessageAttribute:
                return true
            case _ as RichTextMessageAttribute:
                return true
            case _ as InlineBotMessageAttribute:
                return true
            case _ as NotificationInfoMessageAttribute:
                return true
            case _ as OutgoingScheduleInfoMessageAttribute:
                return true
            case _ as OutgoingQuickReplyMessageAttribute:
                return true
            case _ as ForwardOptionsMessageAttribute:
                return true
            case _ as SendAsMessageAttribute:
                return true
            case _ as MediaSpoilerMessageAttribute:
                return true
            case _ as InvertMediaMessageAttribute:
                return true
            case _ as PaidStarsMessageAttribute:
                return true
            case let attribute as ReplyMessageAttribute:
                if attribute.quote != nil {
                    return true
                }
                if let forwardedMessageIds = forwardedMessageIds {
                    return forwardedMessageIds.contains(attribute.messageId)
                } else {
                    return false
                }
            default:
                return false
        }
    }
}

func opportunisticallyTransformMessageWithMedia(network: Network, postbox: Postbox, transformOutgoingMessageMedia: TransformOutgoingMessageMedia, mediaReference: AnyMediaReference, userInteractive: Bool) -> Signal<AnyMediaReference?, NoError> {
    return transformOutgoingMessageMedia(postbox, network, mediaReference, userInteractive)
    |> timeout(2.0, queue: Queue.concurrentDefaultQueue(), alternate: .single(nil))
}

private func forwardedMessageToBeReuploaded(transaction: Transaction, id: MessageId) -> Message? {
    if let message = transaction.getMessage(id) {
        if message.id.namespace != Namespaces.Message.Cloud {
            return message
        } else {
            return nil
        }
    } else {
        return nil
    }
}

private func opportunisticallyTransformOutgoingMedia(network: Network, postbox: Postbox, transformOutgoingMessageMedia: TransformOutgoingMessageMedia, messages: [EnqueueMessage], userInteractive: Bool) -> Signal<[(Bool, EnqueueMessage)], NoError> {
    var hasMedia = false
    loop: for message in messages {
        switch message {
            case let .message(_, _, _, mediaReference, _, _, _, _, _, _):
                if mediaReference != nil {
                    hasMedia = true
                    break loop
                }
            case .forward:
                break
        }
    }
    
    if !hasMedia {
        return .single(messages.map { (true, $0) })
    }
    
    var signals: [Signal<(Bool, EnqueueMessage), NoError>] = []
    for message in messages {
        switch message {
            case let .message(text, attributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, correlationId, bubbleUpEmojiOrStickersets):
                if let mediaReference = mediaReference {
                    signals.append(opportunisticallyTransformMessageWithMedia(network: network, postbox: postbox, transformOutgoingMessageMedia: transformOutgoingMessageMedia, mediaReference: mediaReference, userInteractive: userInteractive)
                    |> map { result -> (Bool, EnqueueMessage) in
                        return (result != nil, .message(text: text, attributes: attributes, inlineStickers: inlineStickers, mediaReference: result ?? mediaReference, threadId: threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: localGroupingKey, correlationId: correlationId, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets))
                    })
                } else {
                    signals.append(.single((false, message)))
                }
            case .forward:
                signals.append(.single((false, message)))
        }
    }
    return combineLatest(signals)
}

public func enqueueMessages(account: Account, peerId: PeerId, messages: [EnqueueMessage]) -> Signal<[MessageId?], NoError> {
    let signal: Signal<[(Bool, EnqueueMessage)], NoError>
    if let transformOutgoingMessageMedia = account.transformOutgoingMessageMedia {
        signal = opportunisticallyTransformOutgoingMedia(network: account.network, postbox: account.postbox, transformOutgoingMessageMedia: transformOutgoingMessageMedia, messages: messages, userInteractive: true)
    } else {
        signal = .single(messages.map { (false, $0) })
    }
    return signal
    |> mapToSignal { messages -> Signal<[MessageId?], NoError> in
        return account.postbox.transaction { transaction -> [MessageId?] in
            return enqueueMessages(transaction: transaction, account: account, peerId: peerId, messages: messages)
        }
    }
}

public func resendMessages(account: Account, messageIds: [MessageId]) -> Signal<Void, NoError> {
    return account.postbox.transaction { transaction -> Void in
        var removeMessageIds: [MessageId] = []
        for (peerId, ids) in messagesIdsGroupedByPeerId(messageIds) {
            var sendPaidMessageStars: StarsAmount?
            let peer = transaction.getPeer(peerId)
            if let user = peer as? TelegramUser, user.flags.contains(.requireStars) {
                if let cachedUserData = transaction.getPeerCachedData(peerId: user.id) as? CachedUserData {
                    sendPaidMessageStars = cachedUserData.sendPaidMessageStars
                }
            } else if let channel = peer as? TelegramChannel {
                if channel.flags.contains(.isCreator) || channel.adminRights != nil {
                } else {
                    sendPaidMessageStars = channel.sendPaidMessageStars
                }
            }
            
            var messages: [EnqueueMessage] = []
            for id in ids {
                if let message = transaction.getMessage(id), !message.flags.contains(.Incoming) {
                    removeMessageIds.append(id)
                    
                    var filteredAttributes: [MessageAttribute] = []
                    var replyToMessageId: EngineMessageReplySubject?
                    var replyToStoryId: StoryId?
                    var bubbleUpEmojiOrStickersets: [ItemCollectionId] = []
                    var forwardSource: MessageId?
                    inner: for attribute in message.attributes {
                        if let attribute = attribute as? ReplyMessageAttribute {
                            replyToMessageId = EngineMessageReplySubject(messageId: attribute.messageId, quote: attribute.quote, innerSubject: attribute.innerSubject)
                        } else if let attribute = attribute as? ReplyStoryAttribute {
                            replyToStoryId = attribute.storyId
                        } else if let attribute = attribute as? OutgoingMessageInfoAttribute {
                            bubbleUpEmojiOrStickersets = attribute.bubbleUpEmojiOrStickersets
                            continue inner
                        } else if let attribute = attribute as? ForwardSourceInfoAttribute {
                            forwardSource = attribute.messageId
                        } else {
                            if attribute is PaidStarsMessageAttribute {
                            } else {
                                filteredAttributes.append(attribute)
                            }
                        }
                    }
                    
                    if let sendPaidMessageStars {
                        filteredAttributes.append(PaidStarsMessageAttribute(stars: sendPaidMessageStars, postponeSending: false))
                    }

                    if let forwardSource = forwardSource {
                        messages.append(.forward(source: forwardSource, threadId: nil, grouping: .auto, attributes: filteredAttributes, correlationId: nil))
                    } else {
                        messages.append(.message(text: message.text, attributes: filteredAttributes, inlineStickers: [:], mediaReference: message.media.first.flatMap(AnyMediaReference.standalone), threadId: message.threadId, replyToMessageId: replyToMessageId, replyToStoryId: replyToStoryId, localGroupingKey: message.groupingKey, correlationId: nil, bubbleUpEmojiOrStickersets: bubbleUpEmojiOrStickersets))
                    }
                }
            }
            let _ = enqueueMessages(transaction: transaction, account: account, peerId: peerId, messages: messages.map { (false, $0) })
        }
        _internal_deleteMessages(transaction: transaction, mediaBox: account.postbox.mediaBox, ids: removeMessageIds, deleteMedia: false)
    }
}

func enqueueMessages(transaction: Transaction, account: Account, peerId: PeerId, messages: [(Bool, EnqueueMessage)], disableAutoremove: Bool = false, transformGroupingKeysWithPeerId: Bool = false) -> [MessageId?] {
    /**
     * If it is a support account, mark messages as read here as they are
     * not marked as read when chat is opened.
     **/
    if account.isSupportUser {
        let namespace: MessageId.Namespace
        if peerId.namespace == Namespaces.Peer.SecretChat {
            namespace = Namespaces.Message.SecretIncoming
        } else {
            namespace = Namespaces.Message.Cloud
        }
        if let index = transaction.getTopPeerMessageIndex(peerId: peerId, namespace: namespace) {
            let _ = transaction.applyInteractiveReadMaxIndex(index)
        }
    }
    
    var forwardedMessageIds = Set<MessageId>()
    for (_, message) in messages {
        if case let .forward(sourceId, _, _, _, _) = message {
            forwardedMessageIds.insert(sourceId)
        }
    }
    
    var updatedMessages: [(Bool, EnqueueMessage)] = []
    outer: for (transformedMedia, message) in messages {
        var updatedMessage = message
        if transformGroupingKeysWithPeerId {
            updatedMessage = updatedMessage.withUpdatedGroupingKey { groupingKey -> Int64? in
                if let groupingKey = groupingKey {
                    return groupingKey &+ peerId.toInt64()
                } else {
                    return nil
                }
            }
        }
        
        switch message {
            case let .message(_, attributes, _, _, threadId, replyToMessageId, _, _, _, _):
                if let replyToMessageId = replyToMessageId, (replyToMessageId.messageId.peerId != peerId && peerId.namespace == Namespaces.Peer.SecretChat), let replyMessage = transaction.getMessage(replyToMessageId.messageId) {
                    var canBeForwarded = true
                    if replyMessage.id.namespace != Namespaces.Message.Cloud {
                        canBeForwarded = false
                    }
                    inner: for media in replyMessage.media {
                        if media is TelegramMediaAction {
                            canBeForwarded = false
                            break inner
                        }
                    }
                    if canBeForwarded {
                        updatedMessages.append((true, .forward(source: replyToMessageId.messageId, threadId: threadId, grouping: .none, attributes: attributes, correlationId: nil)))
                    }
                }
            case let .forward(sourceId, threadId, _, forwardAttributes, forwardCorrelationId):
                // Telewhite: intercept copy-protected forwards here, at the single choke point every
                // forward in the app funnels through, so "Share", search results, profile actions and
                // the context menu are covered as well — not just the forward screen.
                if telewhiteContentRestrictionBypassEnabled(), let sourceMessage = transaction.getMessage(sourceId), sourceMessage.isCopyProtected(), let resent = telewhiteResendableMessagesFromProtectedSource(sourceMessage, mediaBox: account.postbox.mediaBox) {
                    for (index, resentMessage) in resent.enumerated() {
                        // The forward's own attributes carry the send options the user picked —
                        // silent, scheduled, send-as — so they have to travel with the copies,
                        // otherwise a scheduled protected forward would send immediately.
                        var updatedResentMessage = resentMessage.withUpdatedThreadId(threadId).withUpdatedAttributes { attributes in
                            var attributes = attributes
                            attributes.append(contentsOf: forwardAttributes)
                            return attributes
                        }
                        // The correlation id is what the sending animation waits for, and it must
                        // stay unique, so only the first copy inherits it.
                        if index == 0 {
                            updatedResentMessage = updatedResentMessage.withUpdatedCorrelationId(forwardCorrelationId)
                        }
                        updatedMessages.append((transformedMedia, updatedResentMessage))
                    }
                    continue outer
                }
                if let sourceMessage = forwardedMessageToBeReuploaded(transaction: transaction, id: sourceId) {
                    var mediaReference: AnyMediaReference?
                    if sourceMessage.id.peerId.namespace == Namespaces.Peer.SecretChat {
                        if let media = sourceMessage.media.first {
                            mediaReference = .standalone(media: media)
                        }
                    }
                    updatedMessages.append((transformedMedia, .message(text: sourceMessage.text, attributes: sourceMessage.attributes, inlineStickers: [:], mediaReference: mediaReference, threadId: threadId, replyToMessageId: threadId.flatMap { EngineMessageReplySubject(messageId: MessageId(peerId: peerId, namespace: Namespaces.Message.Cloud, id: Int32(clamping: $0)), quote: nil, innerSubject: nil) }, replyToStoryId: nil, localGroupingKey: nil, correlationId: nil, bubbleUpEmojiOrStickersets: [])))
                    continue outer
                }
        }
        updatedMessages.append((transformedMedia, updatedMessage))
    }
    
    if let peer = transaction.getPeer(peerId), let accountPeer = transaction.getPeer(account.peerId) {
        let peerPresence = transaction.getPeerPresence(peerId: peerId)
        
        var storeMessages: [StoreMessage] = []
        var timestamp = Int32(account.network.context.globalTime())
        switch peerId.namespace {
            case Namespaces.Peer.CloudChannel, Namespaces.Peer.CloudGroup, Namespaces.Peer.CloudUser:
                if let topIndex = transaction.getTopPeerMessageIndex(peerId: peerId, namespace: Namespaces.Message.Cloud) {
                    timestamp = max(timestamp, topIndex.timestamp)
                }
            default:
                break
        }
        
        var addedHashtags: [String] = []
        var emojiItems: [RecentEmojiItem] = []
        
        var localGroupingKeyBySourceKey: [Int64: Int64] = [:]
        
        var globallyUniqueIds: [Int64] = []
        for (transformedMedia, message) in updatedMessages {
            var attributes: [MessageAttribute] = []
            var flags = StoreMessageFlags()
            flags.insert(.Unsent)
            
            var randomId: Int64 = 0
            arc4random_buf(&randomId, 8)
            var infoFlags = OutgoingMessageInfoFlags()
            if transformedMedia {
                infoFlags.insert(.transformedMedia)
            }
            
            var partialReference: PartialMediaReference?
            if case let .message(_, _, _, mediaReference, _, _, _, _, _, _) = message {
                partialReference = mediaReference?.partial
            }
            attributes.append(OutgoingMessageInfoAttribute(uniqueId: randomId, flags: infoFlags, acknowledged: false, correlationId: message.correlationId, bubbleUpEmojiOrStickersets: message.bubbleUpEmojiOrStickersets, partialReference: partialReference))
            globallyUniqueIds.append(randomId)
            
            switch message {
                case let .message(text, requestedAttributes, inlineStickers, mediaReference, threadId, replyToMessageId, replyToStoryId, localGroupingKey, _, _):
                    for (_, file) in inlineStickers {
                        transaction.storeMediaIfNotPresent(media: file)
                    }
                
                    for emoji in text.emojis {
                        if emoji.isSingleEmoji {
                            if !emojiItems.contains(where: { $0.content == .text(emoji) }) {
                                emojiItems.append(RecentEmojiItem(.text(emoji)))
                            }
                        }
                    }
                
                    var peerAutoremoveTimeout: Int32?
                    if let peer = peer as? TelegramSecretChat {
                        var isAction = false
                        if let _ = mediaReference?.media as? TelegramMediaAction {
                            isAction = true
                        }
                        if !disableAutoremove, let messageAutoremoveTimeout = peer.messageAutoremoveTimeout, !isAction {
                            peerAutoremoveTimeout = messageAutoremoveTimeout
                        }
                    } else if let cachedData = transaction.getPeerCachedData(peerId: peer.id), !disableAutoremove {
                        var isScheduled = false
                        for attribute in requestedAttributes {
                            if let _ = attribute as? OutgoingScheduleInfoMessageAttribute {
                                isScheduled = true
                            }
                        }
                        
                        if !isScheduled {
                            var messageAutoremoveTimeout: Int32?
                            if let cachedData = cachedData as? CachedUserData {
                                if case let .known(value) = cachedData.autoremoveTimeout {
                                    messageAutoremoveTimeout = value?.effectiveValue
                                }
                            } else if let cachedData = cachedData as? CachedGroupData {
                                if case let .known(value) = cachedData.autoremoveTimeout {
                                    messageAutoremoveTimeout = value?.effectiveValue
                                }
                            } else if let cachedData = cachedData as? CachedChannelData {
                                if case let .known(value) = cachedData.autoremoveTimeout {
                                    messageAutoremoveTimeout = value?.effectiveValue
                                }
                            }
                            
                            if let messageAutoremoveTimeout = messageAutoremoveTimeout {
                                peerAutoremoveTimeout = messageAutoremoveTimeout
                            }
                        }
                    }
                    
                    for attribute in filterMessageAttributesForOutgoingMessage(requestedAttributes) {
                        if let attribute = attribute as? AutoremoveTimeoutMessageAttribute {
                            if let _ = peer as? TelegramSecretChat {
                                peerAutoremoveTimeout = nil
                                attributes.append(attribute)
                            } else {
                                attributes.append(AutoclearTimeoutMessageAttribute(timeout: attribute.timeout, countdownBeginTime: nil))
                            }
                        } else {
                            attributes.append(attribute)
                        }
                    }
                    
                    if let peerAutoremoveTimeout = peerAutoremoveTimeout {
                        attributes.append(AutoremoveTimeoutMessageAttribute(timeout: peerAutoremoveTimeout, countdownBeginTime: nil))
                    }
                        
                    if let replyToMessageId = replyToMessageId {
                        var threadMessageId: MessageId?
                        var quote = replyToMessageId.quote
                        let isQuote = quote != nil
                        if let replyMessage = transaction.getMessage(replyToMessageId.messageId) {
                            if replyMessage.id.namespace == Namespaces.Message.Cloud, let threadId = replyMessage.threadId {
                                threadMessageId = MessageId(peerId: replyMessage.id.peerId, namespace: Namespaces.Message.Cloud, id: Int32(clamping: threadId))
                            }
                            if quote == nil, replyToMessageId.messageId.peerId != peerId {
                                let nsText = replyMessage.text as NSString
                                var replyMedia: Media?
                                for m in replyMessage.media {
                                    switch m {
                                    case _ as TelegramMediaImage, _ as TelegramMediaFile:
                                        replyMedia = m
                                    default:
                                        break
                                    }
                                }
                                quote = EngineMessageReplyQuote(text: replyMessage.text, offset: nil, entities: messageTextEntitiesInRange(entities: replyMessage.textEntitiesAttribute?.entities ?? [], range: NSRange(location: 0, length: nsText.length), onlyQuoteable: true), media: replyMedia)
                            }
                        }
                        attributes.append(ReplyMessageAttribute(messageId: replyToMessageId.messageId, threadMessageId: threadMessageId, quote: quote, isQuote: isQuote, innerSubject: replyToMessageId.innerSubject))
                    }
                    if let replyToStoryId = replyToStoryId {
                        attributes.append(ReplyStoryAttribute(storyId: replyToStoryId))
                    }
                    var mediaList: [Media] = []
                    if let mediaReference = mediaReference {
                        let augmentedMedia = augmentMediaWithReference(mediaReference)
                        mediaList.append(augmentedMedia)
                    }
                    
                    if let file = mediaReference?.media as? TelegramMediaFile, file.isVoice || file.isInstantVideo {
                        if peerId.namespace == Namespaces.Peer.CloudUser || peerId.namespace == Namespaces.Peer.CloudGroup || peerId.namespace == Namespaces.Peer.SecretChat {
                            attributes.append(ConsumableContentMessageAttribute(consumed: false))
                        }
                    }
                    
                    var entitiesAttribute: TextEntitiesMessageAttribute?
                    for attribute in attributes {
                        if let attribute = attribute as? TextEntitiesMessageAttribute {
                            entitiesAttribute = attribute
                            var maybeNsText: NSString?
                            for entity in attribute.entities {
                                if case .Hashtag = entity.type {
                                    let nsText: NSString
                                    if let maybeNsText = maybeNsText {
                                        nsText = maybeNsText
                                    } else {
                                        nsText = text as NSString
                                        maybeNsText = nsText
                                    }
                                    var entityRange = NSRange(location: entity.range.lowerBound, length: entity.range.upperBound - entity.range.lowerBound)
                                    if entityRange.location + entityRange.length > nsText.length {
                                        entityRange.location = max(0, nsText.length - entityRange.length)
                                        entityRange.length = nsText.length - entityRange.location
                                    }
                                    if entityRange.length > 1 {
                                        entityRange.location += 1
                                        entityRange.length -= 1
                                        let hashtag = nsText.substring(with: entityRange)
                                        addedHashtags.append(hashtag)
                                    }
                                } else if case let .CustomEmoji(_, fileId) = entity.type {
                                    let mediaId = MediaId(namespace: Namespaces.Media.CloudFile, id: fileId)
                                    if let file = inlineStickers[mediaId] as? TelegramMediaFile {
                                        emojiItems.append(RecentEmojiItem(.file(file)))
                                    } else if let file = transaction.getMedia(mediaId) as? TelegramMediaFile {
                                        emojiItems.append(RecentEmojiItem(.file(file)))
                                    }
                                }
                            }
                            break
                        }
                    }
                                    
                    let (tags, globalTags) = tagsForStoreMessage(incoming: false, attributes: attributes, media: mediaList, textEntities: entitiesAttribute?.entities, isPinned: false)
                    
                    var localTags: LocalMessageTags = []
                    for media in mediaList {
                        if let media = media as? TelegramMediaMap, media.liveBroadcastingTimeout != nil {
                            localTags.insert(.OutgoingLiveLocation)
                        }
                    }
                    
                    var messageNamespace = Namespaces.Message.Local
                    var effectiveTimestamp = timestamp
                    var sendAsPeer: Peer?
                    for attribute in attributes {
                        if let attribute = attribute as? OutgoingScheduleInfoMessageAttribute {
                            if attribute.scheduleTime == scheduleWhenOnlineTimestamp, let presence = peerPresence as? TelegramUserPresence, case let .present(statusTimestamp) = presence.status, statusTimestamp >= timestamp {
                            } else {
                                messageNamespace = Namespaces.Message.ScheduledLocal
                                effectiveTimestamp = attribute.scheduleTime
                            }
                        } else if attribute is OutgoingQuickReplyMessageAttribute {
                            messageNamespace = Namespaces.Message.QuickReplyLocal
                            effectiveTimestamp = 0
                        } else if let attribute = attribute as? SendAsMessageAttribute {
                            if let peer = transaction.getPeer(attribute.peerId) {
                                sendAsPeer = peer
                            }
                        }
                    }
                
                    var authorId: PeerId?
                    if let sendAsPeer = sendAsPeer {
                        if let peer = peer as? TelegramChannel, case let .broadcast(info) = peer.info {
                            if info.flags.contains(.messagesShouldHaveProfiles) {
                                authorId = sendAsPeer.id
                            } else {
                                authorId = peer.id
                            }
                        } else {
                            authorId = sendAsPeer.id
                        }
                    } else if let peer = peer as? TelegramChannel {
                        if case .broadcast = peer.info {
                            authorId = peer.id
                        } else if case .group = peer.info, peer.hasPermission(.canBeAnonymous) {
                            authorId = peer.id
                        } else {
                            authorId = account.peerId
                        }
                    }  else {
                        authorId = account.peerId
                    }
                    
                    if messageNamespace != Namespaces.Message.ScheduledLocal {
                        attributes.removeAll(where: { $0 is OutgoingScheduleInfoMessageAttribute })
                    }
                    if messageNamespace != Namespaces.Message.QuickReplyLocal {
                        attributes.removeAll(where: { $0 is OutgoingQuickReplyMessageAttribute })
                    }
                                        
                    if let peer = peer as? TelegramChannel {
                        switch peer.info {
                            case let .broadcast(info):
                                if messageNamespace != Namespaces.Message.ScheduledLocal && messageNamespace != Namespaces.Message.QuickReplyLocal {
                                    attributes.append(ViewCountMessageAttribute(count: 1))
                                }
                                if info.flags.contains(.messagesShouldHaveProfiles) {
                                    if sendAsPeer == nil {
                                        authorId = account.peerId
                                    }
                                }
                                if info.flags.contains(.messagesShouldHaveSignatures) {
                                    if let sendAsPeer {
                                        if sendAsPeer.id == peerId {
                                        } else {
                                            attributes.append(AuthorSignatureMessageAttribute(signature: sendAsPeer.debugDisplayTitle))
                                        }
                                    } else {
                                        attributes.append(AuthorSignatureMessageAttribute(signature: accountPeer.debugDisplayTitle))
                                    }
                                }
                            case .group:
                                break
                        }
                    }
                    
                    var threadId: Int64? = threadId
                    if threadId == nil {
                        if let replyToMessageId = replyToMessageId {
                            if let message = transaction.getMessage(replyToMessageId.messageId) {
                                if let threadIdValue = message.threadId {
                                    if threadIdValue == 1 {
                                        if let peer = transaction.getPeer(message.id.peerId), peer.isForum {
                                            threadId = threadIdValue
                                        } else {
                                            if let channel = message.peers[message.id.peerId] as? TelegramChannel, case .group = channel.info {
                                                threadId = Int64(replyToMessageId.messageId.id)
                                            }
                                        }
                                    } else {
                                        threadId = threadIdValue
                                    }
                                } else if let channel = message.peers[message.id.peerId] as? TelegramChannel, case .group = channel.info {
                                    threadId = Int64(replyToMessageId.messageId.id)
                                }
                            }
                        }
                    }
                
                    if threadId == nil, let peer = transaction.getPeer(peerId), (peer is TelegramChannel), peer.isForum {
                        threadId = 1
                    }
                    
                    storeMessages.append(StoreMessage(peerId: peerId, namespace: messageNamespace, customStableId: nil, globallyUniqueId: randomId, groupingKey: localGroupingKey, threadId: threadId, timestamp: effectiveTimestamp, flags: flags, tags: tags, globalTags: globalTags, localTags: localTags, forwardInfo: nil, authorId: authorId, text: text, attributes: attributes, media: mediaList))
                case let .forward(source, threadId, grouping, requestedAttributes, _):
                    let sourceMessage = transaction.getMessage(source)
                    if let sourceMessage = sourceMessage, let author = sourceMessage.author ?? sourceMessage.peers[sourceMessage.id.peerId] {
                        var messageText = sourceMessage.text
                        
                        if let peer = peer as? TelegramSecretChat {
                            var isAction = false
                            for media in sourceMessage.media {
                                if let _ = media as? TelegramMediaAction {
                                    isAction = true
                                }
                            }
                            if !disableAutoremove, let messageAutoremoveTimeout = peer.messageAutoremoveTimeout, !isAction {
                                attributes.append(AutoremoveTimeoutMessageAttribute(timeout: messageAutoremoveTimeout, countdownBeginTime: nil))
                            }
                        } else if let cachedData = transaction.getPeerCachedData(peerId: peer.id), !disableAutoremove {
                            var isScheduled = false
                            for attribute in attributes {
                                if let _ = attribute as? OutgoingScheduleInfoMessageAttribute {
                                    isScheduled = true
                                    break
                                }
                            }
                            
                            if !isScheduled {
                                var messageAutoremoveTimeout: Int32?
                                if let cachedData = cachedData as? CachedUserData {
                                    if case let .known(value) = cachedData.autoremoveTimeout {
                                        messageAutoremoveTimeout = value?.effectiveValue
                                    }
                                } else if let cachedData = cachedData as? CachedGroupData {
                                    if case let .known(value) = cachedData.autoremoveTimeout {
                                        messageAutoremoveTimeout = value?.effectiveValue
                                    }
                                } else if let cachedData = cachedData as? CachedChannelData {
                                    if case let .known(value) = cachedData.autoremoveTimeout {
                                        messageAutoremoveTimeout = value?.effectiveValue
                                    }
                                }
                                
                                if let messageAutoremoveTimeout = messageAutoremoveTimeout {
                                    attributes.append(AutoremoveTimeoutMessageAttribute(timeout: messageAutoremoveTimeout, countdownBeginTime: nil))
                                }
                            }
                        }
                        
                        var forwardInfo: StoreMessageForwardInfo?
                        
                        var hideSendersNames = false
                        var hideCaptions = false
                        for attribute in requestedAttributes {
                            if let attribute = attribute as? ForwardOptionsMessageAttribute {
                                hideSendersNames = attribute.hideNames
                                hideCaptions = attribute.hideCaptions
                                break
                            }
                        }
                        
                        if hideCaptions {
                            for media in sourceMessage.media {
                                if media is TelegramMediaImage || media is TelegramMediaFile {
                                    messageText = ""
                                    break
                                }
                            }
                        }
                        
                        if sourceMessage.id.namespace == Namespaces.Message.Cloud && peerId.namespace != Namespaces.Peer.SecretChat {
                            attributes.append(ForwardSourceInfoAttribute(messageId: sourceMessage.id))
                        
                            if peerId == account.peerId {
                                attributes.append(SourceReferenceMessageAttribute(messageId: sourceMessage.id))
                            }
                            
                            attributes.append(contentsOf: filterMessageAttributesForForwardedMessage(requestedAttributes))
                            attributes.append(contentsOf: filterMessageAttributesForForwardedMessage(sourceMessage.attributes, forwardedMessageIds: forwardedMessageIds))
                            
                            var sourceReplyMarkup: ReplyMarkupMessageAttribute? = nil
                            var sourceSentViaBot = false
                            for attribute in attributes {
                                if let attribute = attribute as? ReplyMarkupMessageAttribute {
                                    sourceReplyMarkup = attribute
                                } else if let _ = attribute as? InlineBotMessageAttribute {
                                    sourceSentViaBot = true
                                }
                            }
                            
                            if let sourceReplyMarkup = sourceReplyMarkup {
                                var rows: [ReplyMarkupRow] = []
                                loop: for row in sourceReplyMarkup.rows {
                                    var buttons: [ReplyMarkupButton] = []
                                    for button in row.buttons {
                                        if case .url = button.action {
                                            buttons.append(button)
                                        } else if case .urlAuth = button.action {
                                            buttons.append(button)
                                        } else if case let .switchInline(samePeer, query, peerTypes) = button.action, sourceSentViaBot {
                                            let samePeer = samePeer && peerId == sourceMessage.id.peerId
                                            let updatedButton = ReplyMarkupButton(title: button.titleWhenForwarded ?? button.title, titleWhenForwarded: button.titleWhenForwarded,  action: .switchInline(samePeer: samePeer, query: query, peerTypes: peerTypes), style: button.style)
                                            buttons.append(updatedButton)
                                        } else {
                                            rows.removeAll()
                                            break loop
                                        }
                                    }
                                    rows.append(ReplyMarkupRow(buttons: buttons))
                                }
                                
                                if !rows.isEmpty {
                                    attributes.append(ReplyMarkupMessageAttribute(rows: rows, flags: sourceReplyMarkup.flags, placeholder: sourceReplyMarkup.placeholder))
                                }
                            }
                            
                            if hideSendersNames {
                                
                            } else if let sourceForwardInfo = sourceMessage.forwardInfo {
                                forwardInfo = StoreMessageForwardInfo(authorId: sourceForwardInfo.author?.id, sourceId: sourceForwardInfo.source?.id, sourceMessageId: sourceForwardInfo.sourceMessageId, date: sourceForwardInfo.date, authorSignature: sourceForwardInfo.authorSignature, psaType: nil, flags: [])
                            } else {
                                if sourceMessage.id.peerId != account.peerId {
                                    var sourceId: PeerId? = nil
                                    var sourceMessageId: MessageId? = nil
                                    if case let .channel(peer) = messageMainPeer(EngineMessage(sourceMessage)), case .broadcast = peer.info {
                                        sourceId = peer.id
                                        sourceMessageId = sourceMessage.id
                                    }

                                    var authorSignature: String?
                                    for attribute in sourceMessage.attributes {
                                        if let attribute = attribute as? AuthorSignatureMessageAttribute {
                                            authorSignature = attribute.signature
                                            break
                                        }
                                    }

                                    let psaType: String? = nil

                                    forwardInfo = StoreMessageForwardInfo(authorId: author.id, sourceId: sourceId, sourceMessageId: sourceMessageId, date: sourceMessage.timestamp, authorSignature: authorSignature, psaType: psaType, flags: [])
                                } else {
                                    forwardInfo = nil
                                }
                            }
                            
                            for attribute in requestedAttributes {
                                if attribute is ForwardVideoTimestampAttribute {
                                    attributes.append(attribute)
                                }
                            }
                        } else {
                            attributes.append(contentsOf: filterMessageAttributesForOutgoingMessage(sourceMessage.attributes))
                        }
                                                
                        var messageNamespace = Namespaces.Message.Local
                        var entitiesAttribute: TextEntitiesMessageAttribute?
                        var effectiveTimestamp = timestamp
                        var sendAsPeer: Peer?
                        var threadId: Int64? = threadId
                        for attribute in attributes {
                            if let attribute = attribute as? TextEntitiesMessageAttribute {
                                entitiesAttribute = attribute
                            } else if let attribute = attribute as? OutgoingScheduleInfoMessageAttribute {
                                if attribute.scheduleTime == scheduleWhenOnlineTimestamp, let presence = peerPresence as? TelegramUserPresence, case let .present(statusTimestamp) = presence.status, statusTimestamp >= timestamp {
                                } else {
                                    messageNamespace = Namespaces.Message.ScheduledLocal
                                    effectiveTimestamp = attribute.scheduleTime
                                }
                            } else if attribute is OutgoingQuickReplyMessageAttribute {
                                messageNamespace = Namespaces.Message.QuickReplyLocal
                                effectiveTimestamp = 0
                            } else if let attribute = attribute as? ReplyMessageAttribute {
                                if let threadMessageId = attribute.threadMessageId {
                                    threadId = Int64(threadMessageId.id)
                                }
                            } else if let attribute = attribute as? SendAsMessageAttribute {
                                if let peer = transaction.getPeer(attribute.peerId) {
                                    sendAsPeer = peer
                                }
                            }
                        }
                        
                        let authorId: PeerId?
                        if let sendAsPeer = sendAsPeer {
                            authorId = sendAsPeer.id
                        } else if let peer = peer as? TelegramChannel {
                            if case .broadcast = peer.info {
                                authorId = peer.id
                            } else if case .group = peer.info, peer.hasPermission(.canBeAnonymous) {
                                authorId = peer.id
                            } else {
                                authorId = account.peerId
                            }
                        }  else {
                            authorId = account.peerId
                        }
                        
                        if messageNamespace != Namespaces.Message.ScheduledLocal {
                            attributes.removeAll(where: { $0 is OutgoingScheduleInfoMessageAttribute })
                        }
                        if messageNamespace != Namespaces.Message.QuickReplyLocal {
                            attributes.removeAll(where: { $0 is OutgoingQuickReplyMessageAttribute })
                        }
                        
                        let (tags, globalTags) = tagsForStoreMessage(incoming: false, attributes: attributes, media: sourceMessage.media, textEntities: entitiesAttribute?.entities, isPinned: false)
                        
                        let localGroupingKey: Int64?
                        switch grouping {
                            case .none:
                                localGroupingKey = nil
                            case .auto:
                                if let groupingKey = sourceMessage.groupingKey {
                                    if let generatedKey = localGroupingKeyBySourceKey[groupingKey] {
                                        localGroupingKey = generatedKey
                                    } else {
                                        let generatedKey = Int64.random(in: Int64.min ... Int64.max)
                                        localGroupingKeyBySourceKey[groupingKey] = generatedKey
                                        localGroupingKey = generatedKey
                                    }
                                } else {
                                    localGroupingKey = nil
                                }
                        }
                        
                        var augmentedMediaList = sourceMessage.media.map { media -> Media in
                            return augmentMediaWithReference(.message(message: MessageReference(sourceMessage), media: media))
                        }
                        
                        if peerId.namespace == Namespaces.Peer.SecretChat {
                            augmentedMediaList = augmentedMediaList.map(convertForwardedMediaForSecretChat)
                        }
                        
                        if threadId == nil, let peer = transaction.getPeer(peerId), peer.isForum {
                            threadId = 1
                        }
                                                
                        storeMessages.append(StoreMessage(peerId: peerId, namespace: messageNamespace, customStableId: nil, globallyUniqueId: randomId, groupingKey: localGroupingKey, threadId: threadId, timestamp: effectiveTimestamp, flags: flags, tags: tags, globalTags: globalTags, localTags: [], forwardInfo: forwardInfo, authorId: authorId, text: messageText, attributes: attributes, media: augmentedMediaList))
                    }
            }
        }
        var messageIds: [MessageId?] = []
        if !storeMessages.isEmpty {
            for emojiItem in emojiItems {
                if let entry = CodableEntry(emojiItem) {
                    let id: RecentEmojiItemId
                    switch emojiItem.content {
                    case let .file(file):
                        id = RecentEmojiItemId(file.fileId)
                    case let .text(text):
                        id = RecentEmojiItemId(text)
                    }
                    transaction.addOrMoveToFirstPositionOrderedItemListItem(collectionId: Namespaces.OrderedItemList.LocalRecentEmoji, item: OrderedItemListEntry(id: id.rawValue, contents: entry), removeTailIfCountExceeds: 20)
                }
            }
            
            let globallyUniqueIdToMessageId = transaction.addMessages(storeMessages, location: .Random)
            for globallyUniqueId in globallyUniqueIds {
                messageIds.append(globallyUniqueIdToMessageId[globallyUniqueId])
            }
            
            if peerId.namespace == Namespaces.Peer.CloudUser {
                if case .notIncluded = transaction.getPeerChatListInclusion(peerId) {
                    transaction.updatePeerChatListInclusion(peerId, inclusion: .ifHasMessagesOrOneOf(groupId: .root, pinningIndex: nil, minTimestamp: nil))
                }
            }
        }
        for hashtag in addedHashtags {
            addRecentlyUsedHashtag(transaction: transaction, string: hashtag)
        }
        return messageIds
    } else {
        return []
    }
}
