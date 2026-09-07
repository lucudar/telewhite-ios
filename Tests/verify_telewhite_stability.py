#!/usr/bin/env python3
"""Source-level regression checks, not a substitute for device crash testing."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
profile = root / 'submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources'
item = (profile / 'TelewhiteRegistrationDateItem.swift').read_text()
parser = (profile / 'TelewhiteRegistrationDate.swift').read_text()
for token in ['ayugram', 'ayuResponse', 'regdate ', 'requestChatContextResults', 'resolvePeerByName', 'MetaDisposable', 'NSCache', 'JSONSerialization', 'textAlertController']:
    assert token.lower() not in (item + parser).lower(), f'Registration lookup must stay local: {token}'
assert 'action: nil' in item and 'longTapAction: nil' in item
assert 'TelewhiteRegistrationDateValue.telegramMonth(telegramMonth)' in item

icons = (root / 'submodules/TelegramPresentationData/Sources/TelewhiteSettingsIcons.swift').read_text()
flags = icons.split('public func telewhiteThemeModsUpdated()', 1)[1]
encoded = [int(value) for value in re.findall(r'variant == (\d+)', flags)]
vectors = {tuple(value == bit for bit in encoded) for value in range(7)}
assert len(vectors) == 7, 'Some icon styles cannot trigger distinctUntilChanged'
key = next(line for line in icons.splitlines() if 'let cacheKey' in line and 'variant.rawValue' in line)
assert '\\(size.width)' in key and '\\(size.height)' in key, 'Icon cache must separate different sizes'

menu = (root / 'submodules/SettingsUI/Sources/TelewhiteModsController.swift').read_text()
assert 'telewhiteMenuIconCache: NSCache<NSString, UIImage>' in menu
assert 'telewhiteMenuIconCache[cacheKey]' not in menu
keys = re.findall(r'static let \w+ = "(telewhite\.mods\.[^"]+)"', menu)
assert len(keys) == len(set(keys)), 'Duplicate persisted settings keys'

# Validate maximal row order; hiding conditional rows preserves this order.
clean = re.sub(r'//[^\n]*', '', menu)
stable = clean.split('    var stableId: Int32 {', 1)[1].split('    static func <', 1)[0]
ids = dict(re.findall(r'case(?: let)? \.(\w+)[^\n]*:\s*return ([^\n]+)', stable))
entries = clean.split('private func telewhiteModsEntries(', 1)[1].split('public func telewhiteModsController(', 1)[0]
tabs = list(re.finditer(r'^    case \.(\w+):', entries, re.M))
for index, tab in enumerate(tabs):
    body = entries[tab.end():tabs[index + 1].start() if index + 1 < len(tabs) else len(entries)]
    values = []
    for row in re.finditer(r'entries\.append\(\.(\w+)\(([^,\n]*)', body):
        name, argument = row.group(1), row.group(2).strip()
        expression = ids[name].strip()
        if name == 'sectionHeader':
            values.append(int(argument))
        elif 'index' in expression:
            base = int(expression.split('+')[0].strip())
            if argument.isdigit():
                indexes = [int(argument)]
            elif name == 'translationLanguageOption':
                # Terminal section: any finite enumerated language list remains
                # strictly increasing because its ID is 61 + index.
                indexes = [0, 1]
            else:
                loops = list(re.finditer(r'for \(index, \w+\) in \[(.*?)\]\.enumerated\(\)', body[:row.start()]))
                assert loops, f'Unrecognized dynamic row: {name}'
                count = len(loops[-1].group(1).split(','))
                indexes = range(count)
            values.extend(base + value for value in indexes)
        else:
            values.append(int(expression))
    assert all(a < b for a, b in zip(values, values[1:])), f'Unordered/duplicate rows in {tab.group(1)}: {values}'
    print('PASS menu order:', tab.group(1))
for text in [item, parser, icons, menu]:
    assert '\ufffd' not in text, 'Invalid replacement character in source'
print('PASS: local-only registration, 7 distinct styles, size-aware/bounded caches, settings keys and menu ordering')
