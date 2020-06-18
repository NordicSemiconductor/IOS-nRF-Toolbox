//
//  EmptyModel+CoreDataClass.swift
//  
//
//  Created by Nick Kibish on 02.06.2020.
//
//

import Foundation
import CoreData
/*
@objc(EmptyModel)
public class EmptyModel: UARTCommandModel {
    
    static func emptyModel(in context: NSManagedObjectContext = CoreDataStack.uart.viewContext) -> EmptyModel {
        return EmptyModel.init(context: context)
        /*
        let request: NSFetchRequest<EmptyModel> = EmptyModel.fetchRequest()
        let objects = try? context.fetch(request)
        
        if let model = objects?.first {
            return model
        } else {
        }
        */
    }
    
    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    private init(context: NSManagedObjectContext) {
        let entity = Self.getEntity(context: context)!
        super.init(entity: entity, insertInto: context)
    }
    
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
*/