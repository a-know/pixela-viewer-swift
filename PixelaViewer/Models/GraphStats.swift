import Foundation

struct GraphStats: Decodable {
    let todaysQuantity: Double
    let yesterdayQuantity: Double
    let maxQuantity: Double
    let minQuantity: Double
    let avgQuantity: Double
}
