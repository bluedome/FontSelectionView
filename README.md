# FontSelectionView
![swift](https://shields.io/static/v1?label=Swift&message=5&color=orange)
![platform](https://shields.io/static/v1?label=Platform&message=macOS&color=yellowgreen)
![mit](https://shields.io/github/license/bluedome/FontSelectionView)

View is for selecting fonts instead of NSFontPanel

![demo](./font_anim.gif)

## How to Use

Just copy *FontSelctionView.swift* and *FontSelectionView.xib* into your project.

example:
```Swift
    let fontView = FontSelectionView.instantiate()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(fontView)

        // select fonts
        fontView.select(fonts: [NSFont(name: "SF Pro", size: NSFont.systemFontSize)!])

        // set callback
        fontView.onSelectHandler = { fonts in
            print("newFonts=\(fonts)")
        }
    }

```

## License

MIT
