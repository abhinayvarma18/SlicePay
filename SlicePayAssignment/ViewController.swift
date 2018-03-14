//
//  ViewController.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    lazy var headerView:UIView = self.getHeaderImageView()
    let scrollView = UIScrollView()
    let contentView = UIView()
    var fieldsArray = ["name","password","description","address","mobile","phone","email"]
    var heightConstraintArray:[NSLayoutConstraint] = []
    var textFieldsArray:[SPExpandableTextFieldView] = []
    let profileView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.relayoutViews()
    }
    
    func relayoutViews(){
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(scrollView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["scrollView":scrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["scrollView":scrollView]))
        
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["contentView":contentView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["contentView":contentView]))
        
        let contentWidthConstraint = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.scrollView, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0)
        scrollView.addConstraint(contentWidthConstraint)
        
        contentView.backgroundColor = UIColor(red: 54.0/255.0, green: 84.0/255.0, blue: 148.0/255.0, alpha: 1.0)
        headerView.backgroundColor = UIColor.black
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        //headerimageview constraints
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[headerView]|", options: [], metrics: nil, views: ["headerView":headerView]))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerView(==\(150.0))]", options: [], metrics: nil, views: ["headerView":headerView]))
        
        var yOrdinate:CGFloat = 150.0 + 94.0
        for index in 0..<fieldsArray.count {
            let fieldView = self.getNameView(index: index)
            fieldView.expandableTextView.text = fieldsArray[index]
            fieldView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(fieldView)
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(40)-[fieldView]-(40)-|", options: [], metrics: nil, views: ["fieldView":fieldView]))
            if(index == fieldsArray.count - 1) {
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lastFieldView]-(40)-[fieldView]-(10)-|", options: [], metrics: nil, views: ["fieldView":fieldView,"lastFieldView":textFieldsArray[index-1]]))
            }else if(index == 0){
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[profileView]-(40.0)-[fieldView]", options: [], metrics: nil, views: ["fieldView":fieldView,"profileView":profileView]))
            }
            else{
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lastFieldView]-(40)-[fieldView]", options: [], metrics: nil, views: ["fieldView":fieldView,"lastFieldView":textFieldsArray[index-1]]))
            }
            
            let heightConstraint = NSLayoutConstraint(item: fieldView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
            heightConstraintArray.append(heightConstraint)
            contentView.addConstraint(heightConstraintArray[index])
            yOrdinate += heightConstraintArray[index].constant + 40.0
            textFieldsArray.append(fieldView)
        }
        
        scrollView.contentSize = CGSize(width: contentView.frame.size.width, height: yOrdinate)
        self.contentView.layoutIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    func updateContentSize(index:Int,constant:CGFloat) {
        var size = scrollView.contentSize
        size.height += constant
        size.height -= heightConstraintArray[index].constant
        scrollView.contentSize = size
        self.contentView.layoutIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    
    func getHeaderImageView() -> UIView {
        let mainView = UIView()
    
        mainView.translatesAutoresizingMaskIntoConstraints = false
        let headImageView = UIImageView()
        headImageView.translatesAutoresizingMaskIntoConstraints = false
        headImageView.image = UIImage(named:"logoSlice")
        headImageView.contentMode = .scaleAspectFill
        
        mainView.addSubview(headImageView)
        
        mainView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[headImageView(==100)]", options: [], metrics: nil, views: ["headImageView":headImageView,"mainView":mainView]))
        mainView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[headImageView(==100)]", options: [], metrics: nil, views: ["headImageView":headImageView,"mainView":mainView]))
        mainView.addConstraint(NSLayoutConstraint(item: headImageView, attribute: .centerX, relatedBy: .equal, toItem: mainView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        mainView.addConstraint(NSLayoutConstraint(item: headImageView, attribute: .centerY, relatedBy: .equal, toItem: mainView, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        
        profileView.translatesAutoresizingMaskIntoConstraints = false
        profileView.backgroundColor = UIColor.white
        
        mainView.addSubview(profileView)
        
        mainView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(10)-[profileView(==100)]", options: [], metrics: nil, views: ["profileView":profileView]))
        mainView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(100)-[profileView(==100)]", options: [], metrics: nil, views: ["profileView":profileView]))
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.image = UIImage(named: "no_photo_detail")
        
        profileView.addSubview(profileImageView)
        profileView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(5)-[profileImageView(==90)]", options: [], metrics: nil, views: ["profileImageView":profileImageView]))
        profileView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5)-[profileImageView(==90)]", options: [], metrics: nil, views: ["profileImageView":profileImageView]))
        profileView.layer.cornerRadius = 50.0
        profileView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = 45.0
        profileImageView.layer.masksToBounds = true
        mainView.backgroundColor = UIColor.black
        
        return mainView
    }
    

    func getNameView(index:Int) -> SPExpandableTextFieldView {
        let newView = SPExpandableTextFieldView(image:fieldsArray[index],text:fieldsArray[index])
        newView.textViewHeightHandler = { (increaseFlag) in
          DispatchQueue.main.async {
            let newSize = newView.expandableTextView.sizeThatFits(CGSize(width: newView.expandableTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            print("iam called with newHeight \(newSize.height)")
            self.heightConstraintArray[index].constant = newSize.height + 20.0
            self.updateContentSize(index:index, constant:self.heightConstraintArray[index].constant)
            //self.view.layoutIfNeeded()
          }
        }
        return newView
    }
}

