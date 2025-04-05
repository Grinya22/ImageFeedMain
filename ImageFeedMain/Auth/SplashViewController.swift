import UIKit

/// Контроллер, который проверяет наличие токена и решает, какой экран показать
final class SplashViewController: UIViewController {
    
    /// Идентификатор перехода на экран авторизации
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    /// Хранилище токена
    private let storage = OAuth2TokenStorage()

    // MARK: - Жизненный цикл контроллера
    
    /// Вызывается, когда экран полностью появился
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Если токен есть, переходим к главному экрану (TabBarController)
        if storage.token != nil {
            switchToTabBarController()
        } else {
            // Если токена нет, переходим к экрану авторизации
            performSegue(withIdentifier: showAuthenticationScreenSegueIdentifier, sender: nil)
        }
    }

    /// Вызывается перед появлением экрана
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Обновляем стиль статус-бара
        setNeedsStatusBarAppearanceUpdate()
    }

    /// Устанавливаем светлый стиль для статус-бара (белый текст)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - Переключение на главный экран (TabBarController)
    
    /// Метод, который заменяет `rootViewController` на `TabBarController`
    private func switchToTabBarController() {
        // Получаем главное окно приложения
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration") // Если окна нет, кидаем ошибку в дебаг
            return
        }
        
        // Создаём экземпляр `TabBarController` из Main.storyboard
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
        
        // Меняем rootViewController на `tabBarController`
        window.rootViewController = tabBarController
    }
}

// MARK: - Подготовка к переходу на AuthViewController

extension SplashViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Проверяем, что выполняем переход именно на экран авторизации
        if segue.identifier == showAuthenticationScreenSegueIdentifier {
            // Извлекаем `UINavigationController`
            guard let navigationController = segue.destination as? UINavigationController,
                  let viewController = navigationController.viewControllers.first as? AuthViewController
            else {
                assertionFailure("Failed to prepare for \(showAuthenticationScreenSegueIdentifier)") // Ошибка, если что-то пошло не так
                return
            }
            
            // Устанавливаем текущий `SplashViewController` как делегат для `AuthViewController`
            viewController.delegate = self
        } else {
            // Если это другой segue, вызываем `super`, чтобы обработка продолжилась
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - Обработка успешной авторизации

extension SplashViewController: AuthViewControllerDelegate {
    /// Этот метод вызывается, когда пользователь успешно авторизовался
    func didAuthenticate(_ vc: AuthViewController) {
        // Закрываем экран авторизации
        vc.dismiss(animated: true)
        
        // Переходим к TabBarController
        switchToTabBarController()
    }
}
