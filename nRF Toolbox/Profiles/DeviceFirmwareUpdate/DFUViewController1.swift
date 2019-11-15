//
// Created by Nick Kibysh on 11/11/2019.
// Copyright (c) 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
private extension Identifier where Value == Section {
    static let openFile: Identifier<Section> = "open file"
    static let howTo: Identifier<Section> = "how to"
}

class DFUViewController1: PeripheralTableViewController {

    override var peripheralDescription: Peripheral {
        Peripheral(uuid: nil, services: [.battery])
    }

    private lazy var iCloudAction = ActionSectionItem(title: "iCloud") { 

    }

    private lazy var localStorage = ActionSectionItem(title: "Local Storage") { 

    }

    private lazy var loadFileSection = ActionSection(id: .openFile, sectionTitle: "Select File", items: [iCloudAction, localStorage])
    private lazy var howTo = ActionSection(id: .howTo, sectionTitle: "Info", items: [
        ActionSectionItem(title: "How To") {

        }
    ])
    override var internalSections: [Section] { [loadFileSection, howTo] }

    override func statusDidChanged(_ status: PeripheralStatus) {
        super.statusDidChanged(status)

        if case .connected = status, #available(iOS 11.0, *) {
                let interaction = UIDropInteraction(delegate: self)
                self.view.addInteraction(interaction)
        }
    }
}

@available(iOS 11.0, *)
extension DFUViewController1: UIDropInteractionDelegate {
    public func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        guard case .some = self.activePeripheral else {
            return false
        }

        return session.hasItemsConforming(toTypeIdentifiers: ["com.pkware.zip-archive"])
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnter session: UIDropSession) {
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .copy)
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidExit session: UIDropSession) {
    }

    public func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let item = session.items.first else { return }
        item.itemProvider.loadFileRepresentation(forTypeIdentifier: "com.pkware.zip-archive") { url, error in  
            if let error = error {
                Log(category: .ui, type: .error).log(message: "Can not drag file: \(error.localizedDescription)")
                return
            }

            guard let url = url else {
                Log(category: .ui, type: .error).log(message: "Drag&Drop: URL is empty")
                return
            }

            DispatchQueue.main.async {
                let vc = UIViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    public func dropInteraction(_ interaction: UIDropInteraction, concludeDrop session: UIDropSession) {
    }

    public func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
    }

    public func dropInteraction(_ interaction: UIDropInteraction, item: UIDragItem, willAnimateDropWith animator: UIDragAnimating) {
    }
}