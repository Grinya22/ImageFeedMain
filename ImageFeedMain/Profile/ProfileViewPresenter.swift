import Foundation

public protocol ProfilePresenterProtocol: AnyObject {
    var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func updateAvatar()
}

final class ProfileViewPresenter: ProfilePresenterProtocol {
    weak var view: ProfileViewControllerProtocol?
    
    func viewDidLoad() {
        guard let profile = ProfileService.shared.profile else { return }
        view?.updateProfileDetails(
            name: profile.name.isEmpty ? "Имя не указано" : profile.name,
            loginName: profile.loginName.isEmpty ? "@неизвестный_пользователь" : profile.loginName,
            bio: (profile.bio?.isEmpty ?? true) ? "Профиль не заполнен" : (profile.bio ?? "")
        )
    }
    
    func updateAvatar() {
        guard let avatarURLString = ProfileImageService.shared.avatarURL,
              let avatarURL = URL(string: avatarURLString) else {
                  print("Нет URL аватарки, устанавливаем плейсхолдер")
                  view?.updateAvatar(with: nil)
                  return
        }
        
        view?.updateAvatar(with: avatarURL)
    }
}
