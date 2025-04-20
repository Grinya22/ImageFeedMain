import Foundation
import CoreGraphics
import Kingfisher

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: String?
    let welcomeDescription: String?
    let thumbImageURL: String
    let smallImageURL: String
    let regularImageURL: String
    let fullImageURL: String
    let isLiked: Bool
}

struct PhotoResult: Codable {
    let id: String
    let width: Int
    let height: Int
    let createdAt: String?
    let description: String?
    let isLikedByUser: Bool
    let urls: UrlsResult
    var createdAtDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, width, height
        case createdAt = "created_at"
        case description
        case isLikedByUser = "liked_by_user"
        case urls
    }
    
    mutating func convertCreatedAtToDate() {
        guard let createdAtString = createdAt else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        self.createdAtDate = dateFormatter.date(from: createdAtString)
    }
}

struct UrlsResult: Codable {
    let thumb: String
    let small: String
    let regular: String
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
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Ошибка: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Нет данных")
                return
            }
            
            // Выводим полученные данные для отладки
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Полученные данные: \(jsonString)")
            }
            
            // Попытка декодировать данные в нужный формат
            do {
                var photoResults = try JSONDecoder().decode([PhotoResult].self, from: data)
                print("Декодированные данные: \(photoResults)")
                
                // Преобразуем строку даты в Date для каждого фото
                for index in photoResults.indices {
                    photoResults[index].convertCreatedAtToDate()
                }
                
                // Создаем массив Photo
                let newPhotos = photoResults.map { result in
                    // Если нам нужно хранить строку в `createdAt`, передаем строку с датой
                    Photo(
                        id: result.id,
                        size: CGSize(width: result.width, height: result.height),
                        createdAt: result.createdAt, // Строка с датой
                        welcomeDescription: result.description,
                        thumbImageURL: result.urls.thumb,
                        smallImageURL: result.urls.small,
                        regularImageURL: result.urls.regular,
                        fullImageURL: result.urls.full,
                        isLiked: result.isLikedByUser
                    )
                }
                
                // Добавляем фото в массив
                //self.photos.append(contentsOf: newPhotos)
                let existingIds = Set(self.photos.map { $0.id })
                let filteredNewPhotos = newPhotos.filter { !existingIds.contains($0.id) }

                self.photos.append(contentsOf: filteredNewPhotos)

                self.lastLoadedPage = nextPage
                NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
                
            } catch {
                print("Ошибка декодирования: \(error)")
            }
            
            self.task = nil
        }
        
        self.task = task
        task.resume()
    }
}

extension ImagesListService {
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "NoToken", code: 401)))
            return
        }

        guard let url = URL(string: "https://api.unsplash.com/photos/\(photoId)/like") else {
            completion(.failure(NSError(domain: "BadURL", code: 400)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = isLike ? "POST" : "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        print("Запрос к API: \(request.httpMethod ?? "") \(url)")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "No response", code: 0)))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "HTTP error", code: httpResponse.statusCode)))
                return
            }

            if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                let photo = self.photos[index]
                let newPhoto = Photo(
                    id: photo.id,
                    size: photo.size,
                    createdAt: photo.createdAt,
                    welcomeDescription: photo.welcomeDescription,
                    thumbImageURL: photo.thumbImageURL,
                    smallImageURL: photo.smallImageURL,
                    regularImageURL: photo.regularImageURL,
                    fullImageURL: photo.fullImageURL,
                    isLiked: !photo.isLiked
                )

                DispatchQueue.main.async {
                    self.photos[index] = newPhoto
                    completion(.success(()))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "PhotoNotFound", code: 404)))
                }
            }
        }

        task.resume()
    }
}

extension ImagesListService {
    func clearData() {
        photos = []
        lastLoadedPage = nil
        task?.cancel()
        task = nil
        NotificationCenter.default.post(name: ImagesListService.didChangeNotification, object: self)
    }
}
