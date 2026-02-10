# dem - Nicotine Tracker iOS App

## Обзор проекта
iOS приложение для отслеживания потребления никотина (сигареты, IQOS, вейп). Помогает пользователям контролировать привычку, видеть статистику и экономию.

## Технологии
- **SwiftUI** (iOS 17+)
- **Supabase** (бэкенд, авторизация, база данных)
- **Swift Package Manager** (зависимости)
- **MVVM архитектура**

## Структура проекта

```
dem/
├── demApp.swift              # Точка входа, роутинг авторизации
├── Models/
│   ├── Profile.swift         # Профиль пользователя
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
│   │   └── AuthView.swift    # Sign in with Apple
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift
│   │   ├── NameStep.swift        # Шаг 1: Имя
│   │   ├── ProductTypeStep.swift # Шаг 2: Тип продукта
│   │   ├── BaselineStep.swift    # Шаг 3: Потребление
│   │   ├── GoalStep.swift        # Шаг 4: Цель
│   │   ├── ProgramTypeStep.swift # Шаг 5: Целевое количество (reduce)
│   │   └── DurationStep.swift    # Шаг 6: Длительность программы
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── TimerPillView.swift
│   │   ├── BigLogButton.swift
│   │   └── TriggerSelectionView.swift
│   ├── History/
│   │   └── HistoryView.swift
│   ├── Stats/
│   │   └── StatsView.swift
│   ├── Profile/
│   │   └── ProfileView.swift
│   └── Components/
│       ├── MainTabView.swift
│       ├── DesignSystem.swift    # Цвета, шрифты, Layout
│       ├── StatCard.swift
│       ├── ActivityChart.swift
│       ├── PressEffectModifier.swift
│       └── LegalDocumentView.swift # Показ политик внутри приложения
├── Services/
│   ├── SupabaseManager.swift # Singleton для работы с Supabase
│   ├── CacheManager.swift    # Локальный кеш (UserDefaults)
│   ├── HapticManager.swift   # Вибрация
│   ├── NotificationManager.swift # Push-уведомления (вечерние отчёты)
│   └── ProgramCalculator.swift   # Расчёт лимитов программы снижения
└── Config/
    └── Supabase.swift        # URL, ключи, названия таблиц/колонок

docs/                         # Документация для App Store
├── privacy-policy.html       # Политика конфиденциальности (для хостинга)
├── terms-of-service.html     # Условия использования (для хостинга)
└── app-store-metadata.md     # Метаданные для App Store Connect
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

Кнопка настроек (шестерёнка) на главной переключает на профиль.

### 6. Программа снижения
- `ProgramCalculator.swift` рассчитывает текущий дневной лимит
- Лимит постепенно снижается от baseline до target за N месяцев
- Формула: `startValue - (startValue - targetValue) * weekNumber / totalWeeks`
- На главном экране показывается счётчик "X/Y" где Y - текущий лимит
- Красный цвет счётчика при превышении лимита

### 7. Push-уведомления (NotificationManager.swift)

**Типы уведомлений:**
1. **Утреннее (10:00)** - мотивация, лимит на день, серия дней
2. **Дневное (14:00)** - проверка прогресса к лимиту
3. **Вечернее (настраиваемое)** - итоги дня, сравнение с лимитом
4. **Мгновенное** - при достижении/превышении лимита
5. **Еженедельное (воскресенье 21:00)** - итоги недели, экономия
6. **Health milestones** - 2ч, 8ч, 24ч, 48ч, 72ч без курения

**Когда планируются:**
- При запуске приложения (`HomeView.task → setupInitialNotifications`)
- После каждого лога (`submitLog → updateNotifications`)
- При включении уведомлений (`ProfileViewModel.toggleNotifications`)
- При изменении времени (`ProfileViewModel.updateNotificationTime`)

### 8. Защита данных профиля (КРИТИЧНО!)
- `fetchOrCreateProfile()` ТОЛЬКО читает данные, НИКОГДА не создаёт/перезаписывает
- Профиль создаётся ТОЛЬКО при первом онбординге
- `ProfileViewModel.saveChanges()` имеет guard против сохранения если profile == nil
- Это предотвращает баг когда дефолтные данные перезаписывают реальные

### 9. Юридические документы
- Политика конфиденциальности и Условия использования
- Встроены в приложение через `LegalDocumentView` + `LegalTexts` enum
- HTML версии в `docs/` для хостинга (GitHub Pages)
- Раздел "О приложении" в ProfileView с ссылками

## Дизайн система

### Цвета (в DesignSystem.swift)
- `appBackground` - фон приложения
- `cardBackground` - фон карточек
- `cardFill` - заливка элементов
- `primaryAccent` - оранжевый акцент
- `textPrimary`, `textSecondary`, `textMuted`
- `buttonBlack` - тёмные кнопки

### Шрифты
- `screenTitle` - заголовок экрана
- `cardTitle`, `cardValue` - для карточек
- `bodyText` - основной текст
- `sectionLabel` - метки секций
- `giantCounter` - большой счётчик

### Layout
- `horizontalPadding = 20`
- `cardCornerRadius = 16`

## Известные особенности

1. **Sheets в ProfileView** - используют `.presentationBackground(.white)` для светлого фона

2. **Редактирование профиля** - текстовые поля используют `String` binding, не `Int`, для плавного ввода

3. **При сохранении профиля** - всегда отправляется `onboarding_done: true` чтобы не сбросить на онбординг

4. **История** - compact карточки статистики сверху, логи снизу

## Supabase конфиг

В `Config/Supabase.swift`:
```swift
enum SupabaseConfig {
    static let url = URL(string: "YOUR_SUPABASE_URL")!
    static let anonKey = "YOUR_ANON_KEY"
}

