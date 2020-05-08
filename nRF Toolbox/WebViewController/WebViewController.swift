/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/



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
            UIApplication.shared.open(self.link.url)
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

