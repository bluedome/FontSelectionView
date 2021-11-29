//
//  FontSelectionView.swift
//

import Cocoa

class FontSelectionView: NSView, NSTextFieldDelegate, NSMenuDelegate {
    
    class func instantiate() -> FontSelectionView {
        if let nib = NSNib(nibNamed: "FontSelectionView", bundle: nil) {
            var views: NSArray?
            if nib.instantiate(withOwner: self, topLevelObjects: &views) {
                if let v = views!.first(where: { $0 is FontSelectionView }) as? FontSelectionView {
                    return v
                }
            }
        }
        preconditionFailure()
    }
    
    /// changed this value, you may also need to update each popup-menu width.
    static let defaultPopUpMenuFontSize: CGFloat = NSFont.systemFontSize

    static let defaultFamilyPopUpMenuWidth: CGFloat = 240
    static let defaultMemberPopUpMenuWidth: CGFloat = 120
    
    /// these fonts are drawn with System Font
    private let specialFontNames: Set<String> = [
        "Bodoni Ornaments"
    ]

    @IBOutlet weak var familyPopUpButton: NSPopUpButton!
    @IBOutlet weak var memberPopUpButton: NSPopUpButton!
    @IBOutlet weak var sizeField: NSTextField! {
        didSet { sizeField.integerValue = 60 }
    }
    @IBOutlet weak var sizeStepper: NSStepper! {
        didSet { sizeStepper.integerValue = 60 }
    }
    
    // MARK: -- Main API

    func select(fonts: [NSFont]) {
        updateViews(fonts)
    }

    /// the order of returned fonts is the same as passed fonts' one via *select*.
    var onSelectHandler: (([NSFont]) -> Void)?

    var isEnabled = true {
        didSet {
            familyPopUpButton.isEnabled = isEnabled
            memberPopUpButton.isEnabled = isEnabled
            sizeField.isEnabled = isEnabled
            sizeStepper.isEnabled = isEnabled
        }
    }
    
    private var familyNames: [String] = []
    private var localizedFamilyNames: [String] = []
    private var currentMembers: [String] = []
    
