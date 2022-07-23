//
//  AppDelegate.swift
//  Redis
//
//  Created by José Padilla on 2/13/16.
//  Copyright © 2016 José Padilla. All rights reserved.
//

import Cocoa
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var updater: SUUpdater!

    var paths = NSSearchPathForDirectoriesInDomains(
        FileManager.SearchPathDirectory.documentDirectory,
        FileManager.SearchPathDomainMask.userDomainMask, true)

    var documentsDirectory: AnyObject
    var dataPath: String
    var logPath: String

    var task: Process = Process()
    var pipe: Pipe = Pipe()
    var file: FileHandle

    var statusBar = NSStatusBar.system
    var statusBarItem: NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()

    var statusMenuItem: NSMenuItem = NSMenuItem()
    var openCLIMenuItem: NSMenuItem = NSMenuItem()
    var openLogsMenuItem: NSMenuItem = NSMenuItem()
    var docsMenuItem: NSMenuItem = NSMenuItem()
    var aboutMenuItem: NSMenuItem = NSMenuItem()
    var versionMenuItem: NSMenuItem = NSMenuItem()
    var quitMenuItem: NSMenuItem = NSMenuItem()
    var updatesMenuItem: NSMenuItem = NSMenuItem()

    override init() {
        self.file = self.pipe.fileHandleForReading
        self.documentsDirectory = self.paths[0] as AnyObject
        self.dataPath = documentsDirectory.appendingPathComponent("RedisData")
        self.logPath = documentsDirectory.appendingPathComponent("RedisData/Logs")

        super.init()
    }

    func startServer() {
        self.task = Process()
        self.pipe = Pipe()
        self.file = self.pipe.fileHandleForReading

        if let path = Bundle.main.path(forResource: "redis-server", ofType: "", inDirectory: "Vendor/redis/bin") {
            self.task.launchPath = path
        }

        self.task.arguments = ["--dir", self.dataPath, "--logfile", "\(self.logPath)/redis.log"]
        self.task.standardOutput = self.pipe

        print("Run redis-server")

        self.task.launch()
    }

    func stopServer() {
        print("Terminate redis-server")
        task.terminate()

        let data: Data = self.file.readDataToEndOfFile()
        self.file.closeFile()

        let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        print(output)
    }

    @objc func openCLI(_ sender: AnyObject) {
        if let path = Bundle.main.path(forResource: "redis-cli", ofType: "", inDirectory: "Vendor/redis/bin") {
            var source: String

            if appExists("iTerm") {
                source = "tell application \"iTerm\" \n" +
                            "activate \n" +
                            "create window with default profile \n" +
                            "tell current session of current window \n" +
                                "write text \"\(path)\" \n" +
                            "end tell \n" +
                        "end tell"
            } else {
                source = "tell application \"Terminal\" \n" +
                    "activate \n" +
                    "do script \"\(path)\" \n" +
                "end tell"
            }

            if let script = NSAppleScript(source: source) {
                script.executeAndReturnError(nil)
            }
        }
    }

    @objc func openDocumentationPage(_ send: AnyObject) {
        if let url: URL = URL(string: "https://github.com/jpadilla/redisapp") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openLogsDirectory(_ send: AnyObject) {
        NSWorkspace.shared.openFile(self.logPath)
    }

    func createDirectories() {
        if (!FileManager.default.fileExists(atPath: self.dataPath)) {
            do {
                try FileManager.default
                    .createDirectory(atPath: self.dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Something went wrong creating dataPath")
            }
        }

        if (!FileManager.default.fileExists(atPath: self.logPath)) {
            do {
                try FileManager.default
                    .createDirectory(atPath: self.logPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Something went wrong creating logPath")
            }
        }

        print("Redis data directory: \(self.dataPath)")
        print("Redis logs directory: \(self.logPath)")
    }

    @objc func checkForUpdates(_ sender: AnyObject?) {
        print("Checking for updates")
        self.updater.checkForUpdates(sender)
    }

    func setupSystemMenuItem() {
        // Add statusBarItem
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu

        let icon = NSImage(named: "logo")
        icon!.isTemplate = true
        icon!.size = NSSize(width: 18, height: 18)
        statusBarItem.image = icon

        // Add version to menu
        versionMenuItem.title = "Redis"
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String? {
            versionMenuItem.title = "Redis v\(version)"
        }
        menu.addItem(versionMenuItem)

        // Add actionMenuItem to menu
        statusMenuItem.title = "Running on Port 6379"
        menu.addItem(statusMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separator())

        // Add open redis-cli to menu
        openCLIMenuItem.title = "Open redis-cli"
        openCLIMenuItem.action = #selector(AppDelegate.openCLI(_:))
        menu.addItem(openCLIMenuItem)

        // Add open logs to menu
        openLogsMenuItem.title = "Open logs directory"
        openLogsMenuItem.action = #selector(AppDelegate.openLogsDirectory(_:))
        menu.addItem(openLogsMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separator())

        // Add check for updates to menu
        updatesMenuItem.title = "Check for Updates..."
        updatesMenuItem.action = #selector(AppDelegate.checkForUpdates(_:))
        menu.addItem(updatesMenuItem)

        // Add about to menu
        aboutMenuItem.title = "About"
        aboutMenuItem.action = #selector(NSApplication.orderFrontStandardAboutPanel(_:))
        menu.addItem(aboutMenuItem)

        // Add docs to menu
        docsMenuItem.title = "Documentation..."
        docsMenuItem.action = #selector(AppDelegate.openDocumentationPage(_:))
        menu.addItem(docsMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separator())

        // Add quitMenuItem to menu
        quitMenuItem.title = "Quit"
        quitMenuItem.action = #selector(NSApplication.shared.terminate)
        menu.addItem(quitMenuItem)
    }

    func appExists(_ appName: String) -> Bool {
        let found = [
            "/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app",
            "\(NSHomeDirectory())/Applications/\(appName).app"
            ].map {
                return FileManager.default.fileExists(atPath: $0)
            }.reduce(false) {
                if $0 == false && $1 == false {
                    return false;
                } else {
                    return true;
                }
        }

        return found
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createDirectories()
        setupSystemMenuItem()
        startServer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopServer()
    }

}
