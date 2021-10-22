import QuartzCore

extension CALayer {
    
    static func swizzleActionForKeyIfNeeded() {
        enum Static {
            
            static var didSwizzle = false
            
        }
        
        guard !Static.didSwizzle else { return }
        
        Static.didSwizzle = true
        
        guard
            let originalMethod = class_getInstanceMethod(Self.self, #selector(action(forKey:))),
            let swizzledMethod = class_getInstanceMethod(Self.self, #selector(swizzled_action(forKey:)))
        else {
            print("⚠️ Error in Animation API: failed to swizzle action(forKey) method; animations made by setting layer properties will fail.")
            
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc(_FlexAnimation_swizzled_actionForKey:)
    func swizzled_action(forKey key: String) -> CAAction? {
        switch key {
            //  Try to exclude non-properties (actions/events) from animation.
            
            case kCAOnOrderIn, kCAOnOrderOut, kCATransition, #keyPath(sublayers):
                break
                
            default:
                if let context = FlexAnimation.context {
                    if !FlexAnimation.canAnimateLayerImplicitly(.init(layer: self)) {
                        break
                    }
                    
                    return FlexAnimation.Action(oldValue: value(forKey: key), context: context)
                }
        }
        
        return swizzled_action(forKey: key)
    }

}
