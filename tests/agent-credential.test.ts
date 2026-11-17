/**
 * The deployer agent says which credential is which: the command's is the CLI login of the machine, the
 * settings file's is the dashboard's.
 *
 * It said "The credential is api_key and api_secret in core/config/plugin.acquia.settings.yml … When the provider refuses it, say that
 * this is where it is set", while `cmd-tools-acquia.sh`, run on the machine, uses the `acli` login and never reads it.
 */
import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import path from 'path';

const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const read = (f: string) => fs.readFileSync(path.join(PKG, f), 'utf8');

test('the agent gives the CLI login for the command, and the settings file for the dashboard', () => {
  const agent = read('ai/agents/acquia-deployer.md');
  assert.doesNotMatch(agent, /The credential is api_key and api_secret in core\/config/, 'not one credential for both');
  assert.match(agent, /uses the `acli` login\s+of the machine: `acli auth:login`/);
  assert.match(agent, /api_key and api_secret in core\/config\/plugin\.acquia\.settings\.yml\s+is the dashboard's/);
  // The login the agent names is the one the command itself prints when there is none.
  assert.ok(read('scripts/functions/fun-acquia.sh').includes('acli auth:login'), 'the command says the same login');
});
