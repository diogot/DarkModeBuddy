//
//  AppDelegate.swift
//  DarkModeBuddy
//
//  Created by Guilherme Rambo on 23/02/21.
//

import Cocoa
import SwiftUI
import DarkModeBuddyCore
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    
    let settings = DMBSettings()

    lazy var switcher: DMBSystemAppearanceSwitcher = {
        DMBSystemAppearanceSwitcher(settings: settings)
    }()
    
    private var shouldShowUI: Bool {
        !settings.hasLaunchedAppBefore || UserDefaults.standard.bool(forKey: "ShowSettings")
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        SUUpdater.shared()?.delegate = self
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if shouldShowUI {
            settings.hasLaunchedAppBefore = true
            showSettingsWindow(nil)
        }
        
        switcher.activate()
    }

    @IBAction func showSettingsWindow(_ sender: Any?) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 385, height: 360),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Settings")
        window.titlebarAppearsTransparent = true
        window.title = "DarkModeBuddy Settings"
        window.isMovableByWindowBackground = true
        window.delegate = self
        window.isReleasedWhenClosed = false
        
        let view = SettingsView()
            .environmentObject(DMBAmbientLightSensorReader(frequency: .realtime))
            .environmentObject(settings)
        
        window.contentView = NSHostingView(rootView: view)
        
        window.makeKeyAndOrderFront(nil)
        window.center()
        
        NSApp.activate(ignoringOtherApps: true)
    }

    private var isShowingSettingsWindow: Bool {
        guard let window = window else { return false }
        return window.isVisible
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !isShowingSettingsWindow else { return true }
        
        showSettingsWindow(nil)
        
        return true
    }
    
    private var shouldSkipTerminationConfirmation = false
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard !shouldSkipTerminationConfirmation else { return .terminateNow }

        let alert = NSAlert()
        alert.messageText = "Quit DarkModeBuddy?"
        alert.informativeText = "If you quit DarkModeBuddy, it won't be able to monitor your ambient light level and change the system theme automatically. Would you like to hide DarkModeBuddy instead?"
        alert.addButton(withTitle: "Hide DarkModeBuddy")
        alert.addButton(withTitle: "Quit")

        let result = alert.runModal()

        if result == .alertSecondButtonReturn {
            return .terminateNow
        } else {
            window?.close()
            
            return .terminateCancel
        }
    }

}

extension AppDelegate: NSWindowDelegate {

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
    
}

extension AppDelegate: SUUpdaterDelegate {
    
    func updaterWillRelaunchApplication(_ updater: SUUpdater) {
        shouldSkipTerminationConfirmation = true
    }
    
    func updater(_ updater: SUUpdater, didCancelInstallUpdateOnQuit item: SUAppcastItem) {
        shouldSkipTerminationConfirmation = false
    }
    
}
