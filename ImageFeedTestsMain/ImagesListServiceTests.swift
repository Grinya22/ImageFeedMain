@testable import ImageFeed
import XCTest

final class ImagesListServiceTests: XCTestCase {
    func testFetchPhotos() {
        let service = ImagesListService.shared
        guard let token = OAuth2TokenStorage.shared.token else { return }
        
        let expectation = self.expectation(description: "Wait for Notification")
        NotificationCenter.default.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: nil,
            queue: .main) { _ in
                print("Получено уведомление о смене данных.")

                expectation.fulfill()
            }
        
        service.fetchPhotosNextPage(token: token)
        wait(for: [expectation], timeout: 30)
        
        XCTAssertEqual(service.photos.count, 10)
    }

}
