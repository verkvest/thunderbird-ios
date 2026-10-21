# Thunderbird для iOS — личная сборка в TestFlight

Это личная сборка открытого [Thunderbird for iOS](https://github.com/thunderbird/thunderbird-ios) (лицензия MPL-2.0, файл `LICENSE`). Код взят с коммита `cb338c68151cc6ed5fc755bbc38d260a4c0ca8b7` от 15 октября 2026 года («Merge pull request #553 from Emifus/flag-implementations»). Как подтягивать следующие коммиты upstream — в конце и в [UPSTREAM.md](UPSTREAM.md).

Идентификатор приложения: **`com.verkvest.thunderbird`**. Сборка рассчитана на аккаунт Apple Developer **Individual** и на установку на свой iPhone через TestFlight. Mac для этого не нужен: компиляция идёт на macOS-раннере GitHub Actions.

Здесь нет Mac и нет ваших ключей Apple, поэтому приложение в этой среде **не компилировалось**. Готовый архив появится только после того, как репозиторий окажется на GitHub, секреты будут добавлены, и вы вручную запустите workflow **Personal TestFlight**.

## Что приложение умеет на этом коммите

Текст README у upstream отстаёт от кода: там написано, что чтение и отправка почты ещё впереди. По исходникам на импортированном коммите картина такая.

**Уже есть в интерфейсе**

- Экран приветствия и добавление учётной записи.
- Автонастройка через Thunderbird ISPDB (по адресу почты ищутся серверы).
- Ручные серверы IMAP, SMTP и JMAP, поле пароля, кнопка входа OAuth (открывается браузерный лист системы).
- Список «Входящие» для первой учётной записи: код вызывает загрузку INBOX по IMAP.

**Пока на экране примеры писем.** Если загрузка ничего не вернула (ошибка входа, пустой ящик, исключение), остаются демонстрационные письма. Над ними есть подпись, что это примеры, а не ваша почта. Реальные письма появляются, когда IMAP вернул хотя бы одно сообщение.

**Библиотеки, на которых это стоит**

- IMAP: соединение, команда `LOGIN` (обычный пароль), список ящиков, загрузка писем, флаги, idle. Это покрыто юнит-тестами upstream. Живые тесты против настоящих серверов в тестовом плане пропускаются.
- SMTP: клиент умеет и STARTTLS, и явный TLS (порт 465) и теперь получает хост и порт из автонастройки. Кнопка отправки на экране письма **ничего не вызывает**.
- JMAP: настройка для Fastmail есть. Загрузка входящих для JMAP в коде бросает ошибку, и остаются примеры.

Минимальная система — **iOS 18**. Подойдёт iPhone XR и новее. iPhone X и более старые эту сборку не установят.

## Gmail, OAuth и mail.ru

**Gmail через OAuth в этом коде почту не откроет.** Экран входа Google может пройти до конца и сохранить токен. Дальше IMAP входит командой `LOGIN` и подставляет токен как пароль. Gmail ждёт `AUTHENTICATE XOAUTH2`. Такого входа в проекте нет, дописывать его здесь не стали: это уже отдельная часть протокола, а не мелкая правка. Свой OAuth-клиент Google (шаги ниже) нужен, чтобы браузерный вход вообще совпал с вашим bundle id. На загрузку писем он не влияет, пока upstream не добавит XOAUTH2.

Запасной путь для Gmail — **пароль приложения**, если аккаунт Google его ещё выдаёт (обычно при включённой двухэтапной проверке). В автонастройке тип входа будет OAuth2, потому что ISPDB перечисляет его первым. В карточке учётной записи переключите аутентификацию на **Password** и вставьте пароль приложения. Обычный пароль от аккаунта Google IMAP не принимает.

**mail.ru, inbox.ru, bk.ru, list.ru** есть в ISPDB. Для IMAP указаны и OAuth2, и пароль; клиент выбирает OAuth2. Отдельного клиента OAuth для `o2.mail.ru` в приложении нет, поэтому кнопка «Войти» для mail.ru конфигурацию не найдёт. Переключите аутентификацию на **Password** и используйте пароль для внешнего приложения из настроек mail.ru, не основной пароль ящика. Сервер входящей почты: `imap.mail.ru`, порт 993, SSL. Чтение INBOX по паролю — как раз тот путь, который экран уже вызывает.

Исходящая почта mail.ru в ISPDB: `smtp.mail.ru`, порт 465 (SSL) и 587 (STARTTLS), пароль. Клиент SMTP эти параметры больше не отбрасывает, но кнопка «отправить» по-прежнему пустая.

**Чужие client id.** Для AOL, Fastmail, Google, Microsoft, Thundermail и Yahoo в коде лежат публичные идентификаторы upstream. Схемы ссылок оставлены `net.thunderbird.ios` и `msauth.net.thunderbird.ios`: именно их эти клиенты ждут в redirect. Bundle id при этом уже `com.verkvest.thunderbird`. Провайдер может отклонить вход, потому что приложение другое. Свой клиент имеет смысл заводить для Google (ниже). Для остальных провайдеров рабочий вариант на сегодня — пароль или пароль приложения, где сервер его разрешает.

Обратный вызов OAuth раньше слушал первую схему из Info.plist, а Microsoft открывает `msauth.` + эту схему. Теперь слушатель берёт схему из redirect URI. Схема `msauth.net.thunderbird.ios` в Info.plist зарегистрирована.

## Чего в приложении нет

- Отправка писем с экрана написания.
- Push-уведомления.
- Настоящий список папок с сервера: боковое меню есть, загрузка ящиков в него не подключена.
- Почта по JMAP во входящих.
- Учёт нескольких ящиков в списке писем: читается первая учётная запись.
- Манифест конфиденциальности (`PrivacyInfo.xcprivacy`). TestFlight может прислать предупреждение. На внутреннюю установку это часто не влияет.
- Флаг `ITSAppUsesNonExemptEncryption` уже стоит в `NO` (так было в upstream). Если App Store Connect всё же спросит про шифрование, для этого клиента ответ про стандартный HTTPS/TLS системы.

Приложение upstream прямо называет не готовым к повседневной почте. Эта сборка это не меняет: цель — поставить текущий код на телефон и посмотреть, что уже открывается.

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

Секреты `GOOGLE_OAUTH_CLIENT_ID` и `GOOGLE_OAUTH_URL_SCHEME` необязательны. Без них сборка ставится, а вход Google идёт со старым client id upstream.

### 5. Свой клиент Google — только если нужен браузерный вход

На загрузку писем Gmail это не влияет (см. выше). Имеет смысл, чтобы лист входа открывался от вашего приложения.

1. [Google Cloud Console](https://console.cloud.google.com/) → проект → APIs & Services → OAuth consent screen. Тип External, статус Testing, в тестовые пользователи добавьте свой Gmail.
2. Credentials → Create credentials → OAuth client ID → тип **iOS**.
3. Bundle ID: `com.verkvest.thunderbird`.
4. Client ID выглядит как `123456789-abcdef.apps.googleusercontent.com`.
5. Схема URL — перевёрнутый id: `com.googleusercontent.apps.123456789-abcdef`. Её же Google показывает как iOS URL scheme.
6. Эти две строки — секреты `GOOGLE_OAUTH_CLIENT_ID` и `GOOGLE_OAUTH_URL_SCHEME`.

Пересоберите TestFlight после добавления секретов: схема зашивается в приложение на этапе сборки.

Область доступа в коде — `https://mail.google.com/`. На экране согласия Google её нужно разрешить. Пока приложение в статусе Testing, войти могут только перечисленные тестовые пользователи.

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

Дальше в приложении: Get started → адрес почты → если автонастройка выбрала OAuth2, а вам нужен пароль, смените тип аутентификации на Password → Save. Потяните список вниз. Пока IMAP не вернул письма, на экране примеры.

## Обновление из upstream

```sh
git remote add upstream https://github.com/thunderbird/thunderbird-ios.git   # один раз
git fetch upstream
git merge upstream/main
```

При конфликтах оставляйте bundle id `com.verkvest.thunderbird`, правки в `fastlane/Fastfile`, `Thunderbird/Thunderbird/Info.plist` и workflow Personal TestFlight. Команда Mozilla в Debug (`BUMSKVQ3D9`) в эту сборку не возвращайте: у раннера нет их сертификата.

## Что осталось на вас

1. Завести репозиторий на GitHub и запушить `main`.
2. Выпустить ключ API Admin и скачать `.p8`.
3. Запустить `scripts/bootstrap_signing.py` и перенести значения в секреты Actions.
4. Дождаться зелёного **Xcode Build** (проверка компиляции без подписи).
5. Запустить **Personal TestFlight** и поставить сборку из TestFlight на iPhone.

Пока нет ключа API, шага 5 не существует: подписать билд чужим сертификатом Mozilla нельзя, и секреты в репозиторий не кладутся.
