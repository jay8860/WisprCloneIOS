import AppKit
import Foundation

@MainActor
final class VaaniSettingsWindowController: NSWindowController {
    struct ModelOption {
        let title: String
        let value: String
    }

    private let configStore: ConfigStore
    private var config: FlowConfig
    private let onConfigApplied: (FlowConfig) -> Void

    private var hotkeyPopup: NSPopUpButton!
    private var modelPopup: NSPopUpButton!
    private var languagePopup: NSPopUpButton!
    private var scriptPopup: NSPopUpButton!

    private var stripFillersCheckbox: NSButton!
    private var autoPunctuationCheckbox: NSButton!
    private var formatListsCheckbox: NSButton!
    private var voiceCommandsCheckbox: NSButton!
    private var blockSensitiveCheckbox: NSButton!

    private var maxRecordingSecondsField: NSTextField!
    private var retriesField: NSTextField!

    private let modelOptions: [ModelOption] = [
        .init(title: "Gemini 3.1 Flash Lite (Preview) - Fast", value: "gemini-3.1-flash-lite-preview"),
        .init(title: "Gemini 3 Flash (Preview) - Balanced", value: "gemini-3-flash-preview"),
        .init(title: "Gemini 2.5 Flash - Smart", value: "gemini-2.5-flash"),
        .init(title: "Gemini 2.5 Flash Lite - Fast", value: "gemini-2.5-flash-lite")
    ]

    init(configStore: ConfigStore, initialConfig: FlowConfig, onConfigApplied: @escaping (FlowConfig) -> Void) {
        self.configStore = configStore
        self.config = initialConfig
        self.onConfigApplied = onConfigApplied
        super.init(window: nil)
        shouldCascadeWindows = true
    }

    required init?(coder: NSCoder) { nil }

