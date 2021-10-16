import QuartzCore

extension FlexAnimation {
    
    //  MARK: - Additive animation helpers
    
    private struct ValuesForAdditiveAnimation {
        
        let subKeyPath: String?
        
        let diff: Any
        
        let zero: Any
        
        
        init<T>(_ subKeyPath: String? = nil, diff: T, zero: T) {
            self.subKeyPath = subKeyPath
            self.diff = diff
            self.zero = zero
        }
        
    }
    
    private static func isAnimationKeyAlwaysNonAdditive(_ key: String) -> Bool {
        //  This is what UIKit does as well.
        
        switch key {
            case
                #keyPath(CALayer.opacity),
                #keyPath(CALayer.backgroundColor),
                #keyPath(CALayer.anchorPoint): return true
                
            default: return false
        }
    }
    
    private static func decomposedDiff<T, V: FloatingPoint>(of from: T, and to: T, into keyPaths: KeyPath<T, V>...) -> [ V ] {
        keyPaths.map { from[keyPath: $0] - to[keyPath: $0] }
    }
    
    private static func valuesForAdditiveAnimation(from: Any?, to: Any?) -> [ ValuesForAdditiveAnimation ]? {
        /// Helper type for indicating a pair of values of the same type
        
        typealias Pair<T> = (T, T)
        
        switch (from, to) {
            case let (from, to) as Pair<CGFloat>:
                return [
                    .init(diff: from - to, zero: .zero)
                ]
                
            case let (from, to) as Pair<CGRect>:
                //  CGRects can't be additively animated, but CGPoint and CGSize can 🙄
                //  This is also how UIKit solves the problem,
                //  by animating a CGRect property via the special keyPaths it supports
                //  for CGRect properties, origin and size.
                
                let originDiff = decomposedDiff(of: from, and: to, into: \.minX, \.minY)
                let sizeDiff = decomposedDiff(of: from, and: to, into: \.width, \.height)
                
                return [
                    .init("origin", diff: CGPoint(x: originDiff[0], y: originDiff[1]), zero: .zero),
                    .init("size", diff: CGSize(width: sizeDiff[0], height: sizeDiff[1]), zero: .zero)
                ]
                
            case let (from, to) as Pair<CGSize>:
                let diff = decomposedDiff(of: from, and: to, into: \.width, \.height)
                
                return [
                    .init(diff: CGSize(width: diff[0], height: diff[1]), zero: .zero)
                ]
                
            case let (from, to) as Pair<CGPoint>:
                let diff = decomposedDiff(of: from, and: to, into: \.x, \.y)
                
                return [
                    .init(diff: CGPoint(x: diff[0], y: diff[1]), zero: .zero)
                ]
                
            case let (from, to) as Pair<CATransform3D>:
                return [
                    .init(
                        diff: CATransform3DConcat(from, CATransform3DInvert(to)),
                        zero: CATransform3DIdentity
                    )
                ]
                
            default:
                //  Not a value that can be additively animated.
                
                return nil
        }
    }
    
    
    //  MARK: - addAnimation
    
