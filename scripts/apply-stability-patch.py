#!/usr/bin/env python3
"""One-shot narrow edits, guarded against changing a different source version."""
import hashlib
from pathlib import Path


def patch(path, expected, edits):
    target = Path(path)
    raw = target.read_bytes()
    sha = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
    if sha != expected:
        raise SystemExit(f'{path}: source changed; refusing to overwrite it')
    text = raw.decode('utf-8')
    for old, new in edits:
        if text.count(old) != 1:
            raise SystemExit(f'{path}: patch anchor is not unique')
        text = text.replace(old, new, 1)
    assert '\ufffd' not in text
    target.write_bytes(text.encode('utf-8'))
    print('Patched', path)


patch('submodules/TelegramPresentationData/Sources/TelewhiteSettingsIcons.swift',
      '4822c60f47ebcad1975c2c4b20a72ef2414f0a36', [
    ('    let cacheKey = "\\(name)-\\(color.argb)-\\(variant.rawValue)" as NSString',
     '    let cacheKey = "\\(name)-\\(color.argb)-\\(variant.rawValue)-\\(size.width)x\\(size.height)" as NSString'),
    ('                chatListDensity == 1, chatListDensity == 2, chatListDensity == 3\n',
     '                chatListDensity == 1, chatListDensity == 2, chatListDensity == 3,\n                variant == 4, variant == 5, variant == 6\n')
])
patch('submodules/SettingsUI/Sources/TelewhiteModsController.swift',
      '7dfdd9762dd6ff174ba321e14cf1147153a8314b', [
    ('private var telewhiteMenuIconCache: [String: UIImage] = [:]',
     'private let telewhiteMenuIconCache: NSCache<NSString, UIImage> = {\n    let cache = NSCache<NSString, UIImage>()\n    cache.countLimit = 100\n    return cache\n}()'),
    ('    let cacheKey = "\\(icon.rawValue)-\\(color.argb)"\n    if let cached = telewhiteMenuIconCache[cacheKey] {',
     '    let cacheKey = "\\(icon.rawValue)-\\(color.argb)" as NSString\n    if let cached = telewhiteMenuIconCache.object(forKey: cacheKey) {'),
    ('    telewhiteMenuIconCache[cacheKey] = image',
     '    telewhiteMenuIconCache.setObject(image, forKey: cacheKey)')
])
