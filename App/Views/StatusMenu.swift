import AppKit
import Combine

// Building with Xcode 13 (no MenuBarExtra): the menu bar icon and menu in AppKit, with the items of MenuBarContent.
#if !compiler(>=5.7)

@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    static let shared = StatusMenu()
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var languageSub: AnyCancellable?

    func install() {
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        languageSub = AppState.shared.$language.sink { [weak self] lang in
            self?.item.button?.image = MenuBarIcon.image(vietnamese: lang == 1)
        }
    }

    /// Rebuilt each time it opens, so the per-app toggle follows the app in front.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let state = AppState.shared
        let d = UserDefaults.standard
        if state.needsOnboarding {
            add(menu, "Cấp quyền cho Vikey…") { OnboardingWindow.show() }
            menu.addItem(.separator())
        }
        let hotkey = Hotkey(raw: d.object(forKey: PrefKey.hotkey) as? Int ?? Hotkey.defaultValue)
        add(menu, "Tiếng Việt   \(hotkey.display)", on: state.language == 1) { state.setLanguage(state.language == 1 ? 0 : 1) }
        let autoSwitch = d.object(forKey: PrefKey.autoSwitch) as? Int ?? 1
        add(menu, "Tự chuyển Anh/Việt", on: autoSwitch == 1) {
            d.set(autoSwitch == 1 ? 0 : 1, forKey: PrefKey.autoSwitch); Preferences.apply()
        }
        let app = VikeyCore.frontAppName()
        if VikeyCore.frontAppIsExcluded() {
            add(menu, "\(app): đã loại trừ", action: nil)
        } else {
            let on = VikeyCore.autoSwitchEnabledForFrontApp()
            add(menu, "Tự chuyển ở \(app)", on: on) { VikeyCore.setAutoSwitchForFrontApp(!on) }
        }
        menu.addItem(.separator())
        add(menu, "Mở Vikey…", key: ",") { Windows.main.show() }
        menu.addItem(.separator())
        add(menu, "Hướng dẫn…") { OnboardingWindow.show() }
        add(menu, "Gửi góp ý…") { Feedback.open() }
        add(menu, "Kiểm tra cập nhật…") { Updater.shared.checkForUpdates() }
        add(menu, "Giới thiệu Vikey") { AboutPanel.show() }
        add(menu, "Thoát Vikey", key: "q") { NSApp.terminate(nil) }
    }

    private func add(_ menu: NSMenu, _ title: String, on: Bool? = nil, key: String = "", action: (() -> Void)?) {
        let mi = NSMenuItem(title: title, action: action == nil ? nil : #selector(ClosureTarget.run), keyEquivalent: key)
        if let action = action {
            let target = ClosureTarget(action)
            mi.target = target
            mi.representedObject = target   // keeps the target alive with the item
        }
        if let on = on { mi.state = on ? .on : .off }
        menu.addItem(mi)
    }
}

private final class ClosureTarget: NSObject {
    private let action: () -> Void
    init(_ action: @escaping () -> Void) { self.action = action }
    @objc func run() { action() }
}

#endif
