#!/usr/bin/env bash
## The host side of the Acquia Cloud plugin: the CLI on this machine and the dashboard's credentials.
## Run by core/scripts/plugins.sh --install acquia, and by core/scripts/install.sh for every installed
## plugin that ships one. Idempotent: whatever is already there is reported, not redone. Offered,
## never automatic: a hosting CLI carries cloud credentials for real environments.
set -u
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)}";

# The acli CLI on this machine, mounted into the dashboard from ~/.local/bin or found on PATH.
BIN='';
for candidate in "$(command -v acli 2>/dev/null)" "${HOME}/.local/bin/acli" ; do
  [ -n "${candidate}" ] && [ -x "${candidate}" ] && { BIN="${candidate}"; break; }
done
if [ -n "${BIN}" ] ; then
  printf '  ✓ %-16s %s\n' "acli" "${BIN}" ;
else
  printf '  ✗ %-16s %s\n' "acli" "missing — the ACQUIA menu needs it (docs.acquia.com/acquia-cli/install — curl -OL https://github.com/acquia/cli/releases/latest/download/acli.phar)" ;
fi

STATE="$(grep -E '^api_key:' "${WORKSPACE_ROOT}/core/config/plugin.acquia.settings.yml" 2>/dev/null | head -1 | sed -E 's/^[a-z_]+:[[:space:]]*//')";
case "${STATE}" in
  ''|CHANGE_ME|"''"|'""') printf '  ✗ %-16s %s\n' "api_key" "not set in plugin.acquia.settings.yml — the dashboard cannot reach Acquia Cloud" ;;
  *)                       printf '  ✓ %-16s %s\n' "api_key" "set (plugin.acquia.settings.yml)" ;;
esac

STATE="$(grep -E '^api_secret:' "${WORKSPACE_ROOT}/core/config/plugin.acquia.settings.yml" 2>/dev/null | head -1 | sed -E 's/^[a-z_]+:[[:space:]]*//')";
case "${STATE}" in
  ''|CHANGE_ME|"''"|'""') printf '  ✗ %-16s %s\n' "api_secret" "not set in plugin.acquia.settings.yml — the dashboard cannot reach Acquia Cloud" ;;
  *)                       printf '  ✓ %-16s %s\n' "api_secret" "set (plugin.acquia.settings.yml)" ;;
esac

