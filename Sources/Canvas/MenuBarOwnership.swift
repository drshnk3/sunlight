import AppKit

/// Who owns the menu bar while the canvas is in front.
///
/// Sunlight is an accessory app (LSUIElement): no Dock icon, no menu bar of its own. With an accessory
/// app in front, macOS leaves the menu bar to the last regular app, and a click anywhere in it (that
/// app's menus, Wi-Fi, the clock, any status item) brings that app forward. On the canvas that reads
/// as the user going to the app, so the canvas went into its window. With Settings › General ›
/// "Sunlight's menu bar on the canvas" on, Sunlight is a regular app while it's active: the menu bar is
/// its own (`AppDelegate.installMenu`), and clicks in it stay on the canvas. Back to accessory once
/// another app is in front, so nothing else changes: no Dock icon, no place in ⌘Tab, while a window is
/// in use. Setup's Dock icon (`SetupWizard`) is asked for here too, so the two never undo each other.
@MainActor
enum MenuBarOwnership {
    /// The setup window is up and wants its Dock icon.
    static var setupShown = false {
        didSet { update() }
    }

    private static var tokens: [NSObjectProtocol] = []

    /// Follows activation from now on.
    static func start() {
        guard tokens.isEmpty else { return }
        let center = NotificationCenter.default
        for name in [NSApplication.didBecomeActiveNotification, NSApplication.didResignActiveNotification,
                     Settings.ownsMenuBarDidChange] {
            tokens.append(center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { update() }
            })
        }
        update()
    }

    /// The policy for the moment: regular while setup is up, or while Sunlight is active with the
    /// setting on; accessory otherwise.
    static func wanted(active: Bool, setupShown: Bool, owns: Bool, sunlightOn: Bool) -> NSApplication.ActivationPolicy {
        setupShown || (active && owns && sunlightOn) ? .regular : .accessory
    }

    static func update() {
        let policy = wanted(active: NSApp.isActive, setupShown: setupShown, owns: Settings.ownsMenuBar,
                            sunlightOn: Settings.sunlightOn)
        guard NSApp.activationPolicy() != policy else { return }
        let wasActive = NSApp.isActive
        NSApp.setActivationPolicy(policy)
        // Going back to accessory can deactivate the app: the canvas stays in front all the same.
        if policy == .accessory, wasActive { NSApp.activate() }
    }
}
