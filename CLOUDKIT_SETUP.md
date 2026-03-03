# CloudKit Dashboard Setup Guide — SEE ME LIVE

> Follow every step below **exactly**. This sets up the public database
> schema that your app and web page depend on.

---

## Step 1 — Open CloudKit Dashboard

1. Go to **https://icloud.developer.apple.com/dashboard/**
2. Sign in with your Apple Developer account
3. In the top-left dropdown, select container: **`iCloud.comedy.SEE-ME-LIVE`**
   - If the container doesn't exist yet, go to
     **Xcode → Signing & Capabilities → iCloud → Containers → "+"**
     and add `iCloud.comedy.SEE-ME-LIVE` first, then come back here.

---

## Step 2 — Select the Correct Database

At the top of the CloudKit Dashboard you'll see a toggle:

> **Private Database** | **Public Database**

**Click "Public Database".**

Your app's `PublicCloudSyncService.swift` writes to the **public** database.
(The private database is handled automatically by `NSPersistentCloudKitContainer`
— you do NOT need to create anything there manually.)

---

## Step 3 — Create the `PublicShow` Record Type

1. In the left sidebar, click **"Record Types"**
2. Click the **"+"** button to create a new record type
3. Name it exactly: **`PublicShow`**
4. Add the following fields one by one (click "Add Field" for each):

| Field Name     | Field Type          | Notes                                |
|----------------|---------------------|--------------------------------------|
| `title`        | **String**          | Show title                           |
| `role`         | **String**          | e.g. "Headliner", "Feature"         |
| `venue`        | **String**          | Venue name                           |
| `date`         | **Date/Time**       | Show date & time                     |
| `price`        | **Double**          | Ticket price (number)                |
| `ticketLink`   | **String**          | URL to buy tickets                   |
| `notes`        | **String**          | Extra notes                          |
| `userID`       | **String**          | The user's unique install ID         |
| `flyer`        | **Asset**           | Flyer image                          |

5. Click **"Save Record Type"**

### ⚠️ Important Notes
- Field names are **case-sensitive** — type them exactly as shown above
- Do NOT add fields like `needsPublicSync`, `publicRecordID`, etc.
  — those are local Core Data fields only, not CloudKit fields
- The `flyer` field must be **Asset** type, not Binary/Bytes

---

## Step 4 — Add Indexes (Required for Queries)

Your web page queries by `userID` and sorts by `date`, so you need indexes.

1. In the left sidebar, click **"Indexes"** (under the `PublicShow` record type)
2. Add the following indexes:

| Field Name   | Index Type     | Why                                    |
|--------------|----------------|----------------------------------------|
| `userID`     | **Queryable**  | Web page filters shows by user         |
| `date`       | **Queryable**  | Web page sorts shows by date           |
| `date`       | **Sortable**   | Enables sort-by-date in queries        |
| `recordName` | **Queryable**  | Required — CloudKit needs this default |

### How to add each index:
1. Click **"Add Index"**
2. Select the **Field** from the dropdown (e.g. `userID`)
3. Select the **Index Type** (e.g. `Queryable`)
4. Click **"Save"**
5. Repeat for each row in the table above

---

## Step 5 — Create a Web API Token (for the public web page)

Your `docs/index.html` web page uses CloudKit JS to read shows. It needs an API token.

1. In the left sidebar, click **"API Access"** (or "Tokens")
2. Click **"+"** to create a new token
3. Fill in:
   - **Token Name**: `SEE ME LIVE Web`
   - **Sign In**: leave unchecked (this is a server/web token, not user sign-in)
4. Click **"Save"**
5. **Copy the API token string** that appears

Then open `docs/index.html` in your project and replace:
```
const API_TOKEN = 'YOUR_CLOUDKIT_API_TOKEN';
```
with your actual token:
```
const API_TOKEN = 'paste-your-token-here';
```

---

## Step 6 — Deploy Schema to Production

**This is critical.** Everything you just created is in the **Development**
environment. Your app won't work in production (TestFlight / App Store)
until you deploy.

1. In the CloudKit Dashboard, click **"Deploy Schema to Production…"**
   (button is usually at the top or under a menu)
2. Review the changes — you should see `PublicShow` record type and its indexes
3. Click **"Deploy"**

> ⚠️ Once deployed to production, you **cannot delete** fields or record types.
> You can only add new ones. So make sure everything looks correct before deploying.

---

## Step 7 — Verify in Xcode

Back in Xcode, make sure:

1. **Signing & Capabilities → iCloud**:
   - ✅ "CloudKit" is selected (not "Compatible with Xcode 5")
   - ✅ Container `iCloud.comedy.SEE-ME-LIVE` is checked

2. **Signing & Capabilities → Background Modes**:
   - ✅ "Remote notifications" is checked
   (Your `Info.plist` already has `remote-notification` — this should match)

3. **Your entitlements file** should contain (already does ✅):
   - `com.apple.developer.icloud-services` → `CloudKit`
   - `com.apple.developer.icloud-container-identifiers` → `iCloud.comedy.SEE-ME-LIVE`
   - `aps-environment` → `development`

---

## Quick Reference — What Goes Where

| Component                           | Database    | Setup Method              |
|-------------------------------------|-------------|---------------------------|
| Core Data `Show` entity (private)   | **Private** | Automatic (NSPersistentCloudKitContainer) |
| `PublicShow` record (shared/public) | **Public**  | Manual (this guide) + `PublicCloudSyncService.swift` |
| Web page reads                      | **Public**  | CloudKit JS + API Token   |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "Container not found" | Make sure container `iCloud.comedy.SEE-ME-LIVE` exists in your Apple Developer account and is checked in Xcode |
| Web page shows "Failed to load" | Check that the API token is correct and `ENVIRONMENT` matches (`development` for testing, `production` for release) |
| Shows save in app but don't appear on web | Make sure you deployed schema to production, and `userID` field + Queryable index exist |
| "Permission failure" errors | Make sure the `PublicShow` record type has the `_world` read permission (default for public DB) |
