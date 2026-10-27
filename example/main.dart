// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_github_actions/otel_github_actions.dart';

/// Traces GitHub Actions calls with OpenTelemetry.
///
/// `otel_github_actions` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each GitHub Actions call in
/// [tracedGithubActions]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'github-actions-example');

  // Wraps a GitHub Actions REST call (workflows.dispatch, workflow_runs.cancel, jobs.list) in a CLIENT span.
  final githubActionsId = await tracedGithubActions<String>(
    resource: 'Order',
    action: 'example',
    owner: 'example',
    repo: 'example',
    workflowId: 'workflow_8f3a2c',
    runId: 1,
    ref: 'example',
    invoke: () async {
      // Make the GitHub Actions call here, then report what it returned.
      return 'github_actions_8f3a2c';
    },
  );
  OTelLog.info('tracedGithubActions returned $githubActionsId');

  // Wraps the body of one Actions job step in an INTERNAL span.
  final githubActionsStepId = await tracedGithubActionsStep<String>(
    stepName: 'example',
    runner: 'example',
    runId: 1,
    invoke: () async {
      // Make the GitHub Actions call here, then report what it returned.
      return 'github_actions_8f3a2c';
    },
  );
  OTelLog.info('tracedGithubActionsStep returned $githubActionsStepId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGithubActionsInstrumentationAsync.
  await runWithoutGithubActionsInstrumentationAsync(
    () => tracedGithubActions<String>(
      resource: 'Order',
      action: 'example',
      owner: 'example',
      repo: 'example',
      workflowId: 'workflow_8f3a2c',
      runId: 1,
      ref: 'example',
      invoke: () async {
        return 'github_actions_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
