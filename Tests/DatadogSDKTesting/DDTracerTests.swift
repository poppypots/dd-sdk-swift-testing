/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

@testable import DatadogSDKTesting
import OpenTelemetryApi
import OpenTelemetrySdk
import XCTest

class DDTracerTests: XCTestCase {
    override func setUp() {
        DDEnvironmentValues.environment["DATADOG_CLIENT_TOKEN"] = "fakeToken"
    }

    override func tearDown() {}

    func testWhenCalledStartSpanAttributes_spanIsCreatedWithAttributes() {
        let tracer = DDTracer()
        let attributes = ["myKey": "myValue"]
        let spanName = "myName"

        let span = tracer.startSpan(name: spanName, attributes: attributes)

        let spanData = span.toSpanData()
        XCTAssertEqual(spanData.name, spanName)
        XCTAssertEqual(spanData.attributes.count, 1)
        XCTAssertEqual(spanData.attributes["myKey"]?.description, "myValue")

        span.end()
    }

    func testWhenCalledStartSpanWithoutAttributes_spanIsCreatedWithoutAttributes() {
        let tracer = DDTracer()
        let spanName = "myName"

        let span = tracer.startSpan(name: spanName, attributes: [:])

        let spanData = span.toSpanData()

        XCTAssertEqual(spanData.name, spanName)
        XCTAssertEqual(spanData.attributes.count, 0)

        span.end()
    }

    func testTracePropagationHTTPHeadersCalledWithAnActiveSpan_returnTraceIdAndSpanId() {
        let tracer = DDTracer()
        let spanName = "myName"

        let span = tracer.startSpan(name: spanName, attributes: [:])
        let spanData = span.toSpanData()
        let headers = tracer.tracePropagationHTTPHeaders()

        XCTAssertEqual(headers[DDHeaders.traceIDField.rawValue], String(format: "%016llx", spanData.traceId.rawLowerLong))
        XCTAssertEqual(headers[DDHeaders.parentSpanIDField.rawValue], spanData.spanId.hexString)

        span.end()
    }

    func testTracePropagationHTTPHeadersCalledWithNoActiveSpan_returnsEmpty() {
        let tracer = DDTracer()
        let headers = tracer.tracePropagationHTTPHeaders()

        XCTAssertEqual(headers.count, 0)
        print(headers)
    }
    
}
