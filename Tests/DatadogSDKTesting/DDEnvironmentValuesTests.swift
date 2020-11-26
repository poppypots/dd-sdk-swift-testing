/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import DatadogSDKTesting
import OpenTelemetrySdk
import OpenTelemetryApi


class DDEnvironmentValuesTests: XCTestCase {
    var testEnvironment = [String: String]()

    var tracerSdkFactory = TracerSdkProvider()
    var tracerSdk: Tracer!

    override func setUp() {
        DDEnvironmentValues.environment = [String: String]()
        tracerSdk = tracerSdkFactory.get(instrumentationName: "SpanBuilderSdkTest")
    }

    func setEnvVariables() {
        DDEnvironmentValues.environment = testEnvironment
    }

    func testWhenDatadogEnvironmentAreSet_TheyAreStoredCorrectly() {
        testEnvironment["DATADOG_CLIENT_TOKEN"] = "token5a101f16"
        testEnvironment["DD_SERVICE"] = "testService"
        testEnvironment["DD_ENV"] = "testEnv"

        setEnvVariables()

        let env = DDEnvironmentValues()
        XCTAssertEqual(env.ddClientToken, "token5a101f16")
        XCTAssertEqual(env.ddEnvironment, "testEnv")
        XCTAssertEqual(env.ddService, "testService")
    }

    func testWhenNoConfigurationEnvironmentAreSet_DefaultValuesAreUsed() {
        let env = DDEnvironmentValues()
        XCTAssertEqual(env.disableNetworkInstrumentation, false)
        XCTAssertEqual(env.disableStdoutInstrumentation, false)
        XCTAssertEqual(env.disableStderrInstrumentation, false)
        XCTAssertEqual(env.disableHeadersInjection, false)
        XCTAssertEqual(env.extraHTTPHeaders, nil)
        XCTAssertEqual(env.excludedURLS, nil)
        XCTAssertEqual(env.enableRecordPayload, false)
    }

    func testWhenConfigurationEnvironmentAreSet_TheyAreStoredCorrectly() {
        testEnvironment["DD_DISABLE_NETWORK_INSTRUMENTATION"] = "1"
        testEnvironment["DD_DISABLE_STDOUT_INSTRUMENTATION"] = "yes"
        testEnvironment["DD_DISABLE_STDERR_INSTRUMENTATION"] = "true"
        testEnvironment["DD_DISABLE_HEADERS_INJECTION"] = "YES"
        testEnvironment["DD_INSTRUMENTATION_EXTRA_HEADERS"] = "header1,header2;header3 header4"
        testEnvironment["DD_EXCLUDED_URLS"] = "http://www.google"
        testEnvironment["DD_ENABLE_RECORD_PAYLOAD"] = "true"

        setEnvVariables()

        let env = DDEnvironmentValues()
        XCTAssertEqual(env.disableNetworkInstrumentation, true)
        XCTAssertEqual(env.disableStdoutInstrumentation, true)
        XCTAssertEqual(env.disableStderrInstrumentation, true)
        XCTAssertEqual(env.disableHeadersInjection, true)
        XCTAssertEqual(env.extraHTTPHeaders?.count, 4)
        XCTAssertEqual(env.excludedURLS?.count, 1)
        XCTAssertEqual(env.enableRecordPayload, true)
    }

