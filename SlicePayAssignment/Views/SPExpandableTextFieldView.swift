//
//  SPExpandableTextFieldView.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit
import FontAwesome_swift

class SPExpandableTextFieldView: UIView,UITextViewDelegate {
    
    typealias HeightUpdateHandler = () -> Void
    var expandableTextView: UITextView = {
        var expandableView = UITextView()
        expandableView.textContainerInset = .zero
        expandableView.textContainer.lineFragmentPadding = 0.0
        expandableView.font = UIFont(name: "Helvetica Neue", size: 25)
        expandableView.isScrollEnabled = false
        expandableView.tintColor = UIColor.orange
        expandableView.backgroundColor = UIColor.clear
        expandableView.textAlignment = .left
        expandableView.autocorrectionType = .no
        expandableView.textColor = UIColor.white
        return expandableView
    }()
    var textViewIcon = UIImageView()
    var textViewHeightHandler: HeightUpdateHandler?
    var baseHeight:CGFloat = 50.0
    var lineView = UIView()
    var previousRect:CGRect = .zero
    var fieldName:String = ""
    var selectedImage:String = ""
    var mainImage:String = ""
    var lineHeightConstraint:[NSLayoutConstraint]?
    var placeholderLabel:UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Helvetica Neue", size: 25.0)
        label.minimumScaleFactor = 0.4
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor.white
        return label
    }()
    var placeholderBottomConstraint:NSLayoutConstraint?
    var placeholderTopConstraint:NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    convenience init(fieldName:String,fieldValue:String?) {
        self.init(frame: CGRect.init())
        self.mainImage = fieldName
        self.textViewIcon.image = UIImage(named:fieldName)
        if(fieldValue != nil && fieldValue?.isEmpty == false) {
            expandableTextView.text = fieldValue
            self.hidePlaceHolder()
        }
        
        expandableTextView.delegate = self
        self.fieldName = fieldName
        placeholderLabel.text = fieldName
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        expandableTextView.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        textViewIcon.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(expandableTextView)
        self.addSubview(textViewIcon)
        self.addSubview(lineView)
        self.addSubview(placeholderLabel)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(10)-[textViewIcon(==30)]-[expandableTextView]-(10)-|", options: [], metrics: nil, views: ["expandableTextView":expandableTextView,"textViewIcon":textViewIcon,"lineView":lineView,"placeHolderLabel":placeholderLabel]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(30)-[expandableTextView]-(10)-|", options: [], metrics: nil, views: ["expandableTextView":expandableTextView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(30)-[textViewIcon(==30)]", options: [], metrics: nil, views: ["textViewIcon":textViewIcon]))
        lineHeightConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:[lineView(==2)]|", options: [], metrics: nil, views: ["lineView":lineView])
        self.addConstraints(lineHeightConstraint!)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[lineView]|", options: [], metrics: nil, views: ["lineView":lineView]))
        
        self.addConstraint(NSLayoutConstraint(item: placeholderLabel, attribute: .left, relatedBy: .equal, toItem: expandableTextView, attribute: .left, multiplier: 1.0, constant: 0.0))
        if(self.expandableTextView.text.isEmpty) {
            placeholderBottomConstraint = NSLayoutConstraint(item: placeholderLabel, attribute: .bottom, relatedBy: .equal, toItem: textViewIcon, attribute: .bottom, multiplier: 1.0, constant: 20.0)
            placeholderTopConstraint = NSLayoutConstraint(item: placeholderLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        }else{
            placeholderTopConstraint = NSLayoutConstraint(item: placeholderLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
            placeholderBottomConstraint = NSLayoutConstraint(item: placeholderLabel, attribute: .bottom, relatedBy: .equal, toItem: textViewIcon, attribute: .bottom, multiplier: 1.0, constant: -20.0)
        }
        self.addConstraint(placeholderBottomConstraint!)
        self.addConstraint(placeholderTopConstraint!)
        
        textViewIcon.contentMode = .scaleAspectFill
       
        lineView.backgroundColor = UIColor.white
    }
    
    func showPlaceHolder() {
        UIView.animate(withDuration: 0.8, animations: {() in
            self.placeholderBottomConstraint?.constant = 20.0
            self.placeholderLabel.font = UIFont(name: "Helvetica Neue", size: 25.0)
//            if(forExpandableView.fieldName == andText) {
//                forExpandableView.lineHeightConstraint?[0].constant = 4.0
//            }else{
//                forExpandableView.lineHeightConstraint?[0].constant = 2.0
//            }
        })
    }
    
    func hidePlaceHolder() {
        UIView.animate(withDuration: 0.8, animations: {() in
            self.placeholderBottomConstraint?.constant = -20.0
            self.placeholderLabel.font = UIFont(name: "Helvetica Neue", size: 20.0)
        })
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let position:UITextPosition = textView.endOfDocument
        let currentRect:CGRect = textView.caretRect(for: position)
        print("\(currentRect.origin.x) --- \(textView.frame.size.width)")
        
        textViewHeightHandler!()
        
        previousRect = currentRect
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if(textView.text.isEmpty) {
            self.hidePlaceHolder()
        }
        
        textViewIcon.image = UIImage(named:mainImage+"selected")
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textViewIcon.image = UIImage(named:mainImage)
        if(textView.text.count == 0 || textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
            textViewHeightHandler!()
            self.showPlaceHolder()
        }
        
        textView.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        textViewHeightHandler!()
    }
}
