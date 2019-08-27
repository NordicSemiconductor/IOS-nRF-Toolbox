//
//  ServiceListViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 15/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

class ServiceListViewController: UITableViewController {
    
    let dataProvider: ServiceProvider
    let serviceRouter: ServiceRouter
    
    private (set) var selectedService: ServiceId?
    
    init(dataProvider: ServiceProvider = DefaultServiceProvider(), serviceRouter: ServiceRouter) {
        self.dataProvider = dataProvider
        self.serviceRouter = serviceRouter
        super.init(style: .grouped)
        self.navigationItem.title = "nRF Toolbox"
    }
    
    required init?(coder aDecoder: NSCoder) {
        let errorMessage = "init(coder:) has not been implemented in ServiceListViewController"
        Log(category: .ui, type: .fault).log(message: errorMessage)
        fatalError(errorMessage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(cell: ServiceTableViewCell.self)
        self.tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: "LinkTableViewCell")
    }
    
}

extension ServiceListViewController {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dataProvider.sections[section].title
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.dataProvider.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataProvider.sections[section].services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.dataProvider.sections[indexPath] {
        case let ble as BLEService:
            let cell = tableView.dequeueCell(ofType: ServiceTableViewCell.self)
            cell.update(with: ble)
            return cell
        case let link as LinkService:
            let cell = tableView.dequeueCell(ofType: LinkTableViewCell.self)
            cell.update(with: link)
            return cell
        default:
            let errorMessage = "Incorrect cell type for indexPath \(indexPath)"
            Log(category: .ui, type: .fault).log(message: errorMessage)
            fatalError(errorMessage)
        }
    }
}

extension ServiceListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let model = self.dataProvider.sections[indexPath]
        if let serviceId = ServiceId(rawValue: model.id) {
            self.selectedService = serviceId
            self.serviceRouter.showServiceController(with: serviceId)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch traitCollection.userInterfaceIdiom {
        case .pad:
            return 100
        default:
            return 80
        }
    }
}
