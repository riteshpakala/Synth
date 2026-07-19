// DifferentialTests.swift — the JS↔Swift faithfulness harness.
// Fixtures/expected.json is generated from the actual JS strudel package by
// Tools/differential/gen_expected.mjs; this test replays the corpus through
// the Swift engine and diffs every hap. AGPL-3.0-or-later.

import XCTest
@testable import StrudelMini
@testable import StrudelCore

final class DifferentialTests: XCTestCase {
    struct ExpectedHap: Decodable {
        let whole: [String]?
        let part: [String]
        let value: AnyValue
    }

    /// JSON value that can be a string, number, bool, or list.
    enum AnyValue: Decodable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case list([AnyValue])

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let b = try? c.decode(Bool.self) { self = .bool(b); return }
            if let n = try? c.decode(Double.self) { self = .number(n); return }
            if let s = try? c.decode(String.self) { self = .string(s); return }
            if let l = try? c.decode([AnyValue].self) { self = .list(l); return }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "unsupported value")
        }

        func matches(_ v: PatternValue) -> Bool {
            switch self {
            case .string(let s): return v.stringValue == s
            case .number(let n): return v.doubleValue == n
            case .bool(let b): return v == .bool(b)
            case .list(let l):
                guard let items = v.listValue, items.count == l.count else { return false }
                return Swift.zip(l, items).allSatisfy { $0.0.matches($0.1) }
            }
        }

        var display: String {
            switch self {
            case .string(let s): return s
            case .number(let n): return "\(n)"
            case .bool(let b): return "\(b)"
            case .list(let l): return "[\(l.map(\.display).joined(separator: ","))]"
            }
        }
    }

    func testCorpusMatchesJS() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures/expected", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let expected = try JSONDecoder().decode([String: [ExpectedHap]].self, from: data)
        XCTAssertGreaterThan(expected.count, 10)

        for (code, expectedHaps) in expected.sorted(by: { $0.key < $1.key }) {
            let pat: StrudelCore.Pattern
            do {
                pat = try mini(code)
            } catch {
                XCTFail("\(code): failed to parse: \(error)")
                continue
            }
            let haps = pat.sortHapsByPart().queryArc(Fraction(0), Fraction(2))
            XCTAssertEqual(haps.count, expectedHaps.count,
                           "\(code): got \(haps.count) haps, JS got \(expectedHaps.count)")
            guard haps.count == expectedHaps.count else { continue }
            for (mine, theirs) in Swift.zip(haps, expectedHaps) {
                let partMatch = mine.part.begin.show() == theirs.part[0]
                    && mine.part.end.show() == theirs.part[1]
                XCTAssertTrue(partMatch,
                    "\(code): part \(mine.part.show()) != \(theirs.part[0])→\(theirs.part[1])")
                if let w = theirs.whole {
                    XCTAssertEqual(mine.whole?.begin.show(), w[0], "\(code): whole begin")
                    XCTAssertEqual(mine.whole?.end.show(), w[1], "\(code): whole end")
                } else {
                    XCTAssertNil(mine.whole, "\(code): expected continuous hap")
                }
                XCTAssertTrue(theirs.value.matches(mine.value),
                    "\(code): value \(mine.value) != \(theirs.value.display)")
            }
        }
    }
}
