import QuartzCore

extension FlexAnimation {
    
    /// Represents the timing (start, duration, etc.) an animation happens in, as well as any traits.

    public class Context {
        
        //  MARK: - Helper types
        
        /// Represents the record of a layer mutation, which occurs whenever a layer's property is set.
        
        public class Mutation {
            
            /// The layer mutated.
            
            weak var layer: CALayer?
            
            /// The layer key that was mutated.
            
            let layerKey: String
            
            /// The layers presentation value at the time of the layer property was set.
            
            let presentationValue: Any?
            
            
            init(layer: CALayer, layerKey: String, presentationValue: Any?) {
                self.layer = layer
                self.layerKey = layerKey
                self.presentationValue = presentationValue
            }
            
        }
        
        
        //  MARK: - Properties
        
        public let start: TimeInterval
        
        public let duration: TimeInterval
        
        public let function: Function
        
        /// Any time a layer's property is changed, a mutation is recorded and stored here.
        /// This does not include purely presentational animations made via animator.
        
        public internal(set) var mutations: [ Mutation ] = []
        
        let traits: [ Trait ]
        
        
        //  MARK: - Init
        
        public init(start: TimeInterval, duration: TimeInterval, function: Function, traits: [ Trait ]) {
            self.start = start
            self.duration = duration
            self.function = function
            self.traits = traits
        }
        
    }

}
