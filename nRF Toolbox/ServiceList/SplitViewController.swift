//
//  SplitViewController.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 19/08/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit

protocol DetailViewController: class { }

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

protocol ServiceSelectedDelegate: class {
    func openServiceController(_ serviceId: ServiceId)
}

class SplitViewController: UISplitViewController {
    
    var masterViewController: ServiceListViewController {
        return self.viewControllers.first
            .flatMap { $0 as? UINavigationController }
            .flatMap { $0.viewControllers.first as? ServiceListViewController }!
    }
    
    private let serviceViewControllers: [ServiceId : UIViewController] = {
        return [
            .glucoseMonitoring : createAndWrappController(controllerClass: BGMViewController.self),
            .bloodPressureMonitoring : createAndWrappController(controllerClass: BPMViewController.self),
            .cyclingSensor : createAndWrappController(controllerClass: CSCViewController.self),
            .heartRateMonitor : createAndWrappController(controllerClass: HRMViewController.self),
            .healthThermometer : createAndWrappController(controllerClass: HTSViewController.self),
            .runningSensor : createAndWrappController(controllerClass: RSCViewController.self),
            .continuousGlucoseMonitor : createAndWrappController(controllerClass: CGMViewController.self),
            .deviceFirmwareUpgrade : createAndWrappController(controllerClass: DFUViewController.self),
            .proximity : createAndWrappController(controllerClass: ProximityViewController.self),
            .homeKit : createAndWrappController(controllerClass: HKViewController.self),
            //            .github : DetailsTabBarController.createAndWrappController(controllerClass: ProximityViewController.self),
            
            .uart : wrapContreller(UARTRevealViewController.instance(storyboard: UIStoryboard(name: "UARTViewController", bundle: .main)))
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredDisplayMode = .allVisible
        self.delegate = self
        self.masterViewController.servicePresenterDelegate = self
    }
}

extension SplitViewController {
    static private func createAndWrappController<T: StoryboardInstantiable>(controllerClass: T.Type) -> UIViewController {
        let controller = controllerClass.instance()
        return self.wrapContreller(controller as! UIViewController)
    }
    
    static private func wrapContreller(_ controller: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.barTintColor = .nordicBlue
        
        if #available(iOS 11.0, *) {
            let attributes: [NSAttributedString.Key : Any] = [
                .foregroundColor : UIColor.almostWhite
            ]
            
            navigationController.navigationBar.titleTextAttributes = attributes
            navigationController.navigationBar.largeTitleTextAttributes = attributes
            navigationController.navigationBar.prefersLargeTitles = true
        }
        
        return navigationController
    }
}

extension SplitViewController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

extension SplitViewController: ServiceSelectedDelegate {
    func openServiceController(_ serviceId: ServiceId) {
        if let selectedController = self.serviceViewControllers[serviceId] {
            self.showDetailViewController(selectedController, sender: nil)
        }
    }
}
