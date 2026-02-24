import SwiftUI

struct DayCardView: View {
    let day: WeekDay
    let onTap: () -> Void
    let onRemove: () -> Void

    private var isWeekend: Bool {
        day.day == "Samstag" || day.day == "Sonntag"
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.day)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(WBColor.textPrimary)
                    if let menu = day.menu {
                        Text(menu.title)
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.accentCyan)
                    } else {
                        Text("Kein Menu gewählt")
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.textMuted)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    if day.menu != nil {
                        Button {
                            onRemove()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundStyle(.red.opacity(0.8))
                                .padding(6)
                        }
                        .buttonStyle(.plain)
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(WBColor.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .cardStyle(isWeekend: isWeekend)
        }
        .buttonStyle(.plain)
    }
}
