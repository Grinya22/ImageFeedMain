import Foundation

final class ProfileImageService {
    // Синглтон
    static let shared = ProfileImageService()
    private init() {}
    
    // Приватное свойство для хранения URL аватарки
    private(set) var avatarURL: String?
    
    private var task: URLSessionTask?
    
    private let urlSession = URLSession.shared
    
    let token = OAuth2TokenStorage.shared.token
    
    static let didChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")

    struct ProfileImage: Codable {
        let small: String
        let medium: String
        let large: String

        private enum CodingKeys: String, CodingKey {
            case small
            case medium
            case large
        }
    }

    struct UserResult: Codable {
        let profileImage: ProfileImage

        private enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
    }
    
    private func makeProfileImageRequest(username: String, token: String) -> URLRequest? {
        guard let url = URL(string: "https://api.unsplash.com/users/\(username)") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    // Метод для получения аватарки по имени пользователя
    func fetchProfileImageURL(username: String, completion: @escaping (Result<String, Error>) -> Void) {
        task?.cancel()

        guard let token = OAuth2TokenStorage.shared.token else {
            completion(.failure(NSError(domain: "ProfileImageService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authorization token missing"])))
            return
        }

        guard let request = makeProfileImageRequest(username: username, token: token) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        //let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        let task = URLSession.shared.objectTask(for: request) { [weak self] (result: Result<UserResult, Error>) in
            switch result {
            case .success(let result):
                guard let self = self else { return }
                self.avatarURL = result.profileImage.large // Используем large вместо small
                completion(.success(result.profileImage.small))
                
                NotificationCenter.default
                    .post(
                        name: ProfileImageService.didChangeNotification,
                        object: self,
                        userInfo: ["URL": self.avatarURL ?? ""]
                    )
                
            case .failure(let error):
                print("[fetchProfileImageURL]: Ошибка запроса: \(error.localizedDescription)")
                completion(.failure(error)) // Прокидываем ошибку
            }
        }

        self.task = task
        task.resume()
    }
}
