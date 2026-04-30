import AppKit
import Foundation

@MainActor
final class VaaniLicenseWindowController: NSWindowController {
    private var keyField: NSSecureTextField!
    private var statusLabel: NSTextField!

    init() {
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

            status.centerYAnchor.constraint(equalTo: activate.centerYAnchor),
            status.leadingAnchor.constraint(equalTo: clear.trailingAnchor, constant: 12),
            status.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16),

            version.topAnchor.constraint(equalTo: activate.bottomAnchor, constant: 12),
            version.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            version.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -16)
        ])

        self.window = window
    }

    private func refresh() {
        let existing = LicenseManager.readKey() ?? ""
        keyField.stringValue = existing
        statusLabel.stringValue = existing.isEmpty ? "Not activated" : "Key saved"
        statusLabel.textColor = existing.isEmpty ? .secondaryLabelColor : .systemGreen
    }

    @objc private func saveKey() {
        do {
            try LicenseManager.saveKey(keyField.stringValue)
            statusLabel.stringValue = "Saved"
            statusLabel.textColor = .systemGreen
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
            statusLabel.stringValue = "Cleared"
            statusLabel.textColor = .secondaryLabelColor
        } catch {
            NSSound.beep()
            statusLabel.stringValue = "Clear failed"
            statusLabel.textColor = .systemRed
        }
    }
}

