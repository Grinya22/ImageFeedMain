import ImageFeed
import Foundation

class ProfileViewControllerSpy: ProfileViewControllerProtocol {
    var presenter: ProfilePresenterProtocol?
    
    var updateProfileDetailsCalled = false
    var updateAvatarCalled = false

    var name: String?
    var loginName: String?
    var bio: String?
    var avatarURL: URL?
    
    func updateProfileDetails(name: String, loginName: String, bio: String) {
        updateProfileDetailsCalled = true
        self.name = name
        self.loginName = loginName
        self.bio = bio
    }
    
    func updateAvatar(with url: URL?) {
        updateAvatarCalled = true
        self.avatarURL = url
    }
}
