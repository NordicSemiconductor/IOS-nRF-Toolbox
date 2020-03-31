//
//  WebViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 27/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class WebViewController: UIViewController {
    var webView: UIWebView { return view as! UIWebView }
    let link: LinkService
    
    override func loadView() {
        view = UIWebView()
    }
    
    init(link: LinkService) {
        self.link = link
        super.init(nibName: nil, bundle: nil)
        let request = URLRequest(url: link.url)
        webView.loadRequest(request)
        
        navigationItem.title = link.name
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action))
    }
    
    required init?(coder aDecoder: NSCoder) {
        SystemLog(category: .ui, type: .fault).fault("init(coder:) has not been implemented")
    }
    
    @objc private func action(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let openInBrowserAction = UIAlertAction(title: "Open in Safari", style: .default) { _ in
            UIApplication.shared.openURL(self.link.url)
        }
        let shareAction = UIAlertAction(title: "Share", style: .default) { _ in
            self.share(sender)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.popoverPresentationController?.barButtonItem = sender
        
        [openInBrowserAction, shareAction, cancelAction].forEach(alertController.addAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func share(_ sender: UIBarButtonItem) {
        let activityController = UIActivityViewController(activityItems: [link.url], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem = sender
        present(activityController, animated: true, completion: nil)
    }
}

