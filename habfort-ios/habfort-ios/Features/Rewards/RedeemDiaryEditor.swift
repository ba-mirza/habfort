import PhotosUI
import SwiftUI

/// Photo + note for a redeem in the reward diary. The photo goes straight to
/// private storage through a one-time signed URL from the backend; the backend
/// then records the path, so the client never writes to Supabase on its own.
struct RedeemDiaryEditor: View {
    let redeem: Redeem
    let onSaved: () async -> Void

    @Environment(APIClient.self) private var apiClient
    @Environment(\.dismiss) private var dismiss

    @State private var note: String
    @State private var pickerItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(redeem: Redeem, onSaved: @escaping () async -> Void) {
        self.redeem = redeem
        self.onSaved = onSaved
        _note = State(initialValue: redeem.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        photoPreview
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                }

                Section("Заметка") {
                    TextField("Как прошло?", text: $note, axis: .vertical)
                        .lineLimit(3...8)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(redeem.rewardName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Сохранить") { Task { await save() } }
                    }
                }
            }
            .onChange(of: pickerItem) { _, item in
                Task { await loadPicked(item) }
            }
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        ZStack {
            Color(.secondarySystemBackground)
            if let pickedImage {
                Image(uiImage: pickedImage).resizable().scaledToFill()
            } else if let url = redeem.photoUrl.flatMap(URL.init(string:)) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Label("Выбрать фото", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func loadPicked(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else { return }
        pickedImage = image
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            var photoPath: String?
            if let pickedImage {
                guard let jpeg = pickedImage.resizedForUpload().jpegData(compressionQuality: 0.8) else {
                    throw APIError(status: 0, message: "Не удалось подготовить фото")
                }
                let upload: PhotoUpload = try await apiClient.post("/redeems/\(redeem.id)/photo-upload")
                try await Self.put(jpeg, to: upload.uploadUrl)
                photoPath = upload.path
            }
            let _: Redeem = try await apiClient.patch(
                "/redeems/\(redeem.id)",
                body: UpdateRedeemRequest(note: note, photoPath: photoPath)
            )
            if photoPath != nil || redeem.photoUrl != nil {
                NotificationScheduler.cancelPhotoReminder()
            }
            await onSaved()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func put(_ data: Data, to urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw APIError(status: 0, message: "Некорректная ссылка для загрузки")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError(status: (response as? HTTPURLResponse)?.statusCode ?? 0, message: "Не удалось загрузить фото")
        }
    }
}

private struct PhotoUpload: Decodable {
    let path: String
    let uploadUrl: String
}

private struct UpdateRedeemRequest: Encodable {
    let note: String
    let photoPath: String?
}

private extension UIImage {
    /// Longest side capped at 1600 px — plenty for a phone screen, and keeps
    /// uploads well under the bucket's 5 MB limit.
    func resizedForUpload(maxSide: CGFloat = 1600) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        let scale = maxSide / longest
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
