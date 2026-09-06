#!/usr/bin/env python3
"""One-shot, hash-guarded source edit; removed by the preparation workflow."""
import hashlib
from pathlib import Path

path = Path('submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoProfileItems.swift')
raw = path.read_bytes()
blob_sha = hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest()
if blob_sha != '0c85efc759109c3e7a22d5be280b720e59186b67':
    raise SystemExit('Profile source changed; refusing to overwrite it. Refresh the patch first.')
text = raw.decode('utf-8')
start_marker = '            // Вычислить примерную дату регистрации из User ID'
end_marker = '\r\n        }\r\n\r\n        if let cachedData = data.cachedData as? CachedUserData {'
assert text.count(start_marker) == 1
start = text.index(start_marker)
end = text.index(end_marker, start)
replacement = '''            items[currentPeerInfoSection]!.append(telewhiteRegistrationDateItem(
                id: ItemRegistrationDate,
                peerId: user.id,
                telegramMonth: (data.cachedData as? CachedUserData)?.peerStatusSettings?.registrationDate,
                context: context,
                presentationData: presentationData,
                interaction: interaction
            ))'''.replace('\n', '\r\n')
updated = text[:start] + replacement + text[end:]
assert '\ufffd' not in updated
assert 'let dataset:' not in updated
assert updated.count('telewhiteRegistrationDateItem(') == 1
assert updated[:start] == text[:start]
assert updated[start + len(replacement):] == text[end:]
assert updated.count('\n') == updated.count('\r\n')
path.write_bytes(updated.encode('utf-8'))
print('Applied narrow profile patch; unrelated content and CRLF preserved.')
