import UIKit
import WebKit

enum WebViewConstants {
    static let unsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

protocol WebViewViewControllerDelegate: AnyObject {
    // Метод, который вызывается, когда WebViewViewController получает код авторизации.
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    
    // Метод, который вызывается, когда пользователь отменяет авторизацию (например, нажимает кнопку "Назад").
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}


final class WebViewViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    weak var delegate: WebViewViewControllerDelegate?
    
    var progress = 0.5
    
    @IBOutlet weak var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        
        loadAuthView()
    }
    
    private func loadAuthView() {
        guard var urlComponents = URLComponents(string: WebViewConstants.unsplashAuthorizeURLString) else {
            print("нет urlComponents")
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: Constants.accessScope)
        ]
//        Мы инициализируем структуру URLComponents с указанием адреса запроса.
//        Устанавливаем значение client_id — код доступа приложения.
//        Теперь — redirect_uri, то есть URI, который обрабатывает успешную авторизацию пользователя.
//        response_type — тип ответа, который мы ожидаем. Unsplash ожидает значения code.
//        Устанавливаем значение scope — списка доступов, разделённых плюсом.
//        В поле urlComponents.url — нужный нам URL.
        
        guard let url = urlComponents.url else {
            print("нет url")
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView.addObserver(self,
                            forKeyPath: #keyPath(WKWebView.estimatedProgress),
                            options: .new,
                            context: nil)
        updateProgress()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            updateProgress()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func updateProgress() {
        progressView.progress = Float(webView.estimatedProgress)
        progressView.isHidden = fabs(webView.estimatedProgress - 1.0) <= 0.0001
    }
}
 
extension WebViewViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
//    Первым параметром метода является webView. Это может быть полезно, если делегат принимает сообщения от нескольких WKWebView. Но у нас WKWebView один, поэтому мы игнорируем этот параметр.
//    В качестве второго параметра передаётся navigationAction: WKNavigationAction. Этот объект содержит информацию о том, что явилось причиной навигационных действий. С помощью него мы отделим событие успешной авторизации от прочих.
//    Наконец, третьим параметром передаётся замыкание decisionHandler. В этом методе его нужно выполнить, передав ему одно из трёх возможных значений WKNavigationActionPolicy:
//    cancel — отменить навигацию,
//    allow — разрешить навигацию,
//    download — разрешить загрузку.
    ) {
        if let code = code(from: navigationAction) {
            //TODO: process code
            print("Получен код: \(code)")
            delegate?.webViewViewController(self, didAuthenticateWithCode: code)
            
            UserDefaults.standard.set(true, forKey: "isAuthorized")
            UserDefaults.standard.synchronize() // Необязательно, но может ускорить сохранение
            
            decisionHandler(.cancel)
            return
        } else {
            print("Навигация продолжается...")
            decisionHandler(.allow)
        }
    }
    
    private func code(from navigationAction: WKNavigationAction) -> String? {
        if
            let url = navigationAction.request.url,
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