enum TableName {
    static let profiles = "profiles"
    static let logs = "smoking_logs"
    static let cravings = "cravings"
    static let achievements = "achievements"
}

enum ColumnName {
    enum Profile {
        static let id = "id"
        static let name = "name"
        static let productType = "product_type"
        // ... и т.д.
    }
    enum Log {
        static let id = "id"
        static let userId = "user_id"
        // ... и т.д.
    }
}
```

## Как добавить новый файл в проект

1. Создать .swift файл в нужной папке
2. Добавить в `project.pbxproj`:
   - PBXBuildFile section: `ID /* File.swift in Sources */`
   - PBXFileReference section: `ID /* File.swift */`
   - PBXGroup section: добавить ID в children нужной группы
   - PBXSourcesBuildPhase: добавить ID в files

## Типичные баги и решения

| Баг | Причина | Решение |
|-----|---------|---------|
| "data couldn't be read" | NULL в БД для non-optional поля | Сделать поле optional + safe accessor |
| Онбординг каждый раз | profile не загружен или onboarding_done = false | Проверить fetchOrCreateProfile, добавить onboarding_done в updates |
| Sheet тёмный | Наследует тему приложения | `.presentationBackground(.white)` |
| Layout jump | Контент меняет размер при загрузке | GeometryReader + minHeight |
| Профиль сбрасывается на дефолт | createNewProfile вызывался при каждом fetch | fetchOrCreateProfile должен ТОЛЬКО читать |
| Cannot find 'X' in scope | Файл не добавлен в project.pbxproj | Добавить в PBXBuildFile, PBXFileReference, PBXGroup, PBXSourcesBuildPhase |
| Программа не снижает с 1 недели | Формула использовала weeksElapsed | Использовать weekNumber в формуле |

## GitHub Pages для хостинга политик

1. Создать репозиторий на GitHub
2. Загрузить файлы из `docs/` в корень или папку
3. В Settings → Pages включить GitHub Pages
4. URL будет: `https://username.github.io/repo-name/privacy-policy.html`
5. Использовать эти URL в App Store Connect
