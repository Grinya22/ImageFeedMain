import UIKit
import Kingfisher

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
    
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var animationLayers = Set<CALayer>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 0.1
        
        placeholderStub.isHidden = false
        placeholderStub.alpha = 1.0
        
        scrollView.bringSubviewToFront(placeholderStub)
        
        scrollView.contentSize = view.bounds.size
        scrollView.contentOffset = .zero
        
        print("scrollView.subviews: \(scrollView.subviews.map { $0.description })")
        print("scrollView.bounds: \(scrollView.bounds)")
        print("scrollView.contentSize: \(scrollView.contentSize)")
        print("scrollView.contentOffset: \(scrollView.contentOffset)")
        print("placeholderStub.frame: \(placeholderStub.frame)")
        print("placeholderStub.isHidden: \(placeholderStub.isHidden)")
        print("placeholderStub.alpha: \(placeholderStub.alpha)")
        
        DispatchQueue.main.async {
            self.addGradient(to: self.placeholderStub)
            self.view.setNeedsDisplay()
            self.view.layoutIfNeeded()
        }
        
        if let image = image, imageURL == nil {
            imageView.image = image
            imageView.frame.size = image.size
            rescaleAndCenterImageInScrollView(image: image)
            removeGradient()
            placeholderStub.isHidden = true
        } else if let url = imageURL {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.imageView.kf.setImage(
                    with: url,
                    placeholder: nil,
                    options: [
                        .transition(.fade(0.3)),
                        .forceRefresh,
                        .forceTransition,
                        .cacheMemoryOnly
                    ]
                ) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let value):
                        self.imageView.image = value.image
                        self.imageView.frame.size = value.image.size
                        self.rescaleAndCenterImageInScrollView(image: value.image)
                        self.activityIndicator.stopAnimating()
                        
                        self.removeGradient()
                        UIView.animate(withDuration: 0.3) {
                            self.placeholderStub.alpha = 0
                        } completion: { _ in
                            self.placeholderStub.isHidden = true
                        }
                    case .failure(let error):
                        print("Ошибка загрузки изображения: \(error)")
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("viewDidLayoutSubviews, placeholderStub.bounds: \(placeholderStub.bounds)")
        updateGradientFrame()
    }
    
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
        
        let scaleHeight = visibleSize.height / imageSize.height
        let scaleWidth = (visibleSize.width - 32) / imageSize.width
        
        scrollView.minimumZoomScale = scaleWidth
        scrollView.maximumZoomScale = 3
        scrollView.zoomScale = scaleHeight
        
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
    private func addGradient(to view: UIImageView, cornerRadius: CGFloat = 0) {
        print("Добавляем градиент для \(view), bounds: \(view.bounds)")
        
        // Очищаем существующие слои
        view.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInSingleImageViewController" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
        
        // Создаём градиент
        let gradient = CAGradientLayer()
        gradient.name = "locationChangeInSingleImageViewController"
//        gradient.colors = [
//            UIColor.red.cgColor, // Контрастные цвета для теста
//            UIColor.blue.cgColor,
//            UIColor.red.cgColor
//        ]
//        gradient.colors = [
//            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor,
//            UIColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 1).cgColor,
//            UIColor(red: 0.682, green: 0.686, blue: 0.706, alpha: 1).cgColor
//        ]
        gradient.colors = [
            UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1).cgColor, // Яркий серо-голубой
            UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1).cgColor, // Белый с голубым оттенком
            UIColor(red: 0.5, green: 0.6, blue: 0.8, alpha: 1).cgColor // Возвращаемся к первому
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = view.bounds
        gradient.locations = [-1, -0.5, 0] // Как в ячейках
        
        // Анимация для градиента
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 2.0 // Как в ячейках
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        // Временно отключаем маску для теста
        
        if let image = view.image {
            print("Изображение placeholderStub: \(image.size)")
            let maskLayer = CALayer()
            maskLayer.name = "maskLayerInSingleImageViewController"
            maskLayer.contents = image.cgImage
            maskLayer.frame = view.bounds
            
            if let cgImage = image.cgImage, cgImage.alphaInfo != .none {
                print("Изображение имеет альфа-канал: \(cgImage.alphaInfo.rawValue)")
            } else {
                print("Изображение не имеет альфа-канала")
            }
            
            gradient.mask = maskLayer
            animationLayers.insert(maskLayer)
        } else {
            print("placeholderStub.image is nil")
        }
        
        
        gradient.add(animation, forKey: "locationChangeInSingleImageViewController")
        
        if gradient.animation(forKey: "locationChangeInSingleImageViewController") != nil {
            print("Анимация градиента успешно добавлена")
        } else {
            print("Анимация градиента НЕ добавлена")
        }
        
        view.layer.addSublayer(gradient)
        animationLayers.insert(gradient)
        
        // Принудительно обновляем слой
        view.layer.setNeedsDisplay()
    }
    
    private func removeGradient() {
        print("Убираем градиент, слои до: \(placeholderStub.layer.sublayers?.map { $0.name ?? "без имени" } ?? [])")
        placeholderStub.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInSingleImageViewController" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
        print("Слои после: \(placeholderStub.layer.sublayers?.map { $0.name ?? "без имени" } ?? [])")
    }
    
    private func updateGradientFrame() {
        for layer in animationLayers {
            if layer.name == "locationChangeInSingleImageViewController" {
                print("Обновляем frame градиента, новый bounds: \(placeholderStub.bounds), layer.frame перед: \(layer.frame)")
                layer.frame = placeholderStub.bounds
                layer.mask?.frame = placeholderStub.bounds
                print("layer.frame после: \(layer.frame)")
            } else if layer.name == "maskLayerInSingleImageViewController" {
                print("Обновляем frame маски, новый bounds: \(placeholderStub.bounds), layer.frame перед: \(layer.frame)")
                layer.frame = placeholderStub.bounds
                print("layer.frame после: \(layer.frame)")
            }
        }
    }
}
