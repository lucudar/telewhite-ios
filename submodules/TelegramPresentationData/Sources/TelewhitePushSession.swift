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
//     api_id — which may or may not have a certificate of its own.
//
// That last uncertainty is deliberate and must stay: whether a given api_id has an APNs
// certificate uploaded is known only to Telegram's servers, and the client cannot query it. An
// earlier version of this file stated "no certificate uploaded — pushes stop permanently" as
// fact; the owner then observed pushes arriving on a session belonging to this very build, which
// disproved it. So the UI reports *whose* session it is and lets that speak for itself, rather
// than predicting delivery it cannot see.
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
///
/// States the mechanism, not an outcome: logging out replaces the authorization with one
/// belonging to this build, and pushes that currently arrive via the other app's certificate
/// may stop. "May", not "will" — see the note at the top of this file.
public func telewhiteLogoutPushWarning(isRussian: Bool) -> String? {
    guard let appName = telewhiteForeignSessionAppName() else {
        return nil
    }
    if isRussian {
        if appName.isEmpty {
            return "Эта сессия принадлежит другому приложению, и пуш-уведомления сейчас идут через его сертификат. Выход уничтожит сессию: следующий вход создаст её заново уже от этой сборки, и уведомления могут перестать приходить. Вернуть прежнюю сессию можно только переустановкой поверх того приложения."
        }
        return "Эта сессия принадлежит приложению «\(appName)», и пуш-уведомления сейчас идут через его сертификат. Выход уничтожит сессию: следующий вход создаст её заново уже от этой сборки, и уведомления могут перестать приходить. Вернуть прежнюю сессию можно только переустановкой поверх «\(appName)»."
    }
    if appName.isEmpty {
        return "This session belongs to another app, and pushes currently arrive through its certificate. Logging out destroys the session: the next login creates one owned by this build, and notifications may stop. The only way back is reinstalling over that app."
    }
    return "This session belongs to “\(appName)”, and pushes currently arrive through its certificate. Logging out destroys the session: the next login creates one owned by this build, and notifications may stop. The only way back is reinstalling over “\(appName)”."
}
