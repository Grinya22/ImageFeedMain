import Foundation

enum AuthServiceError: Error {
    case invalidRequest
}

// MARK: - Основной класс авторизации
final class OAuth2Service {
    // Singleton — создаём один общий экземпляр класса
    static let shared = OAuth2Service()

    // Хранилище токена
    private let dataStorage = OAuth2TokenStorage.shared
    // Сессия для сетевых запросов
    private let urlSession = URLSession.shared

    //Переменная для хранения указателя на последнюю созданную задачу. Если активных задач нет, то значение будет nil.
    private var task: URLSessionTask?
    
    //Переменная для хранения значения code, которое было передано в последнем созданном запросе.
    private var lastCode: String?
    
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
        assert(Thread.isMainThread)
        UIBlockingProgressHUD.show()

        
        guard lastCode != code else {
            UIBlockingProgressHUD.dismiss()
            return completion(.failure(AuthServiceError.invalidRequest))
        }
        
        task?.cancel()
        lastCode = code
        
        // Собираем запрос
        guard let request = makeOAuthTokenRequest(code: code) else {
            completion(.failure(NetworkError.invalidRequest))
            return
        }

        // Отправляем запрос
        //let task = object(for: request) { [weak self] result in
        // Заменяем data(for:) на objectTask(for:)
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in

        //let task = urlSession.dataTask(with: request) { [weak self] data, respones, error in
            DispatchQueue.main.async {
                UIBlockingProgressHUD.dismiss()
                guard let self = self else { return }
                
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken // сохраняем в свойство
                    completion(.success(authToken)) // возвращаем наружу
                    
                    self.task = nil
                    self.lastCode = nil
                    
                case .failure(let error):
                    print("[fetchOAuthToken]: Ошибка запроса: \(error.localizedDescription)")
                    completion(.failure(error)) // ошибка
                    
                    self.task = nil
                    self.lastCode = nil
                }
            }
        }
        self.task = task
        task.resume()
    }

//    // MARK: - Собираем URLRequest для запроса токена
    private func makeOAuthTokenRequest(code: String) -> URLRequest? {
        guard let url = URL(string: "https://unsplash.com/oauth/token") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Используем URLComponents только чтобы собрать строку тела
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
        ]

        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)

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
