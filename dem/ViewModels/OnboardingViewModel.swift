import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentStep = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Step 1 - Name
    @Published var userName: String = ""

    // Step 2 - Product Type
    @Published var selectedProductType: ProductType?

    // Step 3 - Baseline
    @Published var baselinePerDay: Int = 10
    @Published var packPrice: Int = 250
    @Published var sticksInPack: Int = 20

    // Step 4 - Goal (legacy, kept for compatibility)
    @Published var selectedGoalType: GoalType?
    @Published var goalPerDay: Int = 5
    @Published var goalDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @Published var showDatePicker = false

    // Step 5 - Program Type
    @Published var selectedProgramType: ProgramType?
    @Published var programTargetValue: Int = 5

    // Step 6 - Duration
    @Published var selectedDuration: ProgramDuration = .threeMonths
    @Published var customDurationMonths: Int = 3

    private let supabase = SupabaseManager.shared

    let totalSteps = 6

    enum ProgramType: String, CaseIterable {
        case quit
        case reduce
        case observe

        var title: String {
            switch self {
            case .quit: return L.Onboarding.goalQuit
            case .reduce: return L.Onboarding.goalReduce
            case .observe: return L.Onboarding.justObserving
            }
        }

        var subtitle: String {
            switch self {
            case .quit: return L.Onboarding.goalQuitDesc
            case .reduce: return L.Onboarding.setComfortLevel
            case .observe: return L.Onboarding.goalObserveDesc
            }
        }
    }

    enum ProgramDuration: CaseIterable {
        case oneMonth
        case threeMonths
        case sixMonths
        case custom

        var title: String {
            switch self {
            case .oneMonth: return L.Onboarding.duration1Month
            case .threeMonths: return L.Onboarding.duration3Months
            case .sixMonths: return L.Onboarding.duration6Months
            case .custom: return L.Onboarding.durationCustom
            }
        }

        var subtitle: String {
            switch self {
            case .oneMonth: return L.Onboarding.intensive
            case .threeMonths: return L.Onboarding.optimal
            case .sixMonths: return L.Onboarding.gentle
            case .custom: return L.Onboarding.chooseDuration
            }
        }

        var months: Int? {
            switch self {
            case .oneMonth: return 1
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .custom: return nil
            }
        }

        var isRecommended: Bool {
            self == .threeMonths
        }
    }

    var canProceedStep1: Bool {
        !userName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var canProceedStep2: Bool {
        selectedProductType != nil
    }

    var canProceedStep3: Bool {
        baselinePerDay > 0 && packPrice > 0 && sticksInPack > 0
    }

    var canProceedStep4: Bool {
        selectedGoalType != nil
    }

    var canProceedStep5: Bool {
        selectedProgramType != nil
    }

    var canProceedStep6: Bool {
        true // Duration is always valid
    }

    /// Нужно ли показывать шаг выбора срока (только для quit/reduce)
    var needsDurationStep: Bool {
        selectedProgramType == .quit || selectedProgramType == .reduce
    }

    /// Финальное количество месяцев
    var finalDurationMonths: Int {
        selectedDuration.months ?? customDurationMonths
    }

    /// Финальное целевое значение
    var finalTargetValue: Int {
        switch selectedProgramType {
        case .quit: return 0
        case .reduce: return programTargetValue
        case .observe, .none: return baselinePerDay
        }
    }

    var progressText: String {
        // Если observe - пропускаем шаг 6, показываем 5 из 5
        let effectiveTotal = needsDurationStep ? totalSteps : totalSteps - 1
        let effectiveStep = min(currentStep, effectiveTotal)
        return L.Onboarding.stepOf(effectiveStep, effectiveTotal)
    }

    func nextStep() {
        Haptics.selection()

        // После шага 5, если observe - сразу завершаем
        if currentStep == 5 && !needsDurationStep {
            currentStep = totalSteps // Перейти к финалу
            return
        }

        guard currentStep < totalSteps else { return }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 1 else { return }
        Haptics.selection()

        // Если были на финальном шаге и observe - вернуться на 5
        if currentStep == totalSteps && !needsDurationStep {
            currentStep = 5
            return
        }

        currentStep -= 1
    }

    func selectProductType(_ type: ProductType) {
        Haptics.light()
        selectedProductType = type
    }

    func selectGoalType(_ type: GoalType) {
        Haptics.light()
        selectedGoalType = type
        showDatePicker = (type == .quit || type == .reduce)
    }

    func selectProgramType(_ type: ProgramType) {
        Haptics.light()
        selectedProgramType = type

        // Установить дефолт для reduce
        if type == .reduce {
            programTargetValue = max(1, baselinePerDay / 2)
        }
    }

    func selectDuration(_ duration: ProgramDuration) {
        Haptics.light()
        selectedDuration = duration
    }

    func completeOnboarding() async -> Bool {
        guard let productType = selectedProductType,
              let goalType = selectedGoalType else {
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let goalPerDayValue: Int? = goalType == .reduce ? goalPerDay : nil
            let goalDateValue: Date? = (goalType == .quit || goalType == .reduce) ? goalDate : nil
            let trimmedName = userName.trimmingCharacters(in: .whitespaces)

            // Program data
            let programType = selectedProgramType?.rawValue
            let programStartValue = (selectedProgramType == .quit || selectedProgramType == .reduce) ? baselinePerDay : nil
            let programTargetVal = (selectedProgramType == .quit || selectedProgramType == .reduce) ? finalTargetValue : nil
            let programDuration = (selectedProgramType == .quit || selectedProgramType == .reduce) ? finalDurationMonths : nil
            let programStartDate = (selectedProgramType == .quit || selectedProgramType == .reduce) ? Date() : nil

            try await supabase.completeOnboarding(
                name: trimmedName.isEmpty ? nil : trimmedName,
                productType: productType,
                baselinePerDay: baselinePerDay,
                packPrice: packPrice,
                sticksInPack: sticksInPack,
                goalType: goalType,
                goalPerDay: goalPerDayValue,
                goalDate: goalDateValue,
                programType: programType,
                programStartValue: programStartValue,
                programTargetValue: programTargetVal,
                programDurationMonths: programDuration,
                programStartDate: programStartDate
            )

            // Request notification permission
            _ = await NotificationManager.shared.requestPermission()

            Haptics.success()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            Haptics.error()
            return false
        }
    }
}
