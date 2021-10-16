import QuartzCore

extension FlexAnimation {
    
    /// This class mimics how UIKit's animation methods behave, calling the completion closure
    /// once all animations complete.
    
    class AnimationCompletionMonitor: NSObject, CAAnimationDelegate {
        
        //  MARK: - Properties
        
        private weak var parentMonitor: AnimationCompletionMonitor?
        
        private var pendingAnimations: Int = 0
        
        private var onComplete: ((CompletionState) -> Void)?
        
        
        //  MARK: - Init
        
        init(onComplete: @escaping (CompletionState) -> Void, parent: AnimationCompletionMonitor?) {
            self.onComplete = onComplete
            self.parentMonitor = parent
        }
        
        
        //  MARK: - CAAnimationDelegate methods
        
        func animationDidStart(_ anim: CAAnimation) {
            pendingAnimations += 1
            
            parentMonitor?.animationDidStart(anim)
        }
        
        func animationDidStop(_ anim: CAAnimation, finished didFinish: Bool) {
            if !didFinish {
                pendingAnimations = 0
                
                onComplete?(.interrupted)
                onComplete = nil
            } else {
                pendingAnimations -= 1
                
                if pendingAnimations == 0 {
                    onComplete?(.completed)
                    onComplete = nil
                }
            }
            
            parentMonitor?.animationDidStop(anim, finished: didFinish)
        }
        
    }
    
}
