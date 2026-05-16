// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_github_actions/otel_github_actions.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_github_actions-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('workflows.dispatch records CLIENT span', () async {
    await tracedGithubActions<String>(
      resource: 'workflows',
      action: 'dispatch',
      owner: 'acme',
      repo: 'app',
      workflowId: 'ci.yml',
      ref: 'main',
      invoke: () async => 'ok',
    );
    final a = attrsOf(
      spans.findSpanByName('gh-actions workflows.dispatch')!,
    );
    expect(a['cicd.system'], 'github_actions');
    expect(a['github.owner'], 'acme');
    expect(a['github.repo'], 'app');
    expect(a['github_actions.workflow.id'], 'ci.yml');
    expect(a['github_actions.ref'], 'main');
  });

  test('step records INTERNAL span', () async {
    await tracedGithubActionsStep<String>(
      stepName: 'Build',
      runner: 'ubuntu-latest',
      runId: 99,
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('gh-actions step Build');
    expect(span!.kind, SpanKind.internal);
  });

  test('suppression skips spans', () async {
    await runWithoutGithubActionsInstrumentationAsync(() async {
      await tracedGithubActions<String>(
        resource: 'r',
        action: 'a',
        owner: 'o',
        repo: 'r',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('gh-actions '), isEmpty);
  });
}
