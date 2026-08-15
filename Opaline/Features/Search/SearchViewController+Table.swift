import UIKit

// MARK: - Results / panel table

extension SearchViewController: UITableViewDataSource {
    private static let panelCellId = "SearchPanelCell"
    private static let panelRowHeight: CGFloat = 44

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        panelMode == .hidden ? (results.count + 1) / 2 : panelItems.count
    }

    func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        panelMode == .history && !panelItems.isEmpty
            ? "search.recent".localized
            : nil
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        if panelMode != .hidden {
            return panelCell(tableView, indexPath: indexPath)
        }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VideoGridRowCell.reuseId,
            for: indexPath
        ) as? VideoGridRowCell else {
            return UITableViewCell()
        }
        let firstIndex = indexPath.row * 2
        let left = results[firstIndex]
        let right = firstIndex + 1 < results.count
            ? results[firstIndex + 1]
            : nil
        cell.configure(left: left, right: right)
        attachHandlers(to: cell.leftCell, video: left)
        if let right {
            attachHandlers(to: cell.rightCell, video: right)
        }
        cell.onVideoTap = { [weak self] video in
            guard let self else { return }
            self.videoRouter.open(video: video, from: self)
        }
        return cell
    }

    private func attachHandlers(to cell: SubscriptionVideoCell, video: Video) {
        cell.onChannelTap = { [weak self] in
            guard let self,
                  let channelId = video.channelId
            else {
                return
            }
            self.navigationController?.pushViewController(
                self.channelViewControllerFactory(
                    channelId,
                    video.channelName
                ),
                animated: true
            )
        }
        cell.onMenuTap = { [weak self] anchor in
            guard let self else {
                return
            }
            VideoActionMenu.present(video: video, from: self, anchor: anchor)
        }
    }

    private func panelCell(
        _ tableView: UITableView,
        indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Self.panelCellId
        ) ?? UITableViewCell(
            style: .default,
            reuseIdentifier: Self.panelCellId
        )
        let theme = ThemeManager.shared
        cell.backgroundColor = theme.background
        cell.textLabel?.textColor = theme.primaryText
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.textLabel?.text = panelItems[indexPath.row]
        return cell
    }

    func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool {
        panelMode == .history
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard panelMode == .history,
              editingStyle == .delete else {
            return
        }
        removeHistoryItem(at: indexPath.row)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        if panelMode != .hidden {
            tableView.deselectRow(at: indexPath, animated: true)
            executePanelQuery(panelItems[indexPath.row])
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        willDisplayHeaderView view: UIView,
        forSection section: Int
    ) {
        (view as? UITableViewHeaderFooterView)?.textLabel?.textColor =
            ThemeManager.shared.secondaryText
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        guard panelMode == .hidden else {
            return Self.panelRowHeight
        }
        let firstIndex = indexPath.row * 2
        let titles = results[firstIndex...min(firstIndex + 1, results.count - 1)]
            .map(\.title)
        return VideoGridRowCell.rowHeight(
            forWidth: tableView.bounds.width,
            titles: titles
        )
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard panelMode == .hidden,
              indexPath.row * 2 >= results.count - 4 else {
            return
        }
        loadNextPage()
    }
}
