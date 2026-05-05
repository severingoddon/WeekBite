import SwiftUI

struct DayCardView: View {
    let day: WeekDay
    let isToday: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    let onAddToShopping: (String) async -> (success: Bool, itemId: Int?)
    let onUndoShopping: (Int) async -> Void

    @State private var showIngredients = false

    private var isWeekend: Bool {
        day.day == "Samstag" || day.day == "Sonntag"
    }

    var body: some View {
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

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(WBColor.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .cardStyle(isWeekend: isWeekend)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(WBColor.accentGreen.opacity(0.4), lineWidth: 1)
                .shadow(color: WBColor.accentGreen.opacity(0.1), radius: 4)
                .opacity(isToday ? 1 : 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            if day.menu != nil {
                Button {
                    showIngredients = true
                } label: {
                    Label("Zutaten anzeigen", systemImage: "list.bullet")
                }
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Menu entfernen", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showIngredients) {
            if let menu = day.menu {
                DayIngredientSheet(
                    dayName: day.day,
                    menu: menu,
                    onAddToShopping: onAddToShopping,
                    onUndoShopping: onUndoShopping
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
            }
        }
    }
}

struct DayIngredientSheet: View {
    let dayName: String
    let menu: MenuModel
    let onAddToShopping: (String) async -> (success: Bool, itemId: Int?)
    let onUndoShopping: (Int) async -> Void

    @State private var toast: ToastMessage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Menu info
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.textMuted)
                        Text("\(menu.effort_min) Minuten")
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.textSecondary)
                        if !menu.link.isEmpty, let url = URL(string: menu.link) {
                            Link(destination: url) {
                                Image(systemName: "link")
                                    .font(.system(size: 13))
                                    .foregroundStyle(WBColor.accentCyan)
                            }
                        }
                    }

                    if !menu.note.isEmpty {
                        Text(menu.note)
                            .font(.system(size: 13))
                            .foregroundStyle(WBColor.textSecondary)
                    }

                    // Ingredients
                    if menu.ingredients.isEmpty {
                        Text("Keine Zutaten hinterlegt.")
                            .font(.system(size: 14))
                            .foregroundStyle(WBColor.textMuted)
                    } else {
                        Text("Tippe auf eine Zutat, um sie zur Einkaufsliste hinzuzufügen.")
                            .font(.system(size: 12))
                            .foregroundStyle(WBColor.textMuted)

                        FlowLayout(spacing: 6) {
                            ForEach(menu.ingredients, id: \.self) { ingredient in
                                Button {
                                    Task {
                                        let result = await onAddToShopping(ingredient)
                                        if result.success {
                                            let itemId = result.itemId
                                            toast = ToastMessage(
                                                text: "\(ingredient) hinzugefügt",
                                                actionLabel: "Rückgängig",
                                                action: {
                                                    if let id = itemId {
                                                        Task { await onUndoShopping(id) }
                                                    }
                                                }
                                            )
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(ingredient)
                                            .font(.system(size: 13))
                                        Image(systemName: "plus")
                                            .font(.system(size: 10))
                                    }
                                    .foregroundStyle(WBColor.textPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(WBColor.bgActive)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(WBColor.bgDeepest)
            .toast($toast)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(dayName) · \(menu.title)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(WBColor.textPrimary)
                }
            }
        }
    }
}
