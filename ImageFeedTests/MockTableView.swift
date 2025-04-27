import XCTest

class MockTableView: UITableView {
    var performBatchUpdatesCalled: Bool = false
    
    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        performBatchUpdatesCalled = true
        updates?()
        completion?(true)
    }
}
