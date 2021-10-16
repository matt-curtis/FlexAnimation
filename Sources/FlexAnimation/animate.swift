import QuartzCore

extension FlexAnimation {
    
    //  MARK: - Core animator
    
    @discardableResult
    static func animate(
        start: TimeUnit?,
        duration: TimeUnit?,
        function: Function?,
        filter: FilterClosure,
        traits: [ Trait ],
        modifications: (() -> Void),
        completion: ((CompletionState) -> Void)?
    ) -> Context {
        let now = CACurrentMediaTime()
        
        let priorContext = FlexAnimation.context
        let contextToInheritFrom = traits.contains(.ignoringContext) ? nil : priorContext
        
        if case .spring = function, duration != nil {
            print("⚠️ Animation API misuse: an explicit duration has been given for a spring animation; spring animations have their own calculated duration. Explicit duration will be ignored.")
        }
        
        let newContext = Context(
            start:
                start?.asAbsoluteTime(using: contextToInheritFrom, fallbackStartTime: now) ??
                contextToInheritFrom?.start ??
                now,
            
            //    Convert the duration specified to an absolute value;
            //    if we aren't given one, mimic what CALayer.add(_:forKey:) does
            //    (https://developer.apple.com/documentation/quartzcore/calayer/1410848-add)
            //    and use the duration value given by CATransaction.animationDuration()
            //    (https://developer.apple.com/documentation/quartzcore/catransaction/1448263-animationduration)
            //    (if there isn't an explicit CATransaction active, it returns 0.25 seconds.)
            
            duration:
                function?.springDuration ??
                duration?.asAbsoluteDuration(using: contextToInheritFrom) ??
                contextToInheritFrom?.duration ??
                CATransaction.animationDuration(),
            
            //    Use the function specified by the user, if none, use the prior context's.
            //    If it _also_ doesn't have one, do what CAAnimation does and just use a linear animation:
            //    https://developer.apple.com/documentation/quartzcore/caanimation/1412456-timingfunction
            
            function: function ?? contextToInheritFrom?.function ?? .linear,
            
            //    Auxiliary options are not inherited in any way —
            //    it doesn't sense for any of the options to be heritable,
            //    at least for now. That might change, though.
            
            traits: traits
        )
        
        //    Invoke modifications closure
        
        let oldMonitor = FlexAnimation.animationCompletionMonitor
        
        FlexAnimation.context = newContext
        
        if let completion = completion {
            FlexAnimation.animationCompletionMonitor = AnimationCompletionMonitor(
                onComplete: completion,
                parent: oldMonitor
            )
        }
        
        CALayer.swizzleActionForKeyIfNeeded()
        
        withoutActuallyEscaping(filter) {
            let oldFilter = FlexAnimation.canAnimateLayerImplicitly
            
            FlexAnimation.canAnimateLayerImplicitly = $0
            
            modifications()
            
            FlexAnimation.canAnimateLayerImplicitly = oldFilter
        }
        
        FlexAnimation.animationCompletionMonitor = oldMonitor
        FlexAnimation.context = priorContext
        
        return newContext
    }
    
    
    //  MARK: - Convenience
    
    //  MARK: Static
    
    @discardableResult
    static func animate(
        after delay: TimeUnit? = nil,
        for duration: TimeUnit? = nil,
        using function: Function? = nil,
        where filter: FilterClosure = { _ in true },
        _ traits: Trait...,
        modifications: () -> Void,
        completion: ((CompletionState) -> Void)? = nil
    ) -> Context {
        FlexAnimation.animate(
            start: delay,
            duration: duration,
            function: function,
            filter: filter,
            traits: traits,
            modifications: modifications,
            completion: completion
        )
    }
    
    static func animate(
        after delay: TimeUnit? = nil,
        for duration: TimeUnit? = nil,
        using function: Function? = nil,
        _ traits: Trait...
    ) -> Context {
        FlexAnimation.animate(
            after: delay,
            for: duration,
            using: function,
            .array(traits),
            modifications: {}
        )
    }
    
    
    //  MARK: - Transitions
    
    /// Adds a `CATransaction` to the given view or layer. `CATransaction`s manipulate snapshots of layers.
    
    public static func addTransition(
        to layerAssociated: LayerAssociated,
        ofType type: CATransitionType,
        subtype: CATransitionSubtype? = nil,
        after start: TimeUnit? = nil,
        for duration: TimeUnit? = nil,
        using function: Function? = nil,
        completion: ((CompletionState) -> Void)? = nil
    ) {
        let now = CACurrentMediaTime()
        
        func createCATransition(_ modify: (CATransition) -> Void) -> CATransition {
            let transition = CATransition()
            
            modify(transition)
            
            return transition
        }
        
        let transition = createCATransition {
            $0.type = type
            $0.subtype = subtype
            
            $0.timingFunction = function?.asCAMediaTimingFunction
            
            $0.beginTime = start?.asAbsoluteTime(using: context, fallbackStartTime: now) ?? now
            $0.duration = duration?.asAbsoluteDuration(using: context) ?? CATransaction.animationDuration()
            
            if let completion = completion {
                $0.delegate = AnimationCompletionMonitor(onComplete: completion, parent: nil)
            }
        }
        
        layerAssociated.associatedLayer.add(transition, forKey: nil)
    }
    
}

extension FlexAnimation.Context {
    
    //    MARK: - Derive animations from explicit context
    
    @discardableResult
    func animate(
        after delay: FlexAnimation.TimeUnit? = nil,
        for duration: FlexAnimation.TimeUnit? = nil,
        using function: FlexAnimation.Function? = nil,
        where filter: FlexAnimation.FilterClosure = { _ in true },
        _ traits: FlexAnimation.Trait...,
        modifications: () -> Void,
        completion: ((FlexAnimation.CompletionState) -> Void)? = nil
    ) -> FlexAnimation.Context {
        let priorContext = FlexAnimation.context
        
        FlexAnimation.context = self
        
        defer { FlexAnimation.context = priorContext }
        
        return FlexAnimation.animate(
            start: delay,
            duration: duration,
            function: function,
            filter: filter,
            traits: traits,
            modifications: modifications,
            completion: completion
        )
    }
    
    func animate(
        after delay: FlexAnimation.TimeUnit? = nil,
        for duration: FlexAnimation.TimeUnit? = nil,
        using function: FlexAnimation.Function? = nil,
        _ traits: FlexAnimation.Trait...
    ) -> FlexAnimation.Context {
        animate(
            after: delay,
            for: duration,
            using: function,
            .array(traits),
            modifications: {}
        )
    }
    
}
