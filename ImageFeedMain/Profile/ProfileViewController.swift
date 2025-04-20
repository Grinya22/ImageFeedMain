import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private var imageView: UIImageView!
    
    var animationLayers = Set<CALayer>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .ypBlack
                
        profileImageServiceObserver = NotificationCenter.default
            .addObserver(
                forName: ProfileImageService.didChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self else { return }
                self.updateAvatar()
            }
        
        updateAvatar()
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill // Заполняем с сохранением пропорций
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
        //nameLabel.text = "Екатерина Новикова"
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
        addGradient(to: imageView, cornerRadius: 35)
        [nameLabel, loginNameLabel, descriptionLabel].forEach {
            addGradient(to: $0, cornerRadius: 10)
        }
    }
    
    private func updateProfileDetails(with profile: Profile) {
        nameLabel.text = profile.name.isEmpty ? "Имя не указано" : profile.name
        loginNameLabel.text = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
        descriptionLabel.text = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : profile.bio
        updateAvatar()
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
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL),
            imageView != nil // Добавляем проверку
        else { return }

        let imageUrl = url
        print("imageUrl: \(imageUrl)")
        
        let size: CGFloat = 70
        let cornerRadius: CGFloat = 35

        let placeholderImage = makeRoundedPlaceholder(size: size, cornerRadius: cornerRadius)
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35) // Радиус для круга
        //imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: imageUrl,
                              placeholder: placeholderImage,
                              options: [
                                .processor(processor),
                                .scaleFactor(UIScreen.main.scale), // Учитываем масштаб экрана
                                .cacheOriginalImage, // Кэшируем оригинал
                                .forceRefresh // Игнорируем кэш, чтобы обновить
                              ]) { result in

                                  switch result {
                                // Успешная загрузка
                                  case .success(let value):
                                      // Картинка
                                      print(value.image)

                                      // Откуда картинка загружена:
                                      // - .none — из сети.
                                      // - .memory — из кэша оперативной памяти.
                                      // - .disk — из дискового кэша.
                                      print(value.cacheType)

                                      // Информация об источнике.
                                      print(value.source)
                                      
//                                      for layer in self.animationLayers {
//                                          layer.removeFromSuperlayer()
//                                      }
//                                      self.animationLayers.removeAll()
                                      
                                      self.imageView.layer.mask = nil

                                   // В случае ошибки
                                  case .failure(let error):
                                      print(error)
                                  }
                              }
    }
    
    @objc
    func didTapLogoutButton(_ sender: Any) {
        let alert = UIAlertController(
            title: "Пока, пока!",
            message: "Уверены что хотите выйти??",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Да", style: .destructive) { _ in
            ProfileLogoutService.shared.logout()
        })
        
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
}


extension ProfileViewController {
    private func addGradient(to view: UIView, cornerRadius: CGFloat = 0) {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1).cgColor,
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor
        ]

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.cornerRadius = cornerRadius

        gradient.locations = [-1, -0.5, 0] // начальная позиция "белой полосы"
        gradient.frame = view.bounds
        if view === imageView {
            gradient.frame = CGRect(origin: .zero, size: CGSize(width: 70, height: 70))
        }

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "locationChangeInProfileViewController")

        view.layer.addSublayer(gradient)
        animationLayers.insert(gradient)
    }

//    private func addGradient(to view: UIView, cornerRadius: CGFloat = 0) {
//        let gradient = CAGradientLayer()
//
//        if view === imageView {
//            // Фиксированный размер для imageView
//            gradient.frame = CGRect(origin: .zero, size: CGSize(width: 70, height: 70))
//        } else {
//            // Используем bounds для других view
//            gradient.frame = view.bounds
//        }
//
//        gradient.locations = [0, 0.1, 0.3]
//        gradient.colors = [
//            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
//            UIColor(red: 0.531, green: 0.533, blue: 0.553, alpha: 1).cgColor,
//            UIColor(red: 0.431, green: 0.433, blue: 0.453, alpha: 1).cgColor
//        ]
//        gradient.startPoint = CGPoint(x: 0, y: 0.5)
//        gradient.endPoint = CGPoint(x: 1, y: 0.5)
//        gradient.cornerRadius = cornerRadius
//        gradient.masksToBounds = true
//
//        let gradientAnimation = CABasicAnimation(keyPath: "locations")
//        gradientAnimation.duration = 1.5
//        gradientAnimation.repeatCount = .infinity
//        //gradientAnimation.autoreverses = true
//        gradientAnimation.fromValue = [0, 0.1, 0.3]
//        gradientAnimation.toValue = [0, 0.8, 1.0]
//        gradient.add(gradientAnimation, forKey: "locationChange")
//
//        view.layer.addSublayer(gradient)
//        animationLayers.insert(gradient)
//    }
}
