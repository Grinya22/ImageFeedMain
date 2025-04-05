import Foundation

// MARK: - Основной класс авторизации
final class OAuth2Service {
    // Singleton — создаём один общий экземпляр класса
    static let shared = OAuth2Service()

    // Хранилище токена
    private let dataStorage = OAuth2TokenStorage()
    // Сессия для сетевых запросов
    private let urlSession = URLSession.shared

    // Доступ к токену извне только для чтения
    private(set) var authToken: String? {
        get {
            return dataStorage.token // читаем из хранилища
        }
        set {
            dataStorage.token = newValue // сохраняем в хранилище
        }
    }

    // Приватный инициализатор, чтобы никто не создавал новый экземпляр
    private init() { }

    // MARK: - Основной метод получения токена по коду
    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Собираем запрос
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        // Отправляем запрос
        let task = object(for: request) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let body):
                let authToken = body.accessToken
                self.authToken = authToken // сохраняем в свойство
                completion(.success(authToken)) // возвращаем наружу
            case .failure(let error):
                completion(.failure(error)) // ошибка
            }
        }
        task.resume()
    }

    // MARK: - Собираем URLRequest для запроса токена
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard var urlComponents = URLComponents(string: "https://unsplash.com/oauth/token") else {
            return nil
        }

        // Параметры запроса
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]

        // Собираем URL
        guard let authTokenUrl = urlComponents.url else {
            return nil
        }

        var request = URLRequest(url: authTokenUrl)
        request.httpMethod = "POST" // метод POST — отправляем данные
        return request
    }

    // MARK: - Модель тела ответа
    private struct OAuthTokenResponseBody: Codable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }
}

// MARK: - Расширение для выполнения сетевого запроса
extension OAuth2Service {
    // Метод, который отправляет запрос и возвращает модель (или ошибку)
    private func object(for request: URLRequest, completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void) -> URLSessionTask {
        // Декодер для JSON
        let decoder = JSONDecoder()

        // Создаём задачу
        return urlSession.data(for: request) { (result: Result<Data, Error>) in
            switch result {
            case .success(let data):
                do {
                    let body = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                    completion(.success(body))
                } catch {
                    completion(.failure(NetworkError.decodingError(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
