extension FlexAnimation {
    
    /// Represents the completion state of a set of animations.
    
    public enum CompletionState {
        
        /// All animations (even nested ones) ran for their entire durations.
        
        case completed
        
        /// An animation (possibly a nested one) was removed before it could finish.
        
        case interrupted
        
    }
    
}
