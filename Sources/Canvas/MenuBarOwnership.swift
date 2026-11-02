import AppKit

/// Who owns the menu bar while the canvas is in front.
///
/// Sunlight is an accessory app (LSUIElement): no Dock icon, no menu bar of its own. With an accessory
/// app in front, macOS leaves the menu bar to the last regular app, and a click anywhere in it (that
/// app's menus, Wi-Fi, the clock, any status item) brings that app forward. On the canvas that reads
/// as the user going to the app, so the canvas went into its window.
///
/// With Settings › General › "Sunlight's menu bar on the canvas" on, Sunlight is a regular app for as
/// long as it runs: each time it activates, macOS gives it the menu bar (its own, `AppDelegate.installMenu`),
/// and clicks there stay on the canvas. It has to stay regular: macOS hands the menu bar over as an app
/// activates, so turning regular only on activation (before it or after it) left the last app's menus up
/// after most trips back from a window. The price is a Dock icon, which takeover hides with the Dock.
/// Setup's Dock icon (`SetupWizard`) is asked for here too, so the two never undo each other.
@MainActor
enum MenuBarOwnership {
    /// The setup window is up and wants its Dock icon.
    static var setupShown = false {
        didSet { update() }
    }

    private static var token: NSObjectProtocol?

    /// Takes the policy the settings ask for, and follows the setting from now on.
    static func start() {
        guard token == nil else { return }
        token = NotificationCenter.default.addObserver(forName: Settings.ownsMenuBarDidChange, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { update() }
        }
        update()
    }

    /// Regular while setup is up, or for as long as the setting is on and Sunlight is on; accessory otherwise.
    static func wanted(setupShown: Bool, owns: Bool, sunlightOn: Bool) -> NSApplication.ActivationPolicy {
        setupShown || (owns && sunlightOn) ? .regular : .accessory
    }

    /// Applies the policy for now: after a change of the setting, of Sunlight on or off, or of setup.
    static func update() {
        let policy = wanted(setupShown: setupShown, owns: Settings.ownsMenuBar, sunlightOn: Settings.sunlightOn)
        guard NSApp.activationPolicy() != policy else { return }
        let wasActive = NSApp.isActive
        let switched = NSApp.setActivationPolicy(policy)
        NSLog("Menu bar: \(policy == .regular ? "Sunlight's own on the canvas" : "the last app's")\(switched ? "" : " — macOS refused the switch")")
        // Turned regular while active (the setting switched on in Settings), the menu bar is Sunlight's
        // from its next activation. Going back to accessory can deactivate the app: the canvas stays in
        // front all the same.
        if policy == .accessory, wasActive { NSApp.activate() }
    }
}
