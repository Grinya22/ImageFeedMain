import UIKit

class SingleImageViewController: UIViewController {
    var image: UIImage? {
        didSet {
            guard isViewLoaded, let image = image else { return }

            imageView.image = image
            imageView.frame.size = image.size

            rescaleAndCenterImageInScrollView(image: image)
        }
    }
    
    var imageURL: URL?
    
    @IBOutlet weak var placeholderStub: UIImageView!
//    lazy var placeholderStubLayer: CALayer = {
//        let layer = CALayer()
//        layer.contents = placeholderStub.layer.contents
//        layer.frame = placeholderStub.bounds
//        return layer
//    }()
    
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var animationLayers = Set<CALayer>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 0.1
        
        addGradient(to: placeholderStub)
        
        //setupActivityIndicator()
        
        if let image = image, imageURL == nil {
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
        } else if let url = imageURL {
            //imageView.image = UIImage(named: "Stub")
            //activityIndicator.startAnimating()

            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url),
                   let loadedImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView.image = loadedImage
                        self.imageView.frame.size = loadedImage.size
                        self.rescaleAndCenterImageInScrollView(image: loadedImage)
                        //self.activityIndicator.stopAnimating()
                        
                        // Удаление старых градиентов
                        self.animationLayers.forEach { $0.removeFromSuperlayer() }
                        self.animationLayers.removeAll()
                        
                        //self.placeholderStub.isHidden = true
                        
                        UIView.animate(withDuration: 0.3) {
                                self.placeholderStub.alpha = 0
                            } completion: { _ in
                                self.placeholderStub.isHidden = true
                            }

                    }
                } else {
                    DispatchQueue.main.async {
                        //self.activityIndicator.stopAnimating()
                        // можешь показать ошибку или картинку-заглушку
                        //self.imageView.image = UIImage(named: "Stub")
                    }
                }
            }
        }
    }
    
//    private func setupActivityIndicator() {
//            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//            view.addSubview(activityIndicator)
//            NSLayoutConstraint.activate([
//                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//            ])
//        }
    
    @IBAction func didTapBackButton(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapShareButton(_ sender: Any) {
        guard let image = imageView.image else { return }
        
        let activityController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        if #available(iOS 13.0, *) {
            activityController.overrideUserInterfaceStyle = .dark
        }
        
        present(activityController, animated: true)
    }

    private func rescaleAndCenterImageInScrollView(image: UIImage) {
        scrollView.layoutIfNeeded()

        let visibleSize = scrollView.bounds.size
        let imageSize = image.size

        // Высчитываем масштаб так, чтобы картинка заняла всю высоту экрана
        let scaleHight = visibleSize.height / imageSize.height
        
        let scaleWidth = (visibleSize.width - 32) / imageSize.width

        // Обновляем ограничения зума
        scrollView.minimumZoomScale = scaleWidth
        scrollView.maximumZoomScale = 3
        scrollView.zoomScale = scaleHight

        // Центрируем по ширине (если нужно)
        let contentSize = scrollView.contentSize
        let offsetX = max((contentSize.width - visibleSize.width) / 2, 0)
        let offsetY = max((contentSize.height - visibleSize.height) / 2, 0)

        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
    }

}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let insetX = max(0, (scrollView.bounds.width - scrollView.contentSize.width) / 2)
        let insetY = max(0, (scrollView.bounds.height - scrollView.contentSize.height) / 2)
        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
}

extension SingleImageViewController {
    private func addGradient(to view: UIView, cornerRadius: CGFloat = 0) {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
            UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1).cgColor,
            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor
        ]

        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)

        gradient.locations = [-1, -0.5, 0] // начальная позиция "белой полосы"
        gradient.frame = view.bounds
        
        //gradient.mask = placeholderStubLayer
        gradient.mask = view.layer
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "locationChangeInSingleImageViewController")

        //view.layer.addSublayer(gradient)
        view.superview?.layer.addSublayer(gradient)
        animationLayers.insert(gradient)
    }
}

