import UIKit

// MARK: - DataSource / Delegate

extension PlaylistVideosViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = isLoading
            ? PlaylistVideosViewController.skeletonCount
            : videos.count
        return (count + 1) / 2
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: VideoGridRowCell.reuseId,
            for: indexPath
        ) as? VideoGridRowCell else {
            return UITableViewCell()
        }
        if isLoading {
            cell.configure(left: nil, right: nil)
            return cell
        }
        let firstIndex = indexPath.row * 2
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
            let parentNav = self.navigationController?.parent?.navigationController
            let targetNav = parentNav ?? self.navigationController
            targetNav?.pushViewController(
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
            VideoActionMenu.present(
                video: video,
                from: self,
                anchor: anchor,
                removeFrom: (id: self.playlist.id, title: self.playlist.title)
            ) { [weak self] in
                self?.removeVideoFromList(videoId: video.id)
            }
        }
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        guard !isLoading else {
            return
        }
        if indexPath.row >= videos.count - 4 {
            loadMoreVideos()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isLoading else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard !isLoading else {
            return VideoGridRowCell.rowHeight(
                forWidth: tableView.bounds.width,
                titles: ["", ""]
            )
        }
        let firstIndex = indexPath.row * 2
        let titles = videos[firstIndex...min(firstIndex + 1, videos.count - 1)]
            .map(\.title)
        return VideoGridRowCell.rowHeight(
            forWidth: tableView.bounds.width,
            titles: titles
        )
    }
}
