import UIKit

final class ImagesListCell: UITableViewCell {
    static let reuseIdentifier = "ImagesListCell"
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var dataLabel: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    
    var isLiked: Bool = false {
        didSet {
            let imageName = isLiked ? "likeButtonOn" : "likeButtonOff"
            likeButton.setImage(UIImage(named: imageName), for: .normal)
        }
    }
    

    
    @IBAction func tapOnLike(_ sender: Any) {
        isLiked.toggle()
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
