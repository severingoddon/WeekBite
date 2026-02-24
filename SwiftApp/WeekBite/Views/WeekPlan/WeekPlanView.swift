import SwiftUI

struct WeekPlanView: View {
    @Environment(APIClient.self) private var api
    @Environment(UserContextViewModel.self) private var userContext
    @Environment(TourManager.self) private var tourManager

    @State private var viewModel: WeekPlanViewModel?
    @State private var selectedDay: WeekDay?
    @State private var showDatePicker = false
    @State private var selectedDate = Date()
    @State private var showResetConfirm = false
    @State private var toast: ToastMessage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                headerView
                if let vm = viewModel {
                    if vm.noWeekFound {
                        WeekEmptyStateView()
                    } else if let week = vm.currentWeek {
                        ForEach(Array(week.days.enumerated()), id: \.element.id) { index, day in
                            DayCardView(day: day, onTap: {
                                selectedDay = day
                            }, onRemove: {
                                Task { await vm.updateWeekDay(day, menuId: nil) }
                            })
                            .tourAnchor(index == 0 ? "day-card" : "")
                        }
                    }
                }
            }
            .padding()
        }
        .background(WBColor.bgDeepest)
        .toast($toast)
        .onAppear { initVM() }
        .onChange(of: userContext.contextVersion) { initVM() }
        .fullScreenCover(item: $selectedDay) { day in
            MenuPopupView(dayName: day.day) { menuId in
                if let vm = viewModel {
                    Task { await vm.updateWeekDay(day, menuId: menuId) }
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .confirmationDialog("Woche zurücksetzen?", isPresented: $showResetConfirm, titleVisibility: .visible) {
            Button("Zurücksetzen", role: .destructive) {
                Task {
                    await viewModel?.resetWeek()
                    toast = ToastMessage(text: "Woche zurückgesetzt", actionLabel: nil, action: nil)
                }
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
                .tourAnchor("date-picker-btn")

                if let vm = viewModel {
                    OutlineButton(
                        title: vm.nextWeekExists ? "Nächste Woche" : "+ Nächste Woche",
                        action: {
                            Task {
                                if let msg = await vm.createOrShowNextWeek() {
                                    toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                                }
                            }
                        }
                    )
                    .tourAnchor("next-week-btn")

                    if !vm.isCurrentWeek {
                        OutlineButton(title: "Aktuell") {
                            Task { await vm.goToCurrentWeek() }
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
                            Task { await viewModel?.loadWeek(date: selectedDate.toISODateString()) }
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Abbrechen") { showDatePicker = false }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }

    private func initVM() {
        let vm = WeekPlanViewModel(api: api)
        viewModel = vm
        Task {
            await vm.loadWeek()
            tryStartTour()
        }
    }

    private func tryStartTour() {
        guard !tourManager.hasSeenTour("week-plan") else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tourManager.startTour("week-plan", steps: TourDefinitions.weekPlan)
        }
    }
}
