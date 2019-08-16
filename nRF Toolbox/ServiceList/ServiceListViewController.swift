//
//  ServiceListViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit


class ServiceListViewController: UIViewController {
    private static func loadServices(from fileName: String) -> [Service] {
        guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "plist") else { return [] }
        do {
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            return try PropertyListDecoder().decode([Service].self, from: data)
        } catch let error {
            return []
        }
    }
    
    @IBOutlet private var tableView: UITableView!
    
    private let services = loadServices(from: "BLEServiceList")
    // TODO: Consider other name variants
    private let interactions = loadServices(from: "InteractionServiceList")
    private let iot = loadServices(from: "IoTServices")
    
    var serviceGroups: [[Service]] {
        return [services, interactions, iot]
    }
    
}

extension ServiceListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return serviceGroups.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.serviceGroups[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = self.serviceGroups[indexPath]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ServiceTableViewCell") as! ServiceTableViewCell
        cell.update(with: model)
        return cell
    }
    
    
}
