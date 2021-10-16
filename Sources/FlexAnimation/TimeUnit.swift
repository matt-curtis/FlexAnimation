import QuartzCore

extension FlexAnimation {

    /// An absolute or relative unit of time. Float and integer literals are interpreted as absolute values (seconds).

    public enum TimeUnit: Hashable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        
        //  MARK: - Type aliases
        
        public typealias Fraction = TimeInterval
        public typealias Seconds = TimeInterval
        
        
        //  MARK: - Cases
        
        case rel(Fraction)
        case abs(Seconds)
        
        
        //  MARK: - Convenience static properties
        
        public static var end: Self { .rel(1) }
        
        public static var entirety: Self { .rel(1) }
        
        
        //  MARK: - Init
        
        public init(floatLiteral value: FloatLiteralType) {
            self = .abs(value)
        }
        
        public init(integerLiteral value: IntegerLiteralType) {
            self = .abs(TimeInterval(value))
        }
        
        
        //  MARK: - Methods
        
        private func logWarningAboutMisuseOfRelativeUnitsOutsideContext() {
            //    No context available to give meaning to relative unit,
            //    so treat as absolute.
            //    This should only happen if animate() is called at the top-level
            //    with relative time parameters.
            
            print("⚠️ Animation API misuse: relative time units used in animation that has no parent context; treating values as if absolute.")
        }
        
        func asAbsoluteTime(using context: Context?, fallbackStartTime: TimeInterval) -> TimeInterval {
            switch self {
                case .rel(let value):
                    if let context = context {
                        return context.start + (context.duration * value)
                    } else {
                        logWarningAboutMisuseOfRelativeUnitsOutsideContext()
                        
                        fallthrough
                    }
                    
                case .abs(let value):
                    return (context?.start ?? fallbackStartTime) + value
            }
        }
        
        func asAbsoluteDuration(using context: Context?, fallbackToTransitionTime: Bool = true) -> TimeInterval {
            switch self {
                case .rel(let value):
                    if let context = context {
                        return context.duration * value
                    } else {
                        logWarningAboutMisuseOfRelativeUnitsOutsideContext()
                        
                        fallthrough
                    }
                    
                case .abs(let value):
                    if fallbackToTransitionTime && value <= 0 {
                        return CATransaction.animationDuration()
                    }
                    
                    return value
            }
        }
        
    }

}
