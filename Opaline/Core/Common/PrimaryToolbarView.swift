import UIKit

struct PrimaryToolbarActions {
    let search: Selector
    let notifications: Selector
    let settings: Selector
    let profile: Selector
}

/// Content-first root toolbar shared by Home, Subscriptions and Library.
/// The search affordance gets the flexible space; utility actions keep
/// Apple-sized 44pt hit targets at the trailing edge.
final class PrimaryToolbarView: UIView {
    private let searchButton = UIButton(type: .system)
    private let bellButton = NotificationsBellButton()
    private let settingsButton = UIButton(type: .system)
    private let profileButton = ProfileAvatarButton()

    init(target: Any, actions: PrimaryToolbarActions) {
        super.init(frame: .zero)
        setupSearch(target: target, action: actions.search)
        setupBell(target: target, action: actions.notifications)
        setupSettings(target: target, action: actions.settings)
        setupProfile(target: target, action: actions.profile)
        setupLayout()
        applyTheme()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyTheme),
            name: ThemeManager.didChangeNotification,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let width = UIDevice.current.userInterfaceIdiom == .pad
            ? min(screenWidth - 32, 680)
            : max(296, screenWidth - 24)
        return CGSize(width: width, height: 44)
    }

    func refreshProfile() {
        profileButton.refresh()
    }

    private func setupSearch(target: Any, action: Selector) {
        searchButton.setImage(
            resizedNavBarIcon("icon_Magnifyingglass", size: 20),
            for: .normal
        )
        searchButton.setTitle("search.placeholder".localized, for: .normal)
        searchButton.titleLabel?.font = .systemFont(ofSize: 15)
        searchButton.contentHorizontalAlignment = .left
        searchButton.contentEdgeInsets = UIEdgeInsets(
            top: 0, left: 14, bottom: 0, right: 14
        )
        searchButton.titleEdgeInsets = UIEdgeInsets(
            top: 0, left: 8, bottom: 0, right: -8
        )
        searchButton.layer.cornerRadius = 20
        searchButton.clipsToBounds = true
        searchButton.accessibilityLabel = "search.placeholder".localized
        searchButton.addTarget(target, action: action, for: .touchUpInside)
        searchButton.addTapFeedback()
    }

    private func setupBell(target: Any, action: Selector) {
        bellButton.accessibilityLabel = "notifications.title".localized
        bellButton.addTarget(target, action: action, for: .touchUpInside)
        bellButton.addTapFeedback()
    }

    private func setupSettings(target: Any, action: Selector) {
        settingsButton.setImage(
            resizedNavBarIcon("icon_Gear", size: 22),
            for: .normal
        )
        settingsButton.accessibilityLabel = "settings.title".localized
        settingsButton.addTarget(target, action: action, for: .touchUpInside)
        settingsButton.addTapFeedback()
    }

    private func setupProfile(target: Any, action: Selector) {
        profileButton.accessibilityLabel = UserProfileStore.shared.displayName
            ?? "profile.title".localized
        profileButton.addTarget(target, action: action, for: .touchUpInside)
        profileButton.addTapFeedback()
    }

    private func setupLayout() {
        for child in [searchButton, bellButton, settingsButton, profileButton] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
        }
        let searchMinimum = searchButton.widthAnchor.constraint(
            greaterThanOrEqualToConstant: 120
        )
        searchMinimum.priority = .defaultHigh
        NSLayoutConstraint.activate([
            searchButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            searchButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchButton.heightAnchor.constraint(equalToConstant: 40),
            searchMinimum,

            bellButton.leadingAnchor.constraint(
                equalTo: searchButton.trailingAnchor,
                constant: 4
            ),
            bellButton.centerYAnchor.constraint(equalTo: centerYAnchor),

            settingsButton.leadingAnchor.constraint(equalTo: bellButton.trailingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),

            profileButton.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor),
            profileButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            profileButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @objc
    private func applyTheme() {
        let theme = ThemeManager.shared
        searchButton.backgroundColor = theme.controlSurface
        searchButton.tintColor = theme.primaryText
        searchButton.setTitleColor(theme.secondaryText, for: .normal)
        settingsButton.tintColor = theme.primaryText
    }
}
