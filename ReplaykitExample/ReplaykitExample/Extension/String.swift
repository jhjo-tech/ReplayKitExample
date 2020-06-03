//
//  String.swift
//  ReplaykitExmaple
//
//  Created by Bruce on 2020/06/03.
//  Copyright © 2020 jhjo. All rights reserved.
//

import Foundation

extension String {
    func dateFileName(_ fileExtension: String? = nil) -> String {
        let ts = Int(Date().timeIntervalSince1970)
        let prefix = self
        
        if let fileExtension = fileExtension {
            return "\(prefix)_\(ts).\(fileExtension)"
        }
        
        return "\(prefix)_\(ts)"
    }
}
