# Telegram iOS Fork Setup

Эта папка уже подключена к официальному `TelegramMessenger/Telegram-iOS` как `upstream`.
Главная идея: код пишем на Windows, а IPA собираем в GitHub Actions на macOS runner.

## 1. Telegram API данные

Получить свои данные нужно на https://my.telegram.org/apps:

- `api_id`
- `api_hash`

Telegram официально пишет, что примерный API id из исходников подходит только для тестов, а для своего клиента нужно получить свой `api_id`.
Не коммить эти значения в репозиторий.

## 2. Apple данные

Для установки на iPhone нужен не только сертификат, но и provisioning profiles.
Если подписываешь сам внешним инструментом, GitHub Actions может собрать IPA с временной fake-подписью, а финальная подпись будет уже вне CI.
Для первого билда держим конфиг простым: `enable_siri=false`, `enable_icloud=false`, `is_appstore_build=false`.

Нужны:

- `APPLE_TEAM_ID`
- base bundle id, например `com.yourname.tgfork`
- `.p12` сертификат с приватным ключом
- provisioning profiles для bundle id приложения и расширений

Эти Apple данные нужны для твоей финальной подписи. В текущий GitHub Actions workflow их добавлять не надо.

Ожидаемые bundle id:

```text
com.yourname.tgfork
com.yourname.tgfork.NotificationContent
com.yourname.tgfork.NotificationService
com.yourname.tgfork.Share
com.yourname.tgfork.Widget
com.yourname.tgfork.BroadcastUpload
com.yourname.tgfork.watchkitapp
com.yourname.tgfork.watchkitapp.watchkitextension
```

Если позже включим Siri, добавится:

```text
com.yourname.tgfork.SiriIntents
```

Имена файлов `.mobileprovision` могут быть любыми: сборочный скрипт сам разложит их по нужным target names.
Главный profile для `com.yourname.tgfork` должен включать push entitlement `aps-environment`.

## 3. GitHub Secrets

В GitHub repo открой `Settings -> Secrets and variables -> Actions -> New repository secret`.

Добавь:

```text
TG_API_ID
TG_API_HASH
```

Если хочешь, чтобы GitHub сразу подписывал настоящим Apple-сертификатом, тогда отдельно добавим Apple secrets.
Сейчас workflow рассчитан на внешний re-sign после скачивания IPA.
GitHub build использует временный bundle id `ph.telegra.Telegraph`, потому что встроенные fake provisioning profiles Telegram привязаны к нему.
При финальной подписи внешним инструментом задай свой bundle id, например `com.yourname.telewhite`.

На Windows удобно сделать base64 так:

```powershell
Compress-Archive -Path C:\path\certs\* -DestinationPath certs.zip
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certs.zip")) | Set-Content certs.b64

Compress-Archive -Path C:\path\profiles\* -DestinationPath profiles.zip
[Convert]::ToBase64String([IO.File]::ReadAllBytes("profiles.zip")) | Set-Content profiles.b64
```

## 4. Запуск сборки

После push в GitHub открой:

```text
Actions -> iOS IPA -> Run workflow
```

Поля `app_name` и `url_scheme` можно оставить по умолчанию:

```text
app_name: Telewhite
url_scheme: telewhite
```

В artifacts появится `Telewhite-fake-signed.ipa`. Перед установкой на обычный iPhone его нужно переподписать твоим сертификатом/provisioning profile и своим bundle id.

## 5. Локальные файлы

Для локальных экспериментов можно скопировать:

```text
build-system/fork-configuration.example.json
```

в:

```text
build-system/fork-configuration.json
```

`fork-configuration.json`, `.p12` и `.mobileprovision` игнорируются git-ом.
