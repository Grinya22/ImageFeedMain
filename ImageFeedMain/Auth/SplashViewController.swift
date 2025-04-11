import UIKit

/// Контроллер, который проверяет наличие токена и решает, какой экран показать
final class SplashViewController: UIViewController {
    
    /// Идентификатор перехода на экран авторизации
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let profileService = ProfileService.shared
    
    /// Хранилище токена
    private let storage = OAuth2TokenStorage.shared
    
    // MARK: - Жизненный цикл контроллера
    /// Вызывается, когда экран полностью появился
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Если токен есть, переходим к главному экрану (TabBarController)
        if let token = storage.token {
            fetchProfile(token)
            //switchToTabBarController()
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

    private func switchToTabBarController(selectedIndex: Int = 0) {
        // Получаем главное окно приложения
        guard let window = UIApplication.shared.windows.first else {
            assertionFailure("Invalid window configuration")
            return
        }

        // Создаём экземпляр `TabBarController` из Main.storyboard
        guard let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController") as? UITabBarController else {
            assertionFailure("Could not cast to UITabBarController")
            return
        }

        // Выбираем нужную вкладку
        tabBarController.selectedIndex = selectedIndex

        // Меняем rootViewController на TabBarController
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
    // Этот метод вызывается, когда пользователь успешно авторизовался
    func didAuthenticate(_ vc: AuthViewController) {
        vc.dismiss(animated: true)
        //switchToTabBarController(selectedIndex: 1) // <- вот тут выбираешь вкладку
        
        guard let token = OAuth2TokenStorage.shared.token else {
            print("Токен не найден после авторизации")
            return
        }
        fetchProfile(token) // После успешной авторизации запрашиваем профиль
    }
    
}

// MARK: - Подготовка к переходу на AuthViewController

extension SplashViewController {
    private func fetchProfile(_ token: String) {
        UIBlockingProgressHUD.show()
        
        profileService.fetchProfile(token) { [weak self] result in
            UIBlockingProgressHUD.dismiss()
            
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    ProfileImageService.shared.fetchProfileImageURL(username: profile.username) { _ in }
                    
                    self?.switchToTabBarController(selectedIndex: 1) // Переход к ленте фотографий после успешного получения профиляprivate let profileService = ProfileService.shared
                case .failure(let error):
                    print("Ошибка при загрузке профиля: \(error)")
                    // Если не удалось получить профиль, показываем экран с лентой фотографий
                    //self?.switchToTabBarController(selectedIndex: 1)
                    
                    // Показываем ошибку получения профиля
                    let alert = UIAlertController(title: "Ошибка", message: "Не удалось загрузить профиль", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)

                }
            }
        }
    }
}
