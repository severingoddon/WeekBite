import SwiftUI

struct WeekPlanView: View {
    @Environment(APIClient.self) private var api
    @Environment(UserContextViewModel.self) private var userContext

    @State private var viewModel: WeekPlanViewModel?
    @State private var selectedDay: WeekDay?
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var showResetConfirm = false
    @State private var toast: ToastMessage?

    private static let weekdayNames = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"]

    private var todayName: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Self.weekdayNames[weekday - 1]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerView
                if let vm = viewModel {
                    if vm.noWeekFound {
                        WeekEmptyStateView()
                    } else if let week = vm.currentWeek {
                        ForEach(Array(week.days.enumerated()), id: \.element.id) { index, day in
                            DayCardView(day: day, isToday: vm.isCurrentWeek && day.day == todayName, onTap: {
                                selectedDay = day
                            }, onRemove: {
                                vm.updateWeekDay(day, menuId: nil)
                            }, onAddToShopping: { ingredient in
                                await vm.addToShoppingList(ingredient)
                            }, onUndoShopping: { itemId in
                                await vm.undoShoppingAdd(itemId)
                            })
                        }
                    }
                }
            }
            .padding()
        }
        .background(WBColor.bgDeepest)
        .toast($toast)
        .onAppear {
            if viewModel == nil { resetVM() } else { Task { await viewModel?.loadWeek() } }
        }
        .onChange(of: userContext.contextVersion) { resetVM() }
        .onChange(of: userContext.refreshVersion) { Task { await viewModel?.loadWeek() } }
        .fullScreenCover(item: $selectedDay) { day in
            MenuPopupView(dayName: day.day) { menuId in
                viewModel?.updateWeekDay(day, menuId: menuId)
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .confirmationDialog("Woche zurücksetzen?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) {
                viewModel?.resetWeek()
                toast = ToastMessage(text: "Woche zurückgesetzt", actionLabel: nil, action: nil)
            }
        } message: {
            Text("Alle Menu-Zuweisungen dieser Woche werden entfernt.")
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                GradientText(text: "Wochenplan")
                Spacer()
                if let vm = viewModel {
                    Text(vm.weekLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(WBColor.textSecondary)
                }
            }

            HStack(spacing: 8) {
                Button {
                    showDatePicker = true
                } label: {
                    Image(systemName: "calendar")
                        .foregroundStyle(WBColor.textSecondary)
                }

                if let vm = viewModel {
                    OutlineButton(
                        title: vm.nextWeekExists ? "Nächste Woche" : "+ Nächste Woche",
                        action: {
                            if let msg = vm.createOrShowNextWeek() {
                                toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                            }
                        }
                    )

                    if !vm.isCurrentWeek {
                        OutlineButton(title: "Aktuell") {
                            vm.goToCurrentWeek()
                        }
                    }
                }

                Spacer()

                Menu {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Woche zurücksetzen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(WBColor.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("Datum wählen", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(WBColor.accentCyan)
                .padding()
                .presentationDetents([.medium])
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") {
                            showDatePicker = false
                            let dateStr = selectedDate.toISODateString()
                            Task { await viewModel?.loadWeek(date: dateStr) }
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { showDatePicker = false }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }

    private func resetVM() {
        let vm = WeekPlanViewModel(api: api)
        viewModel = vm
        Task { await vm.loadWeek() }
    }
}
