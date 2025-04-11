import UIKit

final class UIBlockingProgressHUD {
    private static var blockingView: UIView?

    static func show() {
        guard let window = UIApplication.shared.windows.first else { return }

        let blocker = UIView(frame: window.bounds)
        blocker.backgroundColor = UIColor(white: 0, alpha: 0.3)
        blocker.isUserInteractionEnabled = true

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = blocker.center
        activityIndicator.startAnimating()

        blocker.addSubview(activityIndicator)
        window.addSubview(blocker)

        blockingView = blocker
    }

    static func dismiss() {
        blockingView?.removeFromSuperview()
        blockingView = nil
    }
}
