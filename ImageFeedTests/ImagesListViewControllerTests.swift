import XCTest
@testable import ImageFeed
@testable import ImageFeedUITests

class ImagesListViewControllerTests: XCTestCase {
    private var viewController: ImagesListViewController?
    private var presenterSpy: ImagesListPresenterSpy!
        
    override func setUp() {
        super.setUp()
        // Инициализируем презентер-шпион перед созданием контроллера
        presenterSpy = ImagesListPresenterSpy()
        
        // Создаём viewController и передаём презентер-шпион в качестве зависимости
        viewController = ImagesListViewController(presenter: presenterSpy)
        
        // Инициализируем tableView раньше, чтобы избежать использования неинициализированной таблицы
        let tableView = UITableView(frame: .zero, style: .plain)
        viewController?.tableView = tableView
        
        // Загружаем view контроллера, чтобы инициализировать UI элементы
        _ = viewController?.view
    }
    
    override func tearDown() {
        // Очищаем объекты после завершения теста
        viewController = nil
        presenterSpy = nil
        super.tearDown()
    }
    
    func testViewDidLoad_CallsPresenterViewDidLoad() {
//        Что проверяет: Этот тест проверяет, вызывается ли метод viewDidLoad презентера при загрузке представления (view) контроллера.
//        Что делает: Когда вызывается viewController?.viewDidLoad(), тест проверяет, был ли вызван метод viewDidLoad в презентере, который должен быть уведомлен о загрузке представления.
        
        // when
        viewController?.viewDidLoad()
        
        // then
        XCTAssertTrue(presenterSpy.viewDidLoadCalled)
    }
    
    func testViewWillAppear_CallsPresenterViewWillAppear() {
//        Что проверяет: Этот тест проверяет, что при появлении представления (метод viewWillAppear) вызывается соответствующий метод презентера.
//        Что делает: Когда вызывается viewController?.viewWillAppear(true), тест проверяет, был ли вызван метод viewWillAppear презентера.
        
        //when
        viewController?.viewWillAppear(true)

        //then
        XCTAssertTrue(presenterSpy.viewWillAppearCalled)
    }
    
    func testUpdateTableView_InsertsRows_WhenOldCountLessThanNewCount() {
//        Что проверяет: Этот тест проверяет, что при изменении количества элементов в таблице (с 2 на 5) происходит корректное обновление таблицы с вставкой новых строк.
//        Что делает: Метод updateTableView(oldCount: 2, newCount: 5) проверяет, были ли вызваны обновления таблицы, и через ожидание (с использованием XCTestExpectation) проверяется, что вызов метода performBatchUpdates был сделан, что свидетельствует о правильном обновлении таблицы.
        
        // given
        let tableView = MockTableView()
        viewController?.tableView = tableView
        
        // when
        viewController?.updateTableView(oldCount: 2, newCount: 5)

        // Создаем ожидание, что обновления завершатся через 10 секунд
        let expectation = XCTestExpectation(description: "Wait for table updates")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            // then
            XCTAssertTrue(tableView.performBatchUpdatesCalled)
            expectation.fulfill()  // Завершаем ожидание
        }

        // Ожидаем, пока не пройдет 10 секунд или не будет выполнено ожидание
        wait(for: [expectation], timeout: 12)
    }

    
    func testShowErrorAlert_PresentsAlertController() {
//        Что проверяет: Этот тест проверяет, что при вызове метода showErrorAlert появляется алерт с правильным сообщением.
//        Что делает: Когда вызывается viewController?.showErrorAlert(), тест проверяет, что отображается алерт с ожидаемым титулом "Что-то пошло не так". Если алерт не появляется, тест завершится с ошибкой (XCTFail).
        
        // given
        let expectation = XCTestExpectation(description: "Wait for alert to be presented")
//        XCTestExpectation — это объект, который используется для ожидания выполнения какого-то действия в асинхронных тестах. Он сообщает тестовому фреймворку, что тест должен подождать, пока не будет выполнено определённое событие (например, появление алерта).
//        description — описание ожидания, которое поможет понять, что именно тест ожидает. Это описание будет видно в выводах теста и поможет легче понять, что происходит.
        
        // Ensure viewController is properly in the view hierarchy
        let window = UIWindow()
        window.rootViewController = viewController
        window.makeKeyAndVisible()

        // when
        viewController?.showErrorAlert()

        // then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            DispatchQueue.main.asyncAfter(deadline:) — используется для задержки выполнения кода на главной очереди. Мы добавляем небольшую задержку (0.2 секунды), чтобы убедиться, что алерт действительно будет представлен в момент, когда тест начнется проверку. Это важно, потому что отображение алерта может занять немного времени, и без этой задержки тест может проверить состояние до того, как алерт будет показан.
            if let presented = self.viewController?.presentedViewController as? UIAlertController {
                print("Alert presented: \(presented.title ?? "nil")") // добавляем логирование
                XCTAssertNotNil(presented)
                XCTAssertEqual(presented.title, "Что-то пошло не так")
            } else {
                XCTFail("Alert controller was not presented")
            }
            expectation.fulfill()  // Завершаем ожидание, когда алерт будет найден
        }

        // Ожидаем появления алерта
        wait(for: [expectation], timeout: 2)
