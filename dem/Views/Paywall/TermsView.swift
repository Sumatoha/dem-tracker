import SwiftUI

struct TermsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionTitle("1. Acceptance of Terms")
                        sectionText("By downloading, installing, or using the dem app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app.")

                        sectionTitle("2. Description of Service")
                        sectionText("dem is a nicotine consumption tracking application designed to help users monitor and reduce their smoking habits. The app provides tracking, statistics, and motivational features.")

                        sectionTitle("3. Subscription Terms")
                        sectionText("""
                        • dem offers subscription-based premium features
                        • Subscription automatically renews unless cancelled at least 24 hours before the end of the current period
                        • Payment will be charged to your Apple ID account at confirmation of purchase
                        • You can manage and cancel subscriptions in your App Store account settings
                        • No refunds will be provided for partial subscription periods
                        """)

                        sectionTitle("4. Free Trial")
                        sectionText("""
                        • New users may be eligible for a 14-day free trial
                        • The trial provides full access to premium features
                        • If you don't cancel before the trial ends, your subscription will automatically begin
                        • Each user is eligible for only one free trial
                        """)
                    }

                    Group {
                        sectionTitle("5. User Responsibilities")
                        sectionText("""
                        • You are responsible for maintaining the confidentiality of your account
                        • You agree to provide accurate information
                        • You agree not to use the app for any illegal purposes
                        • The app is not a medical device and should not replace professional medical advice
                        """)

                        sectionTitle("6. Health Disclaimer")
                        sectionText("dem is a tracking tool only. It does not provide medical advice, diagnosis, or treatment. Always consult with a healthcare professional regarding smoking cessation. The health recovery percentages shown are estimates based on general medical research.")

                        sectionTitle("7. Intellectual Property")
                        sectionText("All content, features, and functionality of dem are owned by the app developers and are protected by international copyright laws.")

                        sectionTitle("8. Limitation of Liability")
                        sectionText("dem is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the app.")

                        sectionTitle("9. Changes to Terms")
                        sectionText("We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of the new terms.")

                        sectionTitle("10. Contact")
                        sectionText("For questions about these Terms, contact us via Telegram or email.")
                    }

                    Text("Last updated: February 2026")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .padding(.top, 20)
                }
                .padding(Layout.horizontalPadding)
            }
            .background(Color.appBackground)
            .navigationTitle(L.Paywall.terms)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L.Common.done) {
                        dismiss()
                    }
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.textPrimary)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.textSecondary)
    }
}

#Preview {
    TermsView()
}
