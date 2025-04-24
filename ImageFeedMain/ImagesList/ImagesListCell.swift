import UIKit
import Kingfisher

protocol ImagesListCellDelegate: AnyObject {
    func imageListCellDidTapLike(_ cell: ImagesListCell)
}

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    weak var delegate: ImagesListCellDelegate?
    
    var animationLayers = Set<CALayer>()
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("prepareForReuse для ячейки \(self)")
        cellImage.kf.cancelDownloadTask()
        cellImage.image = nil
        // Удаляем все градиентные слои
        cellImage.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInImagesListCell" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем frame градиента при изменении размеров cellImage
        updateGradientFrame()
    }
    
    var isLiked: Bool = false {
        didSet {
            let imageName = isLiked ? "likeButtonOn" : "likeButtonOff"
            likeButton.setImage(UIImage(named: imageName), for: .normal)
        }
    }
    
    func setIsLiked(_ isLiked: Bool) {
        self.isLiked = isLiked
    }
    
    @IBAction func tapOnLike(_ sender: Any) {
        delegate?.imageListCellDidTapLike(self)
        //isLiked.toggle()
    }
    
    func addGradientIfNeeded() {
        print("addGradientIfNeeded, cellImage.image: \(cellImage.image != nil ? "не nil" : "nil"), cellImage.bounds: \(cellImage.bounds)")
        // Добавляем градиент, если нет картинки или это плейсхолдер
        if cellImage.image == nil || cellImage.image == UIImage(named: "Stub") {
            addGradient(to: cellImage, cornerRadius: 16)
        }
    }
    
    private func addGradient(to view: UIView, cornerRadius: CGFloat = 0) {
        print("Добавляем градиент для \(view)")
        // Удаляем старые градиенты
        view.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInImagesListCell" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
        
        let gradient = CAGradientLayer()
        gradient.name = "locationChangeInImagesListCell"
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
        gradient.locations = [-1, -0.5, 0]
        gradient.frame = view.bounds
        gradient.cornerRadius = cornerRadius
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = 2
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "locationChangeInImagesListCell")
        
        view.layer.addSublayer(gradient)
        animationLayers.insert(gradient)
    }
    
    func removeGradient() {
        // Удаляем градиент после загрузки картинки
        cellImage.layer.sublayers?.removeAll(where: { $0.name == "locationChangeInImagesListCell" })
        animationLayers.forEach { $0.removeFromSuperlayer() }
        animationLayers.removeAll()
    }
    
    private func updateGradientFrame() {
        // Обновляем frame всех градиентных слоёв
        for layer in animationLayers {
            if layer.name == "locationChangeInImagesListCell" {
                print("Обновляем frame градиента, новый bounds: \(cellImage.bounds)")
                layer.frame = cellImage.bounds
            }
        }
    }
}

//    var tapCount = 0
//    var tapResetTimer: Timer?
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//
//        // Создаём распознаватель двойного нажатия
//        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
//        doubleTap.numberOfTapsRequired = 2
//
//        cellImage.isUserInteractionEnabled = true
//        cellImage.addGestureRecognizer(doubleTap)
//    }
//
//    @objc private func didDoubleTap(gesture: UITapGestureRecognizer) {
//        // Получаем точку нажатия
//        let tapLocation = gesture.location(in: cellImage)
//
//        // Включаем лайк только если он еще не включен
//        if !isLiked {
//            isLiked = true
//        }
//
//        // Увеличиваем счётчик тапов
//        tapCount += 1
//
//        // Сбрасываем таймер, если тапов не было некоторое время
//        resetTapCountTimer()
//
//        // Анимация сердечка
//        showLikeAnimation(tapLocation: tapLocation)
//    }
//
//    private func showLikeAnimation(tapLocation: CGPoint) {
//        // Создаём сердечко с изображением
//        let heartImageView = UIImageView(image: UIImage(named: "like_button_on"))
//        heartImageView.contentMode = .scaleAspectFit
//
//        // Задаём размеры и положение сердечка в точке нажатия
//        heartImageView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        heartImageView.center = tapLocation
//        cellImage.addSubview(heartImageView)
//
//        // Анимация увеличения сердечка с наклоном
//        let scale: CGFloat = 1 + CGFloat(tapCount) * 0.2  // Увеличиваем с каждым нажатием
//        let angle: CGFloat = tapCount % 2 == 0 ? 0 : 0.3  // Наклоняем сердечко при четных нажатиях
//
//        UIView.animate(withDuration: 0.3, animations: {
//            heartImageView.alpha = 1
//            heartImageView.transform = CGAffineTransform(scaleX: scale, y: scale).rotated(by: angle)  // Наклон и увеличение
//        }) { _ in
//            // Плавно уменьшаем сердечко и делаем его прозрачным
//            UIView.animate(withDuration: 0.3, animations: {
//                heartImageView.alpha = 0
//                heartImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) // Уменьшаем сердечко
//            }) { _ in
//                heartImageView.removeFromSuperview()  // Удаляем после анимации
//            }
//        }
//
//        // Анимация для кнопки лайка
//        UIView.animate(withDuration: 0.2,
//                       delay: 0,
//                       usingSpringWithDamping: 0.5,
//                       initialSpringVelocity: 0.5,
//                       options: .curveEaseInOut,
//                       animations: {
//            self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
//            self.likeButton.alpha = 0.8
//        }) { _ in
//            UIView.animate(withDuration: 0.2) {
//                self.likeButton.transform = CGAffineTransform.identity
//                self.likeButton.alpha = 1.0
//            }
//        }
//    }
//
//    private func resetTapCountTimer() {
//        // Останавливаем старый таймер, если есть
//        tapResetTimer?.invalidate()
//
//        // Запускаем новый таймер, который сбросит счётчик после 1.5 секунд
//        tapResetTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(resetTapCount), userInfo: nil, repeats: false)
//    }
//
//    @objc private func resetTapCount() {
//        // Сбрасываем счётчик тапов
//        tapCount = 0
//    }
//}
