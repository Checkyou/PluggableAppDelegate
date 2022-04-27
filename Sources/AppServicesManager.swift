//
//  AppServicesManager.swift
//  PluggableAppDelegate
//
//  Created by Fernando Ortiz on 2/24/17.
//  Modified by Mikhail Pchelnikov on 31/07/2018.
//  Copyright © 2018 Michael Pchelnikov. All rights reserved.
//

import UIKit
import UserNotifications

/// This is only a tagging protocol.
/// It doesn't add more functionalities yet.
public protocol ApplicationService: UIApplicationDelegate, UNUserNotificationCenterDelegate {}

extension ApplicationService {
    public var window: UIWindow? {
        return UIApplication.shared.delegate?.window ?? nil
    }
}

open class PluggableApplicationDelegate: UIResponder, UIApplicationDelegate {

    public var window: UIWindow?

    open var services: [ApplicationService] { return [] }

    lazy var _services: [ApplicationService] = {
        return self.services
    }()
    
    private var methodRespondsCache: [Selector: Bool] = [:]

    @discardableResult
    internal func apply<T, S>(_ work: (ApplicationService, @escaping (T) -> Void) -> S?, completionHandler: @escaping ([T]) -> Void) -> [S] {
        let dispatchGroup = DispatchGroup()
        var results: [T] = []
        var returns: [S] = []

        for service in _services {
            dispatchGroup.enter()
            let returned = work(service, { result in
                results.append(result)
                dispatchGroup.leave()
            })
            if let returned = returned {
                returns.append(returned)
            } else { // delegate doesn't impliment method
                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: .main) {
            completionHandler(results)
        }

        return returns
    }
    
    override open func responds(to aSelector: Selector!) -> Bool {
        if let isHaveServicesResponds = methodRespondsCache[aSelector] {
            return isHaveServicesResponds
        } else {
            let responds = _services.reduce(false, { prev, service in
                service.responds(to: aSelector) || prev
            })
            methodRespondsCache[aSelector] = responds
            return responds
        }
    }
}
