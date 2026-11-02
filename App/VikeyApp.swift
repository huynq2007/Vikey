import SwiftUI

@main
struct VikeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var state = AppState.shared

    var body: some Scene {
        #if compiler(>=5.7)
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(state)
        } label: {
            Image(nsImage: MenuBarIcon.image(vietnamese: state.language == 1))
        }
        .commands { commands }
        #else
        // Xcode 13: the menu bar item is StatusMenu (AppKit); this scene only carries the app menu commands
        Settings { EmptyView() }
            .commands { commands }
        #endif
    }

    @CommandsBuilder private var commands: some Commands {
            CommandGroup(replacing: .appInfo) {
                Button("Giới thiệu về Vikey") { AboutPanel.show() }   // with the credits
                Button("Ghi nhận…") { Windows.acknowledgements.show() }
                Button("Kiểm tra cập nhật…") { Updater.shared.checkForUpdates() }
                Divider()
                DebugMenu()
            }
            CommandGroup(replacing: .appSettings) {
                Button("Mở Vikey…") { Windows.main.show() }
                    .keyboardShortcut(",")
            }
    }
}
