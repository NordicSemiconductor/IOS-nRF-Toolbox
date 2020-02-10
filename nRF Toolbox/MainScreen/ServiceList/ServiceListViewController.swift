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
        navigationItem.title = "nRF Toolbox"
    }
    
    required init?(coder aDecoder: NSCoder) {
        let errorMessage = "init(coder:) has not been implemented in ServiceListViewController"
        Log(category: .ui, type: .fault).log(message: errorMessage)
        fatalError(errorMessage)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCellNib(cell: ServiceTableViewCell.self)
        tableView.register(LinkTableViewCell.self, forCellReuseIdentifier: "LinkTableViewCell")
    }
    
}

extension ServiceListViewController {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataProvider.sections[section].title
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataProvider.sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.sections[section].services.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch dataProvider.sections[indexPath] {
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
        
        switch dataProvider.sections[indexPath] {
        case let model as BLEService:
            guard let serviceId = ServiceId(rawValue: model.id) else {
                Log(category: .ui, type: .debug).log(message: "Unknown service selected with id \(model.id)")
                break
            }
            selectedService = serviceId
            serviceRouter.showServiceController(with: serviceId)
        case let link as LinkService:
            serviceRouter.showLinkController(link)
        default:
            Log(category: .ui, type: .debug).log(message: "Unknown Cell type selected")
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
