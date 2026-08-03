import Foundation

// Telewhite: "Speed Boost" widens the transfer pipe by asking for more parts at once, and
// for bigger parts on downloads. Both numbers are stock Telegram tuning constants that the
// app picks once per transfer; this only substitutes larger values.
//
// The hooks are called from `MultipartFetchManager.init` and `MultipartUploadManager.init`
// — once per file, not per part — so reading UserDefaults here costs nothing measurable and
// needs no cache or change notification. A transfer already in flight keeps the level it
// started with, which is what we want: retuning mid-file would only confuse the part
// scheduler.
//
// Every hook takes the value the app had already chosen and may only raise it (`max`). The
// stock code picks its numbers from the file size — tiny files get 16 KB parts and 16-way
// parallelism, which is deliberately different tuning, not a lower setting to be corrected.
// Without the `max` the boost would slow those downloads down.
public enum TelewhiteSpeedBoost {
    public enum Level: Int32 {
        case off = 0
        case medium = 1
        case maximum = 2
    }

    public static var level: Level {
        let raw = (UserDefaults.standard.object(forKey: "telewhite.mods.speedBoost") as? NSNumber)?.int32Value ?? 0
        return Level(rawValue: raw) ?? .off
    }
}

// Bigger chunks only pay off once the file is large enough to need several of them; on a
// small file a single oversized request just delays the first byte. 1 MB is the ceiling the
// protocol allows: `upload.getFile` needs `1048576 % limit == 0`, and MultipartFetch relies
// on the same property when it trims a part to the next 1 MB boundary.
func telewhiteBoostedDownloadPartSize(_ value: Int64, fileSize: Int64?) -> Int64 {
    let smallFileThreshold: Int64 = 1 * 1024 * 1024
    if let fileSize = fileSize, fileSize <= smallFileThreshold {
        return value
    }
    switch TelewhiteSpeedBoost.level {
    case .off:
        return value
    case .medium:
        return value
    case .maximum:
        return max(value, 1024 * 1024)
    }
}

func telewhiteBoostedDownloadParallelParts(_ value: Int) -> Int {
    switch TelewhiteSpeedBoost.level {
    case .off:
        return value
    case .medium:
        return max(value, 12)
    case .maximum:
        return max(value, 16)
    }
}

// Upload parallelism is the stock 3 for ordinary media. Telegram itself already runs 30 for
// history import, so these numbers are inside the range the server is known to tolerate.
func telewhiteBoostedUploadParallelParts(_ value: Int) -> Int {
    switch TelewhiteSpeedBoost.level {
    case .off:
        return value
    case .medium:
        return max(value, 8)
    case .maximum:
        return max(value, 20)
    }
}

// `useLargerParts` doubles the part size to 256 KB, and only applies below the 10 MB mark
// where big parts have not kicked in yet.
func telewhiteBoostedUploadUseLargerParts(_ value: Bool) -> Bool {
    switch TelewhiteSpeedBoost.level {
    case .off:
        return value
    case .medium, .maximum:
        return true
    }
}
