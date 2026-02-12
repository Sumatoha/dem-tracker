import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionTitle("1. Information We Collect")
                        sectionText("""
                        We collect the following information:
                        • Account information (Apple ID identifier)
                        • Smoking log data (timestamps, triggers, notes)
                        • Profile settings (product type, daily baseline, goals)
                        • Subscription status
                        • App usage analytics
                        """)

                        sectionTitle("2. How We Use Your Information")
                        sectionText("""
                        Your information is used to:
                        • Provide and improve the app's functionality
                        • Track your smoking habits and progress
                        • Generate personalized statistics and insights
                        • Process subscription payments
                        • Send notifications (with your permission)
                        """)

                        sectionTitle("3. Data Storage")
                        sectionText("""
                        • Your data is stored securely on Supabase servers
                        • Data is encrypted in transit and at rest
                        • We use industry-standard security measures
                        • Local data may be cached on your device for offline access
                        """)

                        sectionTitle("4. Data Sharing")
                        sectionText("""
                        We do not sell your personal data. We may share data with:
                        • Service providers (Supabase for database, Apple for payments)
                        • Legal authorities when required by law
                        We do not share your smoking data with third parties for advertising purposes.
                        """)
                    }

                    Group {
                        sectionTitle("5. Your Rights")
                        sectionText("""
                        You have the right to:
                        • Access your personal data
                        • Request correction of inaccurate data
                        • Request deletion of your data
                        • Export your data
                        • Withdraw consent at any time
                        """)

                        sectionTitle("6. Data Retention")
                        sectionText("We retain your data as long as your account is active. You can delete your account and all associated data at any time through the app settings or by contacting us.")

                        sectionTitle("7. Children's Privacy")
                        sectionText("dem is not intended for users under 18 years of age. We do not knowingly collect data from minors.")

                        sectionTitle("8. Cookies and Tracking")
                        sectionText("The app may use local storage and analytics to improve user experience. You can disable analytics in your device settings.")

                        sectionTitle("9. Changes to Privacy Policy")
                        sectionText("We may update this policy periodically. We will notify you of significant changes through the app or email.")

                        sectionTitle("10. Contact Us")
                        sectionText("""
                        For privacy-related questions:
                        • Telegram: @dem_support
                        • Email: privacy@dem-app.com
                        """)
                    }

                    Text("Last updated: February 2026")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .padding(.top, 20)
                }
                .padding(Layout.horizontalPadding)
            }
            .background(Color.appBackground)
            .navigationTitle(L.Paywall.privacy)
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
    PrivacyPolicyView()
}
