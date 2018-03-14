//
//  SPExpandableTextFieldView.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit

class SPExpandableTextFieldView: UIView,UITextViewDelegate {
    
    typealias HeightUpdateHandler = (_ increase:Bool) -> Void
    var expandableTextView = UITextView()
    var textViewHeightHandler: HeightUpdateHandler?
    var baseHeight:CGFloat = 50.0
    
    var previousRect:CGRect = .zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        expandableTextView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(expandableTextView)
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(10)-[expandableTextView]-(10)-|", options: [], metrics: nil, views: ["expandableTextView":expandableTextView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(10)-[expandableTextView]-(10)-|", options: [], metrics: nil, views: ["expandableTextView":expandableTextView]))
        expandableTextView.delegate = self
        expandableTextView.textContainerInset = .zero
        expandableTextView.textContainer.lineFragmentPadding = 0.0
        expandableTextView.font = UIFont(name: "Helvetica Neue", size: 25)
        expandableTextView.isScrollEnabled = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let position:UITextPosition = textView.endOfDocument
        let currentRect:CGRect = textView.caretRect(for: position)
        print("\(currentRect.origin.x) --- \(self.frame.size.width - self.frame.origin.x - 20.0)")
        
        if (currentRect.origin.y > previousRect.origin.y || currentRect.origin.x == 0.0 || currentRect.origin.x >= self.frame.size.width - self.frame.origin.x - 20.0){
            print("increased delegate value passed in handler = \(currentRect.size.height)")
            textViewHeightHandler!(true)
        }else if(currentRect.origin.y < previousRect.origin.y && expandableTextView.frame.size.height > baseHeight) {
            textViewHeightHandler!(false)
        }
        previousRect = currentRect
    }
}
