//
//  ViewController.swift
//  PDFSample
//
//  Created by Peyman on 9/17/19.
//  Copyright © 2019 iOSDeveloper. All rights reserved.
//

import UIKit
import PDFKit

extension UIView {
    
    // Using a function since `var image` might conflict with an existing variable
    // (like on `UIImageView`)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

class PeopleAnnotation: PDFAnnotation {
    var myView: UIView!
    
    // A custom init that sets the type to Stamp on default and assigns our Image variable
    init(forBounds bounds: CGRect, withProperties properties: [AnyHashable : Any]?) {
        super.init(bounds: bounds, forType: PDFAnnotationSubtype.popup, withProperties: properties)
        self.myView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        self.myView.backgroundColor = .red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        let imageToDraw = self.myView.asImage()
        guard let myCGImage = imageToDraw.cgImage else {
            return
        }
        context.draw(myCGImage, in: CGRect(x: 100, y: 200, width: 30, height: 30))
        //self.myView.layer.render(in: context)
        
    }
}

class ViewController: UIViewController {
    /// Search TF
    @IBOutlet weak var searchTF: UITextField!
    /// PDF BaseView
    @IBOutlet weak var pdfBaseView: UIView!
    /// PDF BaseView Bottom Constraint
    @IBOutlet weak var pdfBaseViewBottomConstraint: NSLayoutConstraint!
    
    /// Tap Gesture
    fileprivate var tapGesture: UITapGestureRecognizer!
    /// PDF View
    fileprivate var myPDFView: PDFView!
    /// PDF Document
    fileprivate var pdfDocument: PDFDocument!
    /// PDF Searched Item
    fileprivate var pdfSearchedItem: PDFSelection!
    /// Searched Text
    fileprivate var searchedText: String!
    /// Added Anotation
    fileprivate var addedAnnotation: PDFAnnotation!
    
    //MARK: Search TF Editing Changed
    @IBAction func searchTFEditingChanged(_ sender: UITextField) {
        searchedText = sender.text!.trimmed()
        self.pdfSearchedItem = nil
        self.pdfDocument.beginFindString(sender.text!.trimmed(), withOptions: [.caseInsensitive])
    }
    
}

//MARK:- View Life Cycles
extension ViewController {
    //MARK: Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadAndShowPDF()
    }
    
    //MARK: View will Appear
    override func viewWillAppear(_ animated: Bool) {
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapHandler(_:)))
        self.view.addGestureRecognizer(tapGesture)
        registerForKeyboardNotifications()
    }
    
    //MARK: View Will Disappear
    override func viewWillDisappear(_ animated: Bool) {
        self.view.removeGestureRecognizer(tapGesture)
        deregisterFromKeyboardNotifications()
    }
}

//MARK:- Required Functions
extension ViewController {
    //MARK: Add PDF View
    private func loadAndShowPDF() {
        /// Let Sample PDF Path
        guard let path = Bundle.main.url(forResource: "sample", withExtension: "pdf") else { return
        }
        
        /// Load Document From Path
        guard let document = PDFDocument(url: path) else {
            return
        }
        
        pdfDocument = document
        myPDFView = PDFView()
        myPDFView.document = document
        myPDFView.document?.delegate = self
        myPDFView.displayMode = .singlePageContinuous
        myPDFView.autoScales = true
        myPDFView.translatesAutoresizingMaskIntoConstraints = false
        pdfBaseView.addSubview(myPDFView)
        
        NSLayoutConstraint.activate([
            myPDFView.leadingAnchor.constraint(equalTo: pdfBaseView.leadingAnchor),
            myPDFView.trailingAnchor.constraint(equalTo: pdfBaseView.trailingAnchor),
            myPDFView.topAnchor.constraint(equalTo: pdfBaseView.topAnchor),
            myPDFView.bottomAnchor.constraint(equalTo: pdfBaseView.bottomAnchor)
            ])
    }
    
    //MARK: Screen Tap Handler
    @objc
    private func screenTapHandler(_ gesture: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}

//MARK:- PDF Document Delegate
extension ViewController: PDFDocumentDelegate {
    //MARK: Did End Finding
    func documentDidEndDocumentFind(_ notification: Notification) {
        if pdfSearchedItem != nil {
            myPDFView.setCurrentSelection(pdfSearchedItem, animate: false)
        }
    }
    
    //MARK: Doc Did Find Match
    func documentDidFindMatch(_ notification: Notification) {
        if let selection = notification.userInfo?.first?.value as? PDFSelection {
            selection.color = .yellow
            if pdfSearchedItem == nil {
                // The first found item sets the object.
                pdfSearchedItem = selection
            } else {
                // All other found selection will be nested
                pdfSearchedItem!.add(selection)
            }
            for line in pdfSearchedItem.selectionsByLine() {
                if !line.bounds(for: selection.pages[0]).origin.x.isInfinite {
                    print("X: \(line.bounds(for: selection.pages[0]).origin.x)")
                    myPDFView.go(to: line)
                    addCustomView(At: line.bounds(for: selection.pages[0]))
                } else {
                    print("Infinite")
                }
            }
        }
    }
    
    private func addCustomView(At lineFrame: CGRect) {
        
        if addedAnnotation != nil {
            addedAnnotation.page!.removeAnnotation(addedAnnotation!)
            addedAnnotation = nil
        }
        
        let aan = PeopleAnnotation(forBounds: myPDFView.bounds, withProperties: nil)
        addedAnnotation = aan
        myPDFView.currentPage!.addAnnotation(addedAnnotation)
    }
}

//MARK:- Keyboard Handler
extension ViewController {
    //MARK: Add Observer - Keyboard
    /**
     This function is used to Add All observers required for Keyboard
     */
    private func registerForKeyboardNotifications(){
        //Adding notifies on keyboard appearing
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: Remove Observer - Keyboard
    /**
     This function is used to Remove All observers added
     */
    private func deregisterFromKeyboardNotifications(){
        //Removing notifies on keyboard appearing
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    //MARK: Keyboard Show
    /**
     This is used to add the Keyboard Height to ScrollView for scrolling Effect
     - parameter notification : notification instance
     */
    @objc private func keyboardWasShown(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            pdfBaseViewBottomConstraint.constant = keyboardSize.height
        }
    }
    
    //MARK: Keyboard Hide
    /**
     This is used to retain the orignal Height of View
     - parameter notification : notification instance
     */
    @objc private func keyboardWillBeHidden(_ notification: Notification){
        pdfBaseViewBottomConstraint.constant = 0
    }
}
