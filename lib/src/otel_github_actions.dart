// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_github_actions_suppression.dart';

const _tracerName = 'dartastic_otel_libs_github_actions';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a GitHub Actions REST call (workflows.dispatch,
/// workflow_runs.cancel, jobs.list) in a CLIENT span.
Future<T> tracedGithubActions<T>({
  required String resource,
  required String action,
  required String owner,
  required String repo,
  required Future<T> Function() invoke,
  String? workflowId,
  int? runId,
  String? ref,
}) async {
  if (githubActionsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'cicd.system': 'github_actions',
    'github_actions.resource': resource,
    'github_actions.action': action,
    'github_actions.operation': '$resource.$action',
    'github.owner': owner,
    'github.repo': repo,
  };
  if (workflowId != null) m['github_actions.workflow.id'] = workflowId;
  if (runId != null) m['github_actions.run.id'] = runId;
  if (ref != null) m['github_actions.ref'] = ref;

  final span = _tracer().startSpan(
    'gh-actions $resource.$action',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps the body of one Actions job step in an INTERNAL span. Use
/// inside a custom action to attach step timing as a child span.
Future<T> tracedGithubActionsStep<T>({
  required String stepName,
  required Future<T> Function() invoke,
  String? runner,
  int? runId,
}) async {
  if (githubActionsInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'cicd.system': 'github_actions',
    'github_actions.step.name': stepName,
  };
  if (runner != null) m['github_actions.runner'] = runner;
  if (runId != null) m['github_actions.run.id'] = runId;

  final span = _tracer().startSpan(
    'gh-actions step $stepName',
    kind: SpanKind.internal,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
