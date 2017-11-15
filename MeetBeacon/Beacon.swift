import Foundation

class Beacon {
    var identifier: String!
    var uuid: String!
    var major: Int!
    var minor: Int!
    var rssi = 0
    var count = 0
    var message: String!
    var dial: String!
    
    init(_ identifier: String, uuid: String, major: Int, minor: Int) {
        self.identifier = identifier
        self.uuid = uuid
        self.major = major
        self.minor = minor
    }
}
