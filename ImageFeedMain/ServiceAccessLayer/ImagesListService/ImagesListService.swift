import Foundation
import CoreGraphics

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

struct PhotoResult: Codable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: Date?
    let description: String?
    let isLikedByUser: Bool
    let urls: UrlsResult

    enum CodingKeys: String, CodingKey {
        case id, width, height
        case createdAt = "created_at"
        case description
        case isLikedByUser = "liked_by_user"
        case urls
    }
}

struct UrlsResult: Codable {
    let thumb: String
    let full: String
}

final class ImagesListService {
    private (set) var photos: [Photo] = []

    private var lastLoadedPage: Int?

    static let shared = ImagesListService()
    private init() {}

    private var task: URLSessionTask?

    private let urlSession = URLSession.shared

    private func makeImageListRequest(page: Int, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/photos?page=\(page)&per_page=10") else {
            print("Ошибка: Неверный URL")
            return nil
        }
        print("Запрос к API: \(url)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    static let didChangeNotification = Notification.Name("ImagesListServiceDidChange")

    func fetchPhotosNextPage(token: String) {
        if task != nil { return }

        let nextPage = (lastLoadedPage ?? 0) + 1
        guard let request = makeImageListRequest(page: nextPage, token: token) else {
            return
        }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let photoResults):
                    print("Получено фото: \(photoResults.count)")

                    let newPhotos = photoResults.map { result in
                        Photo(
                            id: result.id,
                            size: CGSize(width: result.width, height: result.height),
                            createdAt: result.createdAt,
                            welcomeDescription: result.description,
                            thumbImageURL: result.urls.thumb,
                            largeImageURL: result.urls.full,
                            isLiked: result.isLikedByUser
                        )
                    }

                    self.photos.append(contentsOf: newPhotos)
                    self.lastLoadedPage = nextPage
                    NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)

                case .failure(let error):
                    print("Ошибка загрузки фото: \(error.localizedDescription)")
                }

                self.task = nil
            }
        }

        self.task = task
        task.resume()
    }
}
