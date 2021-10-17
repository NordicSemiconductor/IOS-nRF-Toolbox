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
    func handleUrl(_ url: URL) -> Bool
}

protocol ServiceRouter {
    func showServiceController(with serviceId: ServiceId)
    func openLink(_ link: LinkService)
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
    
    func openLink(_ link: LinkService) {
        UIApplication.shared.open(link.url)
    }
}

extension DefaultMainRouter: MainRouter {
    var rootViewController: UIViewController { splitViewController }
    
    @discardableResult
    func handleUrl(_ url: URL) -> Bool {
        guard url.scheme == "nrf-toolbox" else {
            return false
        }
        
        let pathComponents = url.pathComponents
        
        guard pathComponents.count > 1 else {
            return false
        }
        
        guard let serviceId = ServiceId(rawValue: pathComponents[1]) else {
            return false
        }
        
        showServiceController(with: serviceId)
        
        return true
    }
}

extension DefaultMainRouter {
    static private func createAndWrapController<T>(controllerClass: T.Type) -> UIViewController where T : UIViewController & StoryboardInstantiable {
        UINavigationController.nordicBranded(rootViewController: controllerClass.instance())
    }
}
