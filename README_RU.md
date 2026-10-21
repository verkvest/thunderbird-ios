# Thunderbird для iOS — личная сборка в TestFlight

Это личная сборка открытого [Thunderbird for iOS](https://github.com/thunderbird/thunderbird-ios) (лицензия MPL-2.0, файл `LICENSE`). Код взят с коммита `cb338c68151cc6ed5fc755bbc38d260a4c0ca8b7` от 15 октября 2026 года («Merge pull request #553 from Emifus/flag-implementations»). Как подтягивать следующие коммиты upstream — в конце и в [UPSTREAM.md](UPSTREAM.md).

Идентификатор приложения: **`com.verkvest.thunderbird`**. Сборка рассчитана на аккаунт Apple Developer **Individual** и на установку на свой iPhone через TestFlight. Mac для этого не нужен: компиляция идёт на macOS-раннере GitHub Actions.

Здесь нет Mac и нет ваших ключей Apple, поэтому приложение в этой среде **не компилировалось**. Готовый архив появится только после того, как репозиторий окажется на GitHub, секреты будут добавлены, и вы вручную запустите workflow **Personal TestFlight**.

## Что приложение умеет

В этой среде нет Mac, поэтому код **не компилировался и не запускался**. Юнит-тесты написаны для Swift Testing на раннере GitHub; на Linux они не выполнялись. Первая настоящая сборка — workflow **Xcode Build**.

Список писем — это ящик, а не примеры.

- Несколько учётных записей. Меню переключает один ящик. Пункт «Все входящие» склеивает их. Каждая запись грузится отдельно: сбой одной не стирает остальные. В строке ошибки будет имя этой записи.
- Пароль и пароль приложения. Если ISPDB ставит OAuth2 первым, а клиента для этого сервера в приложении нет (mail.ru, list.ru, bk.ru, inbox.ru), настройка сама переключает тип входа на **Password**.
- Папки приходят командой IMAP `LIST` и открываются из бокового меню.
- Открытое письмо выбирает ящик и скачивает тело по UID.
- Кнопка **Отправить** говорит с SMTP. Порт 465 — сразу TLS. Порт 587 — STARTTLS, затем второй `EHLO`, затем вход. Вход: `AUTH PLAIN`, `AUTH LOGIN` или `AUTH XOAUTH2`. Ответ, ответ всем и пересылка заполняют черновик.
- После успешной отправки письмо кладётся в «Отправленные» командой IMAP `APPEND` (узнаются Sent, Sent Mail, Отправленные, Enviados и похожие имена). Для Gmail (`smtp.gmail.com`) этот шаг пропускается: Gmail сам кладёт копию в Sent. Запись `APPEND` на живом сервере не проверялась. Клиент отдаёт текст письма и ждёт ответ `OK`. Если сервер и автомат NIOIMAP разойдутся на приглашении `+`, копия в «Отправленных» может зависнуть, хотя SMTP письмо уже принял.
- **Gmail через OAuth.** IMAP входит командой `AUTHENTICATE XOAUTH2`, SMTP — `AUTH XOAUTH2`, с токеном Google. Строка SASL: `user={почта}\u{1}auth=Bearer {токен}\u{1}\u{1}`. Просроченный токен обновляется по HTTPS до соединения, новый токен пишется только в Связку ключей. Пароли и токены в кэш писем не попадают.
- Чтобы этот токен подходил к bundle `com.verkvest.thunderbird`, нужен свой клиент Google типа **iOS**. Область в коде — `https://mail.google.com/`. Без своего клиента остаётся пароль приложения Gmail и тип входа Password. Чужие client id upstream для AOL, Fastmail, Microsoft, Thundermail и Yahoo на месте. Их redirect по-прежнему `net.thunderbird.ios` и `msauth.net.thunderbird.ios`.
- Входящие по JMAP по-прежнему бросают ошибку. Настройка Fastmail не менялась.

### iPhone

- При запуске сначала показываются сохранённые заголовки, затем идёт обновление. Список ленивый. Страница — 40 заголовков. Последняя строка подгружает следующую. Тело письма сохраняется после открытия. Кэш — JSON в Application Support, без паролей и токенов.
- Смахивание: в архив, удалить, прочитано или не прочитано, флажок. Потянуть вниз — обновить. Цвета системные, поэтому есть тёмная тема. Размеры текста следуют Dynamic Type. На действие смахивания есть короткое тактильное подтверждение.
- Вложения отдаются в системный лист «Поделиться».
- В настройках есть блокировка Face ID (если Face ID нет, сработает код-пароль устройства) и фоновая проверка почты. Задача `com.verkvest.thunderbird.refresh` делает короткий IMAP `STATUS` и отключается. IDLE в фоне нет. IDLE работает только когда приложение на экране и выбран один ящик, не «все входящие». В режиме экономии энергии новая фоновая проверка не ставится. Если непрочитанных стало больше, приходит местное уведомление.
- Боковое меню не шире 320 пунктов. На узком экране поля письма компактнее. Новые строки интерфейса есть на английском, русском и испанском. Остальные языки берут английский текст.

Минимальная система — **iOS 18**. Подойдёт iPhone XR и новее, в том числе узкие экраны вроде SE. iPhone X и более старые эту сборку не установят.

## Чего по-прежнему нет

- Настоящих push от сервера. Фон — это короткая проверка по расписанию системы, не мгновенное письмо.
- Почты по JMAP во входящих.
- Манифеста конфиденциальности (`PrivacyInfo.xcprivacy`). TestFlight может прислать предупреждение. На внутреннюю установку это часто не влияет.
- Флаг `ITSAppUsesNonExemptEncryption` уже стоит в `NO` (так было в upstream). Если App Store Connect спросит про шифрование, для этого клиента ответ про стандартный HTTPS/TLS системы.

Это по-прежнему личная сборка поверх кода, который upstream не называет готовым продуктом. На телефон она ставится, чтобы читать и отправлять свою почту, а не чтобы заменить стабильный клиент.

## Почему GitHub Actions

Сборка идёт на **GitHub Actions**, раннер `macos-26`, Xcode **26.4**, выгрузка через **fastlane** (`lane beta`) в App Store Connect. Так уже устроен upstream (`shippable-builds.yml`), поэтому следующие слияния с их репозиторием задевают меньше чужой инфраструктуры. Отдельный аккаунт Codemagic не нужен. Xcode Cloud входит в плату за Apple Developer (25 часов в месяц) и тоже обходится без Mac, но его сценарии живут в App Store Connect и расходятся с тем, что поддерживает upstream.

Секреты подписи в git не попадают. Их читает только workflow **Personal TestFlight**.

### Сколько это стоит

Цифры с документации GitHub Actions на октябрь 2026:

| Где живёт репозиторий | macOS-минуты |
| --- | --- |
| Публичный | стандартные раннеры, включая `macos-26`, бесплатны |
| Приватный, план Free | 2000 минут в месяц на все системы. Минута macOS стоит $0.062, минута Linux — $0.006. Квота тратится на macOS примерно в 10 раз быстрее, то есть около **200 минут macOS**. Дальше без привязанной карты сборки остановятся |

Полный прогон с симулятором легко занимает 30–60 минут. На каждый push в `main` ещё стартует **Swift Format** (тоже macOS). Пока репозиторий приватный, имеет смысл не пушить лишний раз. Публичный репозиторий для кода под MPL эти минуты не тратит. Workflow **Personal TestFlight** по расписанию не запускается, только вручную, и по умолчанию тесты пропускает, чтобы не сжигать минуты второй раз.

Программа **Apple Developer Program** (Individual) оплачивается отдельно. На сайте Apple для США указано $99 в год. Без неё TestFlight недоступен. В эту плату раннеры GitHub не входят.

Чужой workflow `Shippable Builds` сам не соберёт форк: он включён только для репозитория `thunderbird/thunderbird-ios`. Еженедельный CodeQL на `macos-26` от upstream может тратить минуты; его можно выключить во вкладке Actions, если он не нужен.

## Что сделать вам

Нужны: аккаунт Apple Developer Individual, аккаунт GitHub, iPhone на iOS 18 с приложением TestFlight, и любой компьютер с Python 3 и `openssl` (Linux подходит). Mac не нужен.

### 1. Репозиторий на GitHub

Workflow лежит в `.github/workflows/` и выполняется только на GitHub. Если этот проект ещё не на GitHub, создайте там репозиторий и запушьте ветку `main`. Для бесплатных macOS-минут оставьте репозиторий **публичным**.

Проверка без секретов: после push откройте Actions → **Xcode Build**. Это симулятор, анализ и неподписанный архив. Зелёная галочка значит, что проект собирается на Xcode 26.4. Красная — откройте лог; типичные причины: у аккаунта кончились macOS-минуты или раннер `macos-26` ещё не доступен вашему аккаунту.

### 2. Ключ App Store Connect API

1. Войдите на [appstoreconnect.apple.com](https://appstoreconnect.apple.com) под тем же Apple ID, что и Developer.
2. Users and Access → Integrations → App Store Connect API (у Individual пункт может называться Keys).
3. Сгенерируйте ключ с доступом **Admin**. Роли слабее не создают сертификаты.
4. Скачайте файл `AuthKey_XXXXXXXXXX.p8`. Apple отдаёт его один раз. Храните у себя, в git не кладите.
5. Запишите **Key ID** (10 знаков в имени файла) и **Issuer ID** (UUID на той же странице).
6. Team ID — 10 символов на [developer.apple.com/account](https://developer.apple.com/account) в Membership details.

### 3. Сертификат, профиль и запись приложения без Mac

В каталоге репозитория:

```sh
export APP_STORE_CONNECT_KEY_ID="XXXXXXXXXX"
export APP_STORE_CONNECT_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export APP_STORE_CONNECT_KEY_PATH="$HOME/AuthKey_XXXXXXXXXX.p8"
export APPLE_TEAM_ID="XXXXXXXXXX"
export P12_PASSWORD="длинный-пароль-который-вы-запомните"
python3 scripts/bootstrap_signing.py
```

Скрипт через API:

- регистрирует bundle id `com.verkvest.thunderbird`, если его ещё нет;
- выпускает сертификат Apple Distribution (нужен новый: закрытый ключ уже существующего сертификата Apple не отдаёт);
- делает профиль App Store `verkvest-thunderbird-appstore`;
- создаёт приложение в App Store Connect с именем **Thunderbird Verkvest** и SKU `verkvest-thunderbird-ios`.

Имя на витрине должно быть уникальным во всём App Store. «Thunderbird» занято. Если «Thunderbird Verkvest» тоже отклонят, запустите снова с другим именем:

```sh
python3 scripts/bootstrap_signing.py --app-name "Почта Verkvest"
```

Повторный запуск, когда `signing-out/distribution.p12` уже есть, останавливается, чтобы не плодить сертификаты. У аккаунта обычно не больше двух distribution-сертификатов. Если скрипт напишет, что оба слота заняты, отзовите ненужный на developer.apple.com → Certificates и запустите снова. Отзыв ломает приложения, подписанные тем сертификатом.

Проверка без сети к Apple: `python3 scripts/bootstrap_signing.py --self-test`.

Результат в каталоге `signing-out/` (он в `.gitignore`):

- `distribution.p12`
- `distribution.mobileprovision`
- `github-secrets.txt` — готовые значения для GitHub, включая base64

Файл с секретами никому не отправляйте и не коммитьте. После переноса в GitHub каталог `signing-out/` можно удалить. `.p8` храните отдельно: он нужен, если профиль придётся перевыпустить.

### 4. Секреты GitHub

Репозиторий → Settings → Secrets and variables → Actions → New repository secret. Имена строго такие (окружение `thunderbird_release` от upstream не используется):

| Секрет | Откуда |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY` | base64 файла `.p8` из `github-secrets.txt` |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APPLE_TEAM_ID` | Team ID |
| `APPLE_CERTIFICATE_P12` | base64 `.p12` |
| `APPLE_CERTIFICATE_PASSWORD` | пароль `P12_PASSWORD` |
| `APP_STORE_PROVISIONING_PROFILE` | base64 профиля |

Секреты `GOOGLE_OAUTH_CLIENT_ID` и `GOOGLE_OAUTH_URL_SCHEME` необязательны для сборки. Без них вход Google идёт со старым client id upstream, и Gmail может отклонить IMAP. Для своих четырёх ящиков Gmail эти секреты нужны. Пароль приложения работает и без них.

### 5. Свой клиент Google — только если нужен браузерный вход

Этот клиент как раз открывает почту: токен уходит в IMAP и SMTP как XOAUTH2. Без него остаётся пароль приложения.

1. [Google Cloud Console](https://console.cloud.google.com/) → проект → APIs & Services → OAuth consent screen. Тип External, статус Testing, в тестовые пользователи добавьте все свои адреса Gmail.
2. Credentials → Create credentials → OAuth client ID → тип **iOS**.
3. Bundle ID: `com.verkvest.thunderbird`.
4. Client ID выглядит как `123456789-abcdef.apps.googleusercontent.com`.
5. Схема URL — перевёрнутый id: `com.googleusercontent.apps.123456789-abcdef`. Её же Google показывает как iOS URL scheme.
6. Эти две строки — секреты `GOOGLE_OAUTH_CLIENT_ID` и `GOOGLE_OAUTH_URL_SCHEME`.

Пересоберите TestFlight после добавления секретов: схема зашивается в приложение на этапе сборки.

Область доступа в коде — `https://mail.google.com/`. На экране согласия Google её нужно разрешить. Пока приложение в статусе Testing, войти могут только перечисленные тестовые пользователи. Четыре ящика Gmail — четыре тестовых пользователя, один и тот же iOS-клиент.

### 6. Запуск сборки в TestFlight

GitHub → Actions → **Personal TestFlight** → Run workflow.

- Version: `1.0` (можно оставить).
- Skip tests: включено по умолчанию. Снимите галочку, если хотите гонять симулятор ещё и перед выгрузкой.
- Notify testers: выключено. Внутреннее тестирование этого не требует.

Если какого-то секрета нет, шаг «Check required secrets» остановится и назовёт имя. Значения в лог не пишутся.

Дальше fastlane поднимает номер сборки (время UTC `YYYYMMDDHHmm`), подписывает Release и заливает билд. Обработка на стороне Apple занимает от нескольких минут до часа. Письмо от App Store Connect придёт на почту аккаунта разработчика.

Первый билд иногда упирается в отсутствие записи приложения. Скрипт из шага 3 её создаёт. Если вы запускали его с `--skip-app`, создайте приложение сами: App Store Connect → Apps → New App → iOS, bundle id `com.verkvest.thunderbird`, уникальное имя, SKU любой свободный.

Внутренним тестировщиком Individual-аккаунта вы являетесь сами. Отдельная группа внешних тестировщиков для своего телефона не нужна.

### 7. Установка на iPhone

1. На iPhone откройте App Store и установите **TestFlight** от Apple.
2. На телефоне войдите в тот же Apple ID, что и в Developer, либо примите приглашение, если добавите другой Apple ID во внутренние тестировщики (App Store Connect → приложение → TestFlight → Internal Testing).
3. Откройте TestFlight. Сборка появится после обработки. Нажмите Install.
4. На домашнем экране имя будет Thunderbird (имя продукта). Иконка и название витрины «Thunderbird Verkvest» — это имя в App Store Connect, на иконке может отображаться имя из бандла.

Если iOS ниже 18, TestFlight покажет, что устройство не поддерживается.

Дальше в приложении: Начать → адрес почты. Для Gmail с собственным клиентом — «Войти». Для mail.ru и для Gmail с паролем приложения — тип входа Password, затем Save. Для mail.ru, list.ru, bk.ru и inbox.ru тип Password выставится сам, если клиента OAuth нет. Потяните список вниз. Пустой ящик так и останется пустым: примеров писем на экране больше нет. Папки — в боковом меню. Новое письмо — кнопка карандаша. Face ID и фоновая проверка — в Настройках. Язык интерфейса берётся из языка iPhone (русский, испанский или английский).

## Обновление из upstream

```sh
git remote add upstream https://github.com/thunderbird/thunderbird-ios.git   # один раз
git fetch upstream
git merge upstream/main
```

При конфликтах оставляйте bundle id `com.verkvest.thunderbird`, правки в `fastlane/Fastfile`, `Thunderbird/Thunderbird/Info.plist` и workflow Personal TestFlight. Команда Mozilla в Debug (`BUMSKVQ3D9`) в эту сборку не возвращайте: у раннера нет их сертификата.

## Что осталось на вас

1. Завести репозиторий на GitHub и запушить `main`. Сейчас удалённый `origin` этого окружения — не GitHub, а workflow запускается только там.
2. Выпустить ключ API Admin и скачать `.p8`.
3. Запустить `scripts/bootstrap_signing.py` и перенести значения в секреты Actions.
4. Для Gmail по OAuth создать iOS-клиент Google (шаг выше) и положить два секрета. Для пароля приложения этот шаг не нужен.
5. Дождаться зелёного **Xcode Build**. Пока его нет, считать проект собранным нельзя: здесь его не компилировали.
6. Запустить **Personal TestFlight** и поставить сборку из TestFlight на iPhone.

Пока нет ключа API, шага 6 не существует: подписать билд чужим сертификатом Mozilla нельзя, и секреты в репозиторий не кладутся. Пароли почты в git тоже не кладутся: они живут в Связке ключей на телефоне.
