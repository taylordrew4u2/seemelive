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

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // --- Flyer Image ---
                    flyerImageSection
                        .padding(.top, 8)

                    // --- Form Fields ---
                    VStack(spacing: 16) {
                        editorField(
                            icon: "text.quote",
                            placeholder: "Show title (e.g., Comedy Night)",
                            text: $title,
                            field: .title,
                            capitalization: .words
                        )

                        editorField(
                            icon: "person.fill",
                            placeholder: "Your role (e.g., Headliner)",
                            text: $role,
                            field: .role,
                            capitalization: .words
                        )

                        editorField(
                            icon: "mappin.and.ellipse",
                            placeholder: "Venue name",
                            text: $venue,
                            field: .venue,
                            capitalization: .words
                        )

                        // Date & Time
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.body)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            DatePicker("Date & Time",
                                       selection: $date,
                                       in: Date()...,
                                       displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardBackground"))
                        )

                        editorField(
                            icon: "dollarsign.circle",
                            placeholder: "Price (optional)",
                            text: $priceString,
                            field: .price,
                            keyboardType: .decimalPad
                        )

                        editorField(
                            icon: "link",
                            placeholder: "Ticket URL (optional)",
                            text: $ticketLink,
                            field: .ticketLink,
                            keyboardType: .URL,
                            autocapitalization: false
                        )

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "note.text")
                                    .font(.body)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                Text("Notes")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            TextEditor(text: $notes)
                                .focused($focusedField, equals: .notes)
                                .frame(minHeight: 80)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.secondary.opacity(0.06))
                                )
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardBackground"))
                        )
                    }

                    // --- Toggles ---
                    VStack(spacing: 0) {
                        Toggle(isOn: $addToCalendar) {
                            Label("Add to Calendar", systemImage: "calendar.badge.plus")
                        }
                        .padding(14)

                        if addToCalendar {
                            Divider()
                                .padding(.leading, 52)
                            Toggle(isOn: $setReminder) {
                                Label("Reminder (1 hr before)", systemImage: "bell.fill")
                            }
                            .padding(14)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("CardBackground"))
                    )
                    .animation(.easeInOut(duration: 0.2), value: addToCalendar)

                    // --- Save Button ---
                    Button {
                        let impact = UINotificationFeedbackGenerator()
                        impact.notificationOccurred(.success)
                        Task { await saveShow() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(showToEdit == nil ? "Save Gig" : "Update Gig")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(title.trimmingCharacters(in: .whitespaces).isEmpty
                                      ? Color.gray.opacity(0.4)
                                      : Color.accentColor)
                        )
                        .foregroundStyle(.white)
                        .font(.body)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 16)
            }
            .background(Color("AppBackground"))
            .navigationTitle(showToEdit == nil ? "Add New Gig" : "Edit Gig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear(perform: populateFromExisting)
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
                    flyerData = image?.jpegData(compressionQuality: 0.8)
                }
            }
            .photosPicker(isPresented: $showPhotoPicker,
                          selection: $selectedPhotoItem,
                          matching: .images)
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isSaving)
    }

    // MARK: - Flyer Section

    private var flyerImageSection: some View {
        Button {
            showImageSourcePicker = true
        } label: {
            if let data = flyerData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, Color.accentColor)
                        .padding(12)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor.opacity(0.6))
                    Text("Tap to add flyer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentColor.opacity(0.3),
                                      style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor.opacity(0.04))
                        )
                )
            }
        }
        .buttonStyle(.plain)
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
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
            TextField(placeholder, text: text)
                .focused($focusedField, equals: field)
                .textInputAutocapitalization(autocapitalization ? capitalization : .never)
                .keyboardType(keyboardType)
                .autocorrectionDisabled(keyboardType == .URL)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("CardBackground"))
        )
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
            flyerData = UIImage(data: data)?
                .jpegData(compressionQuality: 0.8)
        }
    }

    // MARK: - Save

    private func saveShow() async {
        isSaving = true
        defer { isSaving = false }

        let show = showToEdit ?? Show(context: viewContext)
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
        if showToEdit == nil {
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
        PersistenceController.shared.save(context: viewContext)

        await PublicCloudSyncService.shared.saveOrUpdate(show: show, in: viewContext)

        dismiss()
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
