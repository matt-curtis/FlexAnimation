import QuartzCore

extension FlexAnimation {
    
    class Action: CAAction {
        
        //  MARK: - Properties
        
        let oldValue: Any?
        
        let context: Context
        
        
        //  MARK: - Init
        
        init(oldValue: Any?, context: Context) {
            self.oldValue = oldValue
            self.context = context
        }
        
        
        //  MARK: - Methods
        
        func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable : Any]?) {
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
