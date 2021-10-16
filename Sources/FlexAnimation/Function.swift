import QuartzCore

extension FlexAnimation {
    
    /// Represents an animation timing function.
    
    public enum Function {
        
        //  MARK: - Cases
        
        /// Animates using a spring-like force. Springs calculate their own duration — if you provide your own, it will be ignored.
        
        case spring(damping: CGFloat, mass: CGFloat, stiffness: CGFloat, initialVelocity: CGFloat = 0)
        
        /// Linear pacing, which causes an animation to occur evenly over its duration.
        
        case linear
        
        /// The system default timing function. Use this function to ensure that the timing of your animations matches that of most system animations.
        
        case systemDefault
        
        /// Ease-in pacing, which causes an animation to begin slowly and then speed up as it progresses.
        
        case easeIn
        
        /// Ease-in-ease-out pacing, which causes an animation to begin slowly, accelerate through the middle of its duration, and then slow again before completing.
        
        case easeInEaseOut
        
        /// Ease-out pacing, which causes an animation to begin quickly and then slow as it progresses.
        
        case easeOut
        
        /// Ease-out pacing, which causes an animation to begin quickly and then slow very gradually near the end.
        
        public static let easeOutExpo: Self = .custom(0.16, 1, 0.3, 1)
        
        /// Ease-out pacing, which causes an animation to begin quickly and slow as it progresses, overshooting slightly at the end.
        
        public static let easeOutBack: Self = .custom(0.34, 1.56, 0.64, 1)
        
        /// A timing function modeled as a cubic Bézier curve using the specified control points.
        
        case custom(Float, Float, Float, Float)
        
        
        //  MARK: - Helpers
        
        var asCAMediaTimingFunction: CAMediaTimingFunction {
            switch self {
                case .spring, .linear:
                    return .init(name: .linear)
                    
                case .systemDefault:
                    return .init(name: .default)
                    
                case .easeIn:
                    return .init(name: .easeIn)
                    
                case .easeInEaseOut:
                    return .init(name: .easeInEaseOut)
                    
                case .easeOut:
                    return .init(name: .easeOut)
                    
                case let .custom(x1, y1, x2, y2):
                    return .init(controlPoints: x1, y1, x2, y2)
            }
        }
        
        var springDuration: TimeInterval? {
            switch self {
                case let .spring(damping, mass, stiffness, initialVelocity):
                    let spring = CASpringAnimation()
                    
                    spring.damping = damping
                    spring.mass = mass
                    spring.stiffness = stiffness
                    spring.initialVelocity = initialVelocity
                    
                    return spring.settlingDuration
                    
                default: return nil
            }
        }
        
    }
    
}
