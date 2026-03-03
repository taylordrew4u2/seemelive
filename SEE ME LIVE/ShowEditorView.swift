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
/// Super simple form for adding shows. Only the essentials are visible by default.

struct ShowEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let showToEdit: Show?

    // MARK: Form State - Essential Fields
    @State private var title = ""
    @State private var venue = ""
    @State private var date = Calendar.current.date(byAdding: .day, value: 7,
        to: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!)!
    @State private var flyerData: Data?

    // MARK: Optional Fields (hidden by default)
    @State private var showMoreOptions = false
    @State private var priceString = ""
    @State private var ticketLink = ""
    @State private var notes = ""

    // Image picking
    @State private var showImagePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    // State
    @State private var isSaving = false
    @State private var showCalendarDeniedAlert = false

    @FocusState private var focusedField: Field?
    private enum Field { case title, venue, price, ticketLink, notes }

    private let userID = UserIdentityService.shared.userID

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // --- Flyer Image (Optional but prominent) ---
                    flyerSection
                        .padding(.top, 8)

                    // --- Essential Fields ---
                    VStack(spacing: 14) {
                        // Title
                        HStack(spacing: 12) {
                            Image(systemName: "text.quote")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            TextField("Show title", text: $title)
                                .focused($focusedField, equals: .title)
                                .textInputAutocapitalization(.words)
                                .font(.body)
                        }
                        .padding(16)
                        .background(fieldBackground)

                        // Venue
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            TextField("Venue", text: $venue)
                                .focused($focusedField, equals: .venue)
                                .textInputAutocapitalization(.words)
                                .font(.body)
                        }
                        .padding(16)
                        .background(fieldBackground)

                        // Date & Time
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 24)
                            DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                            Spacer()
                        }
                        .padding(16)
                        .background(fieldBackground)
                    }

                    // --- Add More Details (Expandable) ---
                    VStack(spacing: 14) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showMoreOptions.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: showMoreOptions ? "minus.circle.fill" : "plus.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                Text(showMoreOptions ? "Hide extra details" : "Add more details")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.accentColor)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }

                        if showMoreOptions {
                            VStack(spacing: 14) {
                                // Price
                                HStack(spacing: 12) {
                                    Image(systemName: "dollarsign.circle")
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 24)
                                    TextField("Price (optional)", text: $priceString)
                                        .focused($focusedField, equals: .price)
                                        .keyboardType(.decimalPad)
                                        .font(.body)
                                }
                                .padding(16)
                                .background(fieldBackground)

                                // Ticket Link
                                HStack(spacing: 12) {
                                    Image(systemName: "ticket")
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 24)
                                    TextField("Ticket URL (optional)", text: $ticketLink)
                                        .focused($focusedField, equals: .ticketLink)
                                        .keyboardType(.URL)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled()
                                        .font(.body)
                                }
                                .padding(16)
                                .background(fieldBackground)

                                // Notes
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "note.text")
                                            .foregroundStyle(Color.accentColor)
                                            .frame(width: 24)
                                        Text("Notes")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    TextEditor(text: $notes)
                                        .focused($focusedField, equals: .notes)
                                        .frame(minHeight: 60)
                                        .scrollContentBackground(.hidden)
                                        .padding(8)
                                        .background(Color.secondary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .padding(16)
                                .background(fieldBackground)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    Spacer(minLength: 20)

                    // --- Save Button ---
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { await saveShow() }
                    } label: {
                        HStack(spacing: 10) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(showToEdit == nil ? "Save Gig" : "Update Gig")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(canSave ? Color.accentColor : Color.gray.opacity(0.3))
                        )
                        .foregroundStyle(.white)
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
            .background(Color("AppBackground"))
            .navigationTitle(showToEdit == nil ? "Add Gig" : "Edit Gig")
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
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItem, matching: .images)
            .alert("Calendar Access", isPresented: $showCalendarDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Skip", role: .cancel) {}
            } message: {
                Text("Allow calendar access to automatically add shows to your iPhone calendar.")
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isSaving)
    }

    // MARK: - Helpers

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("CardBackground"))
    }

    // MARK: - Flyer Section

    private var flyerSection: some View {
        Button {
            showImagePicker = true
        } label: {
            if let data = flyerData, let uiImage = UIImage(data: data) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        flyerData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(8)
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor.opacity(0.6))
                    Text("Add flyer (optional)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor.opacity(0.04)))
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func populateFromExisting() {
        guard let show = showToEdit else { return }
        title = show.titleOrEmpty
        venue = show.venueOrEmpty
        date = show.dateOrNow
        flyerData = show.flyerImageData
        priceString = show.price > 0 ? String(format: "%.2f", show.price) : ""
        ticketLink = show.ticketLinkOrEmpty
        notes = show.notesOrEmpty
        // Show extra options if any optional fields have data
        if !priceString.isEmpty || !ticketLink.isEmpty || !notes.isEmpty {
            showMoreOptions = true
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self) {
            flyerData = UIImage(data: data)?.jpegData(compressionQuality: 0.8)
        }
    }

    // MARK: - Save

    private func saveShow() async {
        isSaving = true
        defer { isSaving = false }

        let show = showToEdit ?? Show(context: viewContext)
        let now = Date()

        show.title = title.trimmingCharacters(in: .whitespaces)
        show.venue = venue.trimmingCharacters(in: .whitespaces)
        show.date = date
        show.flyerImageData = flyerData
        show.price = Double(priceString) ?? 0
        show.ticketLink = ticketLink.trimmingCharacters(in: .whitespaces)
        show.notes = notes.trimmingCharacters(in: .whitespaces)
        show.userID = userID
        show.updatedAt = now
        show.addToCalendar = true  // Always add to calendar
        show.setReminder = false
        show.role = ""

        if showToEdit == nil {
            show.createdAt = now
        }

        // Auto-add to calendar (no toggle needed)
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

        show.needsPublicSync = true
        PersistenceController.shared.save(context: viewContext)
        await PublicCloudSyncService.shared.saveOrUpdate(show: show, in: viewContext)

        dismiss()
    }
}

#Preview {
    ShowEditorView(showToEdit: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
