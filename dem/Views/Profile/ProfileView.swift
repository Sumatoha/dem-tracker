import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showProductTypePicker = false
    @State private var showGoalTypePicker = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @FocusState private var focusedField: Field?

    enum Field {
        case baseline, packPrice, sticksInPack
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // User Info Card
                        userInfoCard

                        // Settings Section
                        settingsSection

                        // Program Section
                        programSection

                        // Notifications Section
                        notificationsSection

                        // About Section (Legal)
                        aboutSection

                        // Sign Out Button
                        signOutButton
                            .padding(.top, 16)
                            .padding(.bottom, 120)
                    }
                    .padding(.horizontal, Layout.horizontalPadding)
                }
            }
        }
        .onAppear {
            viewModel.loadProfileData()
        }
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Готово") {
                    focusedField = nil
                }
                .foregroundColor(.primaryAccent)
            }
        }
        .alert("Ошибка", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Произошла ошибка")
        }
        .sheet(isPresented: $showProductTypePicker) {
            productTypePickerSheet
        }
        .sheet(isPresented: $showGoalTypePicker) {
            goalTypePickerSheet
        }
        .sheet(isPresented: $viewModel.showProgramSetup) {
            programSetupSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Профиль")
                .font(.screenTitle)
                .foregroundColor(.textPrimary)

            Spacer()

            if viewModel.isEditing {
                Button {
                    focusedField = nil
                    Task {
                        await viewModel.saveChanges()
                    }
                } label: {
                    Text("Сохранить")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryAccent)
                }
            } else {
                Button {
                    viewModel.startEditing()
                } label: {
                    Text("Изменить")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryAccent)
                }
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }

    // MARK: - User Info Card

    private var userInfoCard: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(Color.primaryAccent.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.primaryAccent)
                }

            VStack(spacing: 4) {
                Text(viewModel.userName)
                    .font(.cardTitle)
                    .foregroundColor(.textPrimary)

                if let profile = viewModel.profile {
                    Text(profile.productType?.displayName ?? "Не указано")
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // Product Type
            SettingsRow(
                title: "Тип продукта",
                value: viewModel.isEditing ? viewModel.productType.displayName : (viewModel.profile?.productType?.displayName ?? "Не указано"),
                isEditable: viewModel.isEditing
            ) {
                showProductTypePicker = true
            }

            Divider().padding(.horizontal, 16)

            // Baseline
            if viewModel.isEditing {
                SettingsInputRow(
                    title: "В день (обычно)",
                    text: $viewModel.baselineText,
                    suffix: "шт.",
                    isFocused: focusedField == .baseline
                )
                .focused($focusedField, equals: .baseline)
            } else {
                SettingsRow(
                    title: "В день (обычно)",
                    value: "\(viewModel.profile?.safeBaselinePerDay ?? 0) шт.",
                    isEditable: false
                ) {}
            }

            Divider().padding(.horizontal, 16)

            // Pack Price
            if viewModel.isEditing {
                SettingsInputRow(
                    title: "Цена пачки",
                    text: $viewModel.packPriceText,
                    suffix: "₸",
                    isFocused: focusedField == .packPrice
                )
                .focused($focusedField, equals: .packPrice)
            } else {
                SettingsRow(
                    title: "Цена пачки",
                    value: "\(viewModel.profile?.safePackPrice ?? 0) ₸",
                    isEditable: false
                ) {}
            }

            Divider().padding(.horizontal, 16)

            // Sticks in Pack
            if viewModel.isEditing {
                SettingsInputRow(
                    title: "Сигарет в пачке",
                    text: $viewModel.sticksInPackText,
                    suffix: "шт.",
                    isFocused: focusedField == .sticksInPack
                )
                .focused($focusedField, equals: .sticksInPack)
            } else {
                SettingsRow(
                    title: "Сигарет в пачке",
                    value: "\(viewModel.profile?.safeSticksInPack ?? 0) шт.",
                    isEditable: false
                ) {}
            }

            Divider().padding(.horizontal, 16)

            // Goal
            SettingsRow(
                title: "Цель",
                value: viewModel.isEditing ? viewModel.goalType.displayName : (viewModel.profile?.goalType?.displayName ?? "Не указана"),
                isEditable: viewModel.isEditing
            ) {
                showGoalTypePicker = true
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Program Section

    private var programSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ПРОГРАММА")
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    if viewModel.hasProgramActive {
                        if let limit = viewModel.currentDailyLimit {
                            Text("Лимит сегодня: \(limit) шт.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryAccent)
                        }
                    } else {
                        Text("Не настроена")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                }

                Spacer()

                Button {
                    viewModel.startProgramSetup()
                } label: {
                    Text(viewModel.hasProgramActive ? "Изменить" : "Настроить")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primaryAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primaryAccent.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(16)

            if viewModel.hasProgramActive {
                Divider().padding(.horizontal, 16)

                HStack {
                    Text("Цель")
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text(viewModel.programTypeDisplayName)
                        .font(.bodyText)
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Program Setup Sheet

    private var programSetupSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Program Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("ВЫБЕРИТЕ ЦЕЛЬ")
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    VStack(spacing: 8) {
                        ProgramOptionButton(
                            title: "Бросить",
                            subtitle: "Постепенно снижать до 0",
                            isSelected: viewModel.programType == "quit"
                        ) {
                            viewModel.programType = "quit"
                            viewModel.programTargetValue = 0
                        }

                        ProgramOptionButton(
                            title: "Снизить",
                            subtitle: "Установить целевой лимит",
                            isSelected: viewModel.programType == "reduce"
                        ) {
                            viewModel.programType = "reduce"
                        }

                        ProgramOptionButton(
                            title: "Наблюдать",
                            subtitle: "Без ограничений",
                            isSelected: viewModel.programType == "observe"
                        ) {
                            viewModel.programType = "observe"
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Target Value (only for reduce)
                if viewModel.programType == "reduce" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ЦЕЛЕВОЕ КОЛИЧЕСТВО В ДЕНЬ")
                            .font(.sectionLabel)
                            .kerning(2)
                            .foregroundColor(.textSecondary)

                        HStack {
                            Button {
                                if viewModel.programTargetValue > 0 {
                                    viewModel.programTargetValue -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.primaryAccent)
                            }

                            Text("\(viewModel.programTargetValue)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.textPrimary)
                                .frame(minWidth: 80)

                            Button {
                                viewModel.programTargetValue += 1
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.primaryAccent)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                }

                // Duration (only for quit/reduce)
                if viewModel.programType == "quit" || viewModel.programType == "reduce" {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("СРОК ПРОГРАММЫ")
                            .font(.sectionLabel)
                            .kerning(2)
                            .foregroundColor(.textSecondary)

                        HStack(spacing: 12) {
                            DurationButton(months: 1, selected: viewModel.programDurationMonths) {
                                viewModel.programDurationMonths = 1
                            }
                            DurationButton(months: 3, selected: viewModel.programDurationMonths) {
                                viewModel.programDurationMonths = 3
                            }
                            DurationButton(months: 6, selected: viewModel.programDurationMonths) {
                                viewModel.programDurationMonths = 6
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Save Button
                Button {
                    Task {
                        await viewModel.saveProgramSettings()
                    }
                } label: {
                    Text("СОХРАНИТЬ")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.primaryAccent)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .padding(.top, 24)
            .navigationTitle("Настройка программы")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Отмена") {
                        viewModel.showProgramSetup = false
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.white)
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(spacing: 0) {
            // Notifications toggle
            HStack {
                Text("Уведомления")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)

                Spacer()

                Toggle("", isOn: $viewModel.notificationsEnabled)
                    .labelsHidden()
                    .tint(.primaryAccent)
                    .onChange(of: viewModel.notificationsEnabled) { _, _ in
                        Task {
                            await viewModel.toggleNotifications()
                        }
                    }
            }
            .padding(16)

            if viewModel.notificationsEnabled {
                Divider().padding(.horizontal, 16)

                // Notification time picker
                HStack {
                    Text("Время вечернего отчёта")
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    DatePicker(
                        "",
                        selection: $viewModel.notificationTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .tint(.primaryAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primaryAccent.opacity(0.1))
                    .cornerRadius(8)
                    .onChange(of: viewModel.notificationTime) { _, _ in
                        Task {
                            await viewModel.updateNotificationTime()
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .animation(.easeInOut(duration: 0.2), value: viewModel.notificationsEnabled)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(spacing: 0) {
            // Privacy Policy
            Button {
                showPrivacyPolicy = true
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .frame(width: 24)

                    Text("Политика конфиденциальности")
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .padding(16)
            }

            Divider().padding(.horizontal, 16)

            // Terms of Service
            Button {
                showTermsOfService = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .frame(width: 24)

                    Text("Условия использования")
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .padding(16)
            }

            Divider().padding(.horizontal, 16)

            // Contact Support
            Button {
                if let url = URL(string: "mailto:kakenov.tokmyrza@gmail.com?subject=dem%20-%20Поддержка") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .frame(width: 24)

                    Text("Написать в поддержку")
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .padding(16)
            }

            Divider().padding(.horizontal, 16)

            // App Version
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .frame(width: 24)

                Text("Версия")
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text("1.0.0")
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
        }
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalDocumentView(
                title: "Политика конфиденциальности",
                content: LegalTexts.privacyPolicy
            )
        }
        .sheet(isPresented: $showTermsOfService) {
            LegalDocumentView(
                title: "Условия использования",
                content: LegalTexts.termsOfService
            )
        }
    }

    // MARK: - Sign Out Button

    private var signOutButton: some View {
        Button {
            Task {
                await viewModel.signOut()
            }
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .medium))

                Text("Выйти из аккаунта")
                    .font(.bodyText)
            }
            .foregroundColor(.primaryAccent)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.primaryAccent.opacity(0.1))
            .cornerRadius(Layout.cardCornerRadius)
        }
        .pressEffect()
    }

    // MARK: - Picker Sheets

    private var productTypePickerSheet: some View {
        NavigationStack {
            List {
                ForEach([ProductType.cigarette, .iqos, .vape], id: \.self) { type in
                    Button {
                        viewModel.productType = type
                        showProductTypePicker = false
                        Haptics.selection()
                    } label: {
                        HStack {
                            Text(type.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if viewModel.productType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle("Тип продукта")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        showProductTypePicker = false
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.white)
    }

    private var goalTypePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(GoalType.allCases, id: \.self) { type in
                    Button {
                        viewModel.goalType = type
                        showGoalTypePicker = false
                        Haptics.selection()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .foregroundColor(.primary)
                                Text(type.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if viewModel.goalType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle("Цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") {
                        showGoalTypePicker = false
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.white)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let title: String
    let value: String
    var isEditable: Bool = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            if isEditable {
                action?()
                Haptics.light()
            }
        } label: {
            HStack {
                Text(title)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text(value)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)

                if isEditable {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .disabled(!isEditable)
    }
}

// MARK: - Settings Input Row

struct SettingsInputRow: View {
    let title: String
    @Binding var text: String
    let suffix: String
    var isFocused: Bool = false

    var body: some View {
        HStack {
            Text(title)
                .font(.bodyText)
                .foregroundColor(.textPrimary)

            Spacer()

            HStack(spacing: 8) {
                TextField("0", text: $text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .frame(width: 70)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(isFocused ? Color.primaryAccent.opacity(0.1) : Color.cardFill)
                    .cornerRadius(8)

                Text(suffix)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(16)
    }
}

// MARK: - Program Option Button

struct ProgramOptionButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryAccent)
                } else {
                    Circle()
                        .stroke(Color.textMuted, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(16)
            .background(isSelected ? Color.primaryAccent.opacity(0.1) : Color.cardFill)
            .cornerRadius(12)
        }
    }
}

// MARK: - Duration Button

struct DurationButton: View {
    let months: Int
    let selected: Int
    let action: () -> Void

    var isSelected: Bool {
        months == selected
    }

    var title: String {
        switch months {
        case 1: return "1 мес"
        case 3: return "3 мес"
        case 6: return "6 мес"
        default: return "\(months) мес"
        }
    }

    var body: some View {
        Button(action: {
            action()
            Haptics.selection()
        }) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.primaryAccent : Color.cardFill)
                .cornerRadius(8)
        }
    }
}

#Preview {
    ProfileView()
}
