//
//  Broadcaster.swift
//  BandPlay
//
//  Created by Shreyash Shah on 04/03/24.
//

import Foundation

class Broadcaster<T> {
    typealias Observer = (T) -> Void
    
    private var observers: [UUID: Observer]
    
    init() {
        self.observers = [:]
    }
    
    func addObserver(with id: UUID, _ observer: @escaping Observer) {
        observers[id] = observer
    }
    
    func removeObserver(with id: UUID) {
        observers[id] = nil
    }
    
    func broadcast(_ value: T) {
        observers.values.forEach { $0(value) }
    }
}
