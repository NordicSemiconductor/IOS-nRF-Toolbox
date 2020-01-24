//
//  AlertPresenter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 24/01/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol AlertPresenter {
    func displayErrorAlert(error: Error)
}

extension AlertPresenter where Self: UIViewController {
    func displayErrorAlert(error: Error) {
        let msg = (error as? ReadableError)?.readableMessage ?? error.localizedDescription
        let alertController = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
