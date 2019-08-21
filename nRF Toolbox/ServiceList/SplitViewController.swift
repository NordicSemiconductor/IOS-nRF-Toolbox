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
            .glucoseMonitoring : SplitViewController.createAndWrappController(controllerClass: BGMViewController.self),
            .bloodPressureMonitoring : SplitViewController.createAndWrappController(controllerClass: BPMViewController.self),
            .cyclingSensor : SplitViewController.createAndWrappController(controllerClass: CSCViewController.self),
            .heartRateMonitor : SplitViewController.createAndWrappController(controllerClass: HRMViewController.self),
            .healthThermometer : SplitViewController.createAndWrappController(controllerClass: HTSViewController.self),
            .runningSensor : SplitViewController.createAndWrappController(controllerClass: RSCViewController.self),
            .continuousGlucoseMonitor : SplitViewController.createAndWrappController(controllerClass: CGMViewController.self),
            .deviceFirmwareUpgrade : SplitViewController.createAndWrappController(controllerClass: DFUViewController.self),
            .proximity : SplitViewController.createAndWrappController(controllerClass: ProximityViewController.self),
            .homeKit : SplitViewController.createAndWrappController(controllerClass: HKViewController.self),
            //            .github : DetailsTabBarController.createAndWrappController(controllerClass: ProximityViewController.self),
            
            .uart : SplitViewController.wrapContreller(UARTRevealViewController.instance(storyboard: UIStoryboard(name: "UARTViewController", bundle: .main)))
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
    static private func createAndWrappController<T: StoryboardInstance>(controllerClass: T.Type) -> UIViewController {
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
