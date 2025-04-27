import XCTest
@testable import ImageFeed
@testable import ImageFeedUITests

class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var photos: [Photo] = []
    
    var viewDidLoadCalled: Bool = false
    var viewWillAppearCalled: Bool = false
    var didSelectRowCalled: Bool = false
    var willDisplayCellCalled: Bool = false
    var configureCellCalled: Bool = false
    var didTapLikeButtonCalled: Bool = false
    
    var didSelectRowAtIndexPath: IndexPath?
    var willDisplayCellAtIndexPath: IndexPath?
    
    func viewDidLoad() {
        viewDidLoadCalled = true
    }
    
    func viewWillAppear() {
        viewWillAppearCalled = true
    }
    
    func didSelectRow(at indexPath: IndexPath) {
        didSelectRowCalled = true
        didSelectRowAtIndexPath = indexPath
    }
    
    func willDisplayCell(at indexPath: IndexPath) {
        willDisplayCellCalled = true
        willDisplayCellAtIndexPath = indexPath
    }
    
    func configureCell(_ cell: ImagesListCell, for indexPath: IndexPath) {
        configureCellCalled = true
    }
    
    func didTapLikeButton(_ cell: ImagesListCell) {
        didTapLikeButtonCalled = true
    }
    


}
