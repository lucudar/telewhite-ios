import Foundation

/// Утилита для чистки трекеров и лишних параметров из URL
public func telewhiteCleanURL(_ urlString: String) -> String {
    guard let url = URL(string: urlString) else {
        return urlString
    }
    
    // Если нет query parameters, возвращаем как есть
    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
          let queryItems = components.queryItems, !queryItems.isEmpty else {
        return urlString
    }
    
    // Список известных трекеров для удаления
    let trackerPrefixes = [
        "utm_", "fbclid", "gclid", "yclid", "mc_", "msclkid",
        "_ga", "_gl", "ysclid", "igshid", "igsh", "si",
        "feature", "app", "roistat", "yclid", "ymclid"
    ]
    
    // Whitelist параметров, которые надо сохранять
    let keepParams = [
        "v", "t", "id", "s", "q", "query", "search",
        "page", "p", "sort", "order", "filter",
        "start", "startapp", "tgWebAppStartParam"  // Telegram mini apps
    ]
    
    // Специальная логика для популярных сервисов
    let host = url.host?.lowercased() ?? ""
    
    // YouTube: оставляем только v и t
    if host.contains("youtube.com") || host.contains("youtu.be") {
        components.queryItems = queryItems.filter { item in
            item.name == "v" || item.name == "t" || item.name == "list"
        }
    }
    // Telegram: оставляем start, startapp и tgWebAppStartParam
    else if host.contains("t.me") || host.contains("telegram.me") {
        components.queryItems = queryItems.filter { item in
            item.name.hasPrefix("start") || item.name == "tgWebAppStartParam"
        }
    }
    // Amazon: оставляем только идентификаторы товара
    else if host.contains("amazon.") {
        components.queryItems = queryItems.filter { item in
            ["dp", "gp", "product", "asin"].contains(item.name)
        }
    }
    // Twitter/X: удаляем s и t
    else if host.contains("twitter.com") || host.contains("x.com") {
        components.queryItems = queryItems.filter { item in
            item.name != "s" && item.name != "t" && item.name != "src"
        }
    }
    // Общая логика для остальных
    else {
        components.queryItems = queryItems.filter { item in
            let name = item.name.lowercased()
            
            // Если в whitelist — оставляем
            if keepParams.contains(name) {
                return true
            }
            
            // Если начинается с трекера — убираем
            for prefix in trackerPrefixes {
                if name.hasPrefix(prefix) {
                    return false
                }
            }
            
            return true
        }
    }
    
    // Если все параметры удалены, убираем знак вопроса
    if components.queryItems?.isEmpty ?? true {
        components.queryItems = nil
    }
    
    return components.url?.absoluteString ?? urlString
}
