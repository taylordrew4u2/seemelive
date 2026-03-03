//
//  PublicCloudSyncService.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import CloudKit
import CoreData
import UIKit

// MARK: - Public Cloud Sync Service
/// Syncs shows to the CloudKit **public** database so anyone can read them
/// via the public web calendar. Core Data + NSPersistentCloudKitContainer
/// handles the *private* database automatically; this service handles only
/// the public copy.
///
/// Offline strategy: when a save/update/delete fails, the show is flagged
/// (`needsPublicSync` or `pendingPublicDelete`) and retried the next time
/// `flushQueue(using:)` is called (e.g. on app launch or when the scene
/// becomes active).

final class PublicCloudSyncService: @unchecked Sendable {
    static let shared = PublicCloudSyncService()

    private let publicDB = CKContainer.default().publicCloudDatabase
    private let recordType = "PublicShow"

    private init() {}

    // MARK: - Save / Update

    /// Saves or updates a PublicShow record for the given Core Data Show.
    func saveOrUpdate(show: Show, in context: NSManagedObjectContext) async {
        let record: CKRecord

        if let existingID = show.publicRecordID {
            // Update existing record.
            let ckRecordID = CKRecord.ID(recordName: existingID)
            do {
                record = try await publicDB.record(for: ckRecordID)
            } catch {
                // Record may have been deleted server-side; create a new one.
                record = CKRecord(recordType: recordType)
            }
        } else {
            record = CKRecord(recordType: recordType)
        }

        // Populate fields.
        record["title"]      = (show.title ?? "") as CKRecordValue
        record["role"]       = (show.role ?? "") as CKRecordValue
        record["venue"]      = (show.venue ?? "") as CKRecordValue
        record["date"]       = (show.date ?? Date()) as CKRecordValue
        record["price"]      = NSNumber(value: show.price)
        record["ticketLink"] = (show.ticketLink ?? "") as CKRecordValue
        record["notes"]      = (show.notes ?? "") as CKRecordValue
        record["userID"]     = (show.userID ?? "") as CKRecordValue

        // Flyer image → CKAsset (write to temp file).
        if let imageData = show.flyerImageData {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".jpg")
            try? imageData.write(to: tempURL)
            record["flyer"] = CKAsset(fileURL: tempURL)
        } else {
            record["flyer"] = nil
        }

        do {
            let saved = try await publicDB.save(record)
            // Store the public record ID back in Core Data.
            let recordName = saved.recordID.recordName
            nonisolated(unsafe) let showObj = show
            await MainActor.run {
                showObj.publicRecordID = recordName
                showObj.needsPublicSync = false
                showObj.lastPublicSyncError = nil
                PersistenceController.shared.save(context: context)
            }
        } catch {
            let errorDescription = error.localizedDescription
            nonisolated(unsafe) let showObj = show
            await MainActor.run {
                showObj.needsPublicSync = true
                showObj.lastPublicSyncError = errorDescription
                PersistenceController.shared.save(context: context)
            }
            print("⚠️ Public CloudKit save failed: \(error)")
        }
    }

    // MARK: - Delete

    /// Marks a show for public deletion. Call before removing from Core Data.
    func markForDelete(show: Show) {
        guard let recordID = show.publicRecordID else { return }
        // Store in a lightweight queue (UserDefaults) because the CD object
        // is about to be deleted.
        var queue = pendingDeleteIDs
        queue.append(recordID)
        pendingDeleteIDs = queue
    }

    /// Deletes a single public record by ID.
    private func deleteRecord(id: String) async throws {
        let ckID = CKRecord.ID(recordName: id)
        try await publicDB.deleteRecord(withID: ckID)
    }

    // MARK: - Offline Queue

    /// Flushes any pending saves or deletes that failed while offline.
    func flushQueue(using context: NSManagedObjectContext) async {
        // 1. Retry pending saves.
        let fetchRequest: NSFetchRequest<Show> = Show.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "needsPublicSync == YES")
        if let pending = try? context.fetch(fetchRequest) {
            for show in pending {
                await saveOrUpdate(show: show, in: context)
            }
        }

        // 2. Retry pending deletes stored in UserDefaults.
        let ids = pendingDeleteIDs
        var failedIDs: [String] = []
        for id in ids {
            do {
                try await deleteRecord(id: id)
            } catch {
                failedIDs.append(id)
                print("⚠️ Public CloudKit delete retry failed for \(id): \(error)")
            }
        }
        pendingDeleteIDs = failedIDs
    }

    // MARK: - Pending Delete Storage (UserDefaults)

    private let deleteQueueKey = "com.seemelive.pendingPublicDeletes"

    private var pendingDeleteIDs: [String] {
        get { UserDefaults.standard.stringArray(forKey: deleteQueueKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: deleteQueueKey) }
    }
}