    static func addAnimation(to layer: CALayer, for keyPath: String, fromForAdditiveAnimation: Any?, from: Any?, to: Any?, context: Context) {
        //  Extract options from traits
        
        var repeatCount: Float = 0
        var repeatDelay: TimeInterval = 0
        var shouldAutoreverse = false
        var fillMode: CAMediaTimingFillMode = .removed
        var shouldReplaceAnimationsForSameKey = false
        
        func processTraits(_ traits: [ Trait ]) {
            for traits in traits {
                switch traits {
                    case let .repeating(count, withGap: gap):
                        repeatCount = count
                        repeatDelay = gap?.asAbsoluteDuration(using: context, fallbackToTransitionTime: false) ?? 0
                        
                    case .autoreversing:
                        shouldAutoreverse = true
                        
                    case .filled(let mode):
                        fillMode = mode
                        
                    case .replacingAnimationsForSameKey:
                        shouldReplaceAnimationsForSameKey = true
                        
                    case .array(let traits):
                        processTraits(traits)
                        
                    default: break
                }
            }
        }
        
        processTraits(context.traits)
        
        //  Animation to & from values, timing functions
        
        var animations: [ CABasicAnimation ] = []
        
        func animationForFunction() -> CABasicAnimation {
            let animation: CABasicAnimation
            
            switch context.function {
                case let .spring(damping, mass, stiffness, initialVelocity):
                    let springAnimation = CASpringAnimation()
                    
                    animation = springAnimation
                    
                    springAnimation.damping = damping
                    springAnimation.mass = mass
                    springAnimation.stiffness = stiffness
                    springAnimation.initialVelocity = initialVelocity
                    
                default:
                    animation = CABasicAnimation()
                    
                    animation.duration = context.duration
            }
            
            animation.keyPath = keyPath
            animation.timingFunction = context.function.asCAMediaTimingFunction
            
            animation.autoreverses = shouldAutoreverse
            
            return animation
        }
        
        if
            !isAnimationKeyAlwaysNonAdditive(keyPath),
            let fromForAdditiveAnimation = fromForAdditiveAnimation,
            let values = valuesForAdditiveAnimation(from: fromForAdditiveAnimation, to: to)
        {
            values.forEach {
                let animation = animationForFunction()
                
                animation.isAdditive = true
                
                if let subKeyPath = $0.subKeyPath {
                    animation.keyPath = "\(keyPath).\(subKeyPath)"
                } else {
                    animation.keyPath = keyPath
                }
                
                animation.fromValue = $0.diff
                animation.toValue = $0.zero
                
                animations.append(animation)
            }
        } else {
            let animation = animationForFunction()
            
            animation.fromValue = from
            animation.toValue = to
            
            animations.append(animation)
        }
        
        //  Timing properties
        //  We use a group to wrap the animations in order to give ourselves
        //  a bit more flexibility with the timing — for example, using one
        //  allows us to create a delay before an animation repeats.
        
        /// Protect ourselves from a `UICollectionView` bug where
        /// during its `layoutSubviews` it blindly calls `setFromValue:` and `setToValue:`
        /// on some animations. (This is caused, I assume, by `UICollectionView`
        /// assuming all animations are `CAPropertyAnimation` subclasses,
        /// rather than doing a type check.)
        
        class Group: CAAnimationGroup {
            
            //  Dummies; unused:
            
            @objc var fromValue: Any? = nil
            @objc var toValue: Any? = nil
            
        }
        
        let parent = Group()
        
        parent.delegate = animationCompletionMonitor
        parent.animations = animations
        parent.fillMode = fillMode
        
        switch fillMode {
            case .forwards, .both:
                parent.isRemovedOnCompletion = false
                
            default: break
        }
        
        //  There's a "bug" (I'm calling it a bug),
        //  where, if you want an animation to begin immediately,
        //  and use the current time (via CACurrentMediaTime())
        //  Core Animation's local animation value calculation system
        //  treats that begin time as if its slightly in the future,
        //  and will — for at least a single frame — give animation values
        //  that don't consider the animation you just added.
        //
        //  (This is most noticeable if you're using CALayer's draw(in:)
        //  method to draw or update in sync with Core Animation.)
        //
        //  To avoid this problem, we check to see if the start time we're given
        //  actually is actually substantially in the future.
        //  The check below seems to suffice, but we may need to do something more robust
        //  (like checking for deviation without a certain window, say 1 / 60fps)
        //  either here or when creating the animations in animate()
        
        if context.start > CACurrentMediaTime() {
            parent.beginTime = layer.convertTime(context.start, from: nil)
        }
        
        if shouldAutoreverse {
            //  Autoreversed animations run for twice their natural duration.
            
            parent.duration = (context.duration * 2) + repeatDelay
            
            //  Adjust the repeat count so that the the last repeat delay is excluded
            //  i.e. if repeat count = 2, we don't want a pause after the last repetition,
            //  since there's no upcoming repetition.
            
            parent.repeatCount = repeatCount - Float(repeatDelay / parent.duration)
        } else {
            parent.duration = context.duration + repeatDelay
            parent.repeatCount = repeatCount
        }
        
        //  Add animation
        
        let rootKey = keyPath.split(separator: ".").first.map(String.init) ?? keyPath
        var existingKeys = Set(layer.animationKeys() ?? [])
        
        if shouldReplaceAnimationsForSameKey {
            for key in existingKeys {
                guard
                    key == rootKey ||
                        key.hasPrefix(rootKey + "-") ||
                        key.hasPrefix(rootKey + ".")
                else { continue }
                
                layer.removeAnimation(forKey: key)
                
                existingKeys.remove(key)
            }
        }
        
        let key = sequence(state: 1, next: {
            (index: inout Int) -> String in
            
            defer { index += 1 }
            
            return index == 1 ? rootKey : "\(rootKey)-\(index)"
        })
        .first { !existingKeys.contains($0) }
        
        layer.add(parent, forKey: key)
    }
    
}
