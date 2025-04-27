import XCTest
@testable import ImageFeed
@testable import ImageFeedUITests

class ProfileTests: XCTestCase {
    func testPresenterCallsUpdateProfileDetailsOnViewDidLoad() {
        // given
        let presenter = ProfileViewPresenter()
        let viewControllerSpy = ProfileViewControllerSpy()
        
        presenter.view = viewControllerSpy

        //when
        ProfileService.shared.setTestProfile(Profile(
            username: "testuser",
            name: "Test Name",
            loginName: "@testloginName",
            bio: "testbio"
        ))
        presenter.viewDidLoad()
        
        // then
        XCTAssertTrue(viewControllerSpy.updateProfileDetailsCalled)

        XCTAssertEqual(viewControllerSpy.name, "Test Name")
        XCTAssertEqual(viewControllerSpy.loginName, "@testloginName")
        XCTAssertEqual(viewControllerSpy.bio, "testbio")

    }
    
    func testPresenterCallsUpdateAvatarOnUpdateAvatar() {
        // given
        let presenter = ProfileViewPresenter()
        let viewControllerSpy = ProfileViewControllerSpy()
        
        presenter.view = viewControllerSpy

        //when
        ProfileImageService.shared.setTestAvatarURL("https://example.com/avatar.jpg")
        presenter.updateAvatar()
        
        // then
        XCTAssertTrue(viewControllerSpy.updateAvatarCalled)
        XCTAssertEqual(viewControllerSpy.avatarURL?.absoluteString, "https://example.com/avatar.jpg")
    }
    
    func testPresenterHandlesEmptyProfileGracefully() {
        // given
        let presenter = ProfileViewPresenter()
        let viewControllerSpy = ProfileViewControllerSpy()
        
        presenter.view = viewControllerSpy
        
        //when
        ProfileService.shared.setTestProfile(nil)
        presenter.viewDidLoad()
        
        // then
        XCTAssertFalse(viewControllerSpy.updateProfileDetailsCalled)
    }
    
    func testPresenterHandlesMissingAvatarGracefully() {
        // given
        let presenter = ProfileViewPresenter()
        let viewControllerSpy = ProfileViewControllerSpy()
        
        presenter.view = viewControllerSpy
        
        //when
        ProfileImageService.shared.setTestAvatarURL(nil)
        presenter.viewDidLoad()
        
        // then
        XCTAssertFalse(viewControllerSpy.updateAvatarCalled)
    }
}
