//
//  ServiceFactory2.swift
//  test
//
//  Created by mat on 9/4/24.
//

import Foundation

enum ServiceType {
    case singleton
    case newSingleton
    case new
    case automatic
}


@propertyWrapper
struct Service<Service> {

    var service: Service

    init(_ type: ServiceType = .singleton) {
        guard let service = ServiceContainer.resolve(type, Service.self) else {
            let serviceName = String(describing: Service.self)
            fatalError("No service of type \(serviceName) registered!")
        }

        self.service = service
    }

    var wrappedValue: Service {
        get { self.service }
        mutating set { service = newValue }
    }
}

class ServiceContainer{
    private static var factories: [String: () -> Any] = [:]
    private static var cache: [String: Any] = [:]
    
    public nonisolated(unsafe) static func resolve<Service>(_ resolveType: ServiceType = .singleton, _ type: Service.Type) -> Service? {
        let serviceName = String(describing: type.self)

        switch resolveType {
        case .singleton:
            if let service = cache[serviceName] as? Service {
                return service
            } else {
                let service = factories[serviceName]?() as? Service
                if let service = service {
                    cache[serviceName] = service
                }
                return service
            }
        case .newSingleton:
            let service = factories[serviceName]?() as? Service

            if let service = service {
                cache[serviceName] = service
            }

            return service
        case .automatic:
            fallthrough
        case .new:
            return factories[serviceName]?() as? Service
        }
    }
    
    public nonisolated(unsafe) static func register<Service>(type: Service.Type, _ factory: @autoclosure @escaping () -> Service) {
        factories[String(describing: type.self)] = factory
    }
}
