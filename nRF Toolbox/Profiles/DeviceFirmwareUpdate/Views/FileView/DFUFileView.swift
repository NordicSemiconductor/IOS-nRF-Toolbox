//
//  DFUFileView.swift
//  nRF Toolbox
//
//  Created by Nick Kibysh on 04/12/2019.
//  Copyright © 2019 Nordic Semiconductor. All rights reserved.
//

import UIKit
import iOSDFULibrary

protocol DFUFileViewActionDelegate: class {
    func openFile(_ fileView: DFUFileView)
    
    func update(_ fileView: DFUFileView)
    func pause(_ fileView: DFUFileView)
    func resume(_ fileView: DFUFileView)
    func stop(_ fileView: DFUFileView)
    
    func share(_ fileView: DFUFileView)
    func done(_ fileView: DFUFileView)
}

protocol DFUFileHandlerDelegate: class {
    func fileView(_ fileView: DFUFileView, loadedFirmware firmware: DFUFirmware)
    func fileView(_ fileView: DFUFileView, didntOpenFileWithError error: Error)
}

extension DFUFirmwareType {
    var desccription: String {
        switch self {
        case .application: return "Application"
        case .bootloader: return "Bootloader"
        case .softdevice: return "SoftDevice"
        case .softdeviceBootloader: return "System Components"
        case .softdeviceBootloaderApplication: return "All"
        }
    }
}

private struct DFUFileViewConfigurator {
    var title: String
    var titleColor: UIColor = .nordicLabel
    
    var leftImageConfigurator: ProgressImageConfigurator? = .file
    
    var rightImageHidden: Bool = true
    var fileSizeViewHidden: Bool = true
    var totalSizeLabelHidden: Bool = true
    
    var leftButtonConfigurator: NordicButtonConfigurator
    var rightButtonConfigurator: NordicButtonConfigurator
}

private extension DFUFileViewConfigurator {
    static let readyToOpen = DFUFileViewConfigurator(title: "Select File", leftButtonConfigurator: .selectFile, rightButtonConfigurator: .hidden)
    static let unsupporded = DFUFileViewConfigurator(title: "Unsupported File", leftImageConfigurator: .error, leftButtonConfigurator: .selectAnotherFile, rightButtonConfigurator: .hidden)
    static let error = DFUFileViewConfigurator(title: "Error", titleColor: .nordicRed, leftImageConfigurator: .error, leftButtonConfigurator: .selectAnotherFile, rightButtonConfigurator: .share)
    static let readyToUpdate = DFUFileViewConfigurator(title: "Ready for Update", leftImageConfigurator: .file, rightImageHidden: true,  fileSizeViewHidden: false, totalSizeLabelHidden: false, leftButtonConfigurator: .selectAnotherFile, rightButtonConfigurator: .update)
    static let updating = DFUFileViewConfigurator(title: "Updating...", leftImageConfigurator: nil, rightImageHidden: false, totalSizeLabelHidden: false, leftButtonConfigurator: .pause, rightButtonConfigurator: .stop)
    static let onPause = DFUFileViewConfigurator(title: "Pause", leftImageConfigurator: nil, rightImageHidden: false, fileSizeViewHidden: true, totalSizeLabelHidden: false, leftButtonConfigurator: .resume, rightButtonConfigurator: .stop)
    static let done = DFUFileViewConfigurator(title: "DONE!", titleColor: .nordicGreen, leftImageConfigurator: .done, leftButtonConfigurator: .share, rightButtonConfigurator: .done)
}

private extension NordicButtonConfigurator {
    static let hidden = NordicButtonConfigurator(isHidden: true, normalTitle: "")
    static let selectFile = NordicButtonConfigurator(normalTitle: "Select File", style: .mainAction)
    static let selectAnotherFile = NordicButtonConfigurator(normalTitle: "Select Another File")
    static let update = NordicButtonConfigurator(normalTitle: "Update", style: .mainAction)
    static let pause = NordicButtonConfigurator(normalTitle: "Pause")
    static let resume = NordicButtonConfigurator(normalTitle: "Resume")
    static let stop = NordicButtonConfigurator(normalTitle: "Stop", style: .distructive)
    static let done = NordicButtonConfigurator(normalTitle: "Done", style: .mainAction)
    static let share = NordicButtonConfigurator(normalTitle: "Share")
}

class DFUFileView: UIView {
    
    enum DFUSelectedPart {
        case application, bootloaderAndApp
    }
    
