import UIKit

extension FlexAnimation {
    
    /// `NSObject`s have a default equatable conformance that doesn't require that the two
    /// types being compared are actually of the same type, only that they're both `NSObject`s.
    /// This struct is intended to make it harder to unintentionally write an incorrect comparison statement
    /// in an `animate()` call, i.e.: `filter: { some CALayer == some UIView }` (which the default == operator would allow.)
    
    public struct SaferLayerWrapperForComparison {
        
        let layer: CALayer
        
        
        public func belongs(to view: UIView) -> Bool {
            view.layer == layer
        }
        
        public func `is`(_ otherLayer: CALayer) -> Bool {
            otherLayer == layer
        }
        
        
        public func isOrDescends(from possibleAncestorLayer: CALayer) -> Bool {
            sequence(first: layer, next: { $0.superlayer }).contains { $0 == possibleAncestorLayer }
        }
        
        public func isOrDescends(from possibleAncestorView: UIView) -> Bool {
            isOrDescends(from: possibleAncestorView.layer)
        }
        
        
        public func descends(from possibleAncestorLayer: CALayer) -> Bool {
            guard let first = layer.superlayer else { return false }
            
            return sequence(first: first, next: { $0.superlayer }).contains { $0 == possibleAncestorLayer }
        }
        
        public func descends(from possibleAncestorView: UIView) -> Bool {
            descends(from: possibleAncestorView.layer)
        }
        
        
        public static func == (lhs: Self, rhs: CALayer) -> Bool {
            lhs.is(rhs)
        }
        
        public static func == (lhs: Self, rhs: UIView) -> Bool {
            lhs.belongs(to: rhs)
        }
        
    }
    
}
