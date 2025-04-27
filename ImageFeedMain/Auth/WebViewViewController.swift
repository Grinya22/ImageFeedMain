import UIKit
import WebKit

public protocol WebViewViewControllerProtocol: AnyObject {
    var presenter: WebViewPresenterProtocol? {get set}
    func load(request: URLRequest)
    func setProgressValue(_ newValue: Float)
    func setProgressHidden(_ isHidden: Bool)
}

protocol WebViewViewControllerDelegate: AnyObject {
    // Метод, который вызывается, когда WebViewViewController получает код авторизации.
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String)
    
    // Метод, который вызывается, когда пользователь отменяет авторизацию (например, нажимает кнопку "Назад").
    func webViewViewControllerDidCancel(_ vc: WebViewViewController)
}

final class WebViewViewController: UIViewController, WebViewViewControllerProtocol {
    @IBOutlet weak var webView: WKWebView!
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    weak var delegate: WebViewViewControllerDelegate?
    
    var progress = 0.5
    
    @IBOutlet weak var progressView: UIProgressView!
    
    private var estimatedProgressObservation: NSKeyValueObservation?
    
    var presenter: WebViewPresenterProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.accessibilityIdentifier = "UnsplashWebView"
        
        webView.navigationDelegate = self
        
        presenter?.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // NOTE: Since the class is marked as `final` we don't need to pass a context.
        // In case of inhertiance context must not be nil.
        webView.addObserver(
            self,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            presenter?.didUpdateProgressValue(webView.estimatedProgress)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func load(request: URLRequest) {
        webView.load(request)
    }
    
    func setProgressValue(_ newValue: Float) {
        progressView.progress = newValue
    }
    
    func setProgressHidden(_ isHidden: Bool) {
        progressView.isHidden = isHidden
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
        if let url = navigationAction.request.url{
            return presenter?.code(from: url)
        }
        return nil
    }
}

