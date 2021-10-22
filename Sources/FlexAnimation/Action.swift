import QuartzCore

extension FlexAnimation {
    
    /// A `CAAction` subclass that, when run on a given `CALayer`'s property,
    /// adds an animation to that layer for that property based on the an animation `Context`.
    /// Intended use as a return value of `CALayer`'s `action(forKey:)` method.
    
    public class Action: CAAction {
        
        //  MARK: - Properties
        
        let oldValue: Any?
        
        let context: Context
        
        
        //  MARK: - Init
        
        public init(oldValue: Any?, context: Context) {
            self.oldValue = oldValue
            self.context = context
        }
        
        
        //  MARK: - Methods
        
        public func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable : Any]?) {
            guard let layer = anObject as? CALayer else { return }
            
            let modelValue = layer.value(forKey: event)
            let presentationValue = layer.presentation()?.value(forKey: event)
            
            context.mutations.append(Context.Mutation(
                layer: layer,
                layerKey: event,
                presentationValue: presentationValue ?? modelValue
            ))
            
            var shouldBeginFromModelValue = false
            
            for case .fromModelValue in context.traits {
                shouldBeginFromModelValue = true
                
                break
            }
            
            FlexAnimation.addAnimation(
                to: layer,
                for: event,
                fromForAdditiveAnimation: oldValue,
                from: shouldBeginFromModelValue ? oldValue : (presentationValue ?? modelValue),
                to: modelValue,
                context: context
            )
        }
        
    }
    
}
