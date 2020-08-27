//
//  String++.swift
//  
//
//  Created by Licardo on 2020/8/28.
//

import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, bundle: .module, comment: self)
    }
}