    func show() {
        ensureWindow()
        window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func ensureWindow() {
        guard window == nil else { return }

        let frame = NSRect(x: 0, y: 0, width: 640, height: 520)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Vaani Settings"
        window.isReleasedWhenClosed = false

        let root = NSView(frame: frame)
        root.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = root

        let tabs = NSTabView()
        tabs.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(tabs)

        NSLayoutConstraint.activate([
            tabs.topAnchor.constraint(equalTo: root.topAnchor, constant: 14),
            tabs.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 14),
            tabs.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -14),
            tabs.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -14)
        ])

        tabs.addTabViewItem(makeGeneralTab())
        tabs.addTabViewItem(makeLanguageTab())
        tabs.addTabViewItem(makeAIBehaviorTab())
        tabs.addTabViewItem(makeAdvancedTab())

        self.window = window
        refreshUI()
    }

    private func makeGeneralTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "general")
        item.label = "General"

        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let hotkeyLabel = label("Hotkey")
        hotkeyPopup = NSPopUpButton()
        hotkeyPopup.translatesAutoresizingMaskIntoConstraints = false
        hotkeyPopup.addItems(withTitles: [
            "Option + Space (hold)",
            "Ctrl + Option + Space (hold)",
            "Double-press Right Option",
            "Double-press Left Control"
        ])
        hotkeyPopup.target = self
        hotkeyPopup.action = #selector(onHotkeyChanged)

        let modelLabel = label("Gemini Model")
        modelPopup = NSPopUpButton()
        modelPopup.translatesAutoresizingMaskIntoConstraints = false
        modelPopup.addItems(withTitles: modelOptions.map(\.title))
        modelPopup.target = self
        modelPopup.action = #selector(onModelChanged)

        let maxRecLabel = label("Max Recording (sec)")
        maxRecordingSecondsField = NSTextField()
        maxRecordingSecondsField.translatesAutoresizingMaskIntoConstraints = false
        maxRecordingSecondsField.target = self
        maxRecordingSecondsField.action = #selector(onAdvancedChanged)

        let retriesLabel = label("Retries")
        retriesField = NSTextField()
        retriesField.translatesAutoresizingMaskIntoConstraints = false
        retriesField.target = self
        retriesField.action = #selector(onAdvancedChanged)

        let grid = NSGridView(views: [
            [hotkeyLabel, hotkeyPopup],
            [modelLabel, modelPopup],
            [maxRecLabel, maxRecordingSecondsField],
            [retriesLabel, retriesField]
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.columnSpacing = 16
        grid.rowSpacing = 12
        grid.yPlacement = .top
        view.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        item.view = view
        return item
    }

    private func makeLanguageTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "language")
        item.label = "Language"

        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let languageLabel = label("Mode")
        languagePopup = NSPopUpButton()
        languagePopup.translatesAutoresizingMaskIntoConstraints = false
        languagePopup.addItems(withTitles: ["Auto", "English", "Hindi", "Mixed"])
        languagePopup.target = self
        languagePopup.action = #selector(onLanguageChanged)

        let scriptLabel = label("Script")
        scriptPopup = NSPopUpButton()
        scriptPopup.translatesAutoresizingMaskIntoConstraints = false
        scriptPopup.addItems(withTitles: ["Auto", "Native", "Romanized"])
        scriptPopup.target = self
        scriptPopup.action = #selector(onLanguageChanged)

        let grid = NSGridView(views: [
            [languageLabel, languagePopup],
            [scriptLabel, scriptPopup]
        ])
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.columnSpacing = 16
        grid.rowSpacing = 12
        grid.yPlacement = .top
        view.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            grid.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        item.view = view
        return item
    }

    private func makeAIBehaviorTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "ai")
        item.label = "AI Behavior"

        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        stripFillersCheckbox = checkbox("Strip filler words", action: #selector(onToggleChanged))
        autoPunctuationCheckbox = checkbox("Auto punctuation", action: #selector(onToggleChanged))
        formatListsCheckbox = checkbox("Format spoken lists", action: #selector(onToggleChanged))
        voiceCommandsCheckbox = checkbox("Voice editing commands", action: #selector(onToggleChanged))
        blockSensitiveCheckbox = checkbox("Block in password/secure fields", action: #selector(onToggleChanged))

        let stack = NSStackView(views: [
            stripFillersCheckbox,
            autoPunctuationCheckbox,
            formatListsCheckbox,
            voiceCommandsCheckbox,
            blockSensitiveCheckbox
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        item.view = view
        return item
    }

    private func makeAdvancedTab() -> NSTabViewItem {
        let item = NSTabViewItem(identifier: "advanced")
        item.label = "Advanced"

        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let openConfig = NSButton(title: "Open config.json in Finder", target: self, action: #selector(openConfigFolder))
        openConfig.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openConfig)

        NSLayoutConstraint.activate([
            openConfig.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            openConfig.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])

        item.view = view
        return item
    }

    private func refreshUI() {
        if let idx = modelOptions.firstIndex(where: { $0.value == config.geminiModel }) {
            modelPopup.selectItem(at: idx)
        } else {
            modelPopup.selectItem(at: 0)
        }

        languagePopup.selectItem(at: languageIndex(config.languageMode))
        scriptPopup.selectItem(at: scriptIndex(config.scriptPreference))

        hotkeyPopup.selectItem(at: hotkeyIndex(config.hotkey))

        stripFillersCheckbox.state = config.stripFillers ? .on : .off
        autoPunctuationCheckbox.state = config.autoPunctuation ? .on : .off
        formatListsCheckbox.state = config.formatSpokenLists ? .on : .off
        voiceCommandsCheckbox.state = config.enableVoiceEditingCommands ? .on : .off
        blockSensitiveCheckbox.state = config.blockInSensitiveFields ? .on : .off

        maxRecordingSecondsField.stringValue = String(config.maxRecordingSeconds)
        retriesField.stringValue = String(config.maxTranscriptionRetries)
    }

    private func persistAndApply() {
        do {
            try configStore.save(config)
        } catch {
            NSSound.beep()
            return
        }
        onConfigApplied(config)
    }

    @objc private func onHotkeyChanged() {
        switch hotkeyPopup.indexOfSelectedItem {
        case 0:
            config.hotkey = HotkeyConfig(keyCode: 49, modifiers: [.option])
        case 1:
            config.hotkey = HotkeyConfig(keyCode: 49, modifiers: [.control, .option])
        case 2:
            config.hotkey = HotkeyConfig(keyCode: 61, modifiers: [])
        case 3:
            config.hotkey = HotkeyConfig(keyCode: 59, modifiers: [])
        default:
            break
        }
        persistAndApply()
    }

    @objc private func onModelChanged() {
        let idx = max(0, modelPopup.indexOfSelectedItem)
        config.geminiModel = modelOptions[min(idx, modelOptions.count - 1)].value
        persistAndApply()
    }

    @objc private func onLanguageChanged() {
        config.languageMode = languageModeForIndex(languagePopup.indexOfSelectedItem)
        config.scriptPreference = scriptPreferenceForIndex(scriptPopup.indexOfSelectedItem)
        persistAndApply()
        refreshUI()
    }

    @objc private func onToggleChanged() {
        config.stripFillers = stripFillersCheckbox.state == .on
        config.autoPunctuation = autoPunctuationCheckbox.state == .on
        config.formatSpokenLists = formatListsCheckbox.state == .on
        config.enableVoiceEditingCommands = voiceCommandsCheckbox.state == .on
        config.blockInSensitiveFields = blockSensitiveCheckbox.state == .on
        persistAndApply()
    }

    @objc private func onAdvancedChanged() {
        config.maxRecordingSeconds = max(5, Int(maxRecordingSecondsField.intValue))
        config.maxTranscriptionRetries = max(0, Int(retriesField.intValue))
        persistAndApply()
    }

    @objc private func openConfigFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([configStore.configURL])
    }

    private func label(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .labelColor
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    private func checkbox(_ title: String, action: Selector) -> NSButton {
        let b = NSButton(checkboxWithTitle: title, target: self, action: action)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    private func hotkeyIndex(_ hotkey: HotkeyConfig) -> Int {
        if hotkey.modifiers.isEmpty && hotkey.keyCode == 61 { return 2 }
        if hotkey.modifiers.isEmpty && hotkey.keyCode == 59 { return 3 }
        if hotkey.keyCode == 49 && hotkey.modifiers == [.option] { return 0 }
        if hotkey.keyCode == 49 && Set(hotkey.modifiers) == Set([.control, .option]) { return 1 }
        return 0
    }

    private func languageIndex(_ mode: FlowConfig.LanguageMode) -> Int {
        switch mode {
        case .auto: return 0
        case .english: return 1
        case .hindi: return 2
        case .mixed: return 3
        }
    }

    private func languageModeForIndex(_ idx: Int) -> FlowConfig.LanguageMode {
        switch idx {
        case 0: return .auto
        case 1: return .english
        case 2: return .hindi
        default: return .mixed
        }
    }

    private func scriptIndex(_ pref: FlowConfig.ScriptPreference) -> Int {
        switch pref {
        case .auto: return 0
        case .native: return 1
        case .romanized: return 2
        }
    }

    private func scriptPreferenceForIndex(_ idx: Int) -> FlowConfig.ScriptPreference {
        switch idx {
        case 1: return .native
        case 2: return .romanized
        default: return .auto
        }
    }
}

