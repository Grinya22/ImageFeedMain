import UIKit
import Kingfisher

class ImagesListViewController: UIViewController {
    private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    static let shared = ImagesListViewController()

    @IBOutlet private var tableView: UITableView!

    var photos: [Photo] = []
    
    var token = OAuth2TokenStorage.shared.token
        
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    // Вспомогательный метод для загрузки фотографий
    private func loadPhotosIfNeeded() {
        if let token = OAuth2TokenStorage.shared.token {
            photos = ImagesListService.shared.photos
            ImagesListService.shared.fetchPhotosNextPage(token: token)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTableViewAnimated),
            name: ImagesListService.didChangeNotification,
            object: nil
        )
        
        loadPhotosIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if photos.isEmpty {
            loadPhotosIfNeeded()
        }
    }
    
    @objc func updateTableViewAnimated() {
        let oldCount = photos.count
        let newPhotos = ImagesListService.shared.photos
        let newCount = newPhotos.count
        
        photos = newPhotos
        
        DispatchQueue.main.async {
            if oldCount < newCount {
                // Добавляем новые строки
                self.tableView.performBatchUpdates {
                    let indexPaths = (oldCount..<newCount).map { i in
                        IndexPath(row: i, section: 0)
                    }
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                } completion: { _ in }
            } else if oldCount > newCount {
                // Удаляем строки или перезагружаем таблицу
                self.tableView.performBatchUpdates {
                    let indexPaths = (newCount..<oldCount).map { i in
                        IndexPath(row: i, section: 0)
                    }
                    self.tableView.deleteRows(at: indexPaths, with: .automatic)
                } completion: { _ in }
            } else if newCount == 0 {
                // Если массив пуст, просто перезагружаем таблицу
                self.tableView.reloadData()
            }
        }
    }
}

extension ImagesListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        imageListCell.delegate = self
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == photos.count - 1 {
            if let token = OAuth2TokenStorage.shared.token {
                ImagesListService.shared.fetchPhotosNextPage(token: token)
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        performSegue(withIdentifier: showSingleImageSegueIdentifier, sender: indexPath)
//    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let photo = photos[indexPath.row]

        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        let singleImageVC = storyboard.instantiateViewController(withIdentifier: "SingleImageViewController") as! SingleImageViewController

        singleImageVC.imageURL = URL(string: photo.fullImageURL)

        present(singleImageVC, animated: true)
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let photo = photos[indexPath.row]
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        
        let imageWidth = photo.size.width
        let imageHeight = photo.size.height
        
        let cellWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = cellWidth / imageWidth
        
        let cellHeight = CGFloat(imageHeight * scale) + imageInsets.top + imageInsets.bottom
        
        return cellHeight
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        //let url = URL(string: photo.regularImageURL)
        let url = URL(string: photo.fullImageURL)
        
        // Отменяем предыдущую загрузку и сбрасываем изображение
        cell.cellImage.kf.cancelDownloadTask()
        cell.cellImage.image = nil
        cell.cellImage.kf.indicatorType = .activity

        // Устанавливаем уникальный тег для отслеживания переиспользования
        let currentTag = indexPath.row
        cell.tag = currentTag

        cell.cellImage.kf.setImage(
            with: url,
            placeholder: UIImage(named: "Stub"),
            options: [.transition(.fade(0.3))]
        ) { result in
            // Проверка: не изменилась ли ячейка с тех пор
            guard cell.tag == currentTag else { return }

            switch result {
            case .success:
                break // можно добавить анимацию при успехе, если хочешь
            case .failure(let error):
                print("Ошибка загрузки изображения: \(error)")
            }
        }

        // Обработка даты
        if let createdAtString = photo.createdAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            
            if let date = dateFormatter.date(from: createdAtString) {
                cell.dataLabel.text = self.dateFormatter.string(from: date)
            } else {
                cell.dataLabel.text = ""
            }
        } else {
            cell.dataLabel.text = ""
        }

        // Устанавливаем статус лайка
        cell.isLiked = photo.isLiked
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        // Покажем лоадер
        //UIBlockingProgressHUD.show()
        
        ImagesListService.shared.changeLike(photoId: photo.id, isLike: !photo.isLiked) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Синхронизируем массив картинок с сервисом
                    self.photos = ImagesListService.shared.photos
                    // Изменим индикацию лайка картинки
                    cell.setIsLiked(self.photos[indexPath.row].isLiked)
                    // Уберём лоадер
                    //UIBlockingProgressHUD.dismiss()
                    
                case .failure:
                    // Уберём лоадер
                    //UIBlockingProgressHUD.dismiss()
                    // Покажем, что что-то пошло не так
                    self.showImageListViewControllerErrorAlert()
                }
            }
        }
    }
}

extension ImagesListViewController {
    func showImageListViewControllerErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось поставить лайк. Попробуйте ещё раз.",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ImagesListViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageSegueIdentifier,
           let viewController = segue.destination as? SingleImageViewController,
           let indexPath = sender as? IndexPath {
            
            let photo = photos[indexPath.row]
            if let url = URL(string: photo.fullImageURL) {
                // Показываем лоадер
                UIBlockingProgressHUD.show()
                
                // Загружаем изображение из сети
                KingfisherManager.shared.retrieveImage(with: url) { result in
                    DispatchQueue.main.async {
                        UIBlockingProgressHUD.dismiss()
                    }
                    
                    switch result {
                    case .success(let imageResult):
                        DispatchQueue.main.async {
                            viewController.image = imageResult.image
                        }
                    case .failure(let error):
                        print("Не удалось загрузить изображение: \(error)")
                    }
                }
            }
        }
    }
}
