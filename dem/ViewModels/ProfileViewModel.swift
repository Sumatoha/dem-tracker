import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var isEditing = false

    // Editable fields
    @Published var productType: ProductType = .cigarette
    @Published var baselineText: String = "10"
    @Published var packPriceText: String = "250"
    @Published var sticksInPackText: String = "20"
    @Published var goalType: GoalType = .observe
    @Published var goalPerDay: Int = 5

    // Notification settings
    @Published var notificationsEnabled: Bool = true
    @Published var notificationTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()

    // Program settings
    @Published var programType: String = "observe" // quit, reduce, observe
    @Published var programTargetValue: Int = 0
    @Published var programDurationMonths: Int = 3
    @Published var showProgramSetup = false

    private let supabase = SupabaseManager.shared

    var profile: Profile? {
        supabase.currentProfile
    }

    var userName: String {
        profile?.name ?? L.Profile.user
    }

    // Computed Int values from text
    var baselinePerDay: Int {
        Int(baselineText) ?? 10
    }

    var packPrice: Int {
        Int(packPriceText) ?? 250
    }

    var sticksInPack: Int {
        Int(sticksInPackText) ?? 20
    }

    func loadProfileData() {
        guard let profile = profile else { return }

        productType = profile.productType ?? .cigarette
        baselineText = "\(profile.safeBaselinePerDay)"
        packPriceText = "\(profile.safePackPrice)"
        sticksInPackText = "\(profile.safeSticksInPack)"
        goalType = profile.goalType ?? .observe
        goalPerDay = profile.goalPerDay ?? 5

        // Load notification settings
        notificationsEnabled = profile.safeNotificationsEnabled
        if let timeStr = profile.notificationTime {
            let components = timeStr.split(separator: ":")
            if components.count == 2,
               let hour = Int(components[0]),
               let minute = Int(components[1]) {
                notificationTime = Calendar.current.date(from: DateComponents(hour: hour, minute: minute)) ?? notificationTime
            }
        }

        // Load program settings
        programType = profile.programType ?? "observe"
        programTargetValue = profile.programTargetValue ?? 0
        programDurationMonths = profile.programDurationMonths ?? 3

        // Check actual iOS notification permission
        Task {
            await checkNotificationPermission()
        }
    }

    /// Проверяет реальный статус разрешения на уведомления в iOS
    func checkNotificationPermission() async {
        let status = await NotificationManager.shared.checkPermissionStatus()
        if status == .denied || status == .notDetermined {
            // Если разрешение не дано, выключаем в UI
            if notificationsEnabled {
                notificationsEnabled = false
            }
        }
    }

    // MARK: - Program Settings

    var hasProgramActive: Bool {
        profile?.hasProgramActive ?? false
    }

    var currentDailyLimit: Int? {
        guard let profile = profile,
              profile.hasProgramActive,
              let startValue = profile.programStartValue,
              let targetValue = profile.programTargetValue,
              let durationMonths = profile.programDurationMonths,
              let startDate = profile.programStartDate else {
            return nil
        }

        return ProgramCalculator.currentDailyLimit(
            startValue: startValue,
            targetValue: targetValue,
            durationMonths: durationMonths,
            startDate: startDate
        )
    }

    var programTypeDisplayName: String {
        switch programType {
        case "quit": return L.Program.quit
        case "reduce": return L.Program.reduce
        default: return L.Program.observe
        }
    }

    func startProgramSetup() {
        loadProfileData()
        showProgramSetup = true
    }

    func saveProgramSettings() async {
        guard profile != nil else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            var updates: [String: AnyEncodable] = [
                ColumnName.Profile.programType: AnyEncodable(programType),
                ColumnName.Profile.goalType: AnyEncodable(programType == "quit" ? "quit" : (programType == "reduce" ? "reduce" : "observe"))
            ]

            // Если программа активная (quit или reduce), устанавливаем параметры
            if programType == "quit" || programType == "reduce" {
                let startValue = baselinePerDay
                let targetValue = programType == "quit" ? 0 : programTargetValue

                updates[ColumnName.Profile.programStartValue] = AnyEncodable(startValue)
                updates[ColumnName.Profile.programTargetValue] = AnyEncodable(targetValue)
                updates[ColumnName.Profile.programDurationMonths] = AnyEncodable(programDurationMonths)
                updates[ColumnName.Profile.programStartDate] = AnyEncodable(Date())
            } else {
                // Наблюдение - очищаем программу
                updates[ColumnName.Profile.programStartValue] = AnyEncodable(nil as Int?)
                updates[ColumnName.Profile.programTargetValue] = AnyEncodable(nil as Int?)
                updates[ColumnName.Profile.programDurationMonths] = AnyEncodable(nil as Int?)
                updates[ColumnName.Profile.programStartDate] = AnyEncodable(nil as Date?)
            }

            try await supabase.updateProfile(updates)
            showProgramSetup = false
            Haptics.success()

            // Перезагружаем профиль чтобы обновить UI
            await supabase.fetchOrCreateProfile()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.error()
        }
    }

    var hasUnsavedChanges: Bool {
        guard let profile = profile else { return false }
        return productType != (profile.productType ?? .cigarette) ||
               baselinePerDay != profile.safeBaselinePerDay ||
               packPrice != profile.safePackPrice ||
               sticksInPack != profile.safeSticksInPack ||
               goalType != (profile.goalType ?? .observe) ||
               goalPerDay != (profile.goalPerDay ?? 5)
    }

    func startEditing() {
        // ЗАЩИТА: не разрешаем редактирование если профиль не загружен
        guard profile != nil else {
            errorMessage = "Профиль не загружен"
            showError = true
            return
        }
        loadProfileData()
        isEditing = true
        Haptics.selection()
    }

    func cancelEditing() {
        loadProfileData() // Restore original values
        isEditing = false
        Haptics.selection()
    }

    func saveChanges() async {
        // ЗАЩИТА: не сохраняем если профиль не загружен
        guard profile != nil else {
            errorMessage = "Профиль не загружен"
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let updates: [String: AnyEncodable] = [
                ColumnName.Profile.productType: AnyEncodable(productType.rawValue),
                ColumnName.Profile.baselinePerDay: AnyEncodable(baselinePerDay),
                ColumnName.Profile.packPrice: AnyEncodable(packPrice),
                ColumnName.Profile.sticksInPack: AnyEncodable(sticksInPack),
                ColumnName.Profile.goalType: AnyEncodable(goalType.rawValue),
                ColumnName.Profile.goalPerDay: AnyEncodable(goalPerDay),
                ColumnName.Profile.onboardingDone: AnyEncodable(true)
            ]

            try await supabase.updateProfile(updates)
            isEditing = false
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.error()
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.signOut()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func deleteAccount() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Delete user data from Supabase (logs and profile)
            try await supabase.deleteUserData()
            // Sign out after deletion
            try await supabase.signOut()
            Haptics.success()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.error()
        }
    }

    // MARK: - Notification Settings

    var notificationTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: notificationTime)
    }

    func toggleNotifications() async {
        Haptics.selection()

        if notificationsEnabled {
            // Включаем - запрашиваем разрешение и планируем
            let granted = await NotificationManager.shared.requestPermission()
            if !granted {
                notificationsEnabled = false
                return
            }
            // Сохраняем и сразу планируем уведомления
            await saveNotificationSettings()
            await scheduleNotificationsNow()
        } else {
            // Выключаем - отменяем все уведомления
            NotificationManager.shared.cancelAll()
            await saveNotificationSettings()
        }
    }

    func updateNotificationTime() async {
        await saveNotificationSettings()
        // Перепланируем с новым временем
        if notificationsEnabled {
            await scheduleNotificationsNow()
        }
    }

    /// Планирует уведомления с текущими данными
    func scheduleNotificationsNow() async {
        let timeComponents = NotificationManager.shared.parseTime(notificationTimeString)

        // Получаем данные для уведомлений
        let cache = CacheManager.shared
        let todayLogs = cache.getCachedTodayLogs() ?? []

        let todayCount = todayLogs.count
        let lastLogDate = todayLogs.first?.createdAt

        // Текущий лимит программы
        var dailyLimit: Int? = nil
        if let profile = profile,
           profile.hasProgramActive,
           let startValue = profile.programStartValue,
           let targetValue = profile.programTargetValue,
           let durationMonths = profile.programDurationMonths,
           let startDate = profile.programStartDate {
            dailyLimit = ProgramCalculator.currentDailyLimit(
                startValue: startValue,
                targetValue: targetValue,
                durationMonths: durationMonths,
                startDate: startDate
            )
        }

        // Планируем вечернее уведомление и milestones
        NotificationManager.shared.scheduleNotifications(
            eveningHour: timeComponents.hour,
            eveningMinute: timeComponents.minute,
            todayCount: todayCount,
            dailyLimit: dailyLimit,
            lastLogDate: lastLogDate
        )
    }

    private func saveNotificationSettings() async {
        // ЗАЩИТА: не сохраняем если профиль не загружен
        guard profile != nil else { return }

        do {
            let timeString = notificationTimeString
            let updates: [String: AnyEncodable] = [
                ColumnName.Profile.notificationsEnabled: AnyEncodable(notificationsEnabled),
                ColumnName.Profile.notificationTime: AnyEncodable(timeString)
            ]

            try await supabase.updateProfile(updates)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
