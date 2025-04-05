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
    
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let image = image else { return }
        
        scrollView.delegate = self
        imageView.image = image
        imageView.frame.size = image.size
        
        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
        scrollView.minimumZoomScale = visibleRectSize.width / imageSize.width
        
        scrollView.minimumZoomScale = visibleRectSize.width / imageSize.width
        scrollView.maximumZoomScale = 1.30
        
        rescaleAndCenterImageInScrollView(image: image)
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
        //let minZoomScale = scrollView.minimumZoomScale // 0.1
        let maxZoomScale = scrollView.maximumZoomScale  // был 1.25 стал 1.30 в 22 строке
        
        view.layoutIfNeeded()
//        Принудительно обновляет layout, если были какие-то изменения.
//         Зачем? Чтобы scrollView.bounds содержал актуальный размер экрана перед вычислениями.

        let visibleRectSize = scrollView.bounds.size
        let imageSize = image.size
        
//        visibleRectSize — размер UIScrollView, т.е. экран (например, 375x812 на iPhone 14 Pro).
//        imageSize — реальный размер картинки (например, 1000x1500 пикселей).
//         Зачем? Чтобы понять, насколько нужно уменьшить или увеличить картинку.
                
        //let wScale = imageSize.width / visibleRectSize.width //wScale — во сколько раз нужно увеличить картинку по ширине, чтобы она влезла на экран.
        let hScale = imageSize.height / visibleRectSize.height // hScale — то же самое, но по высоте.
        var scale = hScale
        
        if hScale < 1.1 {
            scale = 1.25 // был maxZoomScale
            
            var imageSizeAfterHScacle = imageSize.height / hScale

            if imageSizeAfterHScacle <= visibleRectSize.height && scale == 1.25 {
                imageSizeAfterHScacle = visibleRectSize.height
                scale = maxZoomScale
            }

        } else {
            scale = hScale
        }
        
        scrollView.setZoomScale(scale, animated: false)
        scrollView.layoutIfNeeded()
        
        let newContentSize = scrollView.contentSize
        let offsetX = (newContentSize.width - visibleRectSize.width) / 2
        let offsetY = (newContentSize.height - visibleRectSize.height) / 2
        
        scrollView.setContentOffset(CGPoint(x: offsetX, y: offsetY), animated: false)
//        setZoomScale(scale, animated: false) — применяет рассчитанный scale к scrollView.
//        layoutIfNeeded() — гарантирует, что contentSize пересчитается правильно.
//         Зачем? Чтобы scrollView обновил свой contentSize после масштабирования.
    
        scrollViewDidEndZooming(scrollView, with: imageView, atScale: scrollView.zoomScale)
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        let insetX = max(0, (scrollView.bounds.width - scrollView.contentSize.width) / 2)
        let insetY = max(0, (scrollView.bounds.height - scrollView.contentSize.height) / 2)

        scrollView.contentInset = UIEdgeInsets(top: insetY, left: insetX, bottom: insetY, right: insetX)
    }
}
