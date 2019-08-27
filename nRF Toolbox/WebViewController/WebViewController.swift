//
//  WebViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    var webView: UIWebView { return self.view as! UIWebView }
    let link: LinkService
    
    override func loadView() {
        self.view = UIWebView()
    }
    
    init(link: LinkService) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
        let request = URLRequest(url: link.url)
        self.webView.loadRequest(request)
        
        self.navigationItem.title = link.name
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openInSafari))
    }
    
    required init?(coder aDecoder: NSCoder) {
        Log(category: .ui, type: .fault).fault("init(coder:) has not been implemented")
    }
    
    @objc func openInSafari() {
        UIApplication.shared.openURL(self.link.url)
    }
}
