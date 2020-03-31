//
//  LoggerTableViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 09/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import UIKit

class LoggerTableViewController: UITableViewController {
    let observer: LogObserver
    private var loggTableView: LoggerTableView { tableView as! LoggerTableView }
    
    init(observer: LogObserver) {
        self.observer = observer
        super.init(nibName: "LoggerTableViewController", bundle: .main)
        
        tabBarItem = UITabBarItem(title: "Logs", image: TabBarIcon.uartLogs.image, selectedImage: TabBarIcon.uartLogs.filledImage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loggTableView.dataSource = loggTableView
        loggTableView.logs = self.observer.messages
        loggTableView.reloadData()
        
        NotificationCenter.default.addObserver(forName: .newMessage, object: nil, queue: .main) { [weak self] (notification) in
            guard let message = notification.userInfo?[LogObserver.messageNotificationKey] as? LogMessage else { return }
            self?.loggTableView.addMessage(message)
        }
        
        NotificationCenter.default.addObserver(forName: .reset, object: nil, queue: .main) { [weak self] (notification) in
            self?.loggTableView.reset()
        }
        
        navigationItem.title = "Logs"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
