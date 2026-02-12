import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var showProductTypePicker = false
    @State private var showGoalTypePicker = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showLanguagePicker = false
    @State private var showPaywall = false
    @State private var showDiscardChangesAlert = false
    @State private var showSupportSheet = false
    @State private var showDeleteAccountAlert = false
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

                        // Language Section
                        languageSection

                        // Subscription Section
                        subscriptionSection

                        // About Section (Legal)
                        aboutSection

                        // Sign Out Button
                        signOutButton
                            .padding(.top, 16)

                        // Delete Account Button
                        deleteAccountButton
                            .padding(.top, 8)
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
                Button(L.Common.done) {
                    focusedField = nil
                }
                .foregroundColor(.primaryAccent)
            }
        }
        .alert(L.Common.error, isPresented: $viewModel.showError) {
            Button(L.Common.ok, role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? L.Common.error)
        }
        .alert(L.Profile.discardChanges, isPresented: $showDiscardChangesAlert) {
            Button(L.Common.cancel, role: .cancel) {}
            Button(L.Profile.discard, role: .destructive) {
                viewModel.cancelEditing()
            }
        } message: {
            Text(L.Profile.discardChangesMessage)
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
        .sheet(isPresented: $showLanguagePicker) {
            languagePickerSheet
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onSubscribed: { showPaywall = false },
                onStartTrial: { showPaywall = false }
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text(L.Profile.title)
                .font(.screenTitle)
                .foregroundColor(.textPrimary)

            Spacer()

            if viewModel.isEditing {
                HStack(spacing: 16) {
                    Button {
                        focusedField = nil
                        if viewModel.hasUnsavedChanges {
                            showDiscardChangesAlert = true
                        } else {
                            viewModel.cancelEditing()
                        }
                    } label: {
                        Text(L.Common.cancel)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }

                    Button {
                        focusedField = nil
                        Task {
                            await viewModel.saveChanges()
                        }
                    } label: {
                        Text(L.Common.save)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primaryAccent)
                    }
                }
            } else {
                Button {
                    viewModel.startEditing()
                } label: {
                    Text(L.Profile.editProfile)
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
                    Text(profile.productType?.displayName ?? L.Profile.notSpecified)
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
                title: L.Profile.productType,
                value: viewModel.isEditing ? viewModel.productType.displayName : (viewModel.profile?.productType?.displayName ?? L.Profile.notSpecified),
                isEditable: viewModel.isEditing
            ) {
                showProductTypePicker = true
            }

            Divider().padding(.horizontal, 16)

            // Baseline
            if viewModel.isEditing {
                SettingsInputRow(
                    title: L.Profile.perDayUsually,
                    text: $viewModel.baselineText,
                    suffix: L.Units.pieces,
                    isFocused: focusedField == .baseline
                )
                .focused($focusedField, equals: .baseline)
            } else {
                SettingsRow(
                    title: L.Profile.perDayUsually,
                    value: "\(viewModel.profile?.safeBaselinePerDay ?? 0) \(L.Units.pieces)",
                    isEditable: false
                ) {}
            }

            Divider().padding(.horizontal, 16)

            // Pack Price
            if viewModel.isEditing {
                SettingsInputRow(
                    title: L.Profile.packPrice,
                    text: $viewModel.packPriceText,
                    suffix: L.Units.tenge,
                    isFocused: focusedField == .packPrice
                )
                .focused($focusedField, equals: .packPrice)
            } else {
                SettingsRow(
                    title: L.Profile.packPrice,
                    value: "\(viewModel.profile?.safePackPrice ?? 0) \(L.Units.tenge)",
                    isEditable: false
                ) {}
            }

            Divider().padding(.horizontal, 16)

            // Sticks in Pack
            if viewModel.isEditing {
                SettingsInputRow(
                    title: L.Profile.sticksInPack,
                    text: $viewModel.sticksInPackText,
                    suffix: L.Units.pieces,
                    isFocused: focusedField == .sticksInPack
                )
                .focused($focusedField, equals: .sticksInPack)
            } else {
                SettingsRow(
                    title: L.Profile.sticksInPack,
                    value: "\(viewModel.profile?.safeSticksInPack ?? 0) \(L.Units.pieces)",
                    isEditable: false
                ) {}
            }

            Divider().padding(.horizontal, 16)

            // Goal
            SettingsRow(
                title: L.Program.goal,
                value: viewModel.isEditing ? viewModel.goalType.displayName : (viewModel.profile?.goalType?.displayName ?? L.Profile.notSpecified),
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
                    Text(L.Stats.program)
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    if viewModel.hasProgramActive {
                        if let limit = viewModel.currentDailyLimit {
                            Text(L.Profile.todayLimit(limit))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primaryAccent)
                        }
                    } else {
                        Text(L.Profile.notConfigured)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                }

                Spacer()

                Button {
                    viewModel.startProgramSetup()
                } label: {
                    Text(viewModel.hasProgramActive ? L.Profile.editProfile : L.Profile.setupProgram)
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
                    Text(L.Program.goal)
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
                    Text(L.Profile.selectGoal)
                        .font(.sectionLabel)
                        .kerning(2)
                        .foregroundColor(.textSecondary)

                    VStack(spacing: 8) {
                        ProgramOptionButton(
                            title: L.Program.quit,
                            subtitle: L.Profile.quitDesc,
                            isSelected: viewModel.programType == "quit"
                        ) {
                            viewModel.programType = "quit"
                            viewModel.programTargetValue = 0
                        }

                        ProgramOptionButton(
                            title: L.Program.reduce,
                            subtitle: L.Profile.reduceDesc,
                            isSelected: viewModel.programType == "reduce"
                        ) {
                            viewModel.programType = "reduce"
                        }

                        ProgramOptionButton(
                            title: L.Program.observe,
                            subtitle: L.Profile.observeDesc,
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
                        Text(L.Profile.targetPerDay)
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
                        Text(L.Profile.programDuration)
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
                    Text(L.Common.save.uppercased())
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
            .navigationTitle(L.Profile.programSetup)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.cancel) {
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
                Text(L.Profile.notifications)
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
                    Text(L.Profile.eveningReportTime)
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

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(spacing: 0) {
            Button {
                showLanguagePicker = true
            } label: {
                HStack {
                    Text(L.Profile.language)
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    HStack(spacing: 6) {
                        Text(languageManager.currentLanguage.flag)
                            .font(.system(size: 16))
                        Text(languageManager.currentLanguage.displayName)
                            .font(.bodyText)
                            .foregroundColor(.textSecondary)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .padding(16)
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Language Picker Sheet

    private var languagePickerSheet: some View {
        NavigationStack {
            List {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        languageManager.currentLanguage = language
                        showLanguagePicker = false
                        Haptics.selection()
                    } label: {
                        HStack {
                            Text(language.flag)
                                .font(.system(size: 20))

                            Text(language.displayName)
                                .foregroundColor(.primary)

                            Spacer()

                            if languageManager.currentLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.primaryAccent)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle(L.Profile.language)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.done) {
                        showLanguagePicker = false
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.white)
    }

    // MARK: - Subscription Section

    private var subscriptionStatusText: String {
        switch SubscriptionManager.shared.subscriptionState {
        case .subscribed:
            return L.Profile.subscriptionActive
        case .inTrial(let days):
            return L.Paywall.trialDaysLeft(days)
        case .trialExpired:
            return L.Profile.trialExpired
        case .noSubscription:
            return L.Profile.subscriptionSubscribe
        }
    }

    private var subscriptionStatusColor: Color {
        switch SubscriptionManager.shared.subscriptionState {
        case .subscribed:
            return .success
        case .inTrial:
            return .primaryAccent
        case .trialExpired:
            return .red
        case .noSubscription:
            return .textSecondary
        }
    }

    private var subscriptionSection: some View {
        VStack(spacing: 0) {
            Button {
                showPaywall = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryAccent)
                        .frame(width: 24)

                    Text(L.Profile.subscription)
                        .font(.bodyText)
                        .foregroundColor(.textPrimary)

                    Spacer()

                    Text(subscriptionStatusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(subscriptionStatusColor)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textMuted)
                }
                .padding(16)
            }

            if SubscriptionManager.shared.isSubscribed {
                Divider()
                    .background(Color.cardFill)
                    .padding(.horizontal, 16)

                Button {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .font(.system(size: 16))
                            .foregroundColor(.textSecondary)
                            .frame(width: 24)

                        Text(L.Profile.manageSubscription)
                            .font(.bodyText)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textMuted)
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(Layout.cardCornerRadius)
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

                    Text(L.Profile.privacyPolicy)
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

                    Text(L.Profile.termsOfService)
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

            // Support
            Button {
                showSupportSheet = true
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.textSecondary)
                        .frame(width: 24)

                    Text(L.Profile.support)
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

            // App Version
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
                    .frame(width: 24)

                Text(L.Profile.version)
                    .font(.bodyText)
                    .foregroundColor(.textPrimary)

                Spacer()

                Text(Bundle.main.appVersionString)
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
                title: L.Profile.privacyPolicy,
                content: LegalTexts.privacyPolicy
            )
        }
        .sheet(isPresented: $showTermsOfService) {
            LegalDocumentView(
                title: L.Profile.termsOfService,
                content: LegalTexts.termsOfService
            )
        }
        .sheet(isPresented: $showSupportSheet) {
            SupportSheetView()
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

                Text(L.Profile.signOut)
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

    // MARK: - Delete Account Button

    private var deleteAccountButton: some View {
        Button {
            showDeleteAccountAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .medium))

                Text(L.Profile.deleteAccount)
                    .font(.bodyText)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .alert(L.Profile.deleteAccountTitle, isPresented: $showDeleteAccountAlert) {
            Button(L.Common.cancel, role: .cancel) {}
            Button(L.Profile.delete, role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
        } message: {
            Text(L.Profile.deleteAccountMessage)
        }
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
                                    .foregroundColor(.primaryAccent)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle(L.Profile.productType)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.done) {
                        showProductTypePicker = false
                    }
                    .foregroundColor(.primaryAccent)
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
                                    .foregroundColor(.primaryAccent)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.visible)
            .navigationTitle(L.Program.goal)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.done) {
                        showGoalTypePicker = false
                    }
                    .foregroundColor(.primaryAccent)
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
        L.Profile.monthsFormat(months)
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

// MARK: - Support Sheet View

struct SupportSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header text
                Text(L.Profile.supportDescription)
                    .font(.bodyText)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                VStack(spacing: 0) {
                    // Email
                    Button {
                        if let url = URL(string: "mailto:kakenov.tokmyrza@gmail.com?subject=dem%20Support") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primaryAccent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Text("kakenov.tokmyrza@gmail.com")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                                .foregroundColor(.textMuted)
                        }
                        .padding(16)
                    }

                    Divider().padding(.leading, 56)

                    // Telegram
                    Button {
                        if let url = URL(string: "https://t.me/iddlemiddle") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primaryAccent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Telegram")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Text("@iddlemiddle")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                                .foregroundColor(.textMuted)
                        }
                        .padding(16)
                    }

                    Divider().padding(.leading, 56)

                    // Instagram
                    Button {
                        if let url = URL(string: "https://instagram.com/dem.tracker") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.primaryAccent)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Instagram")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                Text("@dem.tracker")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14))
                                .foregroundColor(.textMuted)
                        }
                        .padding(16)
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(Layout.cardCornerRadius)
                .padding(.horizontal, Layout.horizontalPadding)

                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle(L.Profile.support)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L.Common.done) {
                        dismiss()
                    }
                    .foregroundColor(.primaryAccent)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(.white)
    }
}

#Preview {
    ProfileView()
}
