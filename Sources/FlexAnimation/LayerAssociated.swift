import UIKit

/// A protocol conformed to by `UIView`s and `CALayer`s.
/// You should *not* attempt to conform other types to this protocol.

public protocol LayerAssociated { }

extension CALayer: LayerAssociated { }
extension UIView: LayerAssociated { }

extension LayerAssociated {
    
    var associatedLayer: CALayer {
        switch self {
            case let layer as CALayer:
                return layer
                
            case let view as UIView:
                return view.layer
                
            default:
                fatalError("Animation API misuse. Did you try to conform a type to \(type(of: LayerAssociated.self))? That is not allowed.")
        }
    }
    
}
