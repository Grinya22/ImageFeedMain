import Foundation

protocol AuthHelperProtocol {
    func authRequest() -> URLRequest?
    func code(from url: URL) -> String?
}

final class AuthHelper: AuthHelperProtocol {
    let configuration: AuthConfiguration
    
    init(configuration: AuthConfiguration = .standard) {
        self.configuration = configuration
    }
    
    func authRequest() -> URLRequest? {
        guard let url = authURL() else {
            print("нет url")
            return nil
        }
        return URLRequest(url: url)
    }
    
    func authURL() -> URL? {
        guard var urlComponents = URLComponents(string: configuration.authURLString) else {
            print("нет urlComponents")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.accessKey),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.accessScope)
        ]
//        Мы инициализируем структуру URLComponents с указанием адреса запроса.
//        Устанавливаем значение client_id — код доступа приложения.
//        Теперь — redirect_uri, то есть URI, который обрабатывает успешную авторизацию пользователя.
//        response_type — тип ответа, который мы ожидаем. Unsplash ожидает значения code.
//        Устанавливаем значение scope — списка доступов, разделённых плюсом.
//        В поле urlComponents.url — нужный нам URL.
        
        return urlComponents.url
        
    }
    
    func code(from url: URL) -> String? {
        if
            let urlComponents = URLComponents(string: url.absoluteString),
            urlComponents.path == "/oauth/authorize/native",
            let items = urlComponents.queryItems,
            let codeItem = items.first(where: { $0.name == "code" })
//                Получаем из навигационного действия navigationAction URL.
//                Создаём уже известную нам структуру URLComponents. Только теперь мы будем не формировать URL с помощью компонентов, а наоборот — получать значения компонентов из URL.
//                Проверяем, совпадает ли адрес запроса с адресом получения кода.
//                Проверяем, есть ли в URLComponents компоненты запроса (в них должен быть код). Компонент запроса URLQueryItem — это структура, которая содержит имя компонента name и его значение value.
//                Ищем в массиве компонентов такой компонент, у которого значение name == code.
//                Если все проверки выше прошли успешно, возвращаем значение value найденного компонента. Иначе возвращаем nil.
        {
            return codeItem.value
            // Если все проверки выше прошли успешно, возвращаем значение value найденного компонента. Иначе возвращаем nil.
        } else {
            return nil
        }
    }
}
