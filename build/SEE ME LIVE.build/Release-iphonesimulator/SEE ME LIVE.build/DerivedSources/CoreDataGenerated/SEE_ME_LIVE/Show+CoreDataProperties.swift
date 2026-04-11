//
//  Show+CoreDataProperties.swift
//  
//
//  Created by Taylor Drew on 4/11/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ShowCoreDataPropertiesSet = NSSet

extension Show {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Show> {
        return NSFetchRequest<Show>(entityName: "Show")
    }

    @NSManaged public var title: String?
    @NSManaged public var role: String?
    @NSManaged public var venue: String?
    @NSManaged public var date: Date?
    @NSManaged public var price: Double
    @NSManaged public var ticketLink: String?
    @NSManaged public var notes: String?
    @NSManaged public var flyerImageData: Data?
    @NSManaged public var calendarEventID: String?
    @NSManaged public var publicRecordID: String?
    @NSManaged public var userID: String?
    @NSManaged public var addToCalendar: Bool
    @NSManaged public var setReminder: Bool
    @NSManaged public var needsPublicSync: Bool
    @NSManaged public var pendingPublicDelete: Bool
    @NSManaged public var lastPublicSyncError: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?

}

extension Show : Identifiable {

}
