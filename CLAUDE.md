# dem - Nicotine Tracker iOS App

## Обзор проекта
iOS приложение для отслеживания потребления никотина (сигареты, IQOS, вейп). Помогает пользователям контролировать привычку, видеть статистику и экономию.

## Технологии
- **SwiftUI** (iOS 17+)
- **Supabase** (бэкенд, авторизация, база данных)
- **StoreKit 2** (подписки, In-App Purchases)
- **Swift Package Manager** (зависимости)
- **MVVM архитектура**

## Структура проекта

```
dem/
├── demApp.swift              # Точка входа, роутинг авторизации, показ paywall
├── Models/
│   ├── Profile.swift         # Профиль пользователя + поля подписки
│   ├── SmokingLog.swift      # Запись о курении + TriggerType enum
│   ├── Craving.swift         # Тяга (не реализовано)
│   └── Achievement.swift     # Достижения (не реализовано)
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── OnboardingViewModel.swift
│   ├── HomeViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── StatsViewModel.swift
│   └── ProfileViewModel.swift
├── Views/
│   ├── Auth/
│   │   └── AuthView.swift    # Sign in with Apple + логотип DemLogo
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift
│   │   ├── NameStep.swift        # Шаг 1: Имя
│   │   ├── ProductTypeStep.swift # Шаг 2: Тип продукта
│   │   ├── BaselineStep.swift    # Шаг 3: Потребление
│   │   ├── GoalStep.swift        # Шаг 4: Цель
│   │   ├── ProgramTypeStep.swift # Шаг 5: Целевое количество (reduce)
│   │   └── DurationStep.swift    # Шаг 6: Длительность программы
│   ├── Home/
│   │   ├── HomeView.swift        # Хедер с логотипом DemLogo
│   │   ├── TimerPillView.swift
│   │   ├── BigLogButton.swift
│   │   └── TriggerSelectionView.swift
│   ├── History/
│   │   └── HistoryView.swift
│   ├── Stats/
│   │   └── StatsView.swift
│   ├── Profile/
│   │   └── ProfileView.swift     # + секция подписки с управлением
│   ├── Paywall/
│   │   ├── PaywallView.swift     # Экран подписки с планами
│   │   ├── TermsView.swift       # Условия использования
│   │   └── PrivacyPolicyView.swift # Политика конфиденциальности
│   └── Components/
│       ├── MainTabView.swift
│       ├── DesignSystem.swift    # Цвета, шрифты, Layout
│       ├── StatCard.swift
│       ├── ActivityChart.swift
│       ├── PressEffectModifier.swift
│       └── LegalDocumentView.swift
├── Services/
│   ├── SupabaseManager.swift     # Singleton для работы с Supabase
│   ├── CacheManager.swift        # Локальный кеш (UserDefaults)
│   ├── HapticManager.swift       # Вибрация
│   ├── NotificationManager.swift # Push-уведомления
│   ├── LanguageManager.swift     # Локализация (ru/en/kk)
│   ├── SubscriptionManager.swift # StoreKit 2, подписки
│   └── ProgramCalculator.swift   # Расчёт лимитов программы снижения
├── Resources/
│   ├── ru.lproj/Localizable.strings  # Русский
│   ├── en.lproj/Localizable.strings  # English
│   └── kk.lproj/Localizable.strings  # Қазақша
├── Assets.xcassets/
│   ├── AppIcon.appiconset/       # Иконка приложения (dem_breath_v3.png)
│   ├── DemLogo.imageset/         # Логотип для использования в UI
│   └── AccentColor.colorset/
└── Config/
    └── Supabase.swift            # URL, ключи, названия таблиц/колонок

docs/                             # Документация для App Store
├── privacy-policy.html           # Политика конфиденциальности
├── terms-of-service.html         # Условия использования
└── app-store-metadata.md         # Метаданные для App Store Connect
```

## Подписки (StoreKit 2)

