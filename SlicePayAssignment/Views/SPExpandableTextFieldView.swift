//
//  SPExpandableTextFieldView.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit

class SPExpandableTextFieldView: UIView,UITextViewDelegate {
    
    typealias HeightUpdateHandler = () -> Void
    var expandableTextView = UITextView()
    var textViewIcon = UIImageView()
    var textViewHeightHandler: HeightUpdateHandler?
    var baseHeight:CGFloat = 50.0
    var lineView = UIView()
    var previousRect:CGRect = .zero
    var textValue:String = ""
    var selectedImage:String = ""
    var mainImage:String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    convenience init(fieldName:String,fieldValue:String?) {
        self.init(frame: CGRect.init())
        self.mainImage = fieldName
        self.textViewIcon.image = UIImage(named:fieldName)
        self.expandableTextView.text = fieldValue != nil && fieldValue != ""  ? fieldValue : fieldName
        expandableTextView.textColor = fieldValue != nil && fieldValue != "" ? UIColor.black : UIColor.white
        self.textValue = fieldName
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        expandableTextView.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        textViewIcon.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(expandableTextView)
        self.addSubview(textViewIcon)
        self.addSubview(lineView)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(10)-[textViewIcon(==30)]-[expandableTextView]-(10)-|", options: [], metrics: nil, views: ["expandableTextView":expandableTextView,"textViewIcon":textViewIcon,"lineView":lineView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(10)-[expandableTextView]-(10)-|", options: [], metrics: nil, views: ["expandableTextView":expandableTextView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(10)-[textViewIcon(==30)]", options: [], metrics: nil, views: ["textViewIcon":textViewIcon]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lineView(==2)]|", options: [], metrics: nil, views: ["lineView":lineView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[lineView]|", options: [], metrics: nil, views: ["lineView":lineView]))
       
        textViewIcon.contentMode = .scaleAspectFill
        expandableTextView.delegate = self
        expandableTextView.textContainerInset = .zero
        expandableTextView.textContainer.lineFragmentPadding = 0.0
        expandableTextView.font = UIFont(name: "Helvetica Neue", size: 25)
        expandableTextView.isScrollEnabled = false
        expandableTextView.tintColor = UIColor.orange
        expandableTextView.backgroundColor = UIColor.clear
        expandableTextView.textAlignment = .center
        expandableTextView.autocorrectionType = .no
        lineView.backgroundColor = UIColor.white
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let position:UITextPosition = textView.endOfDocument
        let currentRect:CGRect = textView.caretRect(for: position)
        print("\(currentRect.origin.x) --- \(textView.frame.size.width)")
        
        if (currentRect.origin.y > previousRect.origin.y || currentRect.origin.x == 0.0 || currentRect.origin.x >= textView.frame.size.width){
            print("increased delegate value passed in handler = \(currentRect.size.height)")
            textViewHeightHandler!()
        }else if(currentRect.origin.y < previousRect.origin.y && expandableTextView.frame.size.height > baseHeight) {
            textViewHeightHandler!()
        }
        previousRect = currentRect
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(textView.text == textValue) {
            textView.text = ""+text
        }
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        expandableTextView.textColor = UIColor.darkText
        lineView.backgroundColor = UIColor(red: 252.0/255.0, green: 219.0/255.0, blue: 4.0/255.0, alpha: 1.0)
        if(textView.text == textValue) {
            textView.text = ""
        }
        textViewIcon.image = UIImage(named:mainImage+"selected")
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        lineView.backgroundColor = UIColor.white
        textViewIcon.image = UIImage(named:mainImage)
        if(textView.text.count == 0 || textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            textView.text = textValue
            textViewHeightHandler!()
            textView.textColor = UIColor.white
        }
        textView.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        textViewHeightHandler!()
    }
}
