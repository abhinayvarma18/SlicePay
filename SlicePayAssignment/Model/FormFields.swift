//
//  FormFields.swift
//  SlicePayAssignment
//
//  Created by ABHINAY on 15/03/18.
//  Copyright © 2018 ABHINAY. All rights reserved.
//

import UIKit

class FormFields: NSObject {
    var fields:[FormField] = []
    var image:UIImage? = UIImage()
    var imageUrl:String? = ""
}

class FormField:NSObject {
    var fieldName:String? = ""
    var fieldValue:String? = ""
}

