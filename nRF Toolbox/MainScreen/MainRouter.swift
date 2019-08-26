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
    case github
}

protocol MainRouter {
    var rootViewController: UIViewController { get }
}

protocol ServiceRouter {
    func showServiceController(with serviceId: ServiceId)
}

class DefaultMainRouter {
    
    private let serviceViewControllers: [ServiceId : UIViewController] = {
        return [
            .glucoseMonitoring : BGMViewController.instance(),
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
    
    lazy private var splitViewController: UISplitViewController = {
        let serviceList = ServiceListViewController(serviceRouter: self)
        let nc = UINavigationController.nordicBranded(rootViewController: serviceList)
        
        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [nc]
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        
        return splitViewController
    }()
    
}

extension DefaultMainRouter: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}


extension DefaultMainRouter: ServiceRouter {
    func showServiceController(with serviceId: ServiceId) {
        guard let viewController = self.serviceViewControllers[serviceId] else {
            Log(category: .ui, type: .error).log(message: "Cannot find view controller for \(serviceId) service id")
            return
        }
        self.splitViewController.showDetailViewController(viewController, sender: self)
    }
}

extension DefaultMainRouter: MainRouter {
    var rootViewController: UIViewController {
        return self.splitViewController
    }
}

extension DefaultMainRouter {
    static private func createAndWrappController<T>(controllerClass: T.Type) -> UIViewController where T : UIViewController & StoryboardInstantiable {
        return UINavigationController.nordicBranded(rootViewController: controllerClass.instance())
    }
}
