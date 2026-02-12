import SwiftUI

struct TriggerSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTrigger: TriggerType?

    var onConfirm: (TriggerType?) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        Haptics.selection()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.primaryAccent)
                            .frame(width: 10, height: 10)

                        Text("dem")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }

                    Spacer()

                    // Invisible spacer for alignment
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 20)

                // Title section
                VStack(alignment: .center, spacing: 12) {
                    Text(L.Trigger.whyNow)
                        .font(.screenTitle)
                        .foregroundColor(.textPrimary)

                    Text(L.Trigger.selectTrigger)
                        .font(.sectionLabel)
                        .kerning(3)
                        .foregroundColor(.textSecondary)
                }
                .padding(.top, 40)

                // Trigger Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(TriggerType.allCases, id: \.self) { trigger in
                        TriggerCard(
                            trigger: trigger,
                            isSelected: selectedTrigger == trigger
                        ) {
                            Haptics.light()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                if selectedTrigger == trigger {
                                    selectedTrigger = nil
                                } else {
                                    selectedTrigger = trigger
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.top, 32)

                Spacer()

                // Bottom buttons
                VStack(spacing: 16) {
                    Button {
                        Haptics.success()
                        onConfirm(selectedTrigger)
                        dismiss()
                    } label: {
                        Text(L.Trigger.confirmChoice)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        Haptics.selection()
                        onConfirm(nil)
                        dismiss()
                    } label: {
                        Text(L.Trigger.skip)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Trigger Card

struct TriggerCard: View {
    let trigger: TriggerType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: trigger.iconName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.primaryAccent)

                Text(trigger.displayName)
                    .font(.triggerLabel)
                    .kerning(1)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(isSelected ? Color.white : Color.cardFill)
            .cornerRadius(Layout.cardCornerRadius)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                        .stroke(Color.primaryAccent, lineWidth: 2)
                }
            }
        }
        .pressEffect()
    }
}

#Preview {
    TriggerSelectionView { trigger in
        print("Selected: \(String(describing: trigger))")
    }
}
