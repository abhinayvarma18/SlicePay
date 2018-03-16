//
//  ViewController.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit
import FirebaseDatabase

class SPViewController: UIViewController {

    lazy var headerView:UIView = self.getHeaderImageView()
    let scrollView = UIScrollView()
    let contentView = UIView()
    var heightConstraintArray:[NSLayoutConstraint] = []
    var expandableTextViews:[SPExpandableTextFieldView] = []
    let profileView = UIView()
    var submitButton:UIButton = UIButton()
    var firebaseManager = SPFirebaseHandler.handler
    var currentModel:FormFields?
    var relayoutConstraints:[NSLayoutConstraint]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addObservers()
        self.layoutUIComponent()
        self.relayoutViews()
        self.setupListnerOnFormNodes()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissableViewTapped))
        contentView.addGestureRecognizer(gesture)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //removing observers when screen is off
        self.removeObservers()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(SPViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SPViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SPViewController.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
    }
    
    @objc fileprivate func dismissableViewTapped() {
        self.contentView.endEditing(true)
    }
    
    //Imp:
    func setupListnerOnFormNodes() {
        firebaseManager.updateChangeOfFirebase(completion: {(field) in
            if(field != nil) {
                self.findChangedDataInUpdatedDataAndRelayout(fieldObject: field!)
            }
        })
    }
    
    func findChangedDataInUpdatedDataAndRelayout(fieldObject:FormFields) {
        
        for field in fieldObject.fields {
            let sameKeyCurrentObjectArray = currentModel?.fields.filter({$0.fieldName == field.fieldName})
            if(sameKeyCurrentObjectArray?.count == 0) {
                continue
            }
            let sameKeyCurrentObject = sameKeyCurrentObjectArray![0]
            if(sameKeyCurrentObject.fieldValue != field.fieldValue) {
                let expandableViewArray = expandableTextViews.filter({$0.textValue == sameKeyCurrentObject.fieldName})
                if(expandableViewArray.count != 0 || sameKeyCurrentObject.fieldValue == nil) {
                    self.updateTextValue(forExpandableView: expandableViewArray[0],andText: field.fieldValue!)
                }
            }
        }
        
        if(fieldObject.fields.count == 0) {
            for expandableView in expandableTextViews {
                self.updateTextValue(forExpandableView: expandableView, andText: expandableView.textValue)
            }
            for field in 0..<(currentModel?.fields.count ?? 0) {
                //Maintaining Consistency in data
                currentModel?.fields[field].fieldValue = nil
            }
        }else{
//            if(currentModel?.fields.count != fieldObject.fields.count) {
//                self.recursiveRemoveAllViews(view: self.view)
//                currentModel = fieldObject
////                let constraints = self.contentView.constraints
////                self.contentView.removeConstraints(constraints)
//                self.relayoutViews()
//            }
            currentModel = fieldObject
        }
    }
    
    func recursiveRemoveAllViews(view:UIView) {
        if(view.subviews.count > 0) {
            for view in view.subviews {
                return recursiveRemoveAllViews(view:view)
            }
        }else if(view != self.view){
            view.removeFromSuperview()
        }
    }
    
    func updateTextValue(forExpandableView:SPExpandableTextFieldView, andText:String) {
        forExpandableView.expandableTextView.text = andText
        if(forExpandableView.textValue == andText) {
            forExpandableView.expandableTextView.textColor = UIColor.white
        }else{
            forExpandableView.expandableTextView.textColor = UIColor.black
        }
        forExpandableView.textViewHeightHandler!()
    }
    
    func layoutUIComponent() {
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.backgroundColor = UIColor.white
        submitButton.setTitle("Save", for: .normal)
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        submitButton.setTitleColor(UIColor.black, for: .normal)
        submitButton.layer.cornerRadius = 5.0
        submitButton.layer.masksToBounds = true
        submitButton.addTarget(self, action: #selector(saveClicked), for: .touchUpInside)
        
        contentView.backgroundColor = UIColor(red: 1.0/255.0, green: 171.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        headerView.backgroundColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
        
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
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        //headerimageview constraints
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[headerView]|", options: [], metrics: nil, views: ["headerView":headerView]))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerView(==\(150.0))]", options: [], metrics: nil, views: ["headerView":headerView]))
        
        contentView.addSubview(submitButton)
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[submitButton(160)]", options: [], metrics: nil, views: ["submitButton":submitButton]))
        contentView.addConstraint(NSLayoutConstraint(item: submitButton, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 20.0))
        self.relayoutDynamicContentViews()
    }
    
    func relayoutDynamicContentViews() {
        var yOrdinate:CGFloat = 150.0 + 94.0
        for index in 0..<(currentModel?.fields.count ?? 0) {
            let fieldView = self.getNameView(index: index)
            //fieldView.expandableTextView.text = currentModel?.fields[index].fieldName
            fieldView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(fieldView)
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(40)-[fieldView]-(40)-|", options: [], metrics: nil, views: ["fieldView":fieldView]))
            if(index == (currentModel?.fields.count)! - 1) {
                relayoutConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[lastFieldView]-(40)-[fieldView]-(40)-[submitButton(50)]-(40)-|", options: [], metrics: nil, views: ["fieldView":fieldView,"lastFieldView":expandableTextViews[index-1],"submitButton":submitButton])
                contentView.addConstraints(relayoutConstraints!)
            }else if(index == 0){
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[profileView]-(40.0)-[fieldView]", options: [], metrics: nil, views: ["fieldView":fieldView,"profileView":profileView]))
            }
            else{
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lastFieldView]-(40)-[fieldView]", options: [], metrics: nil, views: ["fieldView":fieldView,"lastFieldView":expandableTextViews[index-1]]))
            }
            
            let heightConstraint = NSLayoutConstraint(item: fieldView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 50)
            heightConstraintArray.append(heightConstraint)
            contentView.addConstraint(heightConstraintArray[index])
            yOrdinate += heightConstraintArray[index].constant + 40.0
            expandableTextViews.append(fieldView)
        }
        scrollView.contentSize = CGSize(width: contentView.frame.size.width, height: yOrdinate + 110.0)
        self.contentView.layoutIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    @objc func saveClicked() {
        
        if(currentModel == nil) {
            currentModel = FormFields()
        }else{
            currentModel?.fields.removeAll()
        }
        
        for expandableView in expandableTextViews {
            if(expandableView.expandableTextView.text == expandableView.textValue || expandableView.expandableTextView.text.isEmpty) {
                //error fields can't be empty while saving
                //do something with expandableView to show errors
                let alert = UIAlertController(title: "Error", message: "Unable to save , basic validation failed.(field cannot be empty)", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }else{
                let updatedItem = FormField()
                updatedItem.fieldName = expandableView.textValue
                updatedItem.fieldValue = expandableView.expandableTextView.text
                currentModel?.fields.append(updatedItem)
            }
        }
        if(isServerReachable()) {
            firebaseManager.updateValuesOnFirebase(newModel: currentModel!, completion: {(ref) in
                //show success alert
                if(ref != nil) {
                    self.setupListnerOnFormNodes()
                }
                
                let alert = UIAlertController(title: "Success", message: "Your Data is saved successfully in firebase and local db", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        }else{
            firebaseManager.saveProfileInDB(profileDict: currentModel!, andState:false)
            let alert = UIAlertController(title: "No Internet", message: "Your Data is saved successfully in local db and marked as unsync. Wait for internet to auto update data or open this screen again.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
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
        mainView.backgroundColor = UIColor.white
        
        return mainView
    }
    

    func getNameView(index:Int) -> SPExpandableTextFieldView {
        let newView = SPExpandableTextFieldView(fieldName: (currentModel?.fields[index].fieldName)!,fieldValue:currentModel?.fields[index].fieldValue)
        newView.textViewHeightHandler = { () in
          DispatchQueue.main.async {
            let newSize = newView.expandableTextView.sizeThatFits(CGSize(width: newView.expandableTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
            print("iam called with newHeight \(newSize.height)")
            self.heightConstraintArray[index].constant = newSize.height + 20.0
            self.updateContentSize(index:index, constant:self.heightConstraintArray[index].constant)
          }
        }
        
        return newView
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        let status = InternetStatus().connectionStatus()
        switch status {
        case .unknown, .offline: break
               // handleInternetHasBecomeInactive()
            default:
                handleInternetIsAvailable()
        }
    }
    
    func handleInternetIsAvailable() {
        let offLineData = firebaseManager.fetchProfileFromDB()
        if(offLineData != nil) {
            if(offLineData![0].value(forKey: "isSynced") as! Bool == false) {
                firebaseManager.updateLocalDatabaseValueOverFirebase(updatedArray: offLineData!)
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.contentView.frame.origin.y == 0{
                self.contentView.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.contentView.frame.origin.y != 0{
                self.contentView.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    
}

