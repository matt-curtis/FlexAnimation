//
//  Animation.swift
//  Hyphen
//
//  Created by Matt Curtis on 1/21/21.
//

import UIKit

//  A little bit of the guidance for this implementation came from
//  Google's "Material Motion" libraries, particularly their iOS & Objective-C one:
//	https://github.com/material-motion/motion-animator-objc/
//	Thinking that in the future, if we want to write tests for this
//	we could take inspiration from how they've written their tests.

public enum FlexAnimation {
    
    //  MARK: - Type aliases
    
    public typealias FilterClosure = (SaferLayerWrapperForComparison) -> Bool
    
    
    //  MARK: - Static properties
    
    /// The current animation context.
    
    static var context: Context? = nil
    
    /// A closure used to determine whether or not a layer that is modified within an
    /// animation closure is animated.
    
    static var canAnimateLayerImplicitly: FilterClosure = { _ in true }
    
    /// The current animation completion monitor.
    
    static var animationCompletionMonitor: AnimationCompletionMonitor?
    
    
    //	MARK: Helpers
    
    static func timing(
        from timeUnitA: TimeUnit, of ctxA: Context,
        until timeUnitB: TimeUnit, of ctxB: Context
    ) -> (start: TimeUnit, duration: TimeUnit) {
        let now = CACurrentMediaTime()
        
        let start = timeUnitA.asAbsoluteTime(using: ctxA, fallbackStartTime: now)
        let end = timeUnitB.asAbsoluteTime(using: ctxB, fallbackStartTime: now)
        
        return (
            start: .abs(start - now),
            duration: .abs(end - (start - now))
        )
    }
    
    ///	Disables CALayer actions within the closure.
    
    public static func withoutActions(_ closure: () -> Void) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        closure()
        
        CATransaction.commit()
    }
    
    ///	Ignores the current animation context while inside the closure.
    
    public static func ignoreContext(_ closure: () -> Void) {
        let contextCache = context
        
        context = nil
        
        closure()
        
        context = contextCache
    }
    
}
