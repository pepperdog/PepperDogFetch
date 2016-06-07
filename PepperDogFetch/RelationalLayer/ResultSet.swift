
/*
 General scheme is this:
 
 The DatabaseConnection retrieves rows and appends them to the ResultSet. The ResultSet fills up an incoming buffer. When the buffer is filled, it enqueues an asynchronous block to the synchronizedQueue to dump the block into main storage, then creates a new incoming array. If there are parked iterators, it enables the parkQueue
 
 On the reader side, if an iterator runs into the end of the storage, it enqueues a synchronous block to check if there is more data. If there is more data, it continues with the data. If there is no more data, it adds itself to the parkedIterators, and suspends the parkQueue. Upon exit from the synchronous block, it makes a synchronous call to the parkQueue to park itself and wait for incoming data.
 
 Once the fetch has been completed, the completed flag is set, and the queues are destroyed.
 */
public class ResultSet : Sequence {

    //let description :Table
    lazy var synchronizeQueue :dispatch_queue_t? = {
        guard let queue = dispatch_queue_create("com.pepperdog-enterprises.PepperDogFetch.ResultSet.synchronizeQueue", DISPATCH_QUEUE_SERIAL) else {
            fatalError("Could not create queue")
        }
        return queue
    }()

    lazy var parkQueue        :dispatch_queue_t? = {
        guard let queue = dispatch_queue_create("com.pepperdog-enterprises.PepperDogFetch.ResultSet.parkQueue", DISPATCH_QUEUE_CONCURRENT) else {
            fatalError("Could not create queue")
        }
        dispatch_suspend(queue)
        return queue
    }()
    //var parkedIterators  :Array<Iterator>
    //var incoming         :Array<Iterator.Element>

    var storage :Array<AnyObject>
    var completed :Bool

    var error :ErrorProtocol?

    /*
    init(description :Table) {
        self.description = description;
        self.accessQueue = dispatch_queue_create("com.pepperdog-enterprises.PepperDogFetch.ResultSet.accessQueue", DISPATCH_QUEUE_SERIAL)
    }
    */

    init() {
        self.storage = Array<AnyObject>()
        completed = false
    }


    // MARK: Sequence Protocol

    public func makeIterator() -> ResultSet.Iterator {
        return ResultSet.Iterator()
    }

    public var underestimatedCount: Int {
        get {
            guard let queue = self.synchronizeQueue else {
                return self.storage.underestimatedCount
            }

            var count :Int
            dispatch_sync(queue) {
                count = self.storage.underestimatedCount
            }
            return count
        }
    }

    public func map<T>(_ transform: @noescape (ResultSet.Iterator.Element) throws -> T) rethrows -> [T] {
        fatalError()
    }

    public func filter(_ includeElement: @noescape (Iterator.Element) throws -> Bool) rethrows -> [Iterator.Element] {
        fatalError()
    }

    public func forEach(_ body: @noescape (Iterator.Element) throws -> Swift.Void) rethrows {
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

    public func split(maxSplits: Int, omittingEmptySubsequences: Bool, isSeparator: @noescape (Iterator.Element) throws -> Bool) rethrows -> [ResultSet] {
        fatalError()
    }

    public func first(where: @noescape (Self.Iterator.Element) throws -> Bool) rethrows -> Iterator.Element?

    // MARK: Class Iterator

    public class Iterator<Element> : IteratorProtocol {
        public func next() -> Element? {
            return nil
        }
    }

}