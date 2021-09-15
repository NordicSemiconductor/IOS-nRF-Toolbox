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
import NordicDFU


struct LogMessage {
    let level: LogType
    let message: String
    let time: Date
}

@objc protocol LogPresenter: LoggerDelegate {
    var attributedLog: NSAttributedString { get }
    func reset()
}

class LoggerTableView: UITableView {
    var logs: [LogMessage] = []
    
    var filter: [LogType] = LogType.allCases {
        didSet {
            reloadData()
        }
    }
    
    private var filteredData: [LogMessage] {
        guard filter.count != LogType.allCases.count else { return logs }
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
        self.insertRows(at: [insertIndexPath], with: .none)
        self.scrollToRow(at: insertIndexPath, at: .bottom, animated: true)
    }
    
    func reset() {
        logs.removeAll()
        reloadData()
    }
}

extension LoggerTableView: LogPresenter, Logger {
    func log(level aLevel: LogType, message aMessage: String) {
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
//        print("count: \(filteredData.count)")
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
