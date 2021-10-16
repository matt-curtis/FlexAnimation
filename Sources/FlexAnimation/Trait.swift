import QuartzCore

extension FlexAnimation {

    /// Represents an animation trait.
    
    public enum Trait: Hashable {
        
        /// The animation repeats the specified number of times (fractional values are allowed),
        /// waiting the given amount of time between each repetition.
        /// Note that when using this option together with the autoreverse option,
        /// one repetition = playing forwards, then backwards, effectively doubling the animation's duration
        
        case repeating(Float, withGap: TimeUnit? = nil)
        
        /// The animation repeats forever.
        
        public static let repeatingForever = repeating(.greatestFiniteMagnitude)
        
        /// The animation repeats forever, waiting the specified amount of time between each repetition.
        
        public static func repeatingForever(withGap gap: TimeUnit? = nil) -> Self {
            .repeating(.greatestFiniteMagnitude, withGap: gap)
        }
        
        /// The animation plays backwards after playing forwards.
        
        case autoreversing
        
        /// Treats nested animations as if they were not.
        
        case ignoringContext
        
        /// Defines how the animation behaves before and after its run time.
        /// Note that using `both` or `forwards` means the animation is
        /// not removed from its parent layer after it completes.
        
        case filled(CAMediaTimingFillMode)
        
        /// Removes any other animations for the same identifying key (not layer key) before adding this one.
        
        case replacingAnimationsForSameKey
        
        /// The animation begins from it's current model value, rather than presentation value.
        /// This only applies to layer model animations.
        
        case fromModelValue
        
        /// An array of traits.
        
        case array([ Self ])
        
    }

}
