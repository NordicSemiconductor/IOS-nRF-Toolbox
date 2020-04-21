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
    case zephyrDFU
    case proximity
    case homeKit
}

protocol MainRouter {
    var rootViewController: UIViewController { get }
}

protocol ServiceRouter {
    func showServiceController(with serviceId: ServiceId)
    func showLinkController(_ link: LinkService)
}

class DefaultMainRouter {
    
    private let dfuRouter: DFURouter = DFURouter(navigationController: UINavigationController.nordicBranded())
    private let zephyrRouter: ZephyrDFURouterType = ZephyrDFURouter(navigationController: UINavigationController.nordicBranded())
    
    private lazy var serviceViewControllers: [ServiceId : UIViewController] = {
        return [
            .heartRateMonitor : HeartRateMonitorTableViewController(),
            .bloodPressureMonitoring : BloodPressureTableViewController(),
            .glucoseMonitoring : GlucoseMonitorViewController(),
            .continuousGlucoseMonitor : ContinuousGlucoseMonitor(),
            .healthThermometer : HealthTermometerTableViewController(),
            .cyclingSensor : CyclingTableViewController(),
            .runningSensor : RunningTableViewController(),
            .proximity : ProximityViewController(),
            .uart : UARTTabBarController()
            ].mapValues { UINavigationController.nordicBranded(rootViewController: $0) }
        .merging([
            .deviceFirmwareUpgrade : dfuRouter.initialState(),
            .zephyrDFU : zephyrRouter.setInitialState()
        ], uniquingKeysWith: {n, _ in n})
    }()
    
    lazy private var serviceList = ServiceListViewController(serviceRouter: self)
    
    lazy private var splitViewController: UISplitViewController = {
        let nc = UINavigationController.nordicBranded(rootViewController: serviceList, prefersLargeTitles: true)
        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [nc, NoContentViewController()]
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        
        return splitViewController
    }()
    
}

extension DefaultMainRouter: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        serviceList.selectedService == nil
    }
}

extension DefaultMainRouter: ServiceRouter {
    func showServiceController(with serviceId: ServiceId) {
        guard let viewController = serviceViewControllers[serviceId] else {
            SystemLog(category: .ui, type: .error).log(message: "Cannot find view controller for \(serviceId) service id")
            return
        }
        
        guard (splitViewController.viewControllers.last as? UINavigationController)?.viewControllers.last != viewController else { return }
        splitViewController.showDetailViewController(viewController, sender: self)
    }
    
    func showLinkController(_ link: LinkService) {
        let webViewController = WebViewController(link: link)
        let nc = UINavigationController.nordicBranded(rootViewController: webViewController)
        splitViewController.showDetailViewController(nc, sender: self)
    }
}

extension DefaultMainRouter: MainRouter {
    var rootViewController: UIViewController { splitViewController }
}

extension DefaultMainRouter {
    static private func createAndWrapController<T>(controllerClass: T.Type) -> UIViewController where T : UIViewController & StoryboardInstantiable {
        UINavigationController.nordicBranded(rootViewController: controllerClass.instance())
    }
}
