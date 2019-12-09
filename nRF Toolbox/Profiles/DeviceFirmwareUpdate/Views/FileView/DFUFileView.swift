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
                
                self.fileSizeLabel.text = firmware.fileUrl
                    .flatMap { try? Data(contentsOf: $0) }
                    .map { Int64($0.count) }
                    .flatMap { ByteCountFormatter().string(fromByteCount: $0) }
                
                self.deviceScheme.setParts(with: firmware)
                self.fileSizeView.update(with: firmware)
            case .updating(let firmwareType):
                break
            default:
                break
            }
        }
    }
    
    weak var delegate: DFUFileViewActionDelegate?
    
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
        self.fileScheme.progress = 100 - totalUpdatedPercent
        self.deviceScheme.progress = totalUpdatedPercent
        
        print("Total percent: \(currentPartPercent)")
    }
}
