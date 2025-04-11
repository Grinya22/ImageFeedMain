import UIKit
import Kingfisher

final class ProfileViewController: UIViewController {
    private var nameLabel: UILabel!
    private var loginNameLabel: UILabel!
    private var descriptionLabel: UILabel!
    
    private var profileImageServiceObserver: NSObjectProtocol?
    
    private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
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
        
        let profileImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        imageView = UIImageView(image: profileImage)
        imageView.contentMode = .scaleAspectFill // Добавляем
        
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
        //loginNameLabel.text = "@ekaterina_nov"
        loginNameLabel.text = "@неизвестный_пользователь"
        
        loginNameLabel.textColor = .ypGray
        
        loginNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginNameLabel)
        
        NSLayoutConstraint.activate([
            loginNameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            loginNameLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor)
        ])
        
        descriptionLabel = UILabel()
        //descriptionLabel.text = "Hello, world!"
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
    }
    
    private func updateProfileDetails(with profile: Profile) {
        nameLabel.text = profile.name.isEmpty ? "Имя не указано" : profile.name
        loginNameLabel.text = profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName
        descriptionLabel.text = (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : profile.bio
        updateAvatar()
    }
    
    private func updateAvatar() {
        guard
            let profileImageURL = ProfileImageService.shared.avatarURL,
            let url = URL(string: profileImageURL),
            imageView != nil // Добавляем проверку
        else { return }

        let imageUrl = url
        print("imageUrl: \(imageUrl)")
        
        let placeholderImage = UIImage(systemName: "person.circle.fill")?
            .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 70, weight: .regular, scale: .large))
        
        let processor = RoundCornerImageProcessor(cornerRadius: 35)
        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: imageUrl,
                              placeholder: placeholderImage,
                              options: [
                                .processor(processor),
                                .scaleFactor(UIScreen.main.scale) // Учитываем масштаб экрана
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

                                   // В случае ошибки
                                  case .failure(let error):
                                      print(error)
                                  }
                              }
    }
    
    @objc
    func didTapLogoutButton(_ sender: Any) {
    }
}
