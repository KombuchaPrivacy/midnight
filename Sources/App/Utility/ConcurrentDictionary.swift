//
//  ConcurrentDictionary.swift
//  
//
//  Created by Macro Ramius on 3/31/21.
//

import Foundation

// SynchronizedDictionary
// A Dictionary that uses a DispatchQueue to synchronize access.
// Can handle multiple readers in parallel, as long as there are
// no writers.
public struct SynchronizedDictionary<Key, Value> where Key : Hashable {
    private var dict: [Key:Value]
    private var queue: DispatchQueue
    
    init() {
        self.dict = [:]
        self.queue = DispatchQueue(label: "concurrent dict", qos: .default)
    }
    
    subscript(index: Key) -> Value? {
        get {
            var result: Value?
            self.queue.sync {
                result = dict[index]
            }
            return result
        }
        
        set(newValue) {
            self.queue.sync(flags: .barrier) {
                self.dict[index] = newValue
            }
        }
    }
    
}

// ConcurrentDictionary
// A synchronized dictionary that can be accessed by more than one
// writer at a time.  Built using a hash table of n "buckets", ie
// SynchronizedDictionary structs.  Access to a key only blocks if
// there is already a writer writing to the same bucket.
public struct ConcurrentDictionary<Key, Value> where Key : Hashable {
    private var buckets: [SynchronizedDictionary<Key,Value>]
    
    init(_ n: Int = 32) {
        self.buckets = Array(repeating: SynchronizedDictionary<Key,Value>(), count: n)
    }
    
    subscript(index: Key) -> Value? {
        get {
            let bucket = buckets[abs(index.hashValue) % buckets.count]
            return bucket[index]
        }
        
        set(newValue) {
            var bucket = buckets[abs(index.hashValue) % buckets.count]
            bucket[index] = newValue
        }
    }

}
