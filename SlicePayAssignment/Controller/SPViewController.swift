//
//  ViewController.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 14/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Fusuma

class SPViewController: UIViewController {
    //MARK:Variables Declaration
    //lazy var headerView:UIView = self.getHeaderImageView()
    let scrollView = UIScrollView()
    
    let contentView = UIView()
    
    var submitButton: UIButton = UIButton()
    
    var heightConstraintArray:[NSLayoutConstraint] = []
    var expandableTextViews:[SPExpandableTextFieldView] = []
    let profileView = UIView()
    
    var firebaseManager = SPFirebaseHandler.handler
    var currentModel:FormFields?
    var relayoutConstraints:[NSLayoutConstraint]?
    var profileImageView = ImageLoader(cornerRadius: 45.0, emptyImage: UIImage(named: "noPhotoDetail"))
    let indicatorManager = SPActivityLoaderView.sharedInstance
    
    //MARK:Inital Methods
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func relaunchUIChanges() {
        contentView.backgroundColor = UIColor.clear
        scrollView.backgroundColor = UIColor(red: 1.0/255.0, green: 171.0/255.0, blue: 214.0/255.0, alpha: 1.0)
    }
    
    //adding observer when screen is on
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.addNotificationObservers()
        self.setupListnerOnFormNodes()
    }
    
    //removing observers when screen is off
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.removeObservers()
        firebaseManager.removeListenerFromNode()
    }
    
    override func loadView() {
        super.loadView()
        self.relaunchUIChanges()
        self.addGestures()
        self.relayoutViews()
    }
    
    //MARK:Add/Remove Notification Listner Methods
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(SPViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SPViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SPViewController.networkStatusChanged(_:)), name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: ReachabilityStatusChangedNotification), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    //MARK:Notification Listner Methods
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
        print("I was called 1st")
        let offLineData = firebaseManager.fetchProfileFromDB()
        if(!firebaseManager.isSyncedDataInLocalDB()) {
            firebaseManager.removeListenerFromNode()
            firebaseManager.updateLocalDatabaseValueOverFirebase(updatedArray: offLineData!)
        }
    }
    
    //MARK: MAIN UI CONSTRAINTS
    func relayoutViews(){
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        submitButton.backgroundColor = UIColor.white
        
        submitButton.setTitle("Save", for: [.normal])
        submitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        submitButton.setTitleColor(UIColor.black, for: [.normal])
        
        submitButton.addTarget(self, action: #selector(saveClicked), for: .touchUpInside)
        submitButton.layer.cornerRadius = 5.0
        submitButton.layer.masksToBounds = true
        
        self.view.addSubview(scrollView)
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["scrollView":scrollView]))
        self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["scrollView":scrollView]))
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["contentView":contentView]))
        scrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView]|", options: [NSLayoutFormatOptions(rawValue: 0)], metrics: nil, views: ["contentView":contentView]))
        
        let contentWidthConstraint = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.scrollView, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 0)
        scrollView.addConstraint(contentWidthConstraint)
        
        let headerView = self.getHeaderImageView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerView)
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[headerView]|", options: [], metrics: nil, views: ["headerView":headerView]))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[headerView(==\(150.0))]", options: [], metrics: nil, views: ["headerView":headerView]))
        
        contentView.addSubview(submitButton)
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[submitButton(160)]", options: [], metrics: nil, views: ["submitButton":submitButton]))
        contentView.addConstraint(NSLayoutConstraint(item: submitButton, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        self.relayoutDynamicContentViews()
    }
    
    //MARK:Header View
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
        
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        if (currentModel?.imageUrl != nil && !(currentModel?.imageUrl?.isEmpty == true)){
            if(!isServerReachable()) {
                profileImageView.image = firebaseManager.load(fileName: "FileName")
            }else{
                if(firebaseManager.isSyncedDataInLocalDB()) {
                    profileImageView.loadImage(urlString: (currentModel?.imageUrl)!)
                }else{
                    profileImageView.image = firebaseManager.load(fileName: "FileName")
                }
            }
        }else{
            if(!isServerReachable()) {
                profileImageView.image = firebaseManager.load(fileName: "FileName")
            }else{
                profileImageView.loadImage(urlString: "")
            }
        }
        
        profileImageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(profileUploadClicked))
        profileImageView.addGestureRecognizer(gesture)
        
        profileView.addSubview(profileImageView)
        profileView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(5)-[profileImageView(==90)]", options: [], metrics: nil, views: ["profileImageView":profileImageView]))
        profileView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(5)-[profileImageView(==90)]", options: [], metrics: nil, views: ["profileImageView":profileImageView]))
        profileView.layer.cornerRadius = 50.0
        profileView.layer.masksToBounds = true
        mainView.backgroundColor = UIColor(red: 74.0/255.0, green: 74.0/255.0, blue: 74.0/255.0, alpha: 1.0)
        
        return mainView
    }
    
    //MARK:Dynamic TextViews Based On firebase data
    func relayoutDynamicContentViews() {
        var yOrdinate:CGFloat = 150.0 + 94.0
        for index in 0..<(currentModel?.fields.count ?? 0) {
            let fieldView = self.getNameView(index: index)
            fieldView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(fieldView)
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(40)-[fieldView]-(40)-|", options: [], metrics: nil, views: ["fieldView":fieldView]))
            if(index == 0){
                if(currentModel?.fields.count == 1) {
                    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[profileView]-(40.0)-[fieldView]-(40)-[submitButton(50)]-(40)-|", options: [], metrics: nil, views: ["fieldView":fieldView,"profileView":profileView,"submitButton":submitButton]))
                }else{
                    contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[profileView]-(40.0)-[fieldView]", options: [], metrics: nil, views: ["fieldView":fieldView,"profileView":profileView]))
                }
            }else if(index == (currentModel?.fields.count)! - 1) {
                relayoutConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[lastFieldView]-(40)-[fieldView]-(40)-[submitButton(50)]-(40)-|", options: [], metrics: nil, views: ["fieldView":fieldView,"lastFieldView":expandableTextViews[index-1],"submitButton":submitButton])
                contentView.addConstraints(relayoutConstraints!)
            }
            else{
                contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[lastFieldView]-(40)-[fieldView]", options: [], metrics: nil, views: ["fieldView":fieldView,"lastFieldView":expandableTextViews[index-1]]))
            }
            
            let heightConstraint = NSLayoutConstraint(item: fieldView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70.0)
            heightConstraintArray.append(heightConstraint)
            contentView.addConstraint(heightConstraintArray[index])
            yOrdinate += heightConstraintArray[index].constant + 60.0
            expandableTextViews.append(fieldView)
        }
        
        if(currentModel?.fields.count == 0) {
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[submitButton]-(40)-|", options: [], metrics: nil, views: ["submitButton":submitButton]))
        }
        
        scrollView.contentSize = CGSize(width: contentView.frame.size.width, height: yOrdinate + 110.0)
        self.contentView.layoutIfNeeded()
        self.view.layoutIfNeeded()
        
        for expView in expandableTextViews {
            if(!expView.expandableTextView.text.isEmpty) {
                expView.textViewHeightHandler!()
            }
        }
    }
    
    func getNameView(index:Int) -> SPExpandableTextFieldView {
        let newView = SPExpandableTextFieldView(fieldName: (currentModel?.fields[index].fieldName)!,fieldValue:currentModel?.fields[index].fieldValue)
        newView.textViewHeightHandler = { () in
            DispatchQueue.main.async {
                let newSize = newView.expandableTextView.sizeThatFits(CGSize(width: newView.expandableTextView.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
                print("iam called with newHeight \(newSize.height)")
                if(index < self.heightConstraintArray.count) {
                    self.heightConstraintArray[index].constant = newSize.height + 40.0
                    self.updateContentSize(index:index, constant:self.heightConstraintArray[index].constant)
                }
            }
        }
        return newView
    }
    
    //MARK:Main Listner Method for any dynamic data change
    func setupListnerOnFormNodes() {
        firebaseManager.setupListnerOnUserNode(completion: {(field) in
            if(field != nil) {
                self.findChangedDataInUpdatedDataAndRelayout(fieldObject: field!)
            }
            
            self.indicatorManager.removeLoader()
            
        })
    }
    
    func findChangedDataInUpdatedDataAndRelayout(fieldObject:FormFields) {
        
       // if(fieldObject.imageUrl != currentModel?.imageUrl) {
        profileImageView.loadImage(urlString: fieldObject.imageUrl!)
        if(currentModel?.fields.count != fieldObject.fields.count) {
            currentModel = fieldObject
            self.changeInFieldsInServer()
            return
        }
        
        for field in fieldObject.fields {
            let sameKeyCurrentObjectArray = currentModel?.fields.filter({$0.fieldName == field.fieldName})
            if(sameKeyCurrentObjectArray?.count == 0) {
                //TODO: Handling of new fields addition
                currentModel = fieldObject
                self.changeInFieldsInServer()
                return
            }
            let sameKeyCurrentObject = sameKeyCurrentObjectArray![0]
            if(sameKeyCurrentObject.fieldValue != field.fieldValue) {
                let expandableViewArray = expandableTextViews.filter({$0.fieldName == sameKeyCurrentObject.fieldName})
                if(expandableViewArray.count != 0 || sameKeyCurrentObject.fieldValue == nil) {
                    self.updateFormData(forExpandableView: expandableViewArray[0],andText: field.fieldValue!)
                }
            }
        }
        
        if(fieldObject.fields.count == 0) {
            for expandableView in expandableTextViews {
                self.updateFormData(forExpandableView: expandableView, andText: expandableView.fieldName)
            }
            profileImageView.image = UIImage(named:"noPhotoDetail")
            for field in 0..<(currentModel?.fields.count ?? 0) {
                //Maintaining Consistency in data
                currentModel?.fields[field].fieldValue = nil
            }
        }else{
            //TODO:Dynamic UIAddition
            currentModel = fieldObject
        }
    }
    
    func changeInFieldsInServer() {
        self.recursiveRemoveAllViews(view: self.scrollView)
        relayoutConstraints?.removeAll()
        for constraint in heightConstraintArray {
            constraint.isActive = false
        }
        self.heightConstraintArray.removeAll()
        for view in expandableTextViews {
            view.removeFromSuperview()
        }
        self.expandableTextViews.removeAll()
        self.relayoutViews()
    }
    
    
    //MARK:On change update any data in UI
    func updateFormData(forExpandableView:SPExpandableTextFieldView, andText:String) {
        forExpandableView.expandableTextView.text = andText
        if(andText.isEmpty) {
            forExpandableView.showPlaceHolder()
        }else{
            forExpandableView.hidePlaceHolder()
        }
        forExpandableView.textViewHeightHandler!()
    }
    
    func recursiveRemoveAllViews(view:UIView) {
        if(view.subviews.count > 0) {
            for view in view.subviews {
                recursiveRemoveAllViews(view:view)
            }
        }
        view.removeConstraints(view.constraints)
        //view.removeFromSuperview()
    }
    
    //MARK:SAVE ACTION
    @objc func saveClicked() {
        
        if(profileImageView.image == UIImage(named:"noPhotoDetail")) {
            let alert = UIAlertController(title: "Error", message: "Unable to save , Image can not be empty)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        currentModel?.image = profileImageView.image
        
        let newModel = FormFields()
        for expandableView in expandableTextViews {
            if(expandableView.expandableTextView.text == expandableView.fieldName || expandableView.expandableTextView.text.isEmpty) {
                //error fields can't be empty while saving
                //do something with expandableView to show errors
                let alert = UIAlertController(title: "Error", message: "Unable to save , \(expandableView.fieldName) can not be empty", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }else{
                let updatedItem = FormField()
                updatedItem.fieldName = expandableView.fieldName
                updatedItem.fieldValue = expandableView.expandableTextView.text
                newModel.fields.append(updatedItem)
            }
        }
        
        currentModel?.fields = newModel.fields
        
//        if(currentModel == nil) {
//            currentModel = FormFields()
//        }else{
//            currentModel?.fields.removeAll()
//        }
        
        if(isServerReachable()) {
            indicatorManager.showLoader()
            firebaseManager.updateValuesOnFirebase(newModel: currentModel!, completion: {(ref) in
                //show success alert
                self.indicatorManager.removeLoader()
                if(ref != nil && self.firebaseManager.reference == nil) {
                    self.setupListnerOnFormNodes()
                }
                _ = self.currentModel?.image?.save()
                let alert = UIAlertController(title: "Success", message: "Your Data is saved successfully in firebase and local db", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            })
        }else{
            _ = self.currentModel?.image?.save()
            firebaseManager.saveProfileInDB(profileDict: currentModel!, andState:false)
            let alert = UIAlertController(title: "No Internet", message: "Your Data is saved successfully in local db and marked as unsync. Wait for internet connectivity or open this screen again whenever internet is back to auto sync", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    //MARK: Updated UI on delegate callback
    func updateContentSize(index:Int,constant:CGFloat) {
        var size = scrollView.contentSize
        size.height += constant
        size.height -= heightConstraintArray[index].constant
        scrollView.contentSize = size
        self.contentView.layoutIfNeeded()
        self.view.layoutIfNeeded()
    }
    
    func addGestures() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(dismissableViewTapped))
        scrollView.addGestureRecognizer(gesture)
    }
    
    @objc fileprivate func dismissableViewTapped() {
        self.contentView.endEditing(true)
    }
    
    @objc func profileUploadClicked() {
        let fusuma = FusumaViewController()
        fusuma.delegate = self
        fusuma.cropHeightRatio = 0.6
        fusumaSavesImage = true
        
        fusumaBackgroundColor = UIColor(red: 1.0/255.0, green: 171.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        fusumaBaseTintColor = UIColor.white
        //fusuma.allowMultipleSelection = false // You can select multiple photos from the camera roll. The default value is false.
        self.present(fusuma, animated: true, completion: nil)
    }
}

//Image Library Delegate methods seperate in extension
extension SPViewController:FusumaDelegate {
    func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {
        profileImageView.image = image
        currentModel?.image = image
        currentModel?.imageUrl = "needstobbesaved"
        print(image)
    }
    
    func fusumaMultipleImageSelected(_ images: [UIImage], source: FusumaMode) {
        print("impossible")
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        print("impossible")
    }
    
    func fusumaCameraRollUnauthorized() {
        print("access denied")
        print("Camera roll unauthorized")
        
        let alert = UIAlertController(title: "Access Requested",
                                      message: "Saving image needs to access your photo album",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (action) -> Void in
            
            if let url = URL(string:UIApplicationOpenSettingsURLString) {
                
                //                UIApplication.shared.openURL(url)
                UIApplication.shared.open(url, options: [:], completionHandler: {(flag) in
                    if(flag) {
                        print(flag)
                    }
                })
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            
        })
        
        guard let vc = UIApplication.shared.delegate?.window??.rootViewController,
            let presented = vc.presentedViewController else {
                
                return
        }
        
        presented.present(alert, animated: true, completion: nil)
    }
    
}
