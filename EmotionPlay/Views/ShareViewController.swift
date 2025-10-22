//
//  ShareViewController.swift
//  EmotionPlayShareExtension
//
//  Enhanced to share playlists from within the app using native iOS share sheet
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var sharedImage: UIImage?
    private let appGroupID = "group.com.emotionplay.shared" // MUST match your App Group ID
    
    // UI Elements
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let analyzeButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let loadingView = UIActivityIndicatorView(style: .large)
    
    // For sharing FROM the app
    private var playlistToShare: PlaylistShareData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Determine if we're sharing TO the app (image) or FROM the app (playlist)
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if extensionItem.userInfo?["playlistData"] != nil {
                // Sharing FROM app - playlist data
                extractPlaylistData()
            } else {
                // Sharing TO app - image
                extractSharedImage()
            }
        }
    }
    
    //UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.95) // Semi-transparent dark
        
        // Container with rounded corners
        containerView.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1.0)
        containerView.layer.cornerRadius = 24
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = UIColor(white: 0.2, alpha: 0.3)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        // Title Label
        titleLabel.text = "EmotiPlay"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.text = "Analyze your mood and create a playlist"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(subtitleLabel)
        
        // Analyze Button
        analyzeButton.setTitle("Analyze Mood", for: .normal)
        analyzeButton.setTitleColor(.white, for: .normal)
        analyzeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        analyzeButton.backgroundColor = UIColor(red: 0.11, green: 0.73, blue: 0.33, alpha: 1.0)
        analyzeButton.layer.cornerRadius = 12
        analyzeButton.translatesAutoresizingMaskIntoConstraints = false
        analyzeButton.addTarget(self, action: #selector(primaryActionTapped), for: .touchUpInside)
        containerView.addSubview(analyzeButton)
        
        // Cancel Button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.lightGray, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        containerView.addSubview(cancelButton)
        
        // Loading View
        loadingView.color = .white
        loadingView.hidesWhenStopped = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(loadingView)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            // Container
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: 600),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Image
            imageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 280),
            imageView.heightAnchor.constraint(equalToConstant: 280),
            
            // Analyze Button
            analyzeButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24),
            analyzeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            analyzeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            analyzeButton.heightAnchor.constraint(equalToConstant: 52),
            
            // Cancel Button
            cancelButton.topAnchor.constraint(equalTo: analyzeButton.bottomAnchor, constant: 12),
            cancelButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // Loading
            loadingView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }
    
    //Extract Shared Image (TO App)
    
    private func extractSharedImage() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            showError("No image found")
            return
        }
        
        loadingView.startAnimating()
        imageView.alpha = 0.5
        analyzeButton.isEnabled = false
        
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            itemProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
                DispatchQueue.main.async {
                    self?.loadingView.stopAnimating()
                    self?.imageView.alpha = 1.0
                    self?.analyzeButton.isEnabled = true
                    
                    if let error = error {
                        self?.showError("Failed to load image: \(error.localizedDescription)")
                        return
                    }
                    
                    var loadedImage: UIImage?
                    
                    if let url = item as? URL {
                        loadedImage = UIImage(contentsOfFile: url.path)
                    } else if let data = item as? Data {
                        loadedImage = UIImage(data: data)
                    } else if let image = item as? UIImage {
                        loadedImage = image
                    }
                    
                    if let image = loadedImage {
                        self?.sharedImage = image
                        self?.imageView.image = image
                    } else {
                        self?.showError("Unable to process image")
                    }
                }
            }
        } else {
            loadingView.stopAnimating()
            imageView.alpha = 1.0
            showError("Please share a valid image")
        }
    }
    
    //Extract Playlist Data (FROM App)
    
    private func extractPlaylistData() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let userInfo = extensionItem.userInfo,
              let playlistDataDict = userInfo["playlistData"] as? [String: Any],
              let mood = playlistDataDict["mood"] as? String,
              let playlistName = playlistDataDict["playlistName"] as? String else {
            showError("Invalid playlist data")
            return
        }
        
        let confidence = playlistDataDict["confidence"] as? Double ?? 0.0
        let trackCount = playlistDataDict["trackCount"] as? Int ?? 0
        let spotifyURL = playlistDataDict["spotifyURL"] as? String
        
        playlistToShare = PlaylistShareData(
            mood: mood,
            playlistName: playlistName,
            confidence: confidence,
            trackCount: trackCount,
            spotifyURL: spotifyURL
        )
        
        // Update UI for playlist sharing
        setupPlaylistSharingUI()
    }
    
    private func setupPlaylistSharingUI() {
        guard let playlist = playlistToShare else { return }
        
        titleLabel.text = "Share Playlist"
        subtitleLabel.text = "\(playlist.mood.capitalized) • \(playlist.trackCount) tracks"
        
        // Show playlist preview instead of image
        imageView.isHidden = true
        
        // Create playlist card
        let playlistCard = createPlaylistCard(playlist)
        playlistCard.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(playlistCard)
        
        NSLayoutConstraint.activate([
            playlistCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            playlistCard.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            playlistCard.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            playlistCard.heightAnchor.constraint(equalToConstant: 120)
        ])
        
        // Update button
        analyzeButton.setTitle("Share Playlist", for: .normal)
        
        // Move button constraints
        NSLayoutConstraint.deactivate(analyzeButton.constraints.filter {
            $0.firstAttribute == .top
        })
        
        analyzeButton.topAnchor.constraint(equalTo: playlistCard.bottomAnchor, constant: 24).isActive = true
    }
    
    private func createPlaylistCard(_ playlist: PlaylistShareData) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(red: 0.16, green: 0.16, blue: 0.21, alpha: 1.0)
        card.layer.cornerRadius = 16
        
        let emojiLabel = UILabel()
        emojiLabel.text = moodEmoji(playlist.mood)
        emojiLabel.font = .systemFont(ofSize: 48)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(emojiLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = playlist.playlistName
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 2
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)
        
        let detailsLabel = UILabel()
        detailsLabel.text = "\(playlist.trackCount) tracks • \(Int(playlist.confidence * 100))% match"
        detailsLabel.font = .systemFont(ofSize: 13)
        detailsLabel.textColor = .lightGray
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(detailsLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            emojiLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            
            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 30),
            
            detailsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor)
        ])
        
        return card
    }
    
    //Actions
    
    @objc private func primaryActionTapped() {
        if let playlist = playlistToShare {
            sharePlaylist(playlist)
        } else if let image = sharedImage {
            saveImageAndOpenApp(image)
        }
    }
    
    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    //Save Image and Open App
    
    private func saveImageAndOpenApp(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showError("Failed to process image")
            return
        }
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            showError("Failed to access shared storage")
            return
        }
        
        sharedDefaults.set(imageData, forKey: "pendingAnalysisImage")
        sharedDefaults.set(Date(), forKey: "pendingAnalysisDate")
        sharedDefaults.synchronize()
        
        openMainApp(with: "emotionplay://analyze")
    }
    
    //Share Playlist
    
    private func sharePlaylist(_ playlist: PlaylistShareData) {
        // Create shareable text
        let shareText = """
        🎵 Check out my \(playlist.mood.capitalized) playlist on EmotiPlay!
        
        "\(playlist.playlistName)"
        \(playlist.trackCount) tracks • \(Int(playlist.confidence * 100))% mood match
        
        Created with emotion recognition 🎭
        """
        
        var itemsToShare: [Any] = [shareText]
        
        // Add Spotify URL if available
        if let urlString = playlist.spotifyURL, let url = URL(string: urlString) {
            itemsToShare.append(url)
        }
        
        // Present native share sheet
        let activityVC = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Exclude some activity types if desired
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        activityVC.completionWithItemsHandler = { [weak self] _, completed, _, _ in
            if completed {
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = analyzeButton
            popover.sourceRect = analyzeButton.bounds
        }
        
        present(activityVC, animated: true)
    }
    
    //Open Main App
    
    private func openMainApp(with urlString: String) {
        guard let url = URL(string: urlString) else {
            showError("Invalid URL")
            return
        }
        
        extensionContext?.open(url, completionHandler: { [weak self] success in
            if success {
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            } else {
                self?.showError("Unable to open EmotiPlay app")
            }
        })
    }
    
    //Error Handling
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.cancelTapped()
        })
        present(alert, animated: true)
    }
    
    //Helper Functions
    
    private func moodEmoji(_ mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "sad": return "😢"
        case "calm": return "😌"
        case "energetic": return "⚡"
        case "angry": return "😠"
        case "anxious": return "😰"
        case "melancholic": return "🌧️"
        case "focused": return "🎯"
        case "nostalgic": return "💭"
        default: return "🎵"
        }
    }
}

//Playlist Share Data Model

struct PlaylistShareData {
    let mood: String
    let playlistName: String
    let confidence: Double
    let trackCount: Int
    let spotifyURL: String?
}
