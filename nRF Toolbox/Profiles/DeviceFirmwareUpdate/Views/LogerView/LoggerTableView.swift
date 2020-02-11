//
//  LoggerTableView.swift
//  nRF Toolbox
//
//  Created by Nick Kibish on 18.12.2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

struct LogMessage {
    let level: LogLevel
    let message: String
    let time: Date
}

@objc protocol LogPresenter: LoggerDelegate {
    var attributedLog: NSAttributedString { get }
    func reset()
}

class LoggerTableView: UITableView {
    private var logs: [LogMessage] = []
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    func clear() {
        logs.removeAll()
        reloadData()
    }
    
    private func initialize() {
        registerCellNib(cell: LogTableViewCell.self)
        dataSource = self
        
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44.0
        separatorStyle = .none
    }
}

extension LoggerTableView: LogPresenter, Logger {
    func log(level aLevel: LOGLevel, message aMessage: String) {
        let logLevel: LogLevel = {
            switch aLevel {
            case .debugLogLevel: return .debug
            case .verboseLogLevel: return .verbose
            case .appLogLevel: return .application
            case .errorLogLevel: return .error
            case .infoLogLevel: return .info
            case .warningLogLevel: return .warning
            }
        }()
        
        logWith(logLevel, message: aMessage)
    }
    
    func logWith(_ level: LogLevel, message: String) {
        let insertIndexPath = IndexPath(row: logs.count, section: 0)
        let log = LogMessage(level: level, message: message, time: Date())
        DispatchQueue.main.async {
            self.logs.append(log)
            self.insertRows(at: [insertIndexPath], with: .none)
            self.scrollToRow(at: insertIndexPath, at: .bottom, animated: true)
        }
    }
    
    var attributedLog: NSAttributedString {
        let defaultAttributes: [NSAttributedString.Key : Any] = [
            .font : UIFont.gtEestiDisplay(.medium, size: 14)
        ]
        let timeFormatter = DateFormatter.longTimeFormatter
        
        return logs.map { log -> NSAttributedString in
            let timeString = NSMutableAttributedString(string: "\(timeFormatter.string(from: log.time)): ", attributes: defaultAttributes)
            
            let logAttributes = defaultAttributes.merging([.foregroundColor : log.level.color], uniquingKeysWith: { new, _ in new })
            let logString = NSAttributedString(string: "\(log.message)\n", attributes: logAttributes)
            timeString.append(logString)
            return timeString
        }
        .reduce(NSMutableAttributedString()) {
            $0.append($1)
            return $0
        }
    }
    
    func reset() {
        logs.removeAll()
        reloadData()
    }
}

extension LoggerTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: LogTableViewCell.self)
        let log = logs[indexPath.row]
        cell.update(with: log)
        return cell
    }
}