    func testTravisEnvironment() {
        testEnvironment["TRAVIS"] = "1"
        testEnvironment["TRAVIS_REPO_SLUG"] = "/test/repo"
        testEnvironment["TRAVIS_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["TRAVIS_BUILD_DIR"] = "/build"
        testEnvironment["TRAVIS_BUILD_ID"] = "pipeline1"
        testEnvironment["TRAVIS_BUILD_NUMBER"] = "4345"
        testEnvironment["TRAVIS_BUILD_WEB_URL"] = "http://travis.com/build"
        testEnvironment["TRAVIS_JOB_WEB_URL"] = "http://travis.com/job"
        testEnvironment["TRAVIS_PULL_REQUEST_BRANCH"] = ""
        testEnvironment["TRAVIS_BRANCH"] = "develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "travis")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "http://travis.com/build")
        XCTAssertEqual(env.jobURL!, "http://travis.com/job")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testCircleCIEnvironment() {
        testEnvironment["CIRCLECI"] = "1"
        testEnvironment["CIRCLE_REPOSITORY_URL"] = "/test/repo"
        testEnvironment["CIRCLE_SHA1"] = "37e376448b0ac9b7f54404"
        testEnvironment["CIRCLE_WORKING_DIRECTORY"] = "/build"
        testEnvironment["CIRCLE_BUILD_NUM"] = "43"
        testEnvironment["CIRCLE_BUILD_URL"] = "http://circleenv.com/build"
        testEnvironment["CIRCLE_BRANCH"] = "develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "circleci")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineNumber!, "43")
        XCTAssertEqual(env.pipelineURL!, "http://circleenv.com/build")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testJenkinsEnvironment() {
        testEnvironment["JENKINS_URL"] = "http://jenkins.com/"
        testEnvironment["GIT_URL"] = "/test/repo"
        testEnvironment["GIT_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["WORKSPACE"] = "/build"
        testEnvironment["BUILD_ID"] = "pipeline1"
        testEnvironment["BUILD_NUMBER"] = "45"
        testEnvironment["BUILD_URL"] = "http://jenkins.com/build"
        testEnvironment["JOB_URL"] = "http://jenkins.com/job"
        testEnvironment["GIT_BRANCH"] = "origin/develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "jenkins")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "45")
        XCTAssertEqual(env.pipelineURL!, "http://jenkins.com/build")
        XCTAssertEqual(env.jobURL!, "http://jenkins.com/job")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testGitlabCIEnvironment() {
        testEnvironment["GITLAB_CI"] = "1"
        testEnvironment["CI_REPOSITORY_URL"] = "/test/repo"
        testEnvironment["CI_COMMIT_SHA"] = "37e376448b0ac9b7f54404"
        testEnvironment["CI_PROJECT_DIR"] = "/build"
        testEnvironment["CI_PIPELINE_ID"] = "pipeline1"
        testEnvironment["CI_PIPELINE_IID"] = "4345"
        testEnvironment["CI_PIPELINE_URL"] = "http://travis.com/build"
        testEnvironment["CI_JOB_URL"] = "http://travis.com/job"
        testEnvironment["TRAVIS_PULL_REQUEST_BRANCH"] = ""
        testEnvironment["CI_COMMIT_BRANCH"] = "develop"
        testEnvironment["CI_COMMIT_TAG"] = "0.1.1"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "gitlab")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "http://travis.com/build")
        XCTAssertEqual(env.jobURL!, "http://travis.com/job")
        XCTAssertEqual(env.branch!, "develop")
        XCTAssertEqual(env.tag!, "0.1.1")
    }

    func testAppVeyorEnvironment() {
        testEnvironment["APPVEYOR"] = "1"
        testEnvironment["APPVEYOR_REPO_NAME"] = "/test/repo"
        testEnvironment["APPVEYOR_REPO_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["APPVEYOR_BUILD_FOLDER"] = "/build"
        testEnvironment["APPVEYOR_BUILD_ID"] = "pipeline1"
        testEnvironment["APPVEYOR_BUILD_NUMBER"] = "4345"
        testEnvironment["APPVEYOR_PROJECT_SLUG"] = "projectSlug"
        testEnvironment["APPVEYOR_REPO_BRANCH"] = "develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "appveyor")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "https://ci.appveyor.com/project/projectSlug/builds/pipeline1")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testAzureEnvironment() {
        testEnvironment["TF_BUILD"] = "1"
        testEnvironment["BUILD_SOURCESDIRECTORY"] = "/test/repo"
        testEnvironment["BUILD_SOURCEVERSION"] = "37e376448b0ac9b7f54404"
        testEnvironment["BUILD_BUILDID"] = "pipeline1"
        testEnvironment["BUILD_BUILDNUMBER"] = "4345"
        testEnvironment["SYSTEM_TEAMFOUNDATIONCOLLECTIONURI"] = "foundationCollection"
        testEnvironment["SYSTEM_TEAMPROJECT"] = "teamProject"
        testEnvironment["BUILD_REPOSITORY_URI"] = "/test/repo"
        testEnvironment["BUILD_SOURCEBRANCHNAME"] = "/refs/develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "azurepipelines")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/test/repo")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "foundationCollection/teamProject/_build/results?buildId=pipeline1&_a=summary")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testBitbucketEnvironment() {
        testEnvironment["BITBUCKET_GIT_SSH_ORIGIN"] = "/test/repo"
        testEnvironment["BITBUCKET_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["BITBUCKET_CLONE_DIR"] = "/build"
        testEnvironment["BITBUCKET_PIPELINE_UUID"] = "pipeline1"
        testEnvironment["BITBUCKET_BUILD_NUMBER"] = "4345"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "bitbucketpipelines")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
    }

    func testGithubEnvironment() {
        testEnvironment["GITHUB_REPOSITORY"] = "http://github.com/project"
        testEnvironment["GITHUB_SHA"] = "37e376448b0ac9b7f54404"
        testEnvironment["GITHUB_WORKSPACE"] = "/build"
        testEnvironment["GITHUB_RUN_ID"] = "pipeline1"
        testEnvironment["GITHUB_RUN_NUMBER"] = "4345"
        testEnvironment["TRAVIS_PULL_REQUEST_BRANCH"] = ""
        testEnvironment["GITHUB_REF"] = "/refs/heads/develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "github")
        XCTAssertEqual(env.repository!, "http://github.com/project")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "http://github.com/project/commit/37e376448b0ac9b7f54404/checks")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testTeamCityEnvironment() {
        testEnvironment["TEAMCITY_VERSION"] = "1"
        testEnvironment["BUILD_VCS_URL"] = "/test/repo"
        testEnvironment["BUILD_VCS_NUMBER"] = "37e376448b0ac9b7f54404"
        testEnvironment["BUILD_CHECKOUTDIR"] = "/build"
        testEnvironment["BUILD_ID"] = "pipeline1"
        testEnvironment["BUILD_NUMBER"] = "4345"
        testEnvironment["SERVER_URL"] = "http://teamcity.com"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "teamcity")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "http://teamcity.com/viewLog.html?buildId=pipeline1")
    }

    func testBuildkiteEnvironment() {
        testEnvironment["BUILDKITE"] = "1"
        testEnvironment["BUILDKITE_REPO"] = "/test/repo"
        testEnvironment["BUILDKITE_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["BUILDKITE_BUILD_CHECKOUT_PATH"] = "/build"
        testEnvironment["BUILDKITE_BUILD_ID"] = "pipeline1"
        testEnvironment["BUILDKITE_BUILD_NUMBER"] = "4345"
        testEnvironment["BUILDKITE_BUILD_URL"] = "http://buildkite.com/build"
        testEnvironment["BUILDKITE_BRANCH"] = "develop"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "buildkite")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "http://buildkite.com/build")
        XCTAssertEqual(env.branch!, "develop")
    }

