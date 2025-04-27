import Foundation
import Kingfisher
import UIKit

final class ImagesListPresenter: ImagesListPresenterProtocol {
    // Презентер
    weak var view: ImagesListViewControllerProtocol?
    private let imagesListService: ImagesListServiceProtocol
    private let tokenStorage: TokenStorageProtocol
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private lazy var isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()
    
    var photos: [Photo] {
        imagesListService.photos
    }
    
    init(
        view: ImagesListViewControllerProtocol,
        imagesListService: ImagesListServiceProtocol,
        tokenStorage: TokenStorageProtocol
    ) {
        self.view = view
        self.imagesListService = imagesListService
        self.tokenStorage = tokenStorage
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
    }
    
    func viewDidLoad() {
        if let token = tokenStorage.token {
            imagesListService.fetchPhotosNextPage(token: token)
        }
    }
    
    func viewWillAppear() {
        KingfisherManager.shared.cache.clearMemoryCache()
        view?.updateTableView(oldCount: photos.count, newCount: imagesListService.photos.count)
        
        if imagesListService.photos.isEmpty {
            if let token = tokenStorage.token {
                imagesListService.fetchPhotosNextPage(token: token)
            }
        }
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        
        guard let singleImageVC = storyboard.instantiateViewController(withIdentifier: "SingleImageViewController") as? SingleImageViewController else {
            return
        }
        
        singleImageVC.imageURL = URL(string: photo.fullImageURL)
        view?.present(singleImageVC, animated: true, completion: nil)
    }
    
    func willDisplayCell(at indexPath: IndexPath) {
        if indexPath.row == photos.count - 1, let token = tokenStorage.token {
            imagesListService.fetchPhotosNextPage(token: token)
        }
    }
    
    func configureCell(_ cell: ImagesListCell, for indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        let url = URL(string: photo.regularImageURL)
        //let url = URL(string: photo.fullImageURL)
        print("Настройка ячейки для indexPath: \(indexPath), URL: \(url?.absoluteString ?? "nil")")
        
        // Отменяем предыдущую загрузку и сбрасываем изображение
        cell.cellImage.kf.cancelDownloadTask()
        cell.cellImage.image = nil
        cell.cellImage.kf.indicatorType = .activity
        
        print("Добавляем градиент для ячейки \(indexPath)")
        // Добавляем градиент перед загрузкой
        cell.addGradientIfNeeded()
        
        // Устанавливаем уникальный тег для отслеживания переиспользования
        let currentTag = indexPath.row
        cell.tag = currentTag
        
        cell.cellImage.kf.setImage(
            with: url,
            placeholder: UIImage(named: "Stub"),
            options: [.transition(.fade(0.3)), .forceRefresh, .forceTransition]
        ) { result in
            // Проверка: не изменилась ли ячейка с тех пор
            guard cell.tag == currentTag else {
                print("Ячейка переиспользована, игнорируем результат для \(indexPath)")
                return
            }
            switch result {
            case .success:
                print("Картинка загружена для \(indexPath), убираем градиент")
                // Убираем градиент после успешной загрузки
                cell.removeGradient()
            case .failure(let error):
                print("Ошибка загрузки изображения: \(error)")
                // Оставляем градиент, если картинка не загрузилась
            }
        }
        
        // Обработка даты
        if let createdAtString = photo.createdAt {
            if let date = isoDateFormatter.date(from: createdAtString) {
                cell.dataLabel.text = dateFormatter.string(from: date)
            } else {
                cell.dataLabel.text = ""
            }
        } else {
            cell.dataLabel.text = ""
        }
        
        // Устанавливаем статус лайка
        cell.isLiked = photo.isLiked
        
        // Добавляем градиент после настройки ячейки
        print("Добавляем градиент для ячейки \(indexPath)")
        cell.setNeedsLayout() // Форсируем обновление layout
    }
    
    
    func didTapLikeButton(_ cell: ImagesListCell) {
        guard let viewController = view as? ImagesListViewController,
              let indexPath = viewController.tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.view?.updateTableView(oldCount: self.photos.count, newCount: self.imagesListService.photos.count)
                    if let cell = viewController.tableView.cellForRow(at: indexPath) as? ImagesListCell {
                        cell.setIsLiked(self.photos[indexPath.row].isLiked)
                    }
                case .failure:
                    self.view?.showErrorAlert()
                }
            }
        }
    }
    
    @objc private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        
        view?.updateTableView(oldCount: oldCount, newCount: newCount)
    }
}

