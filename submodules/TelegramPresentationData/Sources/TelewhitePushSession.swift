import Foundation

// Telewhite: Telegram binds an app (its api_id) to an authorization at the moment that
// authorization is created, and the server picks which APNs certificate to push with by that
// api_id — the installed binary has no say in it. Two consequences the user can otherwise only
// discover by losing their notifications:
//
//   * a session created by another client keeps delivering pushes through *that* client's
//     certificate, even after this build is installed over it (same bundle id, preserved data
//     container, so no new login happens and the authorization survives);
//   * logging out destroys that authorization, and the next login creates one under this build's
//     api_id, which has no certificate uploaded — pushes stop permanently.
//
// The two api_ids therefore have to be comparable from several modules at once: TelegramUI knows
// the build's own value, the Mods -> Developer screen learns the session's from the server, and
// the two log-out confirmations (SettingsUI and PeerInfoScreen) need the verdict. They all reach
// TelegramPresentationData, so the small amount of shared state lives here instead of being
// duplicated three times.

private let telewhiteBuildApiIdKey = "telewhite.build.apiId"
private let telewhiteSessionApiIdKey = "telewhite.session.apiId"
private let telewhiteSessionAppNameKey = "telewhite.session.appName"

public func telewhiteStoreBuildApiId(_ apiId: Int32) {
    UserDefaults.standard.set(NSNumber(value: apiId), forKey: telewhiteBuildApiIdKey)
}

public func telewhiteStoreCurrentSessionApp(apiId: Int32, appName: String) {
    let defaults = UserDefaults.standard
    defaults.set(NSNumber(value: apiId), forKey: telewhiteSessionApiIdKey)
    defaults.set(appName, forKey: telewhiteSessionAppNameKey)
}

public func telewhiteBuildApiId() -> Int32? {
    return (UserDefaults.standard.object(forKey: telewhiteBuildApiIdKey) as? NSNumber)?.int32Value
}

/// The app name of the current authorization when it belongs to a *different* app than this
/// build, i.e. when push delivery depends on that app. Returns nil when the session is this
/// build's own, or when nothing has been learned yet (the Developer screen was never opened) —
/// in both cases there is nothing truthful to warn about, so callers keep their stock text.
public func telewhiteForeignSessionAppName() -> String? {
    let defaults = UserDefaults.standard
    guard let sessionApiId = (defaults.object(forKey: telewhiteSessionApiIdKey) as? NSNumber)?.int32Value else {
        return nil
    }
    guard let buildApiId = telewhiteBuildApiId(), buildApiId != sessionApiId else {
        return nil
    }
    return defaults.string(forKey: telewhiteSessionAppNameKey) ?? ""
}

/// Sentence to append to a log-out confirmation, or nil when the warning would not be true.
public func telewhiteLogoutPushWarning(isRussian: Bool) -> String? {
    guard let appName = telewhiteForeignSessionAppName() else {
        return nil
    }
    if isRussian {
        if appName.isEmpty {
            return "Пуш-уведомления приходят через другое приложение, к которому привязана эта сессия. Выход её уничтожит, и уведомления перестанут приходить — вернуть их можно будет только переустановкой поверх того приложения."
        }
        return "Пуш-уведомления приходят через «\(appName)» — к нему привязана эта сессия. Выход её уничтожит, и уведомления перестанут приходить: вернуть их можно будет только переустановкой поверх «\(appName)»."
    }
    if appName.isEmpty {
        return "Push notifications are delivered through another app that this session belongs to. Logging out destroys the session and pushes will stop — the only way back is reinstalling over that app."
    }
    return "Push notifications are delivered through “\(appName)”, which this session belongs to. Logging out destroys the session and pushes will stop — the only way back is reinstalling over “\(appName)”."
}
