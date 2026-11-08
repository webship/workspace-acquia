/**
 * Acquia Cloud Platform, as a hosting provider.
 *
 * The link is `.acquia/workspace.yml` (written by `cmd-tools-acquia.sh --link`, beside acli's own
 * `.acquia-cli.yml`); environments and their domains come from the Cloud API through acli, with the
 * API key and secret from plugin.acquia.settings.yml injected per call; the pulls, the deploy, the
 * logs and the notifications go through cmd-tools-acquia.sh in a screen session.
 */

import type { PluginApi, PluginLib } from '@webship.co/workspace-plugin-api';
import { configured, findCli } from '@webship.co/workspace-hosting';
import type { EnvInfo, EnvRow, HostingLink, HostingProvider } from '@webship.co/workspace-hosting';

import { acquiaLinkOf } from './link';

interface CloudEnv { id: string; name: string; label: string; status: string; active_domain?: string; default_domain?: string; vcs?: { path?: string } }

export function acquiaProvider(api: PluginApi): HostingProvider {
  const settings = () => api.settings.read() || {};
  const bin = () => findCli('acli', ['/host-local-bin/acli']) || 'acli';

  const jobEnv = (): NodeJS.ProcessEnv | null => {
    const key = configured(settings().api_key);
    const secret = configured(settings().api_secret);
    return key && secret ? { ...process.env, ACLI_KEY: key, ACLI_SECRET: secret } : null;
  };

  async function environments(link: HostingLink, lib: PluginLib, env: NodeJS.ProcessEnv): Promise<EnvInfo> {
    const id = link.id as string;
    const out = await lib.run(bin(), ['api:applications:environment-list', id, '--no-interaction'], process.env.HOME, { timeoutMs: 60 * 1000, env });
    if (!out.ok) return { id, rows: [], why: 'list failed' };
    let list: CloudEnv[] = [];
    try { list = JSON.parse(String(out.stdout)); } catch (_) { return { id, rows: [], why: 'list failed' }; }
    const rows: EnvRow[] = list.map((e) => {
      const domain = e.active_domain || e.default_domain;
      // The Cloud API says "normal" for a running environment; the family says "active".
      const status = /^(normal|launched)$/i.test(e.status || '') ? 'active' : String(e.status || 'unknown');
      return { title: e.label || e.name, envId: e.name, status, url: domain ? `https://${domain}` : undefined };
    });
    return { id, rows };
  }

  return {
    id: 'acquia',
    label: 'ACQUIA',
    title: 'Acquia Cloud',
    cli: 'acli',
    script: 'cmd-tools-acquia.sh',
    detect: (projectDir) => acquiaLinkOf(projectDir),
    linkHint: (project) => `bash cmd-tools-acquia.sh ${project} --link <application-uuid>`,
    consoleUrl: (link) => (link.id ? `https://cloud.acquia.com/a/applications/${encodeURIComponent(link.id)}` : null),
    jobEnv,
    tokenHint: 'api_key and api_secret in core/config/plugin.acquia.settings.yml',
    environments,
    tools: {
      status: { verb: 'acquia', label: 'Link and environments', icon: 'info', args: [] },
      activities: { verb: 'acquia-activities', label: 'Last 10 notifications', icon: 'list', args: ['--activities'] },
      logs: { verb: 'acquia-logs', label: 'Tail the environment logs', icon: 'file-text', args: ['--logs'] },
      deploy: { verb: 'acquia-push', label: 'Deploy an artifact (acli push:artifact)…', icon: 'push', args: ['--push'] },
    },
    pull: {
      db: true, files: true,
      dbArgs: (e) => ['--environment', e, '--pull-db'],
      filesArgs: (e) => ['--environment', e, '--pull-files'],
      noSafetyBackupArg: '--no-safety-backup',
    },
    errorHint: (msg) => (/401|unauthorized|invalid_client|credentials/i.test(msg)
      ? `${msg}\n\nThe dashboard reaches Acquia with api_key and api_secret in core/config/plugin.acquia.settings.yml: an API token from cloud.acquia.com → Account → API tokens.`
      : msg),
    folder: {
      idPattern: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
      idPlaceholder: 'a47ac10b-58cc-4372-a567-0e02b2c3d479',
      idHelp: 'An Acquia application id is a UUID (cloud.acquia.com → the application → the id in its URL, or acli app:list).',
    },
    menuNote: 'Linking stays on the command line; a deploy opens a terminal and acli asks before pushing',
  };
}
