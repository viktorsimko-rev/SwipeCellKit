//
//  MailCollectionViewController.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit
import SwipeCellKit

class CustomMailCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var emails: [Email] = []
    
    var defaultOptions = SwipeOptions()
    var isSwipeRightEnabled = true
    var buttonDisplayMode: ButtonDisplayMode = .titleAndImage
    var buttonStyle: ButtonStyle = .backgroundColor
    var usesTallCells = false
    private let isManualMode: Bool

    init() {
        isManualMode = true
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder: NSCoder) {
        isManualMode = false
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = editButtonItem
        if isManualMode {
            collectionView.register(CustomMailCollectionViewCell.self, forCellWithReuseIdentifier: "MailCell")
        }
        
        resetData()
    }

    // MARK: - Collection view data source
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emails.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: usesTallCells ? 160 : 98)
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let email = emails[indexPath.row]
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MailCell", for: indexPath) as! CustomMailCollectionViewCell
        if isManualMode {
            cell.setupViews()
        }
        
        cell.delegate = self
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        
        cell.fromLabel.text = email.from
        cell.dateLabel.text = email.relativeDateString
        cell.subjectLabel.text = email.subject
        cell.bodyLabel.text = email.body
        cell.bodyLabel.numberOfLines = usesTallCells ? 0 : 2
        cell.unread = email.unread
        
        return cell
    }
    
    // MARK: - Actions
    
    @IBAction func moreTapped(_ sender: Any) {
        let controller = UIAlertController(title: "Swipe Transition Style", message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Border", style: .default, handler: { _ in self.defaultOptions.transitionStyle = .border }))
        controller.addAction(UIAlertAction(title: "Drag", style: .default, handler: { _ in self.defaultOptions.transitionStyle = .drag }))
        controller.addAction(UIAlertAction(title: "Reveal", style: .default, handler: { _ in self.defaultOptions.transitionStyle = .reveal }))
        controller.addAction(UIAlertAction(title: "\(isSwipeRightEnabled ? "Disable" : "Enable") Swipe Right", style: .default, handler: { _ in self.isSwipeRightEnabled = !self.isSwipeRightEnabled }))
        controller.addAction(UIAlertAction(title: "Button Display Mode", style: .default, handler: { _ in self.buttonDisplayModeTapped() }))
        controller.addAction(UIAlertAction(title: "Button Style", style: .default, handler: { _ in self.buttonStyleTapped() }))
        controller.addAction(UIAlertAction(title: "Cell Height", style: .default, handler: { _ in self.cellHeightTapped() }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        controller.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { _ in self.resetData() }))
        present(controller, animated: true, completion: nil)
    }
    
    func buttonDisplayModeTapped() {
        let controller = UIAlertController(title: "Button Display Mode", message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Image + Title", style: .default, handler: { _ in self.buttonDisplayMode = .titleAndImage }))
        controller.addAction(UIAlertAction(title: "Image Only", style: .default, handler: { _ in self.buttonDisplayMode = .imageOnly }))
        controller.addAction(UIAlertAction(title: "Title Only", style: .default, handler: { _ in self.buttonDisplayMode = .titleOnly }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func buttonStyleTapped() {
        let controller = UIAlertController(title: "Button Style", message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Background Color", style: .default, handler: { _ in
            self.buttonStyle = .backgroundColor
            self.defaultOptions.transitionStyle = .border
        }))
        controller.addAction(UIAlertAction(title: "Circular", style: .default, handler: { _ in
            self.buttonStyle = .circular
            self.defaultOptions.transitionStyle = .reveal
        }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func cellHeightTapped() {
        let controller = UIAlertController(title: "Cell Height", message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Normal", style: .default, handler: { _ in
            self.usesTallCells = false
            self.collectionView?.reloadData()
        }))
        controller.addAction(UIAlertAction(title: "Tall", style: .default, handler: { _ in
            self.usesTallCells = true
            self.collectionView?.reloadData()
        }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    func resetData() {
        emails = mockEmails
        emails.forEach { $0.unread = false }
        usesTallCells = false
        collectionView?.reloadData()
    }
}

extension CustomMailCollectionViewController: SwipeCollectionViewCellDelegate {
    
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        let email = emails[indexPath.row]
        
        if orientation == .left {
            guard isSwipeRightEnabled else { return nil }
            
            let read = SwipeAction(style: .default, title: nil) { action, indexPath in
                let updatedStatus = !email.unread
                email.unread = updatedStatus
                
                let cell = collectionView.cellForItem(at: indexPath) as! CustomMailCollectionViewCell
                cell.setUnread(updatedStatus, animated: true)
            }
            
            read.hidesWhenSelected = true
            read.accessibilityLabel = email.unread ? "Mark as Read" : "Mark as Unread"
            
            let descriptor: ActionDescriptor = email.unread ? .read : .unread
            configure(action: read, with: descriptor)
            
            return [read]
        } else {
            let flag = SwipeAction(style: .default, title: nil, handler: nil)
            flag.hidesWhenSelected = true
            flag.accessibilityLabel = "Accessible Button"
            configure(action: flag, with: .flag)
            
            let delete = SwipeAction(style: .destructive, title: nil) { action, indexPath in
                self.emails.remove(at: indexPath.row)
            }
            configure(action: delete, with: .trash)
            
            let cell = collectionView.cellForItem(at: indexPath) as! CustomMailCollectionViewCell
            let closure: (UIAlertAction) -> Void = { _ in cell.hideSwipe(animated: true) }
            let more = SwipeAction(style: .default, title: nil) { action, indexPath in
                let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                controller.addAction(UIAlertAction(title: "Reply", style: .default, handler: closure))
                controller.addAction(UIAlertAction(title: "Forward", style: .default, handler: closure))
                controller.addAction(UIAlertAction(title: "Mark...", style: .default, handler: closure))
                controller.addAction(UIAlertAction(title: "Notify Me...", style: .default, handler: closure))
                controller.addAction(UIAlertAction(title: "Move Message...", style: .default, handler: closure))
                controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: closure))
                self.present(controller, animated: true, completion: nil)
            }
            configure(action: more, with: .more)
            
            return [delete, flag, more]
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = orientation == .left ? .selection : .destructive
        options.transitionStyle = defaultOptions.transitionStyle

        options.backgroundColor = .clear
        options.buttonVerticalAlignment = .center
        options.edgeInsets = .init(top: 2, left: 0, bottom: 2, right: 0)
        options.rightPanZone = .fractional(0.3)
        options.leftPanZone = .absolute(100)
        
        return options
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contentViewForAction action: SwipeAction
    ) -> ActionContentView {
        RoundedCornersActionContentView(action: action)
    }
    
    func visibleRect(for collectionView: UICollectionView) -> CGRect? {
        if usesTallCells == false { return nil }
        
        if #available(iOS 11.0, *) {
            return collectionView.safeAreaLayoutGuide.layoutFrame
        } else {
            let topInset = navigationController?.navigationBar.frame.height ?? 0
            let bottomInset = navigationController?.toolbar?.frame.height ?? 0
            let bounds = collectionView.bounds
            
            return CGRect(x: bounds.origin.x, y: bounds.origin.y + topInset, width: bounds.width, height: bounds.height - bottomInset)
        }
    }
    
    func configure(action: SwipeAction, with descriptor: ActionDescriptor) {
        action.title = descriptor.title(forDisplayMode: buttonDisplayMode)
        action.image = descriptor.image(forStyle: buttonStyle, displayMode: buttonDisplayMode)
        
        switch buttonStyle {
        case .backgroundColor:
            action.backgroundColor = descriptor.color(forStyle: buttonStyle)
        case .circular:
            action.backgroundColor = .clear
            action.textColor = descriptor.color(forStyle: buttonStyle)
            action.font = .systemFont(ofSize: 13)
            action.transitionDelegate = ScaleTransition.default
        }
    }
}

class CustomMailCollectionViewCell: SwipeCollectionViewCell {
    @IBOutlet var fromLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var subjectLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    
    var animator: Any?
    
    var indicatorView = IndicatorView(frame: .zero)
    
    var unread = false {
        didSet {
            indicatorView.transform = unread ? CGAffineTransform.identity : CGAffineTransform.init(scaleX: 0.001, y: 0.001)
        }
    }

    func setupViews() {
        fromLabel = UILabel()
        fromLabel.font = .preferredFont(forTextStyle: .headline)
        fromLabel.textColor = .label
        dateLabel = UILabel()
        dateLabel.font = .preferredFont(forTextStyle: .subheadline)
        dateLabel.textColor = .secondaryLabel
        subjectLabel = UILabel()
        subjectLabel.font = .preferredFont(forTextStyle: .subheadline)
        subjectLabel.textColor = .label
        bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .subheadline)
        bodyLabel.textColor = .secondaryLabel

        let hStack = UIStackView(arrangedSubviews: [
            fromLabel,
            dateLabel,
            UIImageView(image: UIImage(named: "Disclosure")!)
        ])
        hStack.axis = .horizontal
        hStack.spacing = 6

        let vStack = UIStackView(arrangedSubviews: [
            hStack,
            subjectLabel,
            bodyLabel
        ])
        vStack.axis = .vertical
        vStack.spacing = 2

        contentView.addSubview(vStack)
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        vStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            vStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            vStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            vStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 4),
            separator.leadingAnchor.constraint(equalTo: vStack.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        setupIndicatorView()
    }

    override func awakeFromNib() {
        setupIndicatorView()
    }
    
    func setupIndicatorView() {
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.color = tintColor
        indicatorView.backgroundColor = .clear
        contentView.addSubview(indicatorView)
        
        let size: CGFloat = 12
        indicatorView.widthAnchor.constraint(equalToConstant: size).isActive = true
        indicatorView.heightAnchor.constraint(equalTo: indicatorView.widthAnchor).isActive = true
        indicatorView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 12).isActive = true
        indicatorView.centerYAnchor.constraint(equalTo: fromLabel.centerYAnchor).isActive = true
    }
    
    func setUnread(_ unread: Bool, animated: Bool) {
        let closure = {
            self.unread = unread
        }
        
        if #available(iOS 10, *), animated {
            var localAnimator = self.animator as? UIViewPropertyAnimator
            localAnimator?.stopAnimation(true)
            
            localAnimator = unread ? UIViewPropertyAnimator(duration: 1.0, dampingRatio: 0.4) : UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1.0)
            localAnimator?.addAnimations(closure)
            localAnimator?.startAnimation()
            
            self.animator = localAnimator
        } else {
            closure()
        }
    }
}
