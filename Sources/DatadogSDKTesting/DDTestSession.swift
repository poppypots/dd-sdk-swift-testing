/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2020-2021 Datadog, Inc.
 */

import Foundation
@_implementationOnly import OpenTelemetryApi


public class DDTestSession: NSObject, Encodable {
    var id: SpanId
    var name: String
    var resource: String
    let startTime: Date
    var duration: UInt64
    var meta: [String: String] = [:]
    var metrics: [String: Double] = [:]
    var status: DDTestStatus

    init(testModule: DDTestModule) {
        //Create a fake session from module Info
        self.id = testModule.sessionId
        self.name = "\(testModule.testFramework).session"
        self.resource = "\(testModule.bundleName) session"
        self.startTime = testModule.startTime
        self.duration = testModule.duration
        self.meta = testModule.meta
        self.metrics = testModule.metrics
        self.status = testModule.status
        
        //Remove and add tags that are different
        self.meta[DDTestTags.testBundle] = nil
        self.meta[DDTestTags.testCommand] = "test \(testModule.bundleName)"
    }
}

extension DDTestSession {
    enum StaticCodingKeys: String, CodingKey {
        case test_session_id
        case name
        case resource
        case error
        case meta
        case metrics
        case start
        case duration
        case service
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StaticCodingKeys.self)
        try container.encode(id.rawValue, forKey: .test_session_id)
        try container.encode(startTime.timeIntervalSince1970.toNanoseconds, forKey: .start)
        try container.encode(duration, forKey: .duration)
        try container.encode(meta, forKey: .meta)
        try container.encode(metrics, forKey: .metrics)
        try container.encode(status == .fail ? 1 : 0, forKey: .error)
        try container.encode(name, forKey: .name)
        try container.encode(resource, forKey: .resource)
        try container.encode(DDTestMonitor.env.ddService ?? DDTestMonitor.env.getRepositoryName() ?? "unknown-swift-repo", forKey: .service)
    }

    struct DDTestSessionEnvelope: Encodable {
        enum CodingKeys: String, CodingKey {
            case type
            case version
            case content
        }

        let version: Int = 1

        let type: String = DDTagValues.typeSessionEnd
        let content: DDTestSession

        init(_ content: DDTestSession) {
            self.content = content
        }
    }
}
