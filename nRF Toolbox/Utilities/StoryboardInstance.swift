//
//  StoryboardInstance.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol StoryboardInstance {
    static func instance(storyboard: UIStoryboard, storyboardId: String) -> Self
    static func instance(storyboardId: String) -> Self
    static func instance(storyboard: UIStoryboard) -> Self
    static func instance() -> Self
}

extension StoryboardInstance where Self: UIViewController {
    static func instance(storyboard: UIStoryboard, storyboardId: String) -> Self {
        return storyboard.instantiateViewController(withIdentifier: storyboardId) as! Self
    }
    
    static func instance(storyboardId: String) -> Self {
        let name = String(describing: self)
        let storyboard = UIStoryboard(name: name, bundle: Bundle.main)
        return self.instance(storyboard: storyboard, storyboardId: storyboardId)
    }
    
    static func instance(storyboard: UIStoryboard) -> Self {
        let name = String(describing: self)
        return self.instance(storyboard: storyboard, storyboardId: name)
    }
    
    static func instance() -> Self {
        let name = String(describing: self)
        let storyboard = UIStoryboard(name: name, bundle: Bundle.main)
        return self.instance(storyboard: storyboard, storyboardId: name)
    }
}
