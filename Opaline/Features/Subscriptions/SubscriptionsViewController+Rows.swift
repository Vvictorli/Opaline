import UIKit

/// A row of the subscriptions list: either a video, or the shelf holding the
/// feed's shorts.
enum FeedRow {
    case video(Video)
    case shortsShelf([Video])
}

extension SubscriptionsViewController {
    /// The shelf sits on top: the feed serves its shorts in one go, in the
    /// first response, so there is nothing to spread further down.
    func rebuildRows() {
        let shelf: [FeedRow] = shortsShelf.isEmpty
            ? [] : [.shortsShelf(shortsShelf)]
        rows = shelf + videos.map(FeedRow.video)
    }
}

// MARK: - Data source

extension SubscriptionsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !isLoadingInitial else {
            return (SubscriptionsViewController.skeletonCount + 1) / 2
        }
        let shelfRows = shortsShelf.isEmpty ? 0 : 1
        return shelfRows + (videos.count + 1) / 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !isLoadingInitial,
           !shortsShelf.isEmpty,
           indexPath.row == 0 {
            let shorts = shortsShelf
            return shortsShelfCell(for: indexPath, shorts: shorts)
        }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VideoGridRowCell.reuseId,
            for: indexPath
        ) as? VideoGridRowCell else {
            return UITableViewCell()
        }
        if isLoadingInitial {
            cell.configure(left: nil, right: nil)
            return cell
        }
        let shelfOffset = shortsShelf.isEmpty ? 0 : 1
        let firstIndex = (indexPath.row - shelfOffset) * 2
        guard firstIndex >= 0, firstIndex < videos.count else {
            return UITableViewCell()
        }
        let left = videos[firstIndex]
        let right = firstIndex + 1 < videos.count
            ? videos[firstIndex + 1]
            : nil
        cell.configure(left: left, right: right)
        attachHandlers(to: cell.leftCell, video: left)
        if let right {
            attachHandlers(to: cell.rightCell, video: right)
        }
        cell.onVideoTap = { [weak self] video in
            guard let self else { return }
            self.markWatchedLocally(video)
            self.videoRouter.open(video: video, from: self)
        }
        return cell
    }

    private func shortsShelfCell(
        for indexPath: IndexPath,
        shorts: [Video]
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ShortsShelfCell.reuseId, for: indexPath
        ) as? ShortsShelfCell else {
            return UITableViewCell()
        }
        cell.configure(with: shorts)
        cell.onSeeAll = { [weak self] in
            self?.openAllShorts()
        }
        cell.onSelect = { [weak self] index in
            guard let self, index < shorts.count else {
                return
            }
            self.videoRouter.open(
                video: shorts[index], from: self, shorts: .pool(shorts)
            )
        }
        return cell
    }

    /// The feed's twelve are all it has; the full list comes from the
    /// channels' own feeds, fetched only when this screen opens. Under a
    /// channel filter the screen stays scoped to that one channel.
    private func openAllShorts() {
        navigationController?.pushViewController(
            SubscriptionShortsViewController(
                channels: selectedChannel.map { [$0] } ?? subscribedChannels,
                rssService: channelRSSService,
                channelViewControllerFactory: channelViewControllerFactory,
                videoRouter: videoRouter
            ),
            animated: true
        )
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
}

// MARK: - Delegate

extension SubscriptionsViewController: UITableViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else {
            return
        }
        topBarHider.handleScroll(scrollView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !isLoadingInitial else {
            return VideoGridRowCell.rowHeight(
                forWidth: tableView.bounds.width,
                titles: ["", ""]
            )
        }
        if !shortsShelf.isEmpty, indexPath.row == 0 {
            return ShortsShelfCell.rowHeight
        }
        let firstIndex = (indexPath.row - (shortsShelf.isEmpty ? 0 : 1)) * 2
        let titles = videos[firstIndex...min(firstIndex + 1, videos.count - 1)]
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
        guard !isLoadingInitial,
              !isLoadingMore,
              continuationToken != nil,
              (indexPath.row - (shortsShelf.isEmpty ? 0 : 1)) * 2
                >= videos.count - 4
        else { return }

        isLoadingMore = true
        loadMore()
    }
}
