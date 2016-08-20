
import Foundation

open class ResultSetIterator<Element> : IteratorProtocol {

    let resultSet :ResultSet<Element>
    var index :Int
    var chunkStart :Int
    var chunk :ArraySlice<Element>?

    init(resultSet :ResultSet<Element>) {
        self.resultSet = resultSet
        index = 0
        chunkStart = 0
    }

    open func next() -> Element? {
        index += 1

        if let chunk = self.chunk {
            if index < chunkStart + chunk.count {
                return chunk[index - chunkStart]
            }
        }

        if index >= resultSet.count {
            resultSet.onMoreData {
                self.resultSet.synchronized {
                    self.chunk = self.resultSet.getChunk(self.index..<self.index + 10)
                }
            }
        }

        return nil
    }
}
