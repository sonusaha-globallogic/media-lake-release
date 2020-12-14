//
//  SplitViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class DetailViewContainer: NSView {
    /** We embed a child view controller into the detail view controller each time a different outline view item is selected.
        In order for the split view controller to consistently remain in the responder chain, the detail view controller's
        view property needs to accept first responder status.
        This is especially important for the consistent valication of the "Show/Hide Sidebar" menu item in the View menu.
    */
    override var acceptsFirstResponder: Bool { return true }
}

class SplitViewController: NSSplitViewController {
    
    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []
    
    private var detailViewController: NSViewController {
        let rightSplitViewItem = splitViewItems[1]
        return rightSplitViewItem.viewController
    }
    
    private var outlineViewController: NSViewController!
    private var progressViewController: ProgressViewController!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if outlineViewController == nil {
            outlineViewController = storyboard!.instantiateController(withIdentifier: "OutlineViewController") as? OutlineViewController
            outlineViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if progressViewController == nil {
            progressViewController = ProgressViewController()
            progressViewController.view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if hasChildViewController == false {
            embedChildViewController(progressViewController)
        } else {
            for child in splitViewItems[1].viewController.children {
                if let outlineViewController = child as? OutlineViewController {
                    embedChildViewController(outlineViewController)
                } else {
                    embedChildViewController(progressViewController)
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showOutlineViewController(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showProgressViewController(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showProgressViewController(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
            object: nil)
    }
    
    private var hasChildViewController: Bool {
        return !detailViewController.children.isEmpty
    }
    
    private func embedChildViewController(_ childViewController: NSViewController) {

        if hasChildViewController {
            detailViewController.removeChild(at: 0)
            // Remove the old child detail view.
            detailViewController.view.subviews[0].removeFromSuperview()
        }
        
        detailViewController.addChild(childViewController)
        detailViewController.view.addSubview(childViewController.view)
        
        // Build the horizontal, vertical constraints so that added child view controllers matches the width and height of it's parent.
        let views = ["targetView": childViewController.view]
        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[targetView]|",
                                           options: [],
                                           metrics: nil,
                                           views: views)
        NSLayoutConstraint.activate(horizontalConstraints)
        
        verticalConstraints =  NSLayoutConstraint.constraints(withVisualFormat: "V:|[targetView]|",
                                           options: [],
                                           metrics: nil,
                                           views: views)
        NSLayoutConstraint.activate(verticalConstraints)
    }
    
    
    @objc private func showOutlineViewController(_ notification: Notification) {
        progressViewController.progressIndicator.stopAnimation(self)
        progressViewController.progressLabel.isHidden = true
        

        
        embedChildViewController(outlineViewController)
    }
    
    @objc private func showProgressViewController(_ notification: Notification) {
        
        if let progressLabel = notification.userInfo?["progressLabel"] as? String {
            progressViewController.progressLabel.stringValue = progressLabel
            progressViewController.progressLabel.isHidden = false
        }
        
        if (notification.userInfo?["disableProgress"] as? Bool) != nil {
            progressViewController.progressIndicator.isHidden = true
        }
        else {
            progressViewController.progressIndicator.isHidden = false
            progressViewController.progressIndicator.startAnimation(self)
        }
        
        if let buttonLabel = notification.userInfo?["enableButton"] as? String {
            progressViewController.progressButton.title = buttonLabel
            progressViewController.progressButton.isHidden = false
            progressViewController.progressIndicator.isHidden = true
        }
        embedChildViewController(progressViewController)
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
            object: nil)
    }
}
