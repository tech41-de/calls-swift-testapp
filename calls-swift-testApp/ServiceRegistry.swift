//
//  ServiceRegistry.swift
//  calls-swift-testApp
//
//  Created by mat on 9/4/24.
//

import Foundation

public struct ServiceRegistry {
    public enum Error: Swift.Error {
        case notRegistered(Any.Type)
    }

    private struct ServiceFactory<Service> {
        let block: (() -> Service)

        init(block: @escaping (() -> Service)) {
            self.block = block
        }

        func make() -> Service {
            return block()
        }
    }

    private var factories: [Any] = []

    public init() {

    }

    public init(registry: ServiceRegistry) {
        self.factories = registry.factories
    }

    public mutating func register<Service>(_ service: Service) {
        register(service, as: type(of: service))
    }

    public mutating func register<Service>(_ service: Service, as serviceType: Service.Type) {
        let factory = ServiceFactory { () -> Service in
            return service
        }

        factories.append(factory)
    }

    public mutating func register<Service>(_ block: @escaping (() -> Service)) {
        let factory = ServiceFactory(block: block)
        factories.append(factory)
    }

    internal func make<Service>(_ serviceType: Service.Type) throws -> Service {
        if let factory = factories.first(where: {($0 is ServiceFactory<Service>)}) {
            let service = (factory as! ServiceFactory<Service>).make()
            return service
        }

        throw Error.notRegistered(Service.self)
    }
}

public struct ServiceLocator {
    public static var shared: ServiceLocator = ServiceLocator()

    public let registry: ServiceRegistry

    public init() {
        let registry = ServiceRegistry()
        self.init(registry: registry)
    }

    public init(registry: ServiceRegistry) {
        self.registry = registry
    }

    public func make<Service>(_ serviceType: Service.Type) throws -> Service {
        let service = try registry.make(Service.self)
        return service
    }
}

@propertyWrapper
public struct Service<ServiceType> {
    public let locator: ServiceLocator

    public var wrappedValue: ServiceType {
        return try! locator.make(ServiceType.self)
    }

    public init(locator: ServiceLocator) {
        self.locator = locator
    }

    public init() {
        self.locator = ServiceLocator.shared
    }
}

