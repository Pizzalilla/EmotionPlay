//
//  ShareViewController.swift
//  EmotionPlayShareExtension
//
//  Created by Wong Wilson on 21/10/2025.
//

import UIKit
import Social
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var sharedImage: UIImage?
    private let appGroupID = "group.com.yourname.emotionplay" // MUST match your App Group ID
    
    // UI Elements
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let analyzeButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let loadingView = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedImage()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.14, alpha: 1.0) // #1C1C23
        
        // Image View
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Title Label
        titleLabel.text = "EmotiPlay"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.text = "Analyze your mood and create a playlist"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
        
        // Analyze Button
        analyzeButton.setTitle("Analyze Mood", for: .normal)
        analyzeButton.setTitleColor(.white, for: .normal)
        analyzeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        analyzeButton.backgroundColor = UIColor(red: 0.11, green: 0.73, blue: 0.33, alpha: 1.0) // Spotify green
        analyzeButton.layer.cornerRadius = 12
        analyzeButton.translatesAutoresizingMaskIntoConstraints = false
        analyzeButton.addTarget(self, action: #selector(analyzeTapped), for: .touchUpInside)
        view.addSubview(analyzeButton)
        
        // Cancel Button
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.lightGray, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Loading View
        loadingView.color = .white
        loadingView.hidesWhenStopped = true
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingView)
        
        // Layout Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            imageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 280),
            imageView.heightAnchor.constraint(equalToConstant: 280),
            
            analyzeButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -12),
            analyzeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            analyzeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            analyzeButton.heightAnchor.constraint(equalToConstant: 52),
            
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            
            loadingView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
    }
    
    // MARK: - Extract Shared Image
    
    private func extractSharedImage() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            showError("No image found")
            return
        }
        
        loadingView.startAnimating()
        imageView.alpha = 0.5
        analyzeButton.isEnabled = false
        
        // Check for images
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
    
    // MARK: - Actions
    
    @objc private func analyzeTapped() {
        guard let image = sharedImage else {
            showError("No image to analyze")
            return
        }
        
        // Save image to shared container and open main app
        saveImageToSharedContainer(image)
    }
    
    @objc private func cancelTapped() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    // MARK: - Save to Shared Container
    
    private func saveImageToSharedContainer(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showError("Failed to process image")
            return
        }
        
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            showError("Failed to access shared storage")
            return
        }
        
        // Save image data
        sharedDefaults.set(imageData, forKey: "pendingAnalysisImage")
        sharedDefaults.set(Date(), forKey: "pendingAnalysisDate")
        sharedDefaults.synchronize()
        
        // Open main app with custom URL scheme
        let urlString = "emotionplay://analyze"
        if let url = URL(string: urlString) {
            var responder: UIResponder? = self
            while responder != nil {
                if let application = responder as? UIApplication {
                    application.perform(#selector(UIApplication.openURL(_:)), with: url)
                    break
                }
                responder = responder?.next
            }
            
            // Alternative: Use extensionContext
            extensionContext?.open(url, completionHandler: { [weak self] success in
                if success {
                    self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                } else {
                    self?.showError("Unable to open EmotiPlay app")
                }
            })
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.cancelTapped()
        })
        present(alert, animated: true)
    }
}