//        Это основной метод, который заставляет тест "ждать". Функция wait заставляет тест ждать, пока не будет вызван fulfill() на соответствующем ожидании (в нашем случае это expectation). Пока этого не произойдёт, тест не завершится.
//        timeout: 2 — означает, что тест будет ожидать 2 секунды, прежде чем завершится с ошибкой, если алерт не был представлен. Если по истечении времени ожидания алерт не появился, тест завершится с ошибкой.
    }
    
    func testDidSelectRow_CallsPresenterDidSelectRow() {
//        Что проверяет: Этот тест проверяет, что при выборе строки в таблице вызывается метод презентера, который сообщает о выбранной строке.
//        Что делает: Когда вызывается метод didSelectRowAt, тест проверяет, что презентер получил правильный indexPath (индекс выбранной строки).
        
        // given
        let indexPath = IndexPath(row: 0, section: 0)
        
        // when
        guard let viewController = viewController else { return }
        guard let _ = viewController.tableView else { return }
        viewController.tableView(viewController.tableView, didSelectRowAt: indexPath)
        
        // then
        XCTAssertEqual(presenterSpy.didSelectRowAtIndexPath, indexPath)
        
    }
    
    func testWillDisplayCell_CallsPresenterWillDisplayCell() {
//        Что проверяет: Этот тест проверяет, что при отображении ячейки таблицы (метод willDisplayCell) презентер получает уведомление о том, какая ячейка будет отображена.
//        Что делает: Когда вызывается метод willDisplay для ячейки, тест проверяет, что презентер получает правильный indexPath для этой ячейки.
        
        // given
        let cell = UITableViewCell()
        let indexPath = IndexPath(row: 0, section: 0)
        
        // when
        guard let viewController = viewController else { return }
        guard let _ = viewController.tableView else { return }
        viewController.tableView(viewController.tableView, willDisplay: cell, forRowAt: indexPath)
        
        // then
        XCTAssertEqual(presenterSpy.willDisplayCellAtIndexPath, indexPath)
    }
    
    func testCellForRow_ConfiguresCell() {
//        Что проверяет: Этот тест проверяет, что при запросе ячейки таблицы, она правильно настраивается и соответствует ожидаемому типу (например, у нее есть делегат, которым является ImagesListViewController).
//        Что делает: Когда запрашивается ячейка с индексом indexPath, тест проверяет, что ячейка (в данном случае ImagesListCell) правильно инициализируется и настроена, а также что делегат ячейки указывает на контроллер.
        
        // given
        let indexPath = IndexPath(row: 0, section: 0)
        guard let viewController = viewController else { return }
        guard let _ = viewController.tableView else { return }
        viewController.tableView.register(ImagesListCell.self, forCellReuseIdentifier: ImagesListCell.reuseIdentifier)
        
        // when
        let cell = viewController.tableView(viewController.tableView, cellForRowAt: indexPath) as? ImagesListCell
        
        // then
        XCTAssertNotNil(cell)
        XCTAssertTrue(cell?.delegate is ImagesListViewController)
    }
    
    func testImageListCellDidTapLike_CallsPresenterDidTapLikeButton() {
//        Что проверяет: Этот тест проверяет, что при нажатии на кнопку "лайк" в ячейке вызывается метод презентера для обработки этого события.
//        Что делает: Когда вызывается метод imageListCellDidTapLike(cell), тест проверяет, что презентер получил уведомление о нажатии кнопки "лайк".
        
        // given
        let cell = ImagesListCell()

        
        // when
        viewController?.imageListCellDidTapLike(cell)
        
        // then
        XCTAssertTrue(presenterSpy.didTapLikeButtonCalled)

    }
}