    let nibName = "DFUFileView"
    var contentView: UIView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        view.addZeroBorderConstraints()
        if #available(iOS 11.0, *) {
            addInteraction(UIDropInteraction(delegate: self))
        }
    }

    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    enum State {
        case readyToOpen, unsupportedFile, readyToUpdate(DFUFirmware), completed, updating(DFUFirmwareType), error(Error), paused
    }
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var fileSizeLabel: UILabel!
    @IBOutlet private var leftButton: NordicButton!
    @IBOutlet private var rightButton: NordicButton!
    @IBOutlet private var schemeStackView: UIStackView!
    @IBOutlet private var buttonStack: UIStackView!
    @IBOutlet private var fileScheme: FirmwareProgressImage!
    
    @IBOutlet private var deviceScheme: FirmwareProgressImage!
    @IBOutlet private var fileSizeView: FileSizeView!
    @IBOutlet private var deviceViewContainer: UIView!
    
    var state: State = .readyToOpen {
        didSet {
            self.update(state: state)
            switch state {
            case .readyToUpdate(let firmware):
                self.fileScheme.setParts(with: firmware)
                
                self.fileSizeLabel.text = ByteCountFormatter().string(fromByteCount: firmware.totalSize)
                
                self.fileSizeView.update(with: firmware)
                self.deviceScheme.setParts(with: firmware, reversed: true)
            default:
                break
            }
        }
    }
     
    weak var delegate: DFUFileViewActionDelegate?
    weak var fileDelegate: DFUFileHandlerDelegate?
    
    @IBAction private func leftButtonAction() {
        switch state {
        case .readyToOpen, .unsupportedFile, .error, .readyToUpdate:
            delegate?.openFile(self)
        case .completed:
            delegate?.share(self)
        case .updating:
            delegate?.pause(self)
        case .paused:
            delegate?.resume(self)
        }
    }
    
    @IBAction private func rightButtonAction() {
        switch state {
        case .readyToUpdate:
            delegate?.update(self)
        case .paused, .updating:
            delegate?.stop(self)
        case .completed:
            delegate?.done(self)
        case .error:
            delegate?.share(self)
        default:
            break
        }
    }
    
    private func update(state: State) {
        let configurator: DFUFileViewConfigurator
        
        switch state {
        case .readyToOpen:
            configurator = .readyToOpen
        case .readyToUpdate:
            configurator = .readyToUpdate
        case .updating:
            configurator = .updating
        case .paused:
            configurator = .onPause
        case .completed:
            configurator = .done
        case .unsupportedFile:
            configurator = .unsupporded
        case .error:
            configurator = .error
        }
        
        self.apply(configurator: configurator)
    }
    
    private func apply(configurator: DFUFileViewConfigurator) {
        titleLabel.text = configurator.title
        titleLabel.textColor = configurator.titleColor
        
        leftButton.apply(configurator: configurator.leftButtonConfigurator)
        rightButton.apply(configurator: configurator.rightButtonConfigurator)
        
        fileSizeView.isHidden = configurator.fileSizeViewHidden
        deviceViewContainer.isHidden = configurator.rightImageHidden
        fileSizeLabel.isHidden = configurator.totalSizeLabelHidden
        
        configurator.leftImageConfigurator.flatMap(fileScheme.apply(configurator:))
    }
}

extension DFUFileView: DFUProgressDelegate {
    public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        let part = part - 1
        let total = deviceScheme.parts
            .map{$0.parts}
            .reduce(0, +)
        let percents = deviceScheme.parts.map { Double($0.parts) / Double(total) }
        let updatedParts = percents.dropLast(percents.count - part).reduce(0, +)
        let currentPartPercent = percents[part] * Double(progress) / 100.0
        let totalUpdatedPercent = Int((currentPartPercent + updatedParts) * 100)
        self.fileScheme.progress = totalUpdatedPercent
        self.deviceScheme.progress = 100 - totalUpdatedPercent
        
        print("Total percent: \(currentPartPercent)")
    }
}

extension DFUFirmware: NSItemProviderReading {
    
    enum Error: Swift.Error {
        case fileNotSupported
    }
    
    public static var readableTypeIdentifiersForItemProvider: [String] {
        ["com.pkware.zip-archive"]
    }
    
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard let firmware = DFUFirmware(zipFile: data) as? Self else {
            throw Error.fileNotSupported
        }
        return firmware
    }
    
    var totalSize: Int64 {
        return Int64(size.application + size.bootloader + size.softdevice)
    }
}

@available(iOS 11.0, *)
extension DFUFileView: UIDropInteractionDelegate {
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
     
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        switch state {
        case .error, .unsupportedFile, .readyToOpen, .readyToUpdate:
            return session.hasItemsConforming(toTypeIdentifiers: ["com.pkware.zip-archive"])
        default:
            return false
        }
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        guard let itemProvider = session.items.first?.itemProvider.copy() as? NSItemProvider else { return }
        
        itemProvider.loadObject(ofClass: DFUFirmware.self) { (reading, error) in
            if let error = error {
                self.fileDelegate?.fileView(self, didntOpenFileWithError: error)
                return
            }
            
            if let firmware = reading as? DFUFirmware {
                self.fileDelegate?.fileView(self, loadedFirmware: firmware)
            }
        }
    }
}
