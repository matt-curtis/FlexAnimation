import UIKit

extension FlexAnimation {
    
    public enum LayerKeyValueTag3DPoint { }
    
    public enum LayerKeyPlaceholderValue {
        
        case presentation, model
        
        
        fileprivate func asLayerKeyValue<T>() -> LayerKeyValue<T> { .placeholder(self) }
        
    }
    
    fileprivate enum LayerKeyValue<T> {
        
        case placeholder(LayerKeyPlaceholderValue)
        case value(T?)
        
        
        func resolve(using layer: CALayer, andKeyPath keyPath: String) -> Any? {
            switch self {
                case .placeholder(.presentation):
                    return (layer.presentation() ?? layer).value(forKey: keyPath)
                    
                case .placeholder(.model):
                    return layer.value(forKey: keyPath)
                    
                case .value(let value):
                    return value
            }
        }
        
    }
    
    public class LayerKeyPathOrValues<Value, Tag> {
        
        //  MARK: - Type aliases
        
        public typealias This = LayerKeyPathOrValues<Value, Tag>
        
        
        //  MARK: - Subtypes
        
        private enum Content {
            
            case layerAndKeyPath(CALayer, String)
            case values(from: LayerKeyValue<Value>?, to: LayerKeyValue<Value>?)
            
        }
        
        
        //    MARK: - Properties
        
        private let content: Content
        
        
        fileprivate var values: (from: LayerKeyValue<Value>?, to: LayerKeyValue<Value>?)? {
            switch content {
                case let .values(from, to): return (from, to)
                default: return nil
            }
        }
        
        
        //    MARK: - Init
        
        fileprivate init(layer: CALayer, keyPath: String) {
            content = .layerAndKeyPath(layer, keyPath)
        }
        
        private init(from: LayerKeyValue<Value>?, to: LayerKeyValue<Value>?) {
            content = .values(from: from, to: to)
        }
        
        
        //    MARK: - From/to variations
        
        static func from(_ from: LayerKeyPlaceholderValue, to: LayerKeyPlaceholderValue) -> This {
            .init(from: from.asLayerKeyValue(), to: to.asLayerKeyValue())
        }
        
        static func from(_ from: Value?, to: LayerKeyPlaceholderValue) -> This {
            .init(from: .value(from), to: to.asLayerKeyValue())
        }
        
        static func from(_ from: LayerKeyPlaceholderValue, to: Value?) -> This {
            .init(from: from.asLayerKeyValue(), to: .value(to))
        }
        
        static func from(_ from: Value?, to: Value?) -> LayerKeyPathOrValues {
            .init(from: .value(from), to: .value(to))
        }
        
        
        static func `static`(_ value: Value?) -> This {
            .init(from: .value(value), to: .value(value))
        }
        
        static func `static`(_ value: LayerKeyPlaceholderValue) -> This {
            .init(from: value.asLayerKeyValue(), to: value.asLayerKeyValue())
        }
        
        
        //  MARK: - Property getter and setters
        
        private func get<KV, T>(property: String = #function) -> LayerKeyPathOrValues<KV, T> {
            switch content {
                case let .layerAndKeyPath(layer, keyPath):
                    return .init(layer: layer, keyPath: "\(keyPath).\(property)")
                    
                default:
                    fatalError("This method should only be called by the getter of a synthetic property.")
            }
        }
        
        private func set<KV, T>(_ values: LayerKeyPathOrValues<KV, T>, property: String = #function) {
            switch (content, values.content) {
                case let (.layerAndKeyPath(layer, keyPath), .values(from, to)):
                    guard let context = FlexAnimation.context else {
                        print("⚠️ Animation API misuse: Layer animator used outside of animate() closure.")
                        
                        return
                    }
                    
                    let fullKeyPath = "\(keyPath).\(property)"
                    
                    FlexAnimation.addAnimation(
                        to: layer,
                        for: fullKeyPath,
                        fromForAdditiveAnimation: nil,
                        from: from?.resolve(using: layer, andKeyPath: fullKeyPath),
                        to: to?.resolve(using: layer, andKeyPath: fullKeyPath),
                        context: context
                    )
                    
                default:
                    fatalError("Unable to use non-value")
            }
        }
        
    }
    
    /// Converts a keyPath to string by intercepting the getter call the keyPath subscript makes.
    
    class LayerKeyPathToStringConverter: NSObject {
        
        private static let shared = LayerKeyPathToStringConverter()
        
        private var target: CALayer?
        
        private var lastPropertyAccessed: String?
        
        
        override func forwardingTarget(for selector: Selector!) -> Any? {
            lastPropertyAccessed = NSStringFromSelector(selector)
            
            return target
        }
        
        
        static func string<Layer: CALayer>(for keyPath: PartialKeyPath<Layer>, on layer: Layer) -> String {
            shared.target = layer
            
            defer {
                shared.lastPropertyAccessed = nil
                shared.target = nil
            }
            
            _ = unsafeBitCast(shared, to: Layer.self)[keyPath: keyPath]
            
            guard let string = shared.lastPropertyAccessed else {
                fatalError("Failed to get property for keyPath: \(keyPath)")
            }
            
            return string
        }
        
    }
    
    @dynamicMemberLookup
    public class LayerProxy<Layer: CALayer> {
        
