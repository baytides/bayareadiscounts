import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    // MARK: - Properties

    private let containerView = UIView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let iconImageView = UIImageView()
    private let closeButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var sharedURL: URL?
    private var sharedText: String?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        // Container
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowRadius = 10
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)

        // Header
        headerView.backgroundColor = UIColor(red: 0.22, green: 0.36, blue: 0.49, alpha: 1.0) // App primary color
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(headerView)

        // Icon
        iconImageView.image = UIImage(systemName: "building.2.crop.circle.fill")
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(iconImageView)

        // Title
        titleLabel.text = "Save to Bay Navigator"
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        // Close button
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white.withAlphaComponent(0.8)
        closeButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(closeButton)

        // Subtitle
        subtitleLabel.text = "Analyzing shared content..."
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 3
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)

        // Activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)
        activityIndicator.startAnimating()

        // Save button
        saveButton.setTitle("Save Program", for: .normal)
        saveButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        saveButton.backgroundColor = UIColor(red: 0.22, green: 0.36, blue: 0.49, alpha: 1.0)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.tintColor = .white
        saveButton.layer.cornerRadius = 12
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        saveButton.isHidden = true
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(saveButton)

        // Constraints
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 320),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            iconImageView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -12),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            subtitleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            activityIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            saveButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            saveButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            saveButton.heightAnchor.constraint(equalToConstant: 48),
            saveButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])

        // Rounded corners for header
        headerView.layer.cornerRadius = 16
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }

    // MARK: - Content Extraction

    private func extractSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showError("No content to share")
            return
        }

        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let url = item as? URL {
                            self?.sharedURL = url
                            self?.processSharedURL(url)
                        } else if let urlData = item as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                            self?.sharedURL = url
                            self?.processSharedURL(url)
                        }
                    }
                }
                return
            }

            if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                    DispatchQueue.main.async {
                        if let text = item as? String {
                            self?.sharedText = text
                            self?.processSharedText(text)
                        }
                    }
                }
                return
            }
        }

        showError("Unsupported content type")
    }

    private func processSharedURL(_ url: URL) {
        activityIndicator.stopAnimating()

        // Check if it's a Bay Navigator URL or external URL
        if url.host?.contains("baynavigator") == true || url.host?.contains("baytides") == true {
            // It's from our own site - extract program info
            if let programId = extractProgramId(from: url) {
                subtitleLabel.text = "Ready to save this program to your favorites"
                saveButton.isHidden = false
            } else {
                subtitleLabel.text = "URL: \(url.absoluteString)\n\nThis link will be saved for later reference."
                saveButton.setTitle("Save Link", for: .normal)
                saveButton.isHidden = false
            }
        } else {
            // External URL - save as a note/reference
            subtitleLabel.text = "External link:\n\(url.host ?? url.absoluteString)\n\nOpen Bay Navigator to search for related programs."
            saveButton.setTitle("Open Bay Navigator", for: .normal)
            saveButton.isHidden = false
        }
    }

    private func processSharedText(_ text: String) {
        activityIndicator.stopAnimating()

        // Try to extract a URL from the text
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let match = detector.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           let url = match.url {
            sharedURL = url
            processSharedURL(url)
            return
        }

        // Plain text - suggest searching
        let truncatedText = text.count > 100 ? String(text.prefix(100)) + "..." : text
        subtitleLabel.text = "Search Bay Navigator for:\n\"\(truncatedText)\""
        saveButton.setTitle("Search Programs", for: .normal)
        saveButton.isHidden = false
    }

    private func extractProgramId(from url: URL) -> String? {
        // Parse URL path for program ID
        // e.g., /programs/abc123 or /p/abc123
        let pathComponents = url.pathComponents
        if let programIndex = pathComponents.firstIndex(where: { $0 == "programs" || $0 == "p" }),
           programIndex + 1 < pathComponents.count {
            return pathComponents[programIndex + 1]
        }
        return url.queryParameters?["id"]
    }

    private func showError(_ message: String) {
        activityIndicator.stopAnimating()
        subtitleLabel.text = message
        subtitleLabel.textColor = .systemRed

        // Auto-dismiss after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.cancelAction()
        }
    }

    // MARK: - Actions

    @objc private func cancelAction() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @objc private func saveAction() {
        // Save to shared UserDefaults
        let defaults = UserDefaults(suiteName: "group.org.baytides.navigator")

        if let url = sharedURL {
            // Save shared URL
            var savedURLs = defaults?.stringArray(forKey: "sharedURLs") ?? []
            savedURLs.insert(url.absoluteString, at: 0)
            savedURLs = Array(savedURLs.prefix(50)) // Keep last 50
            defaults?.set(savedURLs, forKey: "sharedURLs")

            // If it's a program URL, add to favorites
            if let programId = extractProgramId(from: url) {
                var favorites = defaults?.stringArray(forKey: "favoriteIds") ?? []
                if !favorites.contains(programId) {
                    favorites.append(programId)
                    defaults?.set(favorites, forKey: "favoriteIds")
                    defaults?.set(favorites.count, forKey: "favoriteCount")
                }
            }
        }

        if let text = sharedText, sharedURL == nil {
            // Save search query
            var savedQueries = defaults?.stringArray(forKey: "sharedQueries") ?? []
            savedQueries.insert(text, at: 0)
            savedQueries = Array(savedQueries.prefix(20))
            defaults?.set(savedQueries, forKey: "sharedQueries")
        }

        // Show success feedback
        saveButton.setTitle("Saved!", for: .normal)
        saveButton.backgroundColor = UIColor.systemGreen
        saveButton.isEnabled = false

        // Open app if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let url = self?.sharedURL, let programId = self?.extractProgramId(from: url) {
                // Open directly to program
                self?.openURL(URL(string: "baynavigator://program/\(programId)")!)
            } else if let text = self?.sharedText {
                // Open to search
                let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                self?.openURL(URL(string: "baynavigator://search?q=\(encoded)")!)
            }

            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = responder?.next
        }
    }
}

// MARK: - URL Extension

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return nil
        }

        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        return params
    }
}