    private var sizeFieldFont: NSFont!
    private var sizeFieldTextColor: NSColor!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)

        familyNames = NSFontManager.shared.availableFontFamilies
    }
    
    private enum MenuItemTag: Int {
        case family, member
    }
    
    override func awakeFromNib() {
        familyPopUpButton.removeAllItems()
        familyPopUpButton.menu?.delegate = self
        familyNames.forEach {
            guard let font = NSFont(name: $0, size: FontSelectionView.defaultPopUpMenuFontSize) else {
                return
            }
            let locName = NSFontManager.shared.localizedName(forFamily: $0, face: nil)
            localizedFamilyNames.append(locName)
                        
            let item = NSMenuItem()
            item.title = locName
            item.tag = MenuItemTag.family.rawValue
            let itemView = MenuItemlView(frame: NSRect(x: 0, y: 0, width: FontSelectionView.defaultFamilyPopUpMenuWidth, height: 30))

            let f: NSFont
            if specialFontNames.contains($0) {
                f = adjustFont(locName, font: NSFont.systemFont(ofSize: FontSelectionView.defaultPopUpMenuFontSize), height: itemView.frame.height)
            } else {
                f = adjustFont(locName, font: font, height: itemView.frame.height)
            }

            itemView.font = f
//            itemView.autoresizingMask = [.width]
            itemView.selectHandler = menuItemAction(_:)
            item.view = itemView
            
            familyPopUpButton.menu?.addItem(item)
        }
        let multiItem = NSMenuItem()
        multiItem.isHidden = true
        multiItem.title = "Multiple" // should localize
        familyPopUpButton.menu?.addItem(multiItem)
        
        memberPopUpButton.menu?.delegate = self
        updateMembers(familyNames[0])
        
        sizeFieldFont = sizeField.font
        sizeFieldTextColor = sizeField.textColor
    }
        
    private func adjustFont(_ string: String, font: NSFont, height: CGFloat) -> NSFont {
        var current = font
        let margin: CGFloat = 4
        
        while current.pointSize > 1 {
            let attrStr = NSMutableAttributedString(string: string, attributes: [.font: current])
            let rect = attrStr.boundingRect(with: NSSize(width: 0, height: height), options: [.usesDeviceMetrics, .usesFontLeading])
            
            if rect.height + margin <= height {
                break
            }
            current = current.withSize(current.pointSize - 1)
        }
        
        return current
    }
        
    // MARK: -- Action
    
    private func menuItemAction(_ sender: NSMenuItem) {
        if sender.tag == MenuItemTag.family.rawValue {
            // family
            selectFamilyAction(sender)
        } else {
            // member
            selectMemberAction(sender)
        }
    }

    private func selectFamilyAction(_ item: NSMenuItem) {
        familyPopUpButton.menu?.cancelTracking()

        familyPopUpButton.itemArray.filter { $0.state == .mixed }.forEach { $0.state = .off }

        familyPopUpButton.select(item)
        let idx = familyPopUpButton.indexOfSelectedItem
        let familyName = familyNames[idx]
        
        updateMembers(familyName)
        updatedSelectedFont()
    }
    
    private func selectMemberAction(_ item: NSMenuItem) {
        memberPopUpButton.menu?.cancelTracking()

        memberPopUpButton.select(item)
        
        let index = memberPopUpButton.indexOfSelectedItem
        guard index < currentMembers.count else {
            return
        }

        updatedSelectedFont()
    }
    
    @IBAction func updateSizeStepperAction(_ sender: Any) {
        sizeField.integerValue = sizeStepper.integerValue
        updatedSelectedFont(CGFloat(sizeStepper.integerValue))
    }
    
    // MARK: -- views
    
    private var currentFonts: [NSFont] = []
    
    private func updateViews(_ fonts: [NSFont]) {
        guard !fonts.isEmpty else {
            familyPopUpButton.selectItem(at: 0)
            familyPopUpButton.setTitle(localizedFamilyNames[0])
            updateMembers(familyNames[0])
            currentFonts.removeAll()
            return
        }
        
        familyPopUpButton.itemArray.filter { $0.state == .mixed }.forEach { $0.state = .off }

        if fonts.count > 1 {
            let families = Set(fonts.compactMap { $0.familyName })
            let names = Set(fonts.map { $0.fontName })
            
            if families.count == 1 {
                updateMembers(families.first!)
                if names.count == 1 {
                    // same fonts
                    if let index = currentMembers.firstIndex(of: names.first!) {
                        memberPopUpButton.selectItem(at: index)
                    }
                } else {
                    // same fonts with different member
                    let multiItem = NSMenuItem()
                    multiItem.isHidden = true
                    multiItem.title = "Multiple" // should localize
                    memberPopUpButton.menu?.addItem(multiItem)
                    
                    memberPopUpButton.select(multiItem)

                    names.forEach {
                        if let index = currentMembers.firstIndex(of: $0) {
                            memberPopUpButton.item(at: index)?.state = .mixed
                        }
                    }
                }
            } else {
                familyPopUpButton.selectItem(at: familyNames.count)
                
                // multiple
                fonts.forEach {
                    if let fam = $0.familyName, let idx = familyNames.firstIndex(of: fam) {
                        let item = familyPopUpButton.itemArray[idx]
                        item.state = .mixed
                    }
                }
                
                memberPopUpButton.removeAllItems()
                memberPopUpButton.isEnabled = false
                currentMembers.removeAll()
            }
        } else if let name = fonts[0].familyName, let index = familyNames.firstIndex(of: name) {
            familyPopUpButton.selectItem(at: index)

            updateMembers(familyNames[index])

            if let mIndex = currentMembers.firstIndex(of: fonts[0].fontName) {
                memberPopUpButton.selectItem(at: mIndex)
            }
        }
        
        currentFonts = fonts

        let sizes = Set(fonts.map { $0.pointSize })

        if sizes.count == 1 {
            sizeField.font = sizeFieldFont
            sizeField.textColor = sizeFieldTextColor
        } else {
            let descriptor = sizeFieldFont.fontDescriptor.withSymbolicTraits(.italic)
            sizeField.font = NSFont(descriptor: descriptor, size: sizeFieldFont.pointSize)
            sizeField.textColor = .secondaryLabelColor
        }
        
        let size = Int(fonts[0].pointSize)
        sizeField.integerValue = size
        sizeStepper.integerValue = size
    }
    
    private func updateMembers(_ familyName: String) {
        guard let members = NSFontManager.shared.availableMembers(ofFontFamily: familyName) else {
            memberPopUpButton.removeAllItems()
            memberPopUpButton.isEnabled = false
            currentMembers.removeAll()
            return
        }
        
        let isSpecial = specialFontNames.contains(familyName)

        memberPopUpButton.removeAllItems()
        memberPopUpButton.isEnabled = true
        currentMembers.removeAll()
        members.forEach {
            let longName = $0[0] as! String
            let name = $0[1] as! String
            
            let item = NSMenuItem()
            item.title = name
            item.tag = MenuItemTag.member.rawValue

            let itemView = MenuItemlView(frame: NSRect(x: 0, y: 0, width: FontSelectionView.defaultMemberPopUpMenuWidth, height: 30))
            
            let f: NSFont
            if isSpecial {
                f = adjustFont(longName, font: NSFont.systemFont(ofSize: FontSelectionView.defaultPopUpMenuFontSize), height: itemView.frame.height)
            } else {
                f = adjustFont(longName, font: NSFont(name: longName, size: FontSelectionView.defaultPopUpMenuFontSize)!, height: itemView.frame.height)
            }
            
            itemView.font = f
//            itemView.autoresizingMask = [.width]
            itemView.selectHandler = menuItemAction(_:)
            item.view = itemView
            
            memberPopUpButton.menu?.addItem(item)
            
            currentMembers.append(longName)
        }
    }

    private func updatedSelectedFont(_ newSize: CGFloat? = nil) {
        defer {
            if newSize != nil {
                sizeField.font = sizeFieldFont
                sizeField.textColor = sizeFieldTextColor
            }
        }
        
        let index = familyPopUpButton.indexOfSelectedItem
        if index < 0 {
            return
        } else if index >= familyNames.count {
            // multiple fonts selected
            let updatedFonts = currentFonts.map { $0.withSize(CGFloat(sizeStepper.integerValue)) }
            onSelectHandler?(updatedFonts)
            return
        }

        let mIndex = memberPopUpButton.indexOfSelectedItem
        if mIndex < 0 || currentMembers.isEmpty {
            let font = NSFont(name: familyNames[index], size: CGFloat(sizeStepper.integerValue))!
            onSelectHandler?([font])

        } else if mIndex >= currentMembers.count {
            let updatedFonts = currentFonts.map { $0.withSize(CGFloat(sizeStepper.integerValue)) }
            onSelectHandler?(updatedFonts)
        } else {
            let memberName = currentMembers[mIndex]
            if currentFonts.count > 1 {
                let updatedFonts = currentFonts.compactMap { NSFont(name: memberName, size: newSize ?? $0.pointSize) }
                onSelectHandler?(updatedFonts)
            } else {
                let font = NSFont(name: currentMembers[mIndex], size: CGFloat(sizeStepper.integerValue))!
                onSelectHandler?([font])
            }
        }
    }
    
    // MARK: -- NSTextFieldDelegate
    
    func controlTextDidEndEditing(_ obj: Notification) {
        sizeStepper.integerValue = sizeField.integerValue
        updatedSelectedFont(CGFloat(sizeStepper.integerValue))
    }

    func controlTextDidChange(_ obj: Notification) {
        sizeStepper.integerValue = sizeField.integerValue
        updatedSelectedFont(CGFloat(sizeStepper.integerValue))
    }

    // MARK: -- NSMenuDelegate
    
    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        let preSelection = menu.items.first { $0.isHighlighted }
        if let p = preSelection {
            p.view?.needsDisplay = true
        }
    }
    
}

