import Cocoa
import Quantise

let theSea = #imageLiteral(resourceName: "nice-sea-test-image.png").cgImage(forProposedRect: nil, context: nil, hints: nil)!
try theSea.indexed()