### Product IDs (App Store Connect)
```swift
enum ProductID: String, CaseIterable {
    case monthly = "com.dem.monthly"       // $4.99/мес
    case semiannual = "com.dem.halfyear"   // $24.99/6 мес (-17%)
    case annual = "com.dem.yearly"         // $49.99/год
}
```

### SubscriptionManager.swift
- Загрузка продуктов из App Store
- Покупка подписки
- Восстановление покупок
- Проверка статуса подписки
- 14-дневный триал (локальный, через UserDefaults)

### PaywallView.swift
- Показывается при первом запуске после онбординга
- Прогресс-кольцо с днями использования
- Виджет статистики (сигарет меньше, сэкономлено)
- 3 плана подписки (рекомендуемый - 6 месяцев)
- Кнопка "Восстановить покупки"
- Ссылки на Terms и Privacy

### Где показывается Paywall
1. `demApp.swift` - после онбординга, если нет подписки/триала
2. `ProfileView.swift` - секция "Подписка" с кнопкой управления

## Локализация

### Поддерживаемые языки
- Русский (ru) - основной
- English (en)
- Қазақша (kk)

### Как работает
- `LanguageManager.swift` - синглтон с текущим языком
- `L.Section.key` - доступ к локализованным строкам
- `"key".localized` - extension для String
- Язык меняется в ProfileView → languageSection

### Структура L (LanguageManager)
```swift
L.Common.ok, L.Common.cancel, L.Common.save...
L.Auth.welcomeTitle, L.Auth.welcomeSubtitle...
L.Home.today, L.Home.yesterday...
L.Profile.subscription, L.Profile.manageSubscription...
L.Paywall.startTrial, L.Paywall.bestChoice...
L.Notifications.eveningTitle...
```

## Ассеты

### Логотип (dem_breath_v3.png)
- Концентрические круги с оранжевым центром
- Размер: 1024x1024
- Используется как:
  - `AppIcon` - иконка приложения и уведомлений
  - `DemLogo` - в UI (AuthView 120x120, HomeView header 32x32)

### Использование в коде
```swift
Image("DemLogo")
    .resizable()
    .scaledToFit()
    .frame(width: 32, height: 32)
```

## База данных Supabase

### Таблица `profiles`
```sql
- id (uuid, PK, = auth.uid())
- name (text, nullable)
- product_type (text: cigarette/iqos/vape/mix)
- baseline_per_day (int, default 10)
- pack_price (int, default 250)
- sticks_in_pack (int, default 20)
- goal_type (text: quit/reduce/observe)
- goal_per_day (int, nullable)
- goal_date (date, nullable)
- onboarding_done (bool, default false)
- subscription_status (text, nullable)      # active/expired/none
- subscription_product_id (text, nullable)  # com.dem.monthly etc
- subscription_expires_at (timestamptz, nullable)
- trial_started_at (timestamptz, nullable)
- created_at (timestamptz)
- updated_at (timestamptz)
```

### Таблица `smoking_logs`
```sql
- id (bigint, PK, auto)
- user_id (uuid, FK -> auth.users)
- product_type (text)
- trigger (text: stress/coffee/after_meal/alcohol/boredom/social)
- mood (text, nullable)
- nicotine_mg (float, nullable)
- price (int, nullable)
- note (text, nullable)
- created_at (timestamptz)
```

### RLS Policies
Обе таблицы имеют RLS policies:
- SELECT: `auth.uid() = user_id` или `auth.uid() = id`
- INSERT/UPDATE/DELETE: `auth.uid() = user_id` или `auth.uid() = id`

## Ключевые решения

### 1. Авторизация
- Sign in with Apple → Supabase Auth
- После авторизации создаётся/загружается профиль
- `onboarding_done` определяет показывать ли онбординг

### 2. Кеширование
- `CacheManager` кеширует логи в UserDefaults
- Загрузка кеша синхронно в `init()` ViewModel'ей для мгновенного отображения
- Затем фоновый fetch свежих данных

