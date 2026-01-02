import UIKit
import Messages
import SwiftUI

class MessagesViewController: MSMessagesAppViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        presentContentView()
    }

    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
    }

    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        super.didStartSending(message, conversation: conversation)
    }

    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        super.didCancelSending(message, conversation: conversation)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        presentContentView()
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
    }

    private func presentContentView() {
        // Remove existing child view controllers
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let isExpanded = presentationStyle == .expanded
        let contentView = MessageContentView(
            isExpanded: isExpanded,
            onSendProgram: { [weak self] program in
                self?.sendProgram(program)
            },
            onRequestExpand: { [weak self] in
                self?.requestPresentationStyle(.expanded)
            }
        )

        let hostingController = UIHostingController(rootView: contentView)
        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func sendProgram(_ program: SharedProgram) {
        guard let conversation = activeConversation else { return }

        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = MSMessage(session: session)

        // Create message layout
        let layout = MSMessageTemplateLayout()
        layout.caption = program.name
        layout.subcaption = program.category
        layout.trailingCaption = "Free"
        layout.trailingSubcaption = "Bay Navigator"

        // Create a summary for the message body
        let summary = program.description.prefix(100)
        layout.image = createProgramImage(for: program)

        message.layout = layout
        message.summaryText = "\(program.name) - \(program.category)"

        // Create URL with program info for deep linking
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "id", value: program.id),
            URLQueryItem(name: "name", value: program.name),
            URLQueryItem(name: "category", value: program.category)
        ]
        message.url = components.url

        conversation.insert(message) { error in
            if let error = error {
                print("Failed to send message: \(error)")
            } else {
                // Collapse back to compact mode after sending
                self.requestPresentationStyle(.compact)
            }
        }
    }

    private func createProgramImage(for program: SharedProgram) -> UIImage? {
        // Create a simple colored image based on category
        let size = CGSize(width: 300, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)

        let categoryColor = getCategoryColor(program.category)

        return renderer.image { context in
            // Background
            categoryColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Add icon or text
            let icon = getCategoryIcon(program.category)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 60),
                .foregroundColor: UIColor.white
            ]
            let iconSize = icon.size(withAttributes: attributes)
            let iconRect = CGRect(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2 - 20,
                width: iconSize.width,
                height: iconSize.height
            )
            icon.draw(in: iconRect, withAttributes: attributes)

            // Add category label
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let label = program.category.uppercased()
            let labelSize = label.size(withAttributes: labelAttributes)
            let labelRect = CGRect(
                x: (size.width - labelSize.width) / 2,
                y: size.height - 40,
                width: labelSize.width,
                height: labelSize.height
            )
            label.draw(in: labelRect, withAttributes: labelAttributes)
        }
    }

    private func getCategoryColor(_ category: String) -> UIColor {
        switch category.lowercased() {
        case "food", "food assistance":
            return UIColor(red: 1.0, green: 0.44, blue: 0, alpha: 1) // Orange
        case "health", "healthcare":
            return UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1) // Red
        case "recreation", "activities":
            return UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1) // Purple
        case "community", "community services":
            return UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1) // Green
        case "education":
            return UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1) // Blue
        case "transportation":
            return UIColor(red: 0.05, green: 0.65, blue: 0.91, alpha: 1) // Sky
        default:
            return UIColor(red: 0.07, green: 0.55, blue: 0.53, alpha: 1) // Teal (primary)
        }
    }

    private func getCategoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "food", "food assistance":
            return "🍽️"
        case "health", "healthcare":
            return "❤️"
        case "recreation", "activities":
            return "🎫"
        case "community", "community services":
            return "👥"
        case "education":
            return "🎓"
        case "transportation":
            return "🚗"
        case "housing":
            return "🏠"
        case "financial assistance":
            return "💰"
        default:
            return "✨"
        }
    }
}
