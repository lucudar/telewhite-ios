# Дата регистрации в Telewhite

Интеграция с AyuGram удалена после сообщения о нестабильности. Причина конкретного вылета без crash-log не установлена.

- Строка остаётся под ID и подчиняется существующему переключателю показа ID пользователей.
- Используется только месяц, уже полученный от Telegram: `CachedUserData.peerStatusSettings.registrationDate` (`MM.yyyy`).
- Показываются месяц и год, не выдуманный точный день. Если Telegram не передал дату или формат неверен — «Нет данных».
- Нет внешних запросов, бота, JSON-ответов, кэша результатов, кнопок запроса, окон подтверждения и асинхронных обновлений строки.
- Старая таблица ID → дата не возвращается. ID не используется для определения возраста аккаунта.
- Неверные месяцы, годы до 2013 и будущие месяцы отклоняются. Форматирование использует UTC и не зависит от смены часового пояса устройства.

## Проверка

```sh
SOURCES=submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources
xcrun swiftc -warnings-as-errors -parse-as-library \
  "$SOURCES/TelewhiteRegistrationDate.swift" Tests/TelewhiteRegistrationDateTests.swift \
  -o /tmp/telewhite-registration-tests
/tmp/telewhite-registration-tests
python3 Tests/verify_telewhite_stability.py
```

Foundation-тесты проверяют настоящий Swift-парсер; Python-проверки — контракты исходника, а не работу UI. Полная сборка и проверка на iPhone нужны отдельно.
