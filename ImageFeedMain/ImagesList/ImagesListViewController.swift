import UIKit

class ImagesListViewController: UIViewController {
    
    @IBOutlet private var tableView: UITableView!
    
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.delegate = self
//        tableView.dataSource = self
        
        tableView.rowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left:0, bottom: 12, right: 0)
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { // определяет количество ячеек в секции таблицы
        return photosName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { // возвращает ячейку
        let cell = tableView.dequeueReusableCell(withIdentifier: ImagesListCell.reuseIdentifier, for: indexPath)
        
//        Возвращаемая ячейка из метода выше имеет тип UITableViewCell. Но нам нужно работать именно с нашей кастомной ячейкой ImagesListCell, чтобы получить доступ к её специфичным свойствам и методам. Поэтому используется конструкция guard let, которая пытается привести ячейку к типу ImagesListCell.
        
        guard let imageListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        
        imageListCell.isLiked = false
        
        configCell(for: imageListCell, with: indexPath)
        return imageListCell
    }
    
//    По такому принципу этот метод работает для любой таблицы. Сначала нам нужно получить ячейку для определённой секции и позиции в секции, далее — привести её к нужному типу, чтобы работать с ячейкой, сконфигурировать её и вернуть ячейку из метода.
    
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        let photoName = photosName[indexPath.row]
        
        guard let image = UIImage(named: photoName) else {
            return
        }
        cell.cellImage.image = image
        
        cell.dataLabel.text = dateFormatter.string(from: Date())
//
//        if indexPath.row % 2 == 0 {
//            cell.likeButton.setImage(UIImage(named: "like_button_on"), for: .normal)
//        } else {
//            cell.likeButton.setImage(UIImage(named: "like_button_off"), for: .normal)
//        }
//
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let image = UIImage(named: photosName[indexPath.row]) else {
            return 0
        }
        
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)

        let imageWidth = image.size.width
        let imageHeight = image.size.height

        let cellWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let scale = cellWidth / imageWidth

        let cellHeight = imageHeight * scale + imageInsets.top + imageInsets.bottom

        return cellHeight

    }
}