private class MenuItemlView: NSView, NSMenuDelegate {
    var font: NSFont = .systemFont(ofSize: NSFont.systemFontSize)
    var selectHandler: ((NSMenuItem) -> Void)?
    
    private let imageView: NSImageView = {
        let iview = NSImageView()
        iview.translatesAutoresizingMaskIntoConstraints = false
        iview.layer?.backgroundColor = NSColor.blue.cgColor
        iview.wantsLayer = true
        return iview
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        addSubview(effectView)
        addSubview(imageView)
        addSubview(innerView)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: effectView.leadingAnchor, constant: -5),
            topAnchor.constraint(equalTo: effectView.topAnchor),
            bottomAnchor.constraint(equalTo: effectView.bottomAnchor),
            trailingAnchor.constraint(equalTo: effectView.trailingAnchor, constant: 5),
            leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: -8),
            topAnchor.constraint(equalTo: imageView.topAnchor, constant: 0),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 0),
            imageView.widthAnchor.constraint(equalToConstant: 22),
            innerView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor),
            innerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            innerView.topAnchor.constraint(equalTo: topAnchor),
            innerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let effectView: NSVisualEffectView = {
        let e = NSVisualEffectView()
        e.material = .selection
        e.isEmphasized = true
        e.wantsLayer = true
        e.layer?.cornerRadius = 4
        e.translatesAutoresizingMaskIntoConstraints = false
        e.isHidden = true
        return e
    }()
    
    private let innerView: InnerView = {
        let iview = InnerView()
        iview.translatesAutoresizingMaskIntoConstraints = false
        return iview
    }()
    
    override func draw(_ dirtyRect: NSRect) {
        guard let item = enclosingMenuItem else { imageView.image = nil; return }
        
        if item.state == .on {
            imageView.image = item.onStateImage
        } else if item.state == .mixed {
            imageView.image = item.mixedStateImage
        } else {
            imageView.image = item.offStateImage
        }
        
        if item.isHighlighted {
            effectView.isHidden = false
        } else {
            effectView.isHidden = true
        }
        
        innerView.string = NSAttributedString(string: item.title, attributes: [.font: font, .strokeColor: NSColor.black])
    }
    
    override func mouseUp(with event: NSEvent) {
        guard let item = enclosingMenuItem else { return }
        selectHandler?(item)
    }
    
    class InnerView: NSView {
        var string: NSAttributedString! {
            didSet {
                needsDisplay = true
            }
        }
        
        override func draw(_ dirtyRect: NSRect) {
            guard let string = string else { return }
            
            let rect = string.boundingRect(with: NSSize.zero, options: [ .usesDeviceMetrics, .usesFontLeading])

            let y = round((bounds.height - rect.height)/2)

            if rect.minY < 0 {
                let context = NSGraphicsContext.current?.cgContext
                context?.saveGState()
                context?.translateBy(x: 0, y: -rect.minY)
                
                string.draw(with: NSRect(x: 0, y: y, width: bounds.width, height: rect.height), options: [.usesDeviceMetrics, .usesFontLeading])
                
                context?.restoreGState()
            } else {
                string.draw(with: NSRect(x: 0, y: y, width: bounds.width, height: rect.height), options: [.usesDeviceMetrics, .usesFontLeading])
            }
        }
    }
}
