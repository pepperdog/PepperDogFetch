//
//  Column.swift
//  PepperDogFetch
//
//  Created by Kenny Leung on 4/2/16.
//  Copyright © 2016 Kenny Leung. All rights reserved.
//

import Foundation

public class Column {
    
    let name :String
    let type :String
    let precision :Int?
    let scale :Int?
    
    init(name: String, type: String, precision: Int, scale: Int) {
        self.name = name;
        self.type = type;
        self.precision = precision;
        self.scale = scale;
    }
    
}