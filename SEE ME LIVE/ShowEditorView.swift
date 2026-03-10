//
//  ShowEditorView.swift
//  SEE ME LIVE
//
//  Created by Taylor Drew on 3/3/26.
//

import SwiftUI
import PhotosUI
import CoreData

// MARK: - Show Editor View
/// A beautifully styled modal form for adding or editing a show.
/// Includes image picking, calendar event creation, and CloudKit sync.

struct ShowEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let showToEdit: Show?

    // MARK: Form State
    @State private var title = ""
    @State private var role = ""
    @State private var venue = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7,
        to: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!)!
    @State private var priceString = ""
    @State private var ticketLink = ""
    @State private var notes = ""
    @State private var addToCalendar = true
    @State private var setReminder = false
    @State private var flyerData: Data?

    // Image picking
    @State private var showImageSourcePicker = false
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // Alerts
    @State private var showCalendarDeniedAlert = false
    @State private var isSaving = false

    @FocusState private var focusedField: EditorField?

    private let userID = UserIdentityService.shared.userID

    private enum EditorField {
        case title, role, venue, price, ticketLink, notes
    }

    // Downscale helper to keep flyer images lightweight
    private func downscaleJPEGData(_ data: Data, maxDimension: CGFloat = 1600, quality: CGFloat = 0.75) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let maxSide = max(size.width, size.height)
        let scale = max(1, maxSide / maxDimension)
        let targetSize = CGSize(width: size.width / scale, height: size.height / scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                content
            }
            .background(Color("AppBackground"))
            .navigationTitle(showToEdit == nil ? "Add New Gig" : "Edit Gig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                populateFromExisting()
                // Auto-focus the title field for new shows
                if showToEdit == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        focusedField = .title
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task { await loadPhoto(from: newItem) }
            }
            .alert("Calendar Access Denied",
                   isPresented: $showCalendarDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("SEE ME LIVE needs calendar access to add your gigs. Please enable it in Settings.")
            }
            .confirmationDialog("Add Flyer Image",
                                isPresented: $showImageSourcePicker,
                                titleVisibility: .visible) {
                Button("Take Photo") { showCamera = true }
                Button("Choose from Library") { showPhotoPicker = true }
                if flyerData != nil {
                    Button("Remove Image", role: .destructive) { flyerData = nil }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView { image in
                    if let img = image, let data = img.jpegData(compressionQuality: 0.9) {
                        // Downscale off-main if needed, then assign on main
                        DispatchQueue.global(qos: .userInitiated).async {
                            let downsized = downscaleJPEGData(data) ?? data
                            DispatchQueue.main.async { flyerData = downsized }
                        }
                    } else {
                        flyerData = nil
                    }
                }
            }
            .photosPicker(isPresented: $showPhotoPicker,
                          selection: $selectedPhotoItem,
                          matching: .images)
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isSaving)
    }

    // Extracted main content to help the type-checker
    private var content: some View {
        VStack(spacing: 24) {
            flyerImageSection
                .padding(.top, 8)

            formFields
            
            notesField

            calendarToggles

            saveButton
                .padding(.top, 4)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 16)
    }

    // Extracted form fields
    private var formFields: some View {
        VStack(spacing: 0) {
            editorField(
                icon: "text.quote",
                placeholder: "Show title (e.g., Comedy Night)",
                text: $title,
                field: .title,
                capitalization: .words
            )
            .submitLabel(.next)
            .onSubmit { focusedField = .role }
            
            Divider().padding(.leading, 52)

            editorField(
                icon: "person.fill",
                placeholder: "Your role (e.g., Headliner)",
                text: $role,
                field: .role,
                capitalization: .words
            )
            .submitLabel(.next)
            .onSubmit { focusedField = .venue }
            
            Divider().padding(.leading, 52)

            editorField(
                icon: "mappin.and.ellipse",
                placeholder: "Venue name",
                text: $venue,
                field: .venue,
                capitalization: .words
            )
            .submitLabel(.next)
            .onSubmit { focusedField = .price }
            
            Divider().padding(.leading, 52)

            dateTimePicker
            
            Divider().padding(.leading, 52)

            editorField(
                icon: "dollarsign.circle",
                placeholder: "Price (optional)",
                text: $priceString,
                field: .price,
                keyboardType: .decimalPad
            )
            
            Divider().padding(.leading, 52)

            editorField(
                icon: "link",
                placeholder: "Ticket URL (optional)",
                text: $ticketLink,
                field: .ticketLink,
                keyboardType: .URL,
                autocapitalization: false
            )
            .submitLabel(.done)
            .onSubmit { focusedField = nil }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // Extracted date/time picker
    private var dateTimePicker: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 17))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            DatePicker("Date & Time",
                       selection: $date,
                       displayedComponents: [.date, .hourAndMinute])
            .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // Extracted notes field
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 17))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                Text("Notes")
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            TextEditor(text: $notes)
                .focused($focusedField, equals: .notes)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .frame(minHeight: 100)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .scrollContentBackground(.hidden)
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // Extracted toggles
    private var calendarToggles: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $addToCalendar) {
                Label("Add to Calendar", systemImage: "calendar.badge.plus")
                    .font(.system(size: 17))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if addToCalendar {
                Divider()
                    .padding(.leading, 52)
                Toggle(isOn: $setReminder) {
                    Label("Reminder (1 hr before)", systemImage: "bell.fill")
                        .font(.system(size: 17))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.15), value: addToCalendar)
    }

    // Extracted save button
    private var saveButton: some View {
        let isDisabled = title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving
        return Button {
            let impact = UINotificationFeedbackGenerator()
            impact.notificationOccurred(.success)
            Task { await saveShow() }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }
                Text(showToEdit == nil ? "Save Show" : "Update Show")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDisabled ? Color(.systemGray4) : Color.accentColor)
                    .shadow(color: isDisabled ? .clear : Color.accentColor.opacity(0.35),
                            radius: 12, y: 5)
            )
            .foregroundStyle(.white)
        }
        .disabled(isDisabled)
    }

    // MARK: - Flyer Section

    private var flyerImageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section label
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("SHOW FLYER")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                Spacer()
                if flyerData != nil {
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.3)) { flyerData = nil }
                    } label: {
                        Label("Remove", systemImage: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Flyer picker / preview
            Button {
                showImageSourcePicker = true
            } label: {
                if let data = flyerData, let uiImage = UIImage(data: data) {
                    // Flyer preview
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 5)

                        // Edit badge
                        HStack(spacing: 5) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11, weight: .bold))
                            Text("Change")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(12)
                    }
                } else {
                    // Empty state — looks like a poster slot
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color("CardBackground"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        Color.accentColor.opacity(0.35),
                                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                                    )
                            )

                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 26, weight: .light))
                                    .foregroundStyle(Color.accentColor)
                            }
                            VStack(spacing: 4) {
                                Text("Add Show Flyer")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("Upload from your library or take a photo")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            HStack(spacing: 18) {
                                Label("Camera", systemImage: "camera")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.accentColor)
                                Label("Library", systemImage: "photo")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.vertical, 32)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 200)
                }
            }
            .buttonStyle(HeroPress())
        }
    }

    // MARK: - Editor Field

    @ViewBuilder
    private func editorField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: EditorField,
        capitalization: TextInputAutocapitalization = .never,
        keyboardType: UIKeyboardType = .default,
        autocapitalization: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            TextField(placeholder, text: text)
                .focused($focusedField, equals: field)
                .textInputAutocapitalization(autocapitalization ? capitalization : .never)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(keyboardType == .URL)
                .font(.system(size: 17))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Populate (Edit Mode)

    private func populateFromExisting() {
        guard let show = showToEdit else { return }
        title = show.titleOrEmpty
        role = show.roleOrEmpty
        venue = show.venueOrEmpty
        date = show.dateOrNow
        priceString = show.price > 0 ? String(format: "%.2f", show.price) : ""
        ticketLink = show.ticketLinkOrEmpty
        notes = show.notesOrEmpty
        addToCalendar = show.addToCalendar
        setReminder = show.setReminder
        flyerData = show.flyerImageData
    }

    // MARK: - Photo Loading

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            // Downscale off main thread, then assign on main
            let downsized: Data? = await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let result = downscaleJPEGData(data) ?? data
                    continuation.resume(returning: result)
                }
            }
            await MainActor.run {
                flyerData = downsized
            }
        }
    }

    // MARK: - Save

    @MainActor
    private func saveShow() async {
        isSaving = true
        defer { isSaving = false }

        let isNew = (showToEdit == nil)
        let show: Show
        if let existing = showToEdit {
            show = existing
        } else {
            show = Show(context: viewContext)
        }
        let now = Date()

        show.title = title.trimmingCharacters(in: .whitespaces)
        show.role = role.trimmingCharacters(in: .whitespaces)
        show.venue = venue.trimmingCharacters(in: .whitespaces)
        show.date = date
        show.price = Double(priceString) ?? 0
        show.ticketLink = ticketLink.trimmingCharacters(in: .whitespaces)
        show.notes = notes.trimmingCharacters(in: .whitespaces)
        show.flyerImageData = flyerData
        show.addToCalendar = addToCalendar
        show.setReminder = setReminder
        show.userID = userID
        show.updatedAt = now
        if isNew {
            show.createdAt = now
        }

        // Calendar integration.
        if addToCalendar {
            if CalendarService.shared.isAuthorized {
                let eventID = CalendarService.shared.createOrUpdateEvent(for: show)
                show.calendarEventID = eventID
            } else {
                let granted = await CalendarService.shared.requestAccess()
                if granted {
                    let eventID = CalendarService.shared.createOrUpdateEvent(for: show)
                    show.calendarEventID = eventID
                } else {
                    showCalendarDeniedAlert = true
                }
            }
        } else {
            if show.calendarEventID != nil {
                CalendarService.shared.deleteEvent(for: show)
                show.calendarEventID = nil
            }
        }

        show.needsPublicSync = true

        // Save Core Data synchronously to ensure persistence before dismissing.
        do {
            if viewContext.hasChanges {
                try viewContext.save()
            }
        } catch {
            print("⚠️ Core Data save error: \(error)")
        }

        // Dismiss immediately after local save so the UI updates.
        dismiss()

        // Sync to CloudKit in the background (non-blocking).
        let objectID = show.objectID
        Task.detached {
            let bgContext = PersistenceController.shared.container.newBackgroundContext()
            bgContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            if let bgShow = try? bgContext.existingObject(with: objectID) as? Show {
                await PublicCloudSyncService.shared.saveOrUpdate(show: bgShow, in: bgContext)
            }
        }
    }
}

// MARK: - Hero Press Button Style

private struct HeroPress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Camera Picker (UIImagePickerController wrapper)

private struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage?) -> Void
        init(onCapture: @escaping (UIImage?) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            onCapture(image)
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCapture(nil)
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    ShowEditorView(showToEdit: nil)
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

