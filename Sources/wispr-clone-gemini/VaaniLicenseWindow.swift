import AppKit
import Foundation

@MainActor
final class VaaniLicenseWindowController: NSWindowController {
    private let configStore: ConfigStore
    private var config: FlowConfig
    private var keyField: NSSecureTextField!
    private var statusLabel: NSTextField!
    private var buyButton: NSButton!

    init(configStore: ConfigStore, initialConfig: FlowConfig) {
        self.configStore = configStore
        self.config = initialConfig
        super.init(window: nil)
        shouldCascadeWindows = true
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        ensureWindow()
        refresh()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func updateConfig(_ config: FlowConfig) {
        self.config = config
        refresh()
    }

    private func ensureWindow() {
        guard window == nil else { return }

        let frame = NSRect(x: 0, y: 0, width: 520, height: 220)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "License"
        window.isReleasedWhenClosed = false

        let root = NSView(frame: frame)
        root.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = root

        let title = NSTextField(labelWithString: "Activate Wispr Clone Gemini")
        title.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        title.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(title)

        let subtitle = NSTextField(labelWithString: "Enter your license key to activate this device.")
        subtitle.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = .secondaryLabelColor
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(subtitle)

        let keyLabel = NSTextField(labelWithString: "License Key")
        keyLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(keyLabel)

        let keyField = NSSecureTextField()
        keyField.translatesAutoresizingMaskIntoConstraints = false
        keyField.placeholderString = "XXXX-XXXX-XXXX-XXXX"
        root.addSubview(keyField)
        self.keyField = keyField

        let activate = NSButton(title: "Save Key", target: self, action: #selector(saveKey))
        activate.translatesAutoresizingMaskIntoConstraints = false
        activate.bezelStyle = .rounded
        root.addSubview(activate)

        let clear = NSButton(title: "Clear", target: self, action: #selector(clearKey))
        clear.translatesAutoresizingMaskIntoConstraints = false
        clear.bezelStyle = .rounded
        root.addSubview(clear)

        let buy = NSButton(title: "Buy", target: self, action: #selector(openPurchase))
        buy.translatesAutoresizingMaskIntoConstraints = false
        buy.bezelStyle = .rounded
        root.addSubview(buy)
        self.buyButton = buy

        let status = NSTextField(labelWithString: "")
        status.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        status.textColor = .secondaryLabelColor
        status.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(status)
        self.statusLabel = status

        let version = NSTextField(labelWithString: "Version: \(AppVersion.displayString)")
        version.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        version.textColor = .secondaryLabelColor
        version.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(version)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: root.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            subtitle.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            subtitle.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16),

            keyLabel.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 14),
            keyLabel.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),

            keyField.topAnchor.constraint(equalTo: keyLabel.bottomAnchor, constant: 6),
            keyField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            keyField.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),

            activate.topAnchor.constraint(equalTo: keyField.bottomAnchor, constant: 12),
            activate.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),

            clear.centerYAnchor.constraint(equalTo: activate.centerYAnchor),
            clear.leadingAnchor.constraint(equalTo: activate.trailingAnchor, constant: 10),

            buy.centerYAnchor.constraint(equalTo: activate.centerYAnchor),
            buy.leadingAnchor.constraint(equalTo: clear.trailingAnchor, constant: 10),

            status.topAnchor.constraint(equalTo: activate.bottomAnchor, constant: 10),
            status.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            status.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16),

            version.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 10),
            version.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            version.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16)
        ])

        self.window = window
    }

    private func refresh() {
        let existing = LicenseManager.readKey() ?? ""
        keyField.stringValue = existing

        let verified = VaaniLicenseVerifier.verify(licenseKey: existing, publicKeyBase64: config.licensePublicKeyBase64)
        if verified.isValid {
            statusLabel.stringValue = "Activated"
            statusLabel.textColor = .systemGreen
        } else {
            switch config.licenseMode {
            case .off:
                statusLabel.stringValue = "Licensing: off"
                statusLabel.textColor = .secondaryLabelColor
            case .trial:
                let ok = VaaniLicenseVerifier.isTrialValid(trialDays: config.trialDays)
                if ok {
                    let start = VaaniLicenseVerifier.ensureTrialStart()
                    let deadline = start.addingTimeInterval(Double(max(0, config.trialDays)) * 24 * 3600)
                    let remaining = Int(max(0, deadline.timeIntervalSinceNow) / (24 * 3600))
                    statusLabel.stringValue = "Trial active (\(remaining)d left)"
                    statusLabel.textColor = .secondaryLabelColor
                } else {
                    statusLabel.stringValue = "Trial expired. Please buy to continue."
                    statusLabel.textColor = .systemOrange
                }
            case .required:
                statusLabel.stringValue = "Activation required"
                statusLabel.textColor = .systemOrange
            }
        }

        buyButton.isHidden = (config.purchaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @objc private func saveKey() {
        do {
            try LicenseManager.saveKey(keyField.stringValue)
            refresh()
        } catch {
            NSSound.beep()
            statusLabel.stringValue = "Invalid key"
            statusLabel.textColor = .systemRed
        }
    }

    @objc private func clearKey() {
        do {
            try LicenseManager.clearKey()
            keyField.stringValue = ""
            refresh()
        } catch {
            NSSound.beep()
            statusLabel.stringValue = "Clear failed"
            statusLabel.textColor = .systemRed
        }
    }

    @objc private func openPurchase() {
        let urlString = config.purchaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: urlString), !urlString.isEmpty else { return }
        NSWorkspace.shared.open(url)
    }
}
