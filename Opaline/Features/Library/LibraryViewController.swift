import UIKit

/// Library screen with a secondary segmented bar below the shared toolbar.
/// Three embedded child nav controllers switch without changing navigation.
final class LibraryViewController: UIViewController {
    // MARK: - Segments

    private enum Segment: Int, CaseIterable {
        case history   = 0
        case downloads = 1
        case playlists = 2

        var title: String {
            switch self {
            case .history:
                return "library.history".localized
            case .downloads:
                return "library.downloads".localized
            case .playlists:
                return "library.playlists".localized
            }
        }
    }

    private let dependencies: AppDependencies

    // MARK: - Child nav controllers

    private lazy var childNavVCs: [UINavigationController] = {
        let navs = [
            RotatingNavigationController(
                rootViewController: HistoryViewController(
                    service: dependencies.historyService,
                    channelViewControllerFactory:
                        dependencies.makeChannelViewController
                )
            ),
            RotatingNavigationController(rootViewController: DownloadsViewController()),
            RotatingNavigationController(
                rootViewController: PlaylistsViewController(
                    service: dependencies.playlistService,
                    channelViewControllerFactory:
                        dependencies.makeChannelViewController
                )
            )
        ]
        navs.forEach { $0.setNavigationBarHidden(true, animated: false) }
        return navs
    }()

    // MARK: - UI

    private let segmentedControl = UISegmentedControl(
        items: Segment.allCases.map(\.title)
    )
    private let segmentBar = UIView()
    private let segmentSeparator = UIView()
    private let contentView = UIView()
    private var currentChild: UINavigationController?

    // MARK: - Lifecycle

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentedControl()
        setupContentView()
        ToolbarManager.shared.install(in: self)
        applyTheme()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyTheme),
            name: ThemeManager.didChangeNotification,
            object: nil
        )
        show(segment: .history, animated: false)
    }

    // MARK: - Setup

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(
            self,
            action: #selector(segmentChanged),
            for: .valueChanged
        )
        segmentBar.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentSeparator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentBar)
        segmentBar.addSubview(segmentedControl)
        segmentBar.addSubview(segmentSeparator)
        NSLayoutConstraint.activate([
            segmentBar.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            segmentBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentBar.heightAnchor.constraint(equalToConstant: 52),

            segmentedControl.topAnchor.constraint(
                equalTo: segmentBar.topAnchor,
                constant: 8
            ),
            segmentedControl.leadingAnchor.constraint(
                equalTo: segmentBar.leadingAnchor,
                constant: 16
            ),
            segmentedControl.trailingAnchor.constraint(
                equalTo: segmentBar.trailingAnchor,
                constant: -16
            ),
            segmentedControl.heightAnchor.constraint(equalToConstant: 36),

            segmentSeparator.leadingAnchor.constraint(
                equalTo: segmentBar.leadingAnchor
            ),
            segmentSeparator.trailingAnchor.constraint(
                equalTo: segmentBar.trailingAnchor
            ),
            segmentSeparator.bottomAnchor.constraint(
                equalTo: segmentBar.bottomAnchor
            ),
            segmentSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: segmentBar.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Segment switching

    @objc
    private func segmentChanged() {
        let segment = Segment(rawValue: segmentedControl.selectedSegmentIndex) ?? .history
        show(segment: segment, animated: false)
    }

    private func show(segment: Segment, animated: Bool) {
        let newChild = childNavVCs[segment.rawValue]
        guard newChild !== currentChild else {
            return
        }

        // Remove old child
        if let old = currentChild {
            old.willMove(toParent: nil)
            old.view.removeFromSuperview()
            old.removeFromParent()
        }

        // Add new child
        addChild(newChild)
        newChild.view.frame = contentView.bounds
        newChild.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(newChild.view)
        newChild.didMove(toParent: self)
        currentChild = newChild
    }

    // MARK: - Theme

    @objc
    private func applyTheme() {
        let theme = ThemeManager.shared
        view.backgroundColor = theme.background
        segmentBar.backgroundColor = theme.surface
        segmentSeparator.backgroundColor = theme.separator
        contentView.backgroundColor = theme.background
        segmentedControl.backgroundColor = theme.controlSurface
        if #available(iOS 13, *) {
            segmentedControl.selectedSegmentTintColor = theme.accent
            segmentedControl.setTitleTextAttributes(
                [.foregroundColor: theme.primaryText],
                for: .normal
            )
            segmentedControl.setTitleTextAttributes(
                [.foregroundColor: UIColor.white],
                for: .selected
            )
        } else {
            segmentedControl.tintColor = theme.accent
        }
    }
}

// MARK: - ScrollableToTop

extension LibraryViewController: ScrollableToTop {
    func scrollToTop() {
        guard let topVC = currentChild?.topViewController else {
            return
        }
        // Children that auto-hide the top bar restore it themselves.
        if let scrollable = topVC as? ScrollableToTop {
            scrollable.scrollToTop()
            return
        }
        let scrollView = topVC.view.subviews.compactMap { $0 as? UIScrollView }.first
        scrollView?.setContentOffset(
            CGPoint(x: 0, y: -(scrollView?.adjustedContentInset.top ?? 0)),
            animated: true
        )
    }
}
