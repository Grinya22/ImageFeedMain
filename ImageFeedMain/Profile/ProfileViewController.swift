import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private var imageView: UIImageView!
    private var animationLayers = Set<CALayer>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                print("Получено уведомление ProfileImageService.didChangeNotification")
                self.updateAvatar()
            }
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let size: CGFloat = 70
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            imageView.widthAnchor.constraint(equalToConstant: size),
            imageView.heightAnchor.constraint(equalToConstant: size)
        ])
        
        nameLabel = UILabel()
        nameLabel.text = "Имя не указано"
        nameLabel.textColor = .ypWhite
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ])
        
        loginNameLabel = UILabel()
        loginNameLabel.text = "@неизвестный_пользователь"
        loginNameLabel.textColor = .ypGray
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ])
        
        descriptionLabel = UILabel()
        descriptionLabel.text = "Профиль не заполнен"
        descriptionLabel.textColor = .ypWhite
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            descriptionLabel.topAnchor.constraint(equalTo: loginNameLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ])
        
        let logoutButton = UIButton.systemButton(
            with: UIImage(named: "logoutButton")!,
            target: self,
            action: #selector(didTapLogoutButton)
        )
        
        logoutButton.tintColor = .ypRed
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            logoutButton.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            logoutButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -36)
        ])
        
        if let profile = ProfileService.shared.profile {
            updateProfileDetails(with: profile)
        }
        
        view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear, imageView.image: \(imageView.image != nil ? "не nil" : "nil")")
        KingfisherManager.shared.cache.clearMemoryCache()
        view.layoutIfNeeded()
        updateAvatar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews, imageView.bounds: \(imageView.bounds)")
        updateGradientFrame()
    }
    
    private func updateProfileDetails(with profile: Profile) {
        nameLabel.text = profile.name.isEmpty ? "Имя не указано" : profile.name
        loginNameLabel.text = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
        descriptionLabel.text = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : profile.bio
    }
    
    private func makeRoundedPlaceholder(size: CGFloat, cornerRadius: CGFloat) -> UIImage? {
        guard let placeholder = UIImage(systemName: "person.circle.fill")?
                .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: size, weight: .regular, scale: .large))
        else {
            return nil
        }
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            placeholder.draw(in: rect)
        }
        
        return image
    }
    
    private func updateAvatar() {
        print("Вызван updateAvatar, imageView: \(imageView != nil ? "не nil" : "nil")")
        guard imageView != nil else {
            print("imageView is nil, пропускаем обновление аватарки")
            return
        }
        
        // Добавляем градиент, только если аватарка ещё не загружена
        if imageView.image == nil {
            addGradient(to: imageView, cornerRadius: 35)
        }
        
        guard let profileImageURL = ProfileImageService.shared.avatarURL,
              let url = URL(string: profileImageURL) else {
                  print("Нет URL аватарки, устанавливаем плейсхолдер")
                  imageView.image = makeRoundedPlaceholder(size: 70, cornerRadius: 35)
                  return
              }
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        imageView.kf.setImage(
            with: url,
            placeholder: makeRoundedPlaceholder(size: 70, cornerRadius: 35),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .forceRefresh,
                .forceTransition,
                .cacheMemoryOnly
            ]
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                print("Аватарка загружена")
                self.removeGradient() // Убираем градиент после загрузки
            case .failure(let error):
                print("Ошибка загрузки аватарки: \(error)")
                // Оставляем градиент, если загрузка не удалась
            }
        }
    }
    
    @objc
    func didTapLogoutButton(_ sender: Any) {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены что хотите выйти?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Да", style: .destructive) { _ in
            ProfileLogoutService.shared.logout()
        })
        
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    deinit {
        if let observer = profileImageServiceObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

extension ProfileViewController {
    private func addGradient(to view: UIView, cornerRadius: CGFloat = 0) {
        print("Добавляем градиент для \(view), bounds: \(view.bounds)")
        view.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInProfileViewController" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
        
        let gradient = CAGradientLayer()
        gradient.name = "locationChangeInProfileViewController"
//        gradient.colors = [
//            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
//            UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1).cgColor,
//            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor
//        ]
        gradient.colors = [
            UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1).cgColor, // Яркий серо-голубой
            UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1).cgColor, // Белый с голубым оттенком
            UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1).cgColor // Возвращаемся к первому
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.locations = [-1, -0.5, 0]
        gradient.frame = view.bounds
        gradient.cornerRadius = cornerRadius
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "locationChangeInProfileViewController")
        
        view.layer.insertSublayer(gradient, at: 0)
        animationLayers.insert(gradient)
    }
    
    private func removeGradient() {
        print("Убираем градиент, слои до: \(imageView.layer.sublayers?.map { $0.name ?? "без имени" } ?? [])")
        imageView.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInProfileViewController" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
        print("Слои после: \(imageView.layer.sublayers?.map { $0.name ?? "без имени" } ?? [])")
    }
    
    private func updateGradientFrame() {
        for layer in animationLayers {
            if layer.name == "locationChangeInProfileViewController" {
                print("Обновляем frame градиента, новый bounds: \(imageView.bounds)")
                layer.frame = imageView.bounds
            }
        }
    }
}
