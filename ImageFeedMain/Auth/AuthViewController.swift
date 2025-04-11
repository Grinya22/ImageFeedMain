import UIKit

protocol AuthViewControllerDelegate: AnyObject {
    func didAuthenticate(_ vc: AuthViewController)
}

final class AuthViewController: UIViewController {
    private let showWebViewSegueIdentifier = "ShowWebView"
    
    private let oauth2Service = OAuth2Service.shared
    
    weak var delegate: AuthViewControllerDelegate?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showWebViewSegueIdentifier {
            guard
                let webViewViewController = segue.destination as? WebViewViewController
            else {
                assertionFailure("Failed to prepare for \(showWebViewSegueIdentifier)")
                return
            }
            webViewViewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension AuthViewController: WebViewViewControllerDelegate {
    func webViewViewController(_ vc: WebViewViewController, didAuthenticateWithCode code: String) {
        // Получили код авторизации
        print("Авторизация прошла успешно. Код: \(code)")
        
        // Закрываем WebView
        vc.dismiss(animated: true, completion: nil)
        
        // Запускаем процесс получения токена
        fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                print("Получен токен: \(token)")
                // Уведомляем делегата, что аутентификация прошла успешно
                self.delegate?.didAuthenticate(self)
            case .failure(let error):
                print("Ошибка при аутентификации: \(error.localizedDescription)")
                self.showAuthErrorAlert()  // Показываем алерт при ошибке
            }
        }
    }

    func webViewViewControllerDidCancel(_ vc: WebViewViewController) {
        vc.dismiss(animated: true)
    }
}

extension AuthViewController {
    private func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        oauth2Service.fetchOAuthToken(code) { result in
            switch result {
            case .success(let token):
                completion(.success(token))
            case .failure(let error):
                print("Ошибка получения токена: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}


extension AuthViewController {
    
    
    func showAuthErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось войти в систему",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

