import UIKit

/// Контроллер, который проверяет наличие токена и решает, какой экран показать
final class SplashViewController: UIViewController {
    
    /// Идентификатор перехода на экран авторизации
    private let showAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    
    private let profileService = ProfileService.shared
    
    /// Хранилище токена
    private let storage = OAuth2TokenStorage.shared
    
    private var imageView: UIImageView!
    
    // MARK: - Жизненный цикл контроллера
    /// Вызывается, когда экран полностью появился
    override func viewDidAppear(_ animated: Bool) {
        
        view.backgroundColor = .ypBlack
        
        let imageSplachScreenLogo = UIImage(named: "splashScreenLogo")
        
        imageView = UIImageView(image: imageSplachScreenLogo)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
               imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
               imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        super.viewDidAppear(animated)
        // Если токен есть, переходим к главному экрану (TabBarController)
        if let token = storage.token {
            fetchProfile(token)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: .main)
            guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else {
                assertionFailure("Не удалось найти AuthViewController по идентификатору")
                return
            }
            authViewController.delegate = self
            authViewController.modalPresentationStyle = .fullScreen
            present(authViewController, animated: true)
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
                    
                    self?.switchToTabBarController(selectedIndex: 0) // Переход к ленте фотографий после успешного получения профиляprivate let profileService = ProfileService.shared
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