    func testBitriseEnvironment() {
        testEnvironment["BITRISE_BUILD_NUMBER"] = "1"
        testEnvironment["GIT_REPOSITORY_URL"] = "/test/repo"
        testEnvironment["BITRISE_GIT_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["BITRISE_SOURCE_DIR"] = "/build"
        testEnvironment["BITRISE_TRIGGERED_WORKFLOW_ID"] = "pipeline1"
        testEnvironment["BITRISE_BUILD_NUMBER"] = "4345"
        testEnvironment["BITRISE_APP_URL"] = "https://app.bitrise.io/app"
        testEnvironment["BITRISE_BUILD_URL"] = "https://app.bitrise.io/build"
        testEnvironment["TRAVIS_PULL_REQUEST_BRANCH"] = ""
        testEnvironment["BITRISE_GIT_BRANCH"] = "develop"
        testEnvironment["BITRISE_GIT_TAG"] = "0.0.1"

        setEnvVariables()

        let env = DDEnvironmentValues()

        XCTAssertTrue(env.isCi)
        XCTAssertEqual(env.provider!, "bitrise")
        XCTAssertEqual(env.repository!, "/test/repo")
        XCTAssertEqual(env.commit!, "37e376448b0ac9b7f54404")
        XCTAssertEqual(env.sourceRoot!, "/build")
        XCTAssertEqual(env.pipelineId!, "pipeline1")
        XCTAssertEqual(env.pipelineNumber!, "4345")
        XCTAssertEqual(env.pipelineURL!, "https://app.bitrise.io/build")
        XCTAssertEqual(env.jobURL!, "https://app.bitrise.io/app")
        XCTAssertEqual(env.branch!, "develop")
        XCTAssertEqual(env.tag!, "0.0.1")
    }

    func testAddsTagsToSpan() {
        testEnvironment["JENKINS_URL"] = "http://jenkins.com/"
        testEnvironment["GIT_URL"] = "/test/repo"
        testEnvironment["GIT_COMMIT"] = "37e376448b0ac9b7f54404"
        testEnvironment["WORKSPACE"] = "/build"
        testEnvironment["BUILD_ID"] = "pipeline1"
        testEnvironment["BUILD_NUMBER"] = "45"
        testEnvironment["BUILD_URL"] = "http://jenkins.com/build"
        testEnvironment["JOB_URL"] = "http://jenkins.com/job"
        testEnvironment["GIT_BRANCH"] = "origin/develop"

        setEnvVariables()

        let span = createSimpleSpan()
        var spanData = span.toSpanData()
        XCTAssertEqual(spanData.attributes.count, 0)

        let env = DDEnvironmentValues()
        env.addTagsToSpan(span: span)

        spanData = span.toSpanData()
        XCTAssertEqual(spanData.attributes.count, 10)

        XCTAssertEqual(spanData.attributes["ci.provider.name"]?.description, "jenkins")
        XCTAssertEqual(spanData.attributes["git.repository_url"]?.description, "/test/repo")
        XCTAssertEqual(spanData.attributes["git.commit.sha"]?.description, "37e376448b0ac9b7f54404")
        XCTAssertEqual(spanData.attributes["ci.workspace_path"]?.description, "/build")
        XCTAssertEqual(spanData.attributes["ci.pipeline.id"]?.description, "pipeline1")
        XCTAssertEqual(spanData.attributes["ci.pipeline.number"]?.description, "45")
        XCTAssertEqual(spanData.attributes["ci.pipeline.url"]?.description, "http://jenkins.com/build")
        XCTAssertEqual(spanData.attributes["ci.job.url"]?.description, "http://jenkins.com/job")
        XCTAssertEqual(spanData.attributes["git.branch"]?.description, "develop")
    }

    func testWhenNotRunningInCI_TagsAreNotAdded() {
        setEnvVariables()

        let span = createSimpleSpan()
        var spanData = span.toSpanData()
        XCTAssertEqual(spanData.attributes.count, 0)

        let env = DDEnvironmentValues()
        env.addTagsToSpan(span: span)

        spanData = span.toSpanData()
        XCTAssertEqual(spanData.attributes.count, 0)
    }

    func createSimpleSpan() -> RecordEventsReadableSpan {
        return tracerSdk.spanBuilder(spanName: "spanName").startSpan() as! RecordEventsReadableSpan

    }
}
