//
//  AppDelegate.swift
//  Redis
//
//  Created by José Padilla on 2/13/16.
//  Copyright © 2016 José Padilla. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var paths = NSSearchPathForDirectoriesInDomains(
        NSSearchPathDirectory.DocumentDirectory,
        NSSearchPathDomainMask.UserDomainMask, true)

    var documentsDirectory: AnyObject
    var dataPath: String
    var logPath: String

    var task: NSTask = NSTask()
    var pipe: NSPipe = NSPipe()
    var file: NSFileHandle

    var statusBar = NSStatusBar.systemStatusBar()
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
        self.documentsDirectory = self.paths[0]
        self.dataPath = documentsDirectory.stringByAppendingPathComponent("RedisData")
        self.logPath = documentsDirectory.stringByAppendingPathComponent("RedisData/Logs")

        super.init()
    }

    func startServer() {
        self.task = NSTask()
        self.pipe = NSPipe()
        self.file = self.pipe.fileHandleForReading

        if let path = NSBundle.mainBundle().pathForResource("redis-server", ofType: "", inDirectory: "Vendor/redis/bin") {
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

        let data: NSData = self.file.readDataToEndOfFile()
        self.file.closeFile()

        let output: String = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        print(output)
    }

    func openCLI(sender: AnyObject) {
        if let path = NSBundle.mainBundle().pathForResource("redis-cli", ofType: "", inDirectory: "Vendor/redis/bin") {
            var source: String

            if appExists("iTerm") {
                source = "tell application \"iTerm\" \n" +
                    "activate \n" +
                    "set newTerminal to (make new terminal) \n" +
                    "tell newTerminal \n" +
                    "launch session \"Default Session\" \n" +
                    "tell the last session \n" +
                    "write text \"\(path)\" \n" +
                    "end tell \n" +
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

    func openDocumentationPage(send: AnyObject) {
        if let url: NSURL = NSURL(string: "https://github.com/jpadilla/redisapp") {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
    }

    func openLogsDirectory(send: AnyObject) {
        NSWorkspace.sharedWorkspace().openFile(self.logPath)
    }

    func createDirectories() {
        if (!NSFileManager.defaultManager().fileExistsAtPath(self.dataPath)) {
            do {
                try NSFileManager.defaultManager()
                    .createDirectoryAtPath(self.dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Something went wrong creating dataPath")
            }
        }

        if (!NSFileManager.defaultManager().fileExistsAtPath(self.logPath)) {
            do {
                try NSFileManager.defaultManager()
                    .createDirectoryAtPath(self.logPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Something went wrong creating logPath")
            }
        }

        print("Redis data directory: \(self.dataPath)")
        print("Redis logs directory: \(self.logPath)")
    }

    func checkForUpdates(sender: AnyObject?) {
        print("Checking for updates")
    }

    func setupSystemMenuItem() {
        // Add statusBarItem
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu

        let icon = NSImage(named: "logo")
        icon!.template = true
        icon!.size = NSSize(width: 18, height: 18)
        statusBarItem.image = icon

        // Add version to menu
        versionMenuItem.title = "Redis"
        if let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String? {
            versionMenuItem.title = "Redis v\(version)"
        }
        menu.addItem(versionMenuItem)

        // Add actionMenuItem to menu
        statusMenuItem.title = "Running on Port 6379"
        menu.addItem(statusMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separatorItem())

        // Add open redis-cli to menu
        openCLIMenuItem.title = "Open redis-cli"
        openCLIMenuItem.action = Selector("openCLI:")
        menu.addItem(openCLIMenuItem)

        // Add open logs to menu
        openLogsMenuItem.title = "Open logs directory"
        openLogsMenuItem.action = Selector("openLogsDirectory:")
        menu.addItem(openLogsMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separatorItem())

        // Add check for updates to menu
        updatesMenuItem.title = "Check for Updates..."
        updatesMenuItem.action = Selector("checkForUpdates:")
        menu.addItem(updatesMenuItem)

        // Add about to menu
        aboutMenuItem.title = "About"
        aboutMenuItem.action = Selector("orderFrontStandardAboutPanel:")
        menu.addItem(aboutMenuItem)

        // Add docs to menu
        docsMenuItem.title = "Documentation..."
        docsMenuItem.action = Selector("openDocumentationPage:")
        menu.addItem(docsMenuItem)

        // Add separator
        menu.addItem(NSMenuItem.separatorItem())

        // Add quitMenuItem to menu
        quitMenuItem.title = "Quit"
        quitMenuItem.action = Selector("terminate:")
        menu.addItem(quitMenuItem)
    }

    func appExists(appName: String) -> Bool {
        let found = [
            "/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app",
            "\(NSHomeDirectory())/Applications/\(appName).app"
            ].map {
                return NSFileManager.defaultManager().fileExistsAtPath($0)
            }.reduce(false) {
                if $0 == false && $1 == false {
                    return false;
                } else {
                    return true;
                }
        }

        return found
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        createDirectories()
        setupSystemMenuItem()
        startServer()
    }

    func applicationWillTerminate(notification: NSNotification) {
        stopServer()
    }

}
