//
//  MainRouter.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 22/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

enum ServiceId: String, CaseIterable {
    case glucoseMonitoring
    case bloodPressureMonitoring
    case cyclingSensor
    case heartRateMonitor
    case healthThermometer
    case runningSensor
    case continuousGlucoseMonitor
    case uart
    case deviceFirmwareUpgrade
    case proximity
    case homeKit
}

protocol MainRouter {
    var rootViewController: UIViewController { get }
}

protocol ServiceRouter {
    func showServiceController(with serviceId: ServiceId)
    func showServiceController(_ model: BLEService)
    func showLinkController(_ link: LinkService)
}

class DefaultMainRouter {
    
    private let serviceViewControllers: [ServiceId : UIViewController] = {
        return [
//            .glucoseMonitoring : GMTableViewController(), //BGMViewController.instance(),
            .bloodPressureMonitoring : BPMViewController.instance(),
            .cyclingSensor : CSCViewController.instance(),
            .heartRateMonitor : HRMViewController.instance(),
            .healthThermometer : HTSViewController.instance(),
            .runningSensor : RSCViewController.instance(),
            .continuousGlucoseMonitor : CGMViewController.instance(),
            .deviceFirmwareUpgrade : DFUViewController.instance(),
            .proximity : ProximityViewController.instance(),
            .homeKit : HKViewController.instance(),
            .uart : UARTRevealViewController.instance(storyboard: UIStoryboard(name: "UARTViewController", bundle: .main))
        ].mapValues { UINavigationController.nordicBranded(rootViewController: $0) }
    }()
    
    lazy private var serviceList = ServiceListViewController(serviceRouter: self)
    
    lazy private var splitViewController: UISplitViewController = {
        let nc = UINavigationController.nordicBranded(rootViewController: serviceList)
        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [nc, NoContentViewController()]
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        
        return splitViewController
    }()
    
}

extension DefaultMainRouter: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return serviceList.selectedService == nil
    }
}

extension DefaultMainRouter: ServiceRouter {
    func showServiceController(_ model: BLEService) {
        let vc = GlucoseMonitorViewController(style: .grouped)
        splitViewController.showDetailViewController(vc, sender: self)
    }
    
    func showServiceController(with serviceId: ServiceId) {
        guard let viewController = serviceViewControllers[serviceId] else {
            Log(category: .ui, type: .error).log(message: "Cannot find view controller for \(serviceId) service id")
            return
        }
        splitViewController.showDetailViewController(viewController, sender: self)
    }
    
    func showLinkController(_ link: LinkService) {
        let webViewController = WebViewController(link: link)
        let nc = UINavigationController.nordicBranded(rootViewController: webViewController)
        splitViewController.showDetailViewController(nc, sender: self)
    }
}

extension DefaultMainRouter: MainRouter {
    var rootViewController: UIViewController {
        return splitViewController
    }
}

extension DefaultMainRouter {
    static private func createAndWrappController<T>(controllerClass: T.Type) -> UIViewController where T : UIViewController & StoryboardInstantiable {
        return UINavigationController.nordicBranded(rootViewController: controllerClass.instance())
    }
}
