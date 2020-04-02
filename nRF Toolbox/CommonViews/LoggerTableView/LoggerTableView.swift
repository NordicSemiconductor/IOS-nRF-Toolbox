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
    let level: LOGLevel
    let message: String
    let time: Date
}

@objc protocol LogPresenter: LoggerDelegate {
    var attributedLog: NSAttributedString { get }
    func reset()
}

class LoggerTableView: UITableView {
    var logs: [LogMessage] = []
    
    var filter: [LOGLevel] = LOGLevel.allCases {
        didSet {
            reloadData()
        }
    }
    
    private var filteredData: [LogMessage] {
        guard filter.count != LOGLevel.allCases.count else { return logs }
        return logs.filter { filter.contains($0.level) }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }
    
    private func initialize() {
        registerCellNib(cell: LogTableViewCell.self)
        dataSource = self
        
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 44.0
        separatorStyle = .none
    }
}

extension LoggerTableView {
    func addMessage(_ message: LogMessage) {
        self.logs.append(message)
        guard self.filter.contains(message.level) else { return }
        let insertIndexPath = IndexPath(row: self.filteredData.count-1, section: 0)
        self.insertRows(at: [insertIndexPath], with: .bottom)
        self.scrollToRow(at: insertIndexPath, at: .bottom, animated: true)
    }
    
    func reset() {
        logs.removeAll()
        reloadData()
    }
}

extension LoggerTableView: LogPresenter, Logger {
    func log(level aLevel: LOGLevel, message aMessage: String) {
        DispatchQueue.main.async {
            let log = LogMessage(level: aLevel, message: aMessage, time: Date())
            self.addMessage(log)
        }
    }
    
    func logWith(_ level: LogLevel, message: String) {
        self.log(level: level.level, message: message)
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
}

extension LoggerTableView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("count: \(filteredData.count)")
        return filteredData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(ofType: LogTableViewCell.self)
        let log = filteredData[indexPath.row]
        cell.update(with: log)
        cell.selectionStyle = .none
        return cell
    }
}
