import SwiftUI
import BayNavigatorCore

/// PIN entry view for unlocking, setting up, changing, or removing PIN
struct PINEntryView: View {
    enum Mode {
        case unlock
        case setup
        case change
        case remove
        case forgotPIN

        var title: String {
            switch self {
            case .unlock: return "Enter PIN"
            case .setup: return "Set Up PIN"
            case .change: return "Change PIN"
            case .remove: return "Remove PIN"
            case .forgotPIN: return "Forgot PIN"
            }
        }

        var subtitle: String {
            switch self {
            case .unlock: return "Enter your PIN to continue"
            case .setup: return "Create a 6-8 digit PIN"
            case .change: return "Enter your current PIN"
            case .remove: return "Enter your PIN to remove protection"
            case .forgotPIN: return "Resetting will delete all app data"
            }
        }
    }

    enum Step {
        case enterCurrent
        case enterNew
        case confirmNew
    }

    let mode: Mode
    let onComplete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PINEntryViewModel()
    @State private var currentStep: Step = .enterCurrent
    @State private var enteredPIN = ""
    @State private var newPIN = ""
    @State private var showingForgotPINAlert = false
    @State private var showingBiometricOption = false

    private let pinLength = 6
    private let maxPinLength = 8

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: headerIcon)
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)

                Text(headerTitle)
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(headerSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // PIN Dots Display
            HStack(spacing: 16) {
                ForEach(0..<maxPinLength, id: \.self) { index in
                    Circle()
                        .fill(index < enteredPIN.count ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .scaleEffect(index < enteredPIN.count ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2), value: enteredPIN.count)
                }
            }
            .padding(.vertical, 8)

            // Error Message
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.subheadline)
                .foregroundStyle(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Failed Attempts Warning
            if mode == .unlock && viewModel.failedAttempts > 0 && viewModel.panicWipeEnabled {
                let remaining = viewModel.maxFailedAttempts - viewModel.failedAttempts
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("\(remaining) attempt\(remaining == 1 ? "" : "s") remaining")
                }
                .font(.subheadline)
                .foregroundStyle(.orange)
            }

            Spacer()

            // Numeric Keypad
            numericKeypad

            // Biometric Button (for unlock mode)
            if mode == .unlock && viewModel.canUseBiometrics && viewModel.biometricEnabled {
                Button {
                    Task {
                        await authenticateWithBiometrics()
                    }
                } label: {
                    Label("Use \(viewModel.biometricType.displayName)", systemImage: viewModel.biometricType.systemImage)
                        .font(.headline)
                }
                .padding(.top, 8)
            }

            // Forgot PIN Button (for unlock mode)
            if mode == .unlock {
                Button("Forgot PIN?") {
                    showingForgotPINAlert = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(mode.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                if mode != .unlock {
                    Button("Cancel") {
                        onComplete(false)
                    }
                }
            }
        }
        .task {
            await viewModel.loadState()
            // Set initial step based on mode
            switch mode {
            case .unlock, .remove:
                currentStep = .enterCurrent
            case .setup, .forgotPIN:
                currentStep = .enterNew
            case .change:
                currentStep = .enterCurrent
            }

            // Auto-trigger biometrics on unlock if available
            if mode == .unlock && viewModel.canUseBiometrics && viewModel.biometricEnabled {
                await authenticateWithBiometrics()
            }
        }
        .alert("Forgot PIN?", isPresented: $showingForgotPINAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset & Delete Data", role: .destructive) {
                Task {
                    await viewModel.executePanicWipe()
                    onComplete(false)
                }
            }
        } message: {
            Text("If you forgot your PIN, the only option is to reset the app. This will permanently delete ALL your data including your profile, favorites, and history.")
        }
        .onChange(of: enteredPIN) { _, newValue in
            if newValue.count >= pinLength {
                handlePINEntry()
            }
        }
    }

    // MARK: - Header Properties

    private var headerIcon: String {
        switch currentStep {
        case .enterCurrent:
            return mode == .unlock ? "lock.fill" : "lock.open.fill"
        case .enterNew:
            return "lock.badge.plus"
        case .confirmNew:
            return "checkmark.lock.fill"
        }
    }

    private var headerTitle: String {
        switch currentStep {
        case .enterCurrent:
            switch mode {
            case .unlock: return "Enter PIN"
            case .change: return "Current PIN"
            case .remove: return "Confirm PIN"
            default: return mode.title
            }
        case .enterNew:
            return mode == .setup ? "Create PIN" : "New PIN"
        case .confirmNew:
            return "Confirm PIN"
        }
    }

    private var headerSubtitle: String {
        switch currentStep {
        case .enterCurrent:
            switch mode {
            case .unlock: return "Enter your PIN to access the app"
            case .change: return "Enter your current PIN first"
            case .remove: return "Enter your PIN to disable protection"
            default: return mode.subtitle
            }
        case .enterNew:
            return "Create a 6-8 digit PIN that you'll remember"
        case .confirmNew:
            return "Enter your new PIN again to confirm"
        }
    }

    // MARK: - Numeric Keypad

    private var numericKeypad: some View {
        VStack(spacing: 16) {
            ForEach(0..<4) { row in
                HStack(spacing: 24) {
                    ForEach(0..<3) { col in
                        keypadButton(for: row, col: col)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keypadButton(for row: Int, col: Int) -> some View {
        let buttonContent = keypadContent(row: row, col: col)

        Button {
            handleKeypadPress(row: row, col: col)
        } label: {
            if let number = buttonContent.number {
                Text("\(number)")
                    .font(.title)
                    .fontWeight(.medium)
                    .frame(width: 72, height: 72)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
            } else if let icon = buttonContent.icon {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 72, height: 72)
            } else {
                Color.clear
                    .frame(width: 72, height: 72)
            }
        }
        .disabled(buttonContent.number == nil && buttonContent.icon == nil)
    }

    private func keypadContent(row: Int, col: Int) -> (number: Int?, icon: String?) {
        let keypadLayout = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
            [-1, 0, -2] // -1 = empty, -2 = delete
        ]

        let value = keypadLayout[row][col]

        if value == -1 {
            return (nil, nil)
        } else if value == -2 {
            return (nil, "delete.left")
        } else {
            return (value, nil)
        }
    }

    private func handleKeypadPress(row: Int, col: Int) {
        let keypadLayout = [
            [1, 2, 3],
            [4, 5, 6],
            [7, 8, 9],
            [-1, 0, -2]
        ]

        let value = keypadLayout[row][col]

        if value == -2 {
            // Delete
            if !enteredPIN.isEmpty {
                enteredPIN.removeLast()
            }
        } else if value >= 0 {
            // Number
            if enteredPIN.count < maxPinLength {
                enteredPIN.append(String(value))
                #if os(iOS)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
            }
        }
    }

    // MARK: - PIN Entry Handling

    private func handlePINEntry() {
        viewModel.errorMessage = nil

        Task {
            switch currentStep {
            case .enterCurrent:
                await handleCurrentPINEntry()
            case .enterNew:
                await handleNewPINEntry()
            case .confirmNew:
                await handleConfirmPINEntry()
            }
        }
    }

    private func handleCurrentPINEntry() async {
        let isValid = await viewModel.validatePIN(enteredPIN)

        if isValid {
            await viewModel.resetFailedAttempts()

            switch mode {
            case .unlock:
                onComplete(true)
            case .change:
                enteredPIN = ""
                currentStep = .enterNew
            case .remove:
                await viewModel.removePIN()
                onComplete(true)
            default:
                break
            }
        } else {
            let shouldWipe = await viewModel.recordFailedAttempt()
            if shouldWipe {
                await viewModel.executePanicWipe()
                onComplete(false)
            } else {
                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                #endif
                enteredPIN = ""
            }
        }
    }

    private func handleNewPINEntry() async {
        let validation = await viewModel.validatePINStrength(enteredPIN)

        if validation.isValid {
            newPIN = enteredPIN
            enteredPIN = ""
            currentStep = .confirmNew
        } else {
            viewModel.errorMessage = validation.message
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            enteredPIN = ""
        }
    }

    private func handleConfirmPINEntry() async {
        if enteredPIN == newPIN {
            let result = await viewModel.setPIN(newPIN)
            if result.success {
                onComplete(true)
            } else {
                viewModel.errorMessage = result.message
                enteredPIN = ""
                newPIN = ""
                currentStep = .enterNew
            }
        } else {
            viewModel.errorMessage = "PINs do not match. Try again."
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            #endif
            enteredPIN = ""
            newPIN = ""
            currentStep = .enterNew
        }
    }

    // MARK: - Biometric Authentication

    private func authenticateWithBiometrics() async {
        let success = await viewModel.authenticateWithBiometrics()
        if success {
            await viewModel.resetFailedAttempts()
            onComplete(true)
        }
    }
}

// MARK: - View Model

@MainActor
class PINEntryViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var failedAttempts = 0
    @Published var maxFailedAttempts = 3
    @Published var panicWipeEnabled = false
    @Published var biometricEnabled = false
    @Published var canUseBiometrics = false

    var biometricType: BiometricType {
        SafetyService.shared.canUseBiometrics()
    }

    func loadState() async {
        let service = SafetyService.shared

        failedAttempts = await service.getFailedPinAttempts()
        maxFailedAttempts = await service.getMaxFailedAttempts()
        panicWipeEnabled = await service.isPanicWipeEnabled()
        biometricEnabled = await service.isBiometricEnabled()
        canUseBiometrics = biometricType != .none
    }

    func validatePIN(_ pin: String) async -> Bool {
        await SafetyService.shared.validatePin(pin)
    }

    func validatePINStrength(_ pin: String) async -> PinValidation {
        await SafetyService.shared.validatePinStrength(pin)
    }

    func setPIN(_ pin: String) async -> PinSetResult {
        await SafetyService.shared.setPin(pin)
    }

    func removePIN() async {
        await SafetyService.shared.removePin()
    }

    func recordFailedAttempt() async -> Bool {
        let shouldWipe = await SafetyService.shared.recordFailedPinAttempt()
        failedAttempts = await SafetyService.shared.getFailedPinAttempts()
        errorMessage = "Incorrect PIN"
        return shouldWipe
    }

    func resetFailedAttempts() async {
        await SafetyService.shared.resetFailedPinAttempts()
        failedAttempts = 0
    }

    func authenticateWithBiometrics() async -> Bool {
        await SafetyService.shared.authenticateWithBiometrics(reason: "Unlock Bay Navigator")
    }

    func executePanicWipe() async {
        await SafetyService.shared.executePanicWipe()
    }
}

#Preview("Unlock") {
    NavigationStack {
        PINEntryView(mode: .unlock) { success in
            print("PIN unlock: \(success)")
        }
    }
}

#Preview("Setup") {
    NavigationStack {
        PINEntryView(mode: .setup) { success in
            print("PIN setup: \(success)")
        }
    }
}
