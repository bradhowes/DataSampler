//
//  TabBarController.swift
//  Blah
//
//  Created by Brad Howes on 10/13/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

/**
 Specialization of UITabVarController that provides an animation transition when switching tabs
 */
public final class TabBarController: UITabBarController {

    /** 
     Custom transitioning animator. Implements `UIViewControllerAnimatedTransitioning`
     */
    fileprivate class CrossDissolveAnimator: NSObject, UIViewControllerAnimatedTransitioning {

        /**
         Duration of the animation
         - parameter transitionContext: the context where the transition will occur
         - returns: duration in seconds
         */
        func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
            return 0.25
        }

        /**
         Perform the animation
         - parameter transitionContext: the context where the transition will occur
         */
        func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {

            // Perform a cross-fade transition between the current tab view and the one that the user selected.
            //
            guard let fromView = transitionContext.view(forKey: .from) else { return }
            guard let toView = transitionContext.view(forKey: .to) else { return }
            UIView.transition(from: fromView, to: toView,
                              duration: transitionDuration(using: transitionContext),
                              options: [.transitionCrossDissolve]) {
                transitionContext.completeTransition($0)
            }

            // For views managed by a UINavigationController, the title will appear in the wrong location as the 
            // new view appears. I believe this is due to the fact that the title position is animatable. Clear out any
            // animations there.
            //
            let toNavController = transitionContext.viewController(forKey: .to) as? UINavigationController
            if toNavController != nil {
                toNavController?.navigationBar.layer.removeAllAnimations()
            }
        }
    }

    fileprivate let animator = CrossDissolveAnimator()

    /**
     View loaded. Install ourselves as the tab bar's delegate so we can use our custom animator.
     */
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
    }
}

// - MARK: UITabBarControllerDelegate methods

extension TabBarController: UITabBarControllerDelegate {

    /**
     Obtain an animator for the transition from one view to another.
     - parameter tabBarController: the UITabBarController performing the view change
     - parameter fromVC: the view controller transitioning from
     - parameter toVC: the view controller transitioning to
     - returns: animation to use for the transition
     */
    public func tabBarController(_ tabBarController: UITabBarController,
                                 animationControllerForTransitionFrom fromVC: UIViewController,
                                 to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animator
    }
}
