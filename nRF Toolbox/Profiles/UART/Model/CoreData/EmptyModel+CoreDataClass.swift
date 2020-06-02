//
//  EmptyModel+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 02.06.2020.
//
//

import Foundation
import CoreData

@objc(EmptyModel)
public class EmptyModel: UARTCommandModel {
    public override var title: String! {
        get { "" }
        set { SystemLog.fault("EmptyModel has only readOnsy permission", category: .coreData) }
    }
    
    override var icon: CommandImage? {
        get { nil }
        set { SystemLog.fault("EmptyModel has only readOnsy permission", category: .coreData) }
    }
    
    override var data: Data! {
        get { Data() }
        set { SystemLog.fault("EmptyModel has only readOnsy permission", category: .coreData) }
    }
    
}