        private let layer: Layer
        
        
        init(for layer: Layer) {
            self.layer = layer
        }
        
        
        public subscript<T>(dynamicMember keyPath: KeyPath<Layer, T>) -> LayerKeyPathOrValues<T, Void> {
            get {
                .init(layer: layer, keyPath: LayerKeyPathToStringConverter.string(for: keyPath, on: layer))
            }
            
            set {
                guard let (from, to) = newValue.values else {
                    fatalError("Unable to use non-value")
                }
                
                guard let context = FlexAnimation.context else {
                    print("⚠️ Animation API misuse: Layer animator used outside of animate() closure.")
                    
                    return
                }
                
                let keyPathString = LayerKeyPathToStringConverter.string(for: keyPath, on: layer)
                
                FlexAnimation.addAnimation(
                    to: layer,
                    for: keyPathString,
                    fromForAdditiveAnimation: nil,
                    from: from?.resolve(using: layer, andKeyPath: keyPathString),
                    to: to?.resolve(using: layer, andKeyPath: keyPathString),
                    context: context
                )
            }
        }
        
        
        subscript(keyPath: String) -> LayerKeyPathOrValues<Any, Void> {
            get {
                .init(layer: layer, keyPath: keyPath)
            }
            
            set {
                guard let (from, to) = newValue.values else {
                    //    This should only happen when setters "echo" up the property access chain, i.e.:
                    //    bounds.origin.x = ..., will trigger x's setter, then origin's, then bounds...
                    //    but that isn't what we want, we only care about the tail assignment of property access,
                    //    which will always have a value for us
                    
                    return
                }
                
                guard let context = FlexAnimation.context else {
                    print("⚠️ Animation API misuse: Layer animator used outside of animate() closure.")
                    
                    return
                }
                
                FlexAnimation.addAnimation(
                    to: layer,
                    for: keyPath,
                    fromForAdditiveAnimation: nil,
                    from: from?.resolve(using: layer, andKeyPath: keyPath),
                    to: to?.resolve(using: layer, andKeyPath: keyPath),
                    context: context
                )
            }
        }
        
    }
    
}

extension FlexAnimation.LayerKeyPathOrValues where Value == CGRect {
    
    public var origin: FlexAnimation.LayerKeyPathOrValues<CGPoint, Void> { get { get() } set { set(newValue) } }
    
    public var size: FlexAnimation.LayerKeyPathOrValues<CGSize, Void> { get { get() } set { set(newValue) } }
    
}

extension FlexAnimation.LayerKeyPathOrValues where Value == CGPoint {
    
    public var x: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
    public var y: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
}

extension FlexAnimation.LayerKeyPathOrValues where Value == CGSize, Tag == Void {
    
    public var width: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
    public var height: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
}

extension FlexAnimation.LayerKeyPathOrValues where Value == CATransform3D {
    
    public static func from(_ from: CGAffineTransform?, to: FlexAnimation.LayerKeyPlaceholderValue) -> This {
        .from(
            from.map(CATransform3DMakeAffineTransform),
            to: to
        )
    }
    
    public static func from(_ from: FlexAnimation.LayerKeyPlaceholderValue, to: CGAffineTransform?) -> This {
        .from(
            from,
            to: to.map(CATransform3DMakeAffineTransform)
        )
    }
    
    public static func from(_ from: CGAffineTransform?, to: CGAffineTransform?) -> This {
        .from(
            from.map(CATransform3DMakeAffineTransform),
            to: to.map(CATransform3DMakeAffineTransform)
        )
    }
    
    public static func `static`(_ value: CGAffineTransform?) -> This {
        .from(value, to: value)
    }
    
    
    ///    Set to a CGSize that indicates the amount to translate in the x and y axis.
    
    public var translation: FlexAnimation.LayerKeyPathOrValues<CGSize, FlexAnimation.LayerKeyValueTag3DPoint> { get { get() } set { set(newValue) } }
    
    ///    Set to a number whose value is the rotation, in radians, of the z axis. This field is identical to setting the rotation.z field.
    
    public var rotation: FlexAnimation.LayerKeyPathOrValues<CGFloat, FlexAnimation.LayerKeyValueTag3DPoint> { get { get() } set { set(newValue) } }
    
    ///    Set to a number whose value is the average of all three scale factors.
    
    public var scale: FlexAnimation.LayerKeyPathOrValues<CGFloat, FlexAnimation.LayerKeyValueTag3DPoint> { get { get() } set { set(newValue) } }
    
}

extension FlexAnimation.LayerKeyPathOrValues where Tag == FlexAnimation.LayerKeyValueTag3DPoint {
    
    public var x: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
    public var y: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
    public var z: FlexAnimation.LayerKeyPathOrValues<CGFloat, Void> { get { get() } set { set(newValue) } }
    
}

extension FlexAnimation.LayerKeyPathOrValues where Value == CGSize, Tag == FlexAnimation.LayerKeyValueTag3DPoint {
    
    public static func from(_ from: CGPoint?, to: FlexAnimation.LayerKeyPlaceholderValue) -> This {
        .from(
            from.map { CGSize(width: $0.x, height: $0.y) },
            to: to
        )
    }
    
    public static func from(_ from: FlexAnimation.LayerKeyPlaceholderValue, to: CGPoint?) -> This {
        .from(
            from,
            to: to.map { CGSize(width: $0.x, height: $0.y) }
        )
    }
    
    public static func from(_ from: CGPoint?, to: CGPoint?) -> This {
        .from(
            from.map { CGSize(width: $0.x, height: $0.y) },
            to: to.map { CGSize(width: $0.x, height: $0.y) }
        )
    }
    
    public static func `static`(_ value: CGPoint?) -> This {
        .from(value, to: value)
    }
    
}

extension CALayer {
    
    public var animator: FlexAnimation.LayerProxy<CALayer> { .init(for: self) }
    
}

extension UIView {
    
    public var animator: FlexAnimation.LayerProxy<CALayer> { layer.animator }
    
}
