import UIKit
import Messages

/// Bay Navigator iMessage Extension
/// Allows users to share saved programs directly in Messages conversations
class MessagesViewController: MSMessagesAppViewController {

    // MARK: - Properties

    private let appGroupIdentifier = "group.org.baytides.navigator"
    private let favoritesKey = "shared_favorites"

    private var favorites: [[String: Any]] = []

    // UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(ProgramCell.self, forCellWithReuseIdentifier: "ProgramCell")
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private lazy var emptyStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: "heart.slash"))
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .light)

        let titleLabel = UILabel()
        titleLabel.text = "No Saved Programs"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label

        let subtitleLabel = UILabel()
        subtitleLabel.text = "Save programs in Bay Navigator to share them here"
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let openAppButton = UIButton(type: .system)
        openAppButton.setTitle("Open Bay Navigator", for: .normal)
        openAppButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        openAppButton.addTarget(self, action: #selector(openMainApp), for: .touchUpInside)

        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(openAppButton)

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])

        return view
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: UIImage(systemName: "sparkles"))
        iconView.tintColor = UIColor(red: 0.35, green: 0.50, blue: 0.92, alpha: 1.0) // App primary color
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Share a Program"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(iconView)
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadFavorites()
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        loadFavorites()
        updateUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(headerView)
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 44),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyStateView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func loadFavorites() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            favorites = []
            return
        }

        favorites = defaults.array(forKey: favoritesKey) as? [[String: Any]] ?? []
    }

    private func updateUI() {
        let hasFavorites = !favorites.isEmpty
        collectionView.isHidden = !hasFavorites
        emptyStateView.isHidden = hasFavorites
        collectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func openMainApp() {
        if let url = URL(string: "baynavigator://favorites") {
            extensionContext?.open(url)
        }
    }

    private func shareProgram(_ program: [String: Any]) {
        guard let conversation = activeConversation else { return }

        // Create a message with the program info
        let layout = MSMessageTemplateLayout()

        let name = program["name"] as? String ?? "Program"
        let category = program["category"] as? String ?? ""
        let description = program["description"] as? String ?? ""

        layout.caption = name
        layout.subcaption = category
        layout.trailingCaption = "Bay Navigator"

        // Use app icon as image placeholder
        if let image = UIImage(systemName: "sparkles.rectangle.stack") {
            layout.image = image
        }

        let message = MSMessage()
        message.layout = layout

        // Include program data in URL for deep linking
        var components = URLComponents()
        components.scheme = "baynavigator"
        components.host = "program"
        components.path = "/\(program["id"] as? String ?? "")"
        message.url = components.url

        // Add summary text
        message.summaryText = "\(name) - \(category)"

        conversation.insert(message) { error in
            if let error = error {
                print("[BayNavigatorMessages] Error inserting message: \(error)")
            }
        }

        // Dismiss to compact mode after sending
        dismiss()
    }
}

// MARK: - UICollectionViewDataSource

extension MessagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return favorites.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProgramCell", for: indexPath) as! ProgramCell
        cell.configure(with: favorites[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MessagesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        shareProgram(favorites[indexPath.item])
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MessagesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.bounds.height - 32 // Account for insets
        return CGSize(width: min(200, view.bounds.width * 0.6), height: max(100, height))
    }
}

// MARK: - Program Cell

class ProgramCell: UICollectionViewCell {
    private let nameLabel = UILabel()
    private let categoryLabel = UILabel()
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        iconView.tintColor = UIColor(red: 0.35, green: 0.50, blue: 0.92, alpha: 1.0)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        categoryLabel.font = .systemFont(ofSize: 13)
        categoryLabel.textColor = .secondaryLabel
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false

        let shareIcon = UIImageView(image: UIImage(systemName: "paperplane.circle.fill"))
        shareIcon.tintColor = UIColor(red: 0.35, green: 0.50, blue: 0.92, alpha: 1.0)
        shareIcon.contentMode = .scaleAspectFit
        shareIcon.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(shareIcon)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            categoryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            categoryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            categoryLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            shareIcon.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            shareIcon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            shareIcon.widthAnchor.constraint(equalToConstant: 24),
            shareIcon.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(with program: [String: Any]) {
        nameLabel.text = program["name"] as? String ?? ""
        categoryLabel.text = program["category"] as? String ?? ""

        // Set category icon
        let category = (program["category"] as? String ?? "").lowercased()
        let iconName: String
        switch category {
        case "food", "food assistance":
            iconName = "fork.knife"
        case "health", "healthcare":
            iconName = "heart.fill"
        case "housing":
            iconName = "house.fill"
        case "utilities":
            iconName = "bolt.fill"
        case "transportation":
            iconName = "bus.fill"
        case "education":
            iconName = "book.fill"
        case "employment":
            iconName = "briefcase.fill"
        case "legal":
            iconName = "scale.3d"
        default:
            iconName = "star.fill"
        }
        iconView.image = UIImage(systemName: iconName)
    }
}
