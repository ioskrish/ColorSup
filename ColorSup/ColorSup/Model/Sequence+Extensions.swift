//
//  Sequence+Extensions.swift
//  ColorSup
//
//  Created by Krishna Panchal on 13/11/23.
//

import Foundation

extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var set = Set<Element>()
        return filter { set.insert($0).inserted }
    }
}
