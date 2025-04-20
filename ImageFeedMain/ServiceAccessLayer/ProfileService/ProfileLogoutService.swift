import Foundation
import WebKit
import Kingfisher

final class ProfileLogoutService {
    static let shared = ProfileLogoutService()
    
    private init() {}
    
    func logout() {
        // Очищаем токен
        cleanToken()
        // Очищаем куки
        cleanCookies()
        // Очищаем данные профиля
        cleanProfileData()
        // Очищаем аватарку
        cleanProfileImageData()
        // Очищаем список изображений (если есть ImagesListService)
        cleanImagesListData()
        // Очищаем кэш изображений Kingfisher
        cleanImageCache()
        // Переходим на начальный экран
        switchToSplashScreen()
    }
    
    private func cleanToken() {
        OAuth2TokenStorage.shared.token = nil
    }
    
    private func cleanCookies() {
        // Очищаем все куки из хранилища
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        // Очищаем данные из WKWebView
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    
    private func cleanProfileData() {
        ProfileService.shared.resetProfile()
    }
    
    private func cleanProfileImageData() {
        ProfileImageService.shared.resetProfileImage()
    }
    
    private func cleanImagesListData() {
        ImagesListService.shared.clearData()
    }
    
    private func cleanImageCache() {
        // Очищаем кэш Kingfisher
        ImageCache.default.clearMemoryCache()
        ImageCache.default.clearDiskCache { print("Кэш изображений очищен") }
    }
    
    private func switchToSplashScreen() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first else {
                assertionFailure("Invalid window configuration")
                return
            }
            
            let splashViewController = SplashViewController()
            window.rootViewController = splashViewController
        }
    }
}
