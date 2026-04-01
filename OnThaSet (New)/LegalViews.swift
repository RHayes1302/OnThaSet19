//
//  LegalViews.swift
//  OnThaSet (New)
//

import SwiftUI

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        VStack(spacing: 8) {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 60)).foregroundColor(.yellow)
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 10, weight: .black))
                                    Text("THA").font(.system(size: 8, weight: .black))
                                    Text("SET").font(.system(size: 13, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            }
                            Text("Privacy Policy")
                                .font(.title.bold()).foregroundColor(.yellow)
                            Text("Last Updated: March 30, 2026")
                                .font(.caption).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 10)

                        policySection(title: "1. Introduction",
                            content: "Welcome to On Tha Set. We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application. Please read this policy carefully. If you disagree with its terms, please discontinue use of the App.")

                        policySection(title: "2. Information We Collect",
                            content: "We may collect the following types of information:\n\nLocation Data: With your permission, we collect your device's GPS location to show you nearby motorcycle events. This data is used only within the app and is not stored on our servers.\n\nAccount Information: If you sign in with Apple, we receive a unique identifier and optionally your name and email address as provided by Apple.\n\nEvent Information: When you post an event, we collect the event title, date, location, description, and any images you upload.\n\nPayment Information: Subscription and single-post purchases are processed entirely through Apple's In-App Purchase system. We do not collect or store your payment card information.\n\nAdvertiser Information: Businesses that submit advertising inquiries provide their business name, contact information, address, and logo. This information is stored securely in our database.")

                        policySection(title: "3. How We Use Your Information",
                            content: "We use the information we collect to display motorcycle events near your location, enable you to post and manage events, process subscription and single-post purchases through Apple, display approved business advertisements to app users, contact advertisers regarding their advertising submissions, improve and optimize the App, respond to your inquiries, and comply with legal obligations.")

                        policySection(title: "4. Sharing Your Information",
                            content: "We do not sell, trade, or rent your personal information to third parties. We may share information with service providers such as Supabase for secure cloud database storage. We may also share information if required by law or in response to valid legal process.")

                        policySection(title: "5. Location Information",
                            content: "We request access to your device's location to show you nearby motorcycle events. Location access is optional. We do not store your location on our servers or share it with third parties. Location data is used only in real-time within the App.")

                        policySection(title: "6. Photos and Media",
                            content: "We request access to your photo library to allow you to upload event flyers and business logos. Images you upload are stored securely in our cloud storage and are visible to all App users. We do not access photos you have not explicitly selected for upload.")

                        policySection(title: "7. Data Retention",
                            content: "We retain your posted events and account information for as long as your account is active or as needed to provide services. You may request deletion of your data by contacting us at contact.onthaset@gmail.com.")

                        policySection(title: "8. Children's Privacy",
                            content: "On Tha Set is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13.")

                        policySection(title: "9. Security",
                            content: "We implement industry-standard security measures to protect your information, including encrypted data transmission and secure cloud storage. However, no method of transmission over the internet is 100% secure.")

                        policySection(title: "10. Your Rights",
                            content: "Depending on your location, you may have the right to access, correct, or delete your personal information. To exercise these rights, contact us at contact.onthaset@gmail.com.")

                        policySection(title: "11. Third-Party Links",
                            content: "The App may contain links to third-party websites or services, including advertiser websites. We are not responsible for the privacy practices of these third parties.")

                        policySection(title: "12. Changes to This Policy",
                            content: "We may update this Privacy Policy from time to time. Your continued use of the App after changes constitutes acceptance of the updated policy.")

                        policySection(title: "13. Event Safety Notice",
                            content: "On Tha Set is a platform for discovering motorcycle community events. We do not organize or supervise any events listed on our platform. Attendance at any event discovered through On Tha Set is entirely at your own risk. On Tha Set and its owners are not responsible for any harm, injury, death, property damage, or damage of any kind that occurs at or in connection with any event posted on the platform.")

                        policySection(title: "14. Contact Us",
                            content: "If you have questions or concerns about this Privacy Policy, please contact us at:\n\nOn Tha Set\nEmail: contact.onthaset@gmail.com")
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.yellow).font(.title3.bold())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Privacy Policy").font(.caption.bold()).foregroundColor(.yellow)
                }
            }
        }
    }

    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline.bold()).foregroundColor(.yellow)
            Text(content).font(.subheadline).foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        VStack(spacing: 8) {
                            ZStack {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 60)).foregroundColor(.yellow)
                                VStack(spacing: -1) {
                                    Text("ON").font(.system(size: 10, weight: .black))
                                    Text("THA").font(.system(size: 8, weight: .black))
                                    Text("SET").font(.system(size: 13, weight: .black))
                                }.foregroundColor(.black).offset(y: -2)
                            }
                            Text("Terms of Service")
                                .font(.title.bold()).foregroundColor(.yellow)
                            Text("Last Updated: March 30, 2026")
                                .font(.caption).foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity).padding(.top, 10)

                        termSection(title: "1. Acceptance of Terms",
                            content: "By downloading, installing, or using the On Tha Set mobile application, you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the App.")

                        termSection(title: "2. Description of Service",
                            content: "On Tha Set is a motorcycle community platform that allows users to discover, post, and share motorcycle events including rallies, club annuals, charity rides, and other community gatherings. The App also provides weather forecasts, nearby event discovery, and a national run calendar.")

                        termSection(title: "3. User Accounts",
                            content: "You may sign in using Apple Sign In. You must be at least 13 years of age to use this App. You are responsible for all activity that occurs under your account and agree to provide accurate and complete information.")

                        termSection(title: "4. Event Posting",
                            content: "When posting events on On Tha Set, you agree to post only events related to the motorcycle community, provide accurate event information, not post events that promote illegal activity or discrimination, and not post spam or misleading content. We reserve the right to remove any event that violates these terms without notice.")

                        termSection(title: "5. Subscription and Payments",
                            content: "Single Post ($0.99): A one-time consumable purchase allowing you to post one event.\n\nMonthly Subscription ($2.99/month): An auto-renewing subscription providing up to 4 event posts per month. Additional posts can be purchased at $0.99 each when the monthly limit is reached.\n\nAll payments are processed through Apple's App Store. Subscriptions automatically renew unless cancelled at least 24 hours before the renewal date. Manage subscriptions through your Apple ID account settings.")

                        termSection(title: "6. Advertising",
                            content: "Businesses wishing to advertise on On Tha Set agree to provide accurate business information, pay the applicable advertising fee upon approval, and not submit false or deceptive advertising content. We reserve the right to reject or remove any advertisement at our discretion. Advertising fees are non-refundable once an ad has been approved and made live.")

                        termSection(title: "7. User Content",
                            content: "By posting content on On Tha Set including event descriptions, images, and flyers, you grant us a non-exclusive, worldwide, royalty-free license to use, display, and distribute that content within the App.")

                        termSection(title: "8. Prohibited Conduct",
                            content: "You agree not to use the App for any unlawful purpose, post offensive or threatening content, attempt to access other users' accounts, interfere with the App's servers, use automated tools to scrape data, impersonate any person, or post content that infringes intellectual property rights.")

                        termSection(title: "9. Disclaimer of Warranties",
                            content: "The App is provided 'as is' and 'as available' without warranties of any kind. We are not responsible for the accuracy of event information posted by users.")

                        termSection(title: "10. Event Liability Disclaimer",
                            content: "ON THA SET, ITS OWNERS, OPERATORS, EMPLOYEES, AFFILIATES, AND AGENTS ARE NOT RESPONSIBLE FOR, AND EXPRESSLY DISCLAIM ALL LIABILITY FOR, ANY INJURY, DEATH, PROPERTY DAMAGE, LOSS, ACCIDENT, DELAY, OR OTHER HARM OR DAMAGE OF ANY KIND THAT OCCURS IN CONNECTION WITH, AS A RESULT OF, OR IN ASSOCIATION WITH ANY EVENT POSTED ON THE ON THA SET PLATFORM.\n\nOn Tha Set is a technology platform that provides a digital space for motorcycle community members to post and discover events. We do not organize, host, sponsor, supervise, or control any events listed on our platform. We make no representations or warranties regarding the safety, legality, accuracy, or quality of any event posted by users.\n\nBy using this App, you acknowledge and agree that:\n\n1. Attendance at any event discovered through On Tha Set is entirely at your own risk.\n\n2. On Tha Set has no control over the conduct of event organizers, attendees, motorcycle clubs, or any individuals associated with events posted on the platform.\n\n3. On Tha Set is not liable for any criminal acts, violent conduct, accidents, injuries, property damage, or any other harm arising from or related to events posted on the platform.\n\n4. Event organizers who post events on On Tha Set assume full responsibility for the safety, legality, and conduct of their events and all persons in attendance.\n\n5. On Tha Set does not endorse, verify, or guarantee the accuracy of any event information posted by users.\n\n6. You waive any and all claims against On Tha Set arising from your attendance at or participation in any event posted on the platform.\n\nThis disclaimer applies to all event categories including but not limited to motorcycle rallies, club annuals, charity events, unity runs, social club events, riding club events, and bike nights.\n\nIF YOU DO NOT AGREE TO ASSUME FULL RESPONSIBILITY FOR YOUR ATTENDANCE AT EVENTS DISCOVERED THROUGH THIS PLATFORM, DO NOT USE THE APP TO DISCOVER OR ATTEND EVENTS.")

                        termSection(title: "11. Limitation of Liability",
                            content: "To the maximum extent permitted by law, On Tha Set shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of the App, including damages related to events you attend based on information found in the App.")

                        termSection(title: "12. Indemnification",
                            content: "You agree to indemnify and hold harmless On Tha Set and its owners, operators, employees, affiliates, and agents from any and all claims, damages, losses, liabilities, costs, and expenses including reasonable attorneys fees arising from your use of the App, your attendance at any event posted on the platform, your violation of these Terms, or your violation of any third-party rights.")

                        termSection(title: "13. Changes to Terms",
                            content: "We reserve the right to modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the new Terms.")

                        termSection(title: "14. Governing Law",
                            content: "These Terms shall be governed by and construed in accordance with the laws of the State of Nevada. Any disputes arising under these Terms shall be resolved in the courts of Clark County, Nevada.")

                        termSection(title: "15. Severability",
                            content: "If any provision of these Terms is found to be unenforceable or invalid, that provision will be limited or eliminated to the minimum extent necessary so that these Terms will otherwise remain in full force and effect.")

                        termSection(title: "16. Contact",
                            content: "For questions about these Terms of Service, contact us at:\n\nOn Tha Set\nEmail: contact.onthaset@gmail.com")
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(.yellow).font(.title3.bold())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Terms of Service").font(.caption.bold()).foregroundColor(.yellow)
                }
            }
        }
    }

    private func termSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline.bold()).foregroundColor(.yellow)
            Text(content).font(.subheadline).foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white.opacity(0.04))
        .cornerRadius(10)
    }
}
