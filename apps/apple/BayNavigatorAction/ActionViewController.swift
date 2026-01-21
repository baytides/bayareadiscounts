import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!

    private let resultLabel = UILabel()
    private let searchButton = UIButton(type: .system)
    private var extractedText: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        extractContent()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Navigation bar
        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        let navItem = UINavigationItem(title: "Bay Navigator")
        navItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelAction)
        )
        navBar.items = [navItem]

        // Result label
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .center
        resultLabel.font = .systemFont(ofSize: 16)
        resultLabel.textColor = .secondaryLabel
        resultLabel.text = "Analyzing content..."
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultLabel)

        // Search button
        searchButton.setTitle("Search Programs", for: .normal)
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.backgroundColor = UIColor(red: 0.22, green: 0.36, blue: 0.49, alpha: 1.0)
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.tintColor = .white
        searchButton.layer.cornerRadius = 12
        searchButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        searchButton.isHidden = true
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchButton)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            resultLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            resultLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            searchButton.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 24),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 200),
            searchButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    private func extractContent() {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            showNoContent()
            return
        }

        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else { continue }

            for attachment in attachments {
                // Handle text
                if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
                        DispatchQueue.main.async {
                            if let text = item as? String {
                                self?.handleExtractedText(text)
                            }
                        }
                    }
                    return
                }

                // Handle URL
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] item, error in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.handleExtractedText(url.absoluteString)
                            }
                        }
                    }
                    return
                }
            }
        }

        showNoContent()
    }

    private func handleExtractedText(_ text: String) {
        extractedText = text

        // Detect keywords related to social services
        let keywords = ["food", "housing", "health", "medical", "job", "employment", "legal", "assistance", "help", "benefit", "calfresh", "medi-cal", "snap"]

        let lowerText = text.lowercased()
        let matchedKeywords = keywords.filter { lowerText.contains($0) }

        if !matchedKeywords.isEmpty {
            resultLabel.text = "Found relevant keywords:\n\(matchedKeywords.joined(separator: ", "))\n\nSearch Bay Navigator for related programs?"
        } else {
            let truncated = text.count > 100 ? String(text.prefix(100)) + "..." : text
            resultLabel.text = "Selected text:\n\"\(truncated)\"\n\nSearch for related programs?"
        }

        searchButton.isHidden = false
    }

    private func showNoContent() {
        resultLabel.text = "No text content found to search."
        resultLabel.textColor = .systemRed
    }

    @objc private func cancelAction() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    @objc private func searchAction() {
        guard let text = extractedText else {
            cancelAction()
            return
        }

        // Save for later and open app
        let defaults = UserDefaults(suiteName: "group.org.baytides.navigator")
        defaults?.set(text, forKey: "pendingSearch")

        // Open the app with search query
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "baynavigator://search?q=\(encoded)") {
            openURL(url)
        }

        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
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
