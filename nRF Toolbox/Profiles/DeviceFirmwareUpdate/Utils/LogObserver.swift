//
//  LoggObserver.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 06/03/2020.
//  Copyright © 2020 Nordic Semiconductor. All rights reserved.
//

import Foundation
import iOSDFULibrary

extension Notification.Name {
    static let newMessage = Notification.Name("newMessage")
    static let reset = Notification.Name("reset")
}

class LogObserver {
    
    static let messageNotificationKey = Identifier<String>.init(string: "message")
        
    private (set) var messages: [LogMessage] = []
    private let notificationCenter: NotificationCenter
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }
    
    func reset() {
        messages.removeAll()
        notificationCenter.post(Notification(name: .reset, object: self, userInfo: nil))
    }
    
    func logWith(_ level: LogType, message: String) {
        let message = LogMessage(level: level, message: message, time: Date())
        messages.append(message)
        
        let notification = Notification.init(name: .newMessage, object: self, userInfo: [LogObserver.messageNotificationKey : message])
        notificationCenter.post(notification)
    }
    
    
}
