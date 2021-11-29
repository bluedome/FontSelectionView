//
//  SidebarViewController.swift
//  Sample
//
//

import Cocoa

class SidebarViewController: NSViewController {

    private var fontView: FontSelectionView!
    
    var observer: Any?
    var currentFields: [NSTextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fontView = FontSelectionView.instantiate()
        fontView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(fontView)
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: fontView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: fontView.trailingAnchor),
            view.topAnchor.constraint(equalTo: fontView.topAnchor)
        ])
        
        fontView.onSelectHandler = { [unowned self] fonts in
            guard !self.currentFields.isEmpty else { return }
            
            if fonts.count == 1 {
                self.currentFields.forEach { $0.font = fonts[0]}
            } else {
                for (idx, field) in self.currentFields.enumerated() {
                    field.font = fonts[idx]
                }
            }
        }
        
        observer = NotificationCenter.default.addObserver(forName: ViewController.selectionChanged, object: nil, queue: nil) { notif in
            guard let fields = notif.userInfo?[ViewController.selectedFieldsKey] as? [NSTextField] else {
                return
            }
            
            if fields.isEmpty {
                self.fontView.isEnabled = false
                self.currentFields.removeAll()
            } else {
                self.fontView.isEnabled = true
                self.currentFields = fields
                self.fontView.select(fonts: fields.compactMap { $0.font })
            }
        }
    }
    
    deinit {
        if let obs = observer {
            NotificationCenter.default.removeObserver(obs)
            observer = nil
        }
    }
}
