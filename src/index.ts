/**
 * Acquia Cloud for Webship Workspace.
 *
 * The ACQUIA menu on every site row, a live-site chip, the New-folder link option and the
 * `/acquia-site/<workspace>/<project>` jump: all of it is the hosting family's surface
 * (@webship.co/workspace-hosting). This package is the Acquia Cloud provider plus what the installer places
 * (the per-workspace command, its bash functions, the settings template, the host install).
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from
 * the dashboard's own files.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';
import { registerHosting } from '@webship.co/workspace-hosting';

import { acquiaProvider } from './lib/provider';

export { acquiaProvider };
export { acquiaLinkOf } from './lib/link';

export function register(api: PluginApi): void {
  registerHosting(api, acquiaProvider(api));
}
