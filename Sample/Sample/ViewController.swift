//
//  ViewController.swift
//  Sample
//
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var textField1: FocusRingTextField!
    @IBOutlet weak var textField2: FocusRingTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.window?.center()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        
        textField1.isSelected = true
        selectedViews.append(textField1)
        NotificationCenter.default.post(name: ViewController.selectionChanged, object: self, userInfo: [ViewController.selectedFieldsKey: selectedViews])
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    var selectedViews: [FocusRingTextField] = []
    
    override func mouseDown(with event: NSEvent) {
        let point = view.convert(event.locationInWindow, from: nil)
        
        let targetView = view.subviews.first { $0.frame.contains(point) }
        if let text = targetView as? FocusRingTextField {
            if event.modifierFlags.contains(.command) {
                if !selectedViews.contains(text) {
                    selectedViews.append(text)
                }
            } else {
                selectedViews.forEach { $0.isSelected = false }
                selectedViews.removeAll()
                selectedViews.append(text)
            }
            text.isSelected = true
        }
        
        NotificationCenter.default.post(name: ViewController.selectionChanged, object: self, userInfo: [ViewController.selectedFieldsKey: selectedViews])
    }
    
    override func mouseUp(with event: NSEvent) {
        let point = view.convert(event.locationInWindow, from: nil)
        
        let targetView = view.subviews.first { $0.frame.contains(point) }
        if targetView == nil {
            view.subviews.forEach {
                ($0 as? FocusRingTextField)?.isSelected = false
            }
            selectedViews.removeAll()
            NotificationCenter.default.post(name: ViewController.selectionChanged, object: self, userInfo: [ViewController.selectedFieldsKey: []])

        }
    }
    
    /// the userInfo contains selectedFieldsKey
    static let selectionChanged = Notification.Name("selectionChanged")
    /// value is [NSTextField]
    static let selectedFieldsKey = "selectedFieldsKey"
}

class FocusRingTextField: NSTextField {
    var isSelected: Bool = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if isSelected {
            NSGraphicsContext.saveGraphicsState()
            NSFocusRingPlacement.only.set()
            bounds.insetBy(dx: 2, dy: 2).fill()
            NSGraphicsContext.restoreGraphicsState()
        }
    }
    
    private var trackingArea: NSTrackingArea?
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        trackingAreas.forEach {
            self.removeTrackingArea($0)
        }
        
        let area = NSTrackingArea(rect: bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(area)
        
        trackingArea = area
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == trackingArea {
            NSCursor.openHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == trackingArea {
            NSCursor.arrow.set()
        }
    }
}
