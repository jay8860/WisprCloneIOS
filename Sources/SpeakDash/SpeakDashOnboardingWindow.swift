import AppKit
import Foundation

@MainActor
final class SpeakDashOnboardingWindowController: NSWindowController {
    private let configStore: ConfigStore
    private var config: FlowConfig
    private let onFinished: (FlowConfig) -> Void

    private var stepIndex: Int = 0
    private var titleLabel: NSTextField!
    private var bodyLabel: NSTextField!

    private var apiKeyField: NSSecureTextField!
    private var statusLabel: NSTextField!

    private var backButton: NSButton!
    private var nextButton: NSButton!
    private var testKeyButton: NSButton!

    init(configStore: ConfigStore, initialConfig: FlowConfig, onFinished: @escaping (FlowConfig) -> Void) {
        self.configStore = configStore
        self.config = initialConfig
        self.onFinished = onFinished
        super.init(window: nil)
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        ensureWindow()
        updateStepUI()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func ensureWindow() {
        guard window == nil else { return }
        let frame = NSRect(x: 0, y: 0, width: 620, height: 420)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to SpeakDash"
        window.isReleasedWhenClosed = false

        let root = NSView(frame: frame)
        root.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = root

        titleLabel = NSTextField(labelWithString: "")
        titleLabel.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(titleLabel)

        bodyLabel = NSTextField(wrappingLabelWithString: "")
        bodyLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bodyLabel)

        apiKeyField = NSSecureTextField()
        apiKeyField.placeholderString = "Paste Gemini API key"
        apiKeyField.translatesAutoresizingMaskIntoConstraints = false
        apiKeyField.isHidden = true
        root.addSubview(apiKeyField)

        testKeyButton = NSButton(title: "Test Key", target: self, action: #selector(testAPIKey))
        testKeyButton.translatesAutoresizingMaskIntoConstraints = false
        testKeyButton.isHidden = true
        root.addSubview(testKeyButton)

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(statusLabel)

        backButton = NSButton(title: "Back", target: self, action: #selector(goBack))
        backButton.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(backButton)

        nextButton = NSButton(title: "Next", target: self, action: #selector(goNext))
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.keyEquivalent = "\r"
        root.addSubview(nextButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: root.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            titleLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            bodyLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),

            apiKeyField.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 16),
            apiKeyField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            apiKeyField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),

            testKeyButton.topAnchor.constraint(equalTo: apiKeyField.bottomAnchor, constant: 10),
            testKeyButton.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),

            statusLabel.topAnchor.constraint(equalTo: testKeyButton.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            statusLabel.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),

            backButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
            backButton.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),

            nextButton.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -16),
            nextButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18)
        ])

        self.window = window
    }

    private func updateStepUI() {
        backButton.isEnabled = stepIndex > 0
        apiKeyField.isHidden = true
        testKeyButton.isHidden = true
        statusLabel.stringValue = ""

        switch stepIndex {
        case 0:
            titleLabel.stringValue = "SpeakDash is ready to dictate"
            bodyLabel.stringValue =
                "SpeakDash lets you hold a hotkey, speak, and paste the transcription into any app. " +
                "We will set up permissions and your Gemini API key now."
            nextButton.title = "Next"
        case 1:
            titleLabel.stringValue = "Grant permissions"
            bodyLabel.stringValue =
                "Please grant these permissions in System Settings: Accessibility, Input Monitoring, and Microphone. " +
                "Then return here and click Next."
            nextButton.title = "Next"
            // Trigger prompts (macOS will no-op if already granted).
            PermissionGate.promptForAccessibilityTrust()
            PermissionGate.promptForInputMonitoring()
            PermissionGate.promptForMicrophone()
        case 2:
            titleLabel.stringValue = "Add your Gemini API key"
            bodyLabel.stringValue =
                "Paste your Gemini API key. We store it in your macOS Keychain (recommended). " +
                "Click Test Key before finishing."
            apiKeyField.isHidden = false
            testKeyButton.isHidden = false
            nextButton.title = "Finish"
        default:
            break
        }
    }

    @objc private func goBack() {
        stepIndex = max(0, stepIndex - 1)
        updateStepUI()
    }

    @objc private func goNext() {
        if stepIndex == 2 {
            finishIfPossible()
            return
        }
        stepIndex = min(2, stepIndex + 1)
        updateStepUI()
    }

    @objc private func testAPIKey() {
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            statusLabel.stringValue = "Paste a key first."
            return
        }

        statusLabel.stringValue = "Testing key..."
        testKeyButton.isEnabled = false
        let model = config.geminiModel

        Task { [weak self] in
            guard let self else { return }
            let ok = await Self.validateGeminiKey(key: key, model: model)
            self.testKeyButton.isEnabled = true
            self.statusLabel.stringValue = ok ? "Key works." : "Key test failed. Check project/billing/model."
        }
    }

    private func finishIfPossible() {
        let key = apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            statusLabel.stringValue = "API key is required to finish."
            return
        }

        do {
            try KeychainStore.save(key, service: config.keychainService, account: config.keychainAccount)
        } catch {
            statusLabel.stringValue = "Failed to save key to Keychain."
            return
        }

        UserDefaults.standard.set(true, forKey: "speakdash.onboarding.completed")
        onFinished(config)
        window?.close()
    }

    nonisolated private static func validateGeminiKey(key: String, model: String) async -> Bool {
        guard var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model)") else {
            return false
        }
        components.queryItems = [URLQueryItem(name: "key", value: key)]
        guard let url = components.url else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 8

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                return (200...299).contains(http.statusCode)
            }
            return false
        } catch {
            return false
        }
    }
}
