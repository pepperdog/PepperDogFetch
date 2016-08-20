
/*
 General scheme is this:
 
 The DatabaseConnection retrieves rows and appends them to the ResultSet. The ResultSet fills up an incoming buffer. When the buffer is filled, it enqueues an asynchronous block to the synchronizedQueue to dump the block into main storage, then creates a new incoming array. If there are parked iterators, it enables the parkQueue
 
 On the reader side, if an iterator runs into the end of the storage, it enqueues a synchronous block to check if there is more data. If there is more data, it continues with the data. If there is no more data, it adds itself to the parkedIterators, and suspends the parkQueue. Upon exit from the synchronous block, it makes a synchronous call to the parkQueue to park itself and wait for incoming data.
 
 Once the fetch has been completed, the completed flag is set, and the queues are destroyed.
 */
open class ResultSet<Element> : Sequence {

    var storage :[Element]
    var count :Int {
        get {
            guard let info = self.fetchingInfo else {
                return self.storage.count
            }
            return info.storageCount
        }
    }
    var error :Error? {
        get {return self.fetchingInfo?.error}
        set {
            guard let info = self.fetchingInfo else {
                fatalError("tried to set error on ResultSet with no fetching info")
            }
            info.error = newValue
        }
    }

    // Store fetching info on the side so when fetching is done, we can just blow the whole thing away to save space.
    fileprivate var fetchingInfo :ResultSetFetchingInfo<Element>?

    /*
    init(description :Table) {
        self.description = description;
        self.accessQueue = dispatch_queue_create("com.pepperdog-enterprises.PepperDogFetch.ResultSet.accessQueue", DISPATCH_QUEUE_SERIAL)
    }
    */

    init() {
        self.storage = [Element]()
    }

    func goAsynchronous() {
        self.fetchingInfo = ResultSetFetchingInfo()
    }

    func synchronized(_ handler :() ->Void) {
        guard let info = self.fetchingInfo else {
            handler()
            return
        }
        info.synchronizeQueue.sync(execute: handler)
    }

    func onMoreData(_ handler :() -> Void) {
        guard let info = self.fetchingInfo else {
            handler()
            return
        }
        info.parkQueue.sync(execute: handler)
    }

    func getChunk(_ range :Range<Int>) -> ArraySlice<Element> {
        return self.storage[range]
    }

    // MARK: Sequence Protocol

    /*
    public func makeIterator() -> ResultSetIterator<Element> {
        return ResultSetIterator<Element>(resultSet: self)
    }

    public var underestimatedCount: Int {
        get {
            guard let fetchingInfo = self.fetchingInfo else {
                return self.storage.underestimatedCount
            }

            var count :Int = 0
            fetchingInfo.synchronizeQueue.sync() {
                count = self.storage.underestimatedCount
            }
            return count
        }
    }

    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        fatalError()
    }

    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        fatalError()
    }

    public func forEach(_ body: (Element) throws -> Void) rethrows {
    }

    public func dropFirst(_ n: Int) -> ResultSet {
        fatalError()
    }

    public func dropLast(_ n: Int) -> ResultSet {
        fatalError()
    }

    public func prefix(_ maxLength: Int) -> ResultSet {
        fatalError()
    }

    public func suffix(_ maxLength: Int) -> ResultSet {
        fatalError()
    }

    public func split(maxSplits: Int, omittingEmptySubsequences: Bool, isSeparator: (Element) throws -> Bool) rethrows -> [ResultSet] {
        fatalError()
    }

    public func first(where: (Element) throws -> Bool) rethrows -> Element? {
        fatalError()
    }
    */


    /// A type that provides the sequence's iteration interface and
    /// encapsulates its iteration state.
    //associatedtype Iterator : IteratorProtocol

    /// A type that represents a subsequence of some of the sequence's elements.
    //associatedtype SubSequence

    /// Returns an iterator over the elements of this sequence.
    public func makeIterator() -> ResultSetIterator<Element> {
        return ResultSetIterator<Element>(resultSet: self)
    }

    public var underestimatedCount: Int {
        get {
            guard let fetchingInfo = self.fetchingInfo else {
                return self.storage.underestimatedCount
            }

            var count :Int = 0
            fetchingInfo.synchronizeQueue.sync() {
                count = self.storage.underestimatedCount
            }
            return count
        }
    }

    public func map<T>(_ transform: (Element) throws -> T) rethrows -> [T] {
        fatalError()
    }

    public func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> [Element] {
        fatalError()
    }

    public func forEach(_ body: (Element) throws -> Swift.Void) rethrows {
        fatalError()
    }

    public func dropFirst(_ n: Int) -> ResultSet {
        fatalError()
    }

    public func dropLast(_ n: Int) -> ResultSet {
        fatalError()
    }

    public func prefix(_ maxLength: Int) -> ResultSet {
        fatalError()
    }

    public func suffix(_ maxLength: Int) -> ResultSet {
        fatalError()
    }

    public func split(maxSplits: Int, omittingEmptySubsequences: Bool, whereSeparator isSeparator: (Element) throws -> Bool) rethrows -> [ResultSet] {
        fatalError()
    }

    public func first(where predicate: (Element) throws -> Bool) rethrows -> Element? {
        fatalError()
    }
}


private class ResultSetFetchingInfo<Element> {
    let synchronizeQueue :DispatchQueue
    let parkQueue        :DispatchQueue

    var parkedIterators  :Array<ResultSetIterator<Element>>
    var incoming         :Array<Element>
    var error            :Error?
    var storageCount     :Int  // keep storageCount here while we're loading because Array.count may not necessarily be threadsafe.

    init() {
        synchronizeQueue = DispatchQueue(label: "c.p-e.PDF.ResultSet.synchronizeQueue", attributes: [])
        parkQueue = DispatchQueue(label: "c.p-e.PDF.ResultSet.parkQueue", attributes: .concurrent)
        parkQueue.suspend()
        parkedIterators = Array<ResultSetIterator<Element>>()
        incoming = Array<Element>()
        storageCount = 0
    }

}
