//
//  LinedTextEditor.swift
//  Dijital Ajanda
//
//  Çizgili defter kağıdı gibi yazılan metin alanı. Çizgiler yazıyla birlikte kayar.
//

import SwiftUI
import UIKit

struct LinedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var lineHeight: CGFloat = 34
    var fontSize: CGFloat = 19

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> LinedUITextView {
        let view = LinedUITextView.make()
        view.lineHeight = lineHeight
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textContainerInset = UIEdgeInsets(top: 0, left: 2, bottom: 32, right: 2)
        view.textContainer.lineFragmentPadding = 0
        view.alwaysBounceVertical = true
        view.keyboardDismissMode = .interactive
        view.inputAccessoryView = Self.doneToolbar(for: view)
        view.attributedText = NSAttributedString(string: text, attributes: attributes)
        view.typingAttributes = attributes
        return view
    }

    func updateUIView(_ view: LinedUITextView, context: Context) {
        context.coordinator.text = $text
        if view.text != text {
            view.attributedText = NSAttributedString(string: text, attributes: attributes)
            view.typingAttributes = attributes
        }
    }

    private var attributes: [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight

        var font = UIFont.systemFont(ofSize: fontSize)
        if let serif = font.fontDescriptor.withDesign(.serif) {
            font = UIFont(descriptor: serif, size: fontSize)
        }
        return [.font: font, .paragraphStyle: paragraph, .foregroundColor: Theme.inkUI]
    }

    private static func doneToolbar(for view: UITextView) -> UIToolbar {
        let toolbar = UIToolbar()
        let done = UIBarButtonItem(title: "Bitti", primaryAction: UIAction { [weak view] _ in
            view?.resignFirstResponder()
        })
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace), done]
        toolbar.tintColor = UIColor(Theme.accent)
        toolbar.sizeToFit()
        return toolbar
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
    }
}

/// Satır çizgilerini çizen, metnin arkasında duran görünüm.
private final class RulesView: UIView {
    override class var layerClass: AnyClass { CAShapeLayer.self }
    var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        shapeLayer.fillColor = nil
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) yok") }
}

/// Arka planına satır çizgileri çizen metin görünümü. Çizgiler kaydırmayla birlikte hareket eder.
final class LinedUITextView: UITextView {
    var lineHeight: CGFloat = 34

    private let rules = RulesView()
    private var observesTraits = false

    /// Çizgilerle satırların kaymaması için öngörülebilir çalışan TextKit 1 düzeniyle kurar.
    static func make() -> LinedUITextView {
        let storage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        container.widthTracksTextView = true
        storage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(container)
        return LinedUITextView(frame: .zero, textContainer: container)
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) yok")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !observesTraits else { return }
        observesTraits = true
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: LinedUITextView, _) in
            view.setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if rules.superview == nil {
            insertSubview(rules, at: 0)
        }

        let height = max(contentSize.height, bounds.height)
        let count = Int(height / lineHeight) + 1
        let path = CGMutablePath()
        for line in 1...count {
            let y = textContainerInset.top + CGFloat(line) * lineHeight
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: bounds.width, y: y))
        }

        rules.frame = CGRect(x: 0, y: 0, width: bounds.width, height: height)
        rules.shapeLayer.path = path
        rules.shapeLayer.strokeColor = Theme.ruleUI.resolvedColor(with: traitCollection).cgColor
        rules.shapeLayer.lineWidth = 1
    }
}
