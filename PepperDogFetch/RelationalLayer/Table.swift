//
//  Table.swift
//  PepperDogFetch
//
//  Created by Kenny Leung on 4/2/16.
//  Copyright © 2016 Kenny Leung. All rights reserved.
//

import Foundation

public class Table {
    
    var name :String
    var columns :[Column]
    
    init(name :String) {
        self.name = name;
        self.columns = [Column]()
    }
    
}