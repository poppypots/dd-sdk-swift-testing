/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import Foundation
import OpenTelemetryApi

import OpenTelemetrySdk

/// An implementation of the SpanProcessor that converts the ReadableSpan SpanData
///  and passes it to the configured exporter.
class SpySpanProcessor: SpanProcessor {
    var lastProcessedSpan: Span?

    init() {}

    let isStartRequired = true
    let isEndRequired = false

    func onStart(parentContext: SpanContext?, span: ReadableSpan) {
        lastProcessedSpan = span
    }

    func onEnd(span: ReadableSpan) {}

    func shutdown() {}

    func forceFlush() {}
}
