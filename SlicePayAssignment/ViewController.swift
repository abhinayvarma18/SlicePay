//
//  ViewController.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    lazy var resizableView:SPExpandableTextFieldView = self.getNameView()
    
    var heightConstraint:NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(resizableView)
        resizableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-40-[resizableView]-40-|", options: [], metrics: nil, views: ["resizableView":resizableView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(50)-[resizableView]", options: [], metrics: nil, views: ["resizableView":resizableView]))
        heightConstraint = NSLayoutConstraint(item: resizableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
        self.view.addConstraint(heightConstraint!)
        // Do any additional setup after loading the view, typically from a nib.
    }

    func getNameView() -> SPExpandableTextFieldView {
        let newView = SPExpandableTextFieldView()
        newView.backgroundColor = UIColor.green
        newView.textViewHeightHandler = { (increaseFlag) in
           DispatchQueue.main.async {
                let newSize = newView.expandableTextView.sizeThatFits(CGSize(width: newView.frame.size.width - 20.0, height: CGFloat.greatestFiniteMagnitude))
                print("iam called with newHeight \(newSize.height)")
                self.heightConstraint?.constant = newSize.height + 20.0
                self.view.layoutIfNeeded()
            }
        }
        
        return newView
    }
}