### 3. Profile поля опциональные
Все числовые поля в Profile опциональные (`Int?`, `Bool?`) чтобы избежать ошибок декодирования при NULL в БД:
```swift
var baselinePerDay: Int?
var safeBaselinePerDay: Int { baselinePerDay ?? 10 }
```

### 4. Онбординг
6 шагов:
1. NameStep - имя/никнейм
2. ProductTypeStep - тип продукта
3. BaselineStep - сколько в день, цена пачки, штук в пачке
4. GoalStep - цель (бросить/снизить/наблюдать)
5. ProgramTypeStep - целевое количество (если reduce)
6. DurationStep - длительность программы (1-6 месяцев)

### 5. Tab Bar
Кастомный tab bar в `MainTabView`:
- Главная (home)
- История (history)
- Отчёты (stats)
- Профиль (profile)

### 6. Программа снижения
- `ProgramCalculator.swift` рассчитывает текущий дневной лимит
- Лимит постепенно снижается от baseline до target за N месяцев
- На главном экране показывается счётчик "X/Y" где Y - текущий лимит

### 7. Push-уведомления (NotificationManager.swift)
**Типы уведомлений:**
- Вечернее (настраиваемое время) - итоги дня
- При превышении лимита
- Health milestones - 2ч, 6ч, 12ч, 24ч, 72ч без курения

### 8. Защита данных профиля (КРИТИЧНО!)
- `fetchOrCreateProfile()` ТОЛЬКО читает данные, НИКОГДА не создаёт/перезаписывает
- Профиль создаётся ТОЛЬКО при первом онбординге

## Дизайн система

### Цвета (в DesignSystem.swift)
- `appBackground` - фон приложения
- `cardBackground` - фон карточек
- `cardFill` - заливка элементов
- `primaryAccent` - оранжевый акцент (#E86F45)
- `textPrimary`, `textSecondary`, `textMuted`
- `success` - зелёный для позитивных значений

### Шрифты
- `screenTitle` - заголовок экрана
- `cardTitle`, `cardValue` - для карточек
- `bodyText` - основной текст
- `sectionLabel` - метки секций
- `giantCounter` - большой счётчик

### Layout
- `horizontalPadding = 20`
- `cardCornerRadius = 16`

## Xcode конфигурация

### Capabilities (dem.entitlements)
- Sign in with Apple
- In-App Purchase (для подписок)

### Info.plist ключи
- Privacy - Photo Library Usage (если нужно)

## Тестирование подписок

### Sandbox Testing
1. Создать Sandbox Tester в App Store Connect
2. На устройстве: Settings → App Store → Sandbox Account
3. В приложении покупки будут через Sandbox

### Ошибки в симуляторе
```
Error Domain=ASDErrorDomain Code=509 "No active account"
```
Это нормально - в симуляторе нет App Store аккаунта. Тестировать на реальном устройстве.

## Типичные баги и решения

| Баг | Причина | Решение |
|-----|---------|---------|
| "data couldn't be read" | NULL в БД для non-optional поля | Сделать поле optional + safe accessor |
| Онбординг каждый раз | profile не загружен или onboarding_done = false | Проверить fetchOrCreateProfile |
| Sheet тёмный | Наследует тему приложения | `.presentationBackground(.white)` |
| Иконка не обновляется | iOS кеширует иконки | Clean Build + удалить app + rebuild |
| StoreKit products пустые | Нет продуктов в App Store Connect | Создать продукты, проверить Bundle ID |
| Подписка не работает | Agreements не подписаны | App Store Connect → Agreements |

## App Store Connect

### Product IDs
- `com.dem.monthly` - Monthly ($4.99)
- `com.dem.halfyear` - 6 Months ($24.99)
- `com.dem.yearly` - Annual ($49.99)

### Subscription Group
- Название: "dem Premium"
- Все три продукта в одной группе

### URLs для Review
- Privacy Policy: https://[github-pages-url]/privacy-policy.html
- Terms of Service: https://[github-pages-url]/terms-of-service.html
