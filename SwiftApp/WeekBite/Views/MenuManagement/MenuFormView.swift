import SwiftUI

struct MenuFormView: View {
    @Bindable var viewModel: MenuManagementViewModel
    @Binding var toast: ToastMessage?
    var onDone: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Menu Titel", text: $viewModel.menuTitle)
                .textFieldStyle(WBTextFieldStyle())

            HStack(spacing: 8) {
                TextField("Notiz", text: $viewModel.menuNote)
                    .textFieldStyle(WBTextFieldStyle())
                TextField("Min.", value: $viewModel.menuEffort, format: .number)
                    .textFieldStyle(WBTextFieldStyle())
                    .frame(width: 70)
                    .keyboardType(.numberPad)
            }

            TextField("Link (optional)", text: $viewModel.menuLink)
                .textFieldStyle(WBTextFieldStyle())
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)

            HStack(spacing: 8) {
                TextField("Zutat hinzufügen", text: $viewModel.ingredientInput)
                    .textFieldStyle(WBTextFieldStyle())
                    .onSubmit { viewModel.addIngredient() }
                Button {
                    viewModel.addIngredient()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(viewModel.ingredientInput.trimmingCharacters(in: .whitespaces).isEmpty ? WBColor.textMuted : WBColor.accentCyan)
                }
                .disabled(viewModel.ingredientInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !viewModel.ingredients.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(viewModel.ingredients, id: \.self) { ingredient in
                        HStack(spacing: 4) {
                            Text(ingredient)
                                .font(.system(size: 13))
                            Button {
                                viewModel.removeIngredient(ingredient)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                            }
                        }
                        .foregroundStyle(WBColor.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(WBColor.bgActive)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }

            GradientButton(
                title: viewModel.editingMenu != nil ? "Aktualisieren" : "Hinzufügen",
                action: {
                    if let msg = viewModel.saveMenu() {
                        toast = ToastMessage(text: msg, actionLabel: nil, action: nil)
                    }
                    onDone?()
                },
                disabled: viewModel.menuTitle.trimmingCharacters(in: .whitespaces).isEmpty
            )
        }
    }
}

struct WBTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14))
            .foregroundStyle(WBColor.textPrimary)
            .padding(10)
            .background(WBColor.bgDeepest)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(WBColor.borderSubtle, lineWidth: 1)
            )
    }
}
