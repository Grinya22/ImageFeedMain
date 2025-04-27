import UIKit
import Kingfisher

// MARK: - Protocols
// Протоколы разделяют ответственность и упрощают тестирование
protocol ImagesListViewControllerProtocol: AnyObject {
    // Протокол для контроллера, чтобы презентер мог обновлять UI
    func updateTableView(oldCount: Int, newCount: Int)
    // Обновляет таблицу при изменении массива фотографий
    func showErrorAlert()
    // Показывает алерт при ошибке (например, не удалось поставить лайк)
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?)
    // Показывает другой контроллер (например, SingleImageViewController)
}

protocol ImagesListPresenterProtocol {
    // Протокол для презентера, управляющего бизнес-логикой
    var photos: [Photo] { get }
    // Массив фотографий
    func viewDidLoad()
    // Вызывается при загрузке контроллера
    func viewWillAppear()
    // Вызывается перед появлением контроллера
    func didSelectRow(at indexPath: IndexPath)
    // Обрабатывает выбор строки
    func willDisplayCell(at indexPath: IndexPath)
    // Вызывается перед отображением ячейки
    func configureCell(_ cell: ImagesListCell, for indexPath: IndexPath)
    // Настраивает ячейку
    func didTapLikeButton(_ cell: ImagesListCell)
    // Обрабатывает нажатие кнопки лайка
}

protocol ImagesListServiceProtocol {
    /// Массив загруженных фотографий
    var photos: [Photo] { get }
    
    /// Загружает следующую страницу фотографий с Unsplash API
    /// - Parameter token: Токен авторизации
    func fetchPhotosNextPage(token: String)
    
    /// Изменяет статус лайка для фотографии
    /// - Parameters:
    ///   - photoId: Идентификатор фотографии
    ///   - isLike: Установить или снять лайк
    ///   - completion: Замыкание с результатом операции
    func changeLike(photoId: String, isLike: Bool, completion: @escaping (Result<Void, Error>) -> Void)
    
    /// Уведомление об изменении массива фотографий
    static var didChangeNotification: Notification.Name { get }
}

protocol TokenStorageProtocol {
    // Протокол для хранилища токена
    var token: String? { get }
    // Токен авторизации
}

// MARK: - ImagesListViewController
class ImagesListViewController: UIViewController, ImagesListViewControllerProtocol {
    private var presenter: ImagesListPresenterProtocol?
    
    //private let showSingleImageSegueIdentifier = "ShowSingleImage"
    
    @IBOutlet weak var tableView: UITableView!
    
    init(presenter: ImagesListPresenterProtocol) {
        // Программный инициализатор
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        // Инициализатор для Storyboard
        super.init(coder: coder)

        self.presenter = ImagesListPresenter(
            view: self,
            imagesListService: ImagesListService.shared,
            tokenStorage: OAuth2TokenStorage.shared
        )
    }
    
    override func viewDidLoad() {
        // Загрузка контроллера
        super.viewDidLoad()
        // Настроить tableView после того, как она загрузится
        if tableView != nil {
            setupTableView()
            print("tableView is initialized")
        } else {
            print("tableView is nil in viewDidLoad")
        }
        presenter?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter?.viewWillAppear()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Делаем дополнительную проверку и настройку, если tableView еще не настроена
        if tableView != nil && tableView.dataSource == nil {
            setupTableView()
        }
    }
    
    // MARK: - Private Methods
    private func setupTableView() {
        // Настройка таблицы
        // Устанавливаем dataSource и delegate только после того, как view загружен
        if isViewLoaded {
            tableView.dataSource = self
            tableView.delegate = self
            tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        }
    }
    
    // MARK: - ImagesListViewControllerProtocol
    func updateTableView(oldCount: Int, newCount: Int) {
        guard self.tableView != nil else {
            print("tableView is nil")
            return
        }
        
        DispatchQueue.main.async {
            if oldCount < newCount {
                // Добавляем новые строки
                self.tableView.performBatchUpdates {
                    let indexPaths = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                }
            } else if oldCount > newCount {
                // Удаляем строки или перезагружаем таблицу
                self.tableView.performBatchUpdates {
                    let indexPaths = (newCount..<oldCount).map { IndexPath(row: $0, section: 0) }
                    self.tableView.deleteRows(at: indexPaths, with: .automatic)
                }
            } else if newCount == 0 {
                // Если массив пуст, просто перезагружаем таблицу
                self.tableView.reloadData()
            }
        }
    }
    
    func showErrorAlert() {
        let alertController = UIAlertController(
            title: "Что-то пошло не так",
            message: "Не удалось поставить лайк. Попробуйте ещё раз.",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "Ок", style: .default, handler: nil)
        alertController.addAction(okAction)

        // Презентуем алерт прямо от текущего viewController
        self.present(alertController, animated: true, completion: nil)
    }

    
    override func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        // Показ другого контроллера
        print("Presenting \(viewController) from ImagesListViewController")
        guard isViewLoaded, view.window != nil else {
            print("Cannot present: View controller is not in view hierarchy")
            completion?()
            return
        }
        super.present(viewController, animated: animated, completion: completion)
    }
}
// MARK: - UITableViewDataSource, UITableViewDelegate
extension ImagesListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Количество строк
        return presenter?.photos.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Ячейка для строки
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        )
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        imageListCell.delegate = self
        
        presenter?.configureCell(imageListCell, for: indexPath)
        return imageListCell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Перед отображением ячейки
        presenter?.willDisplayCell(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Выбор строки
        tableView.deselectRow(at: indexPath, animated: true)
        presenter?.didSelectRow(at: indexPath)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Высота ячейки
        guard let photo = presenter?.photos[indexPath.row],
              let imageWidth = photo.size.width as CGFloat?,
              let imageHeight = photo.size.height as CGFloat? else {
                  // Возвращаем 0, если данные отсутствуют
                  return 0
              }
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let cellWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = cellWidth / imageWidth
        let cellHeight = imageHeight * scale + imageInsets.top + imageInsets.bottom
        
        return cellHeight
    }
}


// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    func imageListCellDidTapLike(_ cell: ImagesListCell) {
        // Нажатие лайка
        presenter?.didTapLikeButton(cell)
    }
}
