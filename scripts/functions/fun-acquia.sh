#!/usr/bin/env bash

# Acquia Cloud Platform (https://cloud.acquia.com) through the Acquia CLI (acli). The hooks the
# hosting dispatcher (fun-acquia-tool.sh) calls for one project directory. Everything defaults to
# read-only; --link, --push, --pull-db and --pull-files each demand their flag, and nothing here
# ever creates or deletes an application or an environment.

function ensure_acquia() {
  if command -v acli > /dev/null 2>&1 ; then
    # The dashboard container has the key and secret in its job environment; the host has its own
    # login. Either way acli must be able to answer.
    if ! acli auth:info > /dev/null 2>&1 && [ -z "${ACLI_KEY:-}" ] ; then
      echo "acli is installed but not logged in. On the host: acli auth:login (an API token from cloud.acquia.com → Account → API tokens)." ;
      return 1 ;
    fi
    return 0 ;
  fi
  echo "The Acquia CLI is not installed. Install it first:" ;
  echo "  curl -OL https://github.com/acquia/cli/releases/latest/download/acli.phar && chmod +x acli.phar && mv acli.phar ~/.local/bin/acli" ;
  echo "then authenticate with: acli auth:login" ;
  return 1 ;
}

# acli resolves a name or a UUID; the link file keeps the UUID so the dashboard needs no lookup.
function acquia_do_link() {
  local project_path="$1" app="$2" uuid;
  (cd "${project_path}" && acli link "${app}" --no-interaction) || return 1 ;
  uuid="$(cd "${project_path}" && acli api:applications:find "${app}" --no-interaction 2>/dev/null | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("uuid",""))' 2>/dev/null)";
  uuid="${uuid:-${app}}";
  acquia_link_set "${project_path}" id "${uuid}" ;
}

function acquia_environments_json() {
  acli api:applications:environment-list "$2" --no-interaction 2>/dev/null ;
}

function acquia_list_environments() {
  acquia_environments_json "$1" "$2" | python3 -c 'import json,sys
for e in json.load(sys.stdin): print(e.get("name",""))' 2>/dev/null ;
}

function acquia_do_environments() {
  acquia_environments_json "$1" "$2" | python3 -c 'import json,sys
for e in json.load(sys.stdin):
    d = e.get("active_domain") or e.get("default_domain") or ""
    print("  %-10s %-24s %-10s %s" % (e.get("name",""), (e.get("label") or "")[:24], e.get("status",""), ("https://"+d) if d else ""))' \
    || { echo "  (could not list the environments — check acli auth:info)"; return 1; } ;
}

# The environment id acli's verbs take: <app-uuid>.<env-name>, or the environment's own uuid.
function acquia_env_id() {
  local app="$1" env="$2";
  acquia_environments_json "" "${app}" | python3 -c 'import json,sys
want=sys.argv[1]
for e in json.load(sys.stdin):
    if e.get("name")==want: print(e.get("id","")); break' "${env}" 2>/dev/null ;
}

function acquia_pull_db() {
  local project_path="$1" app="$2" env="$3" stamp out dump safety env_id;
  stamp="$(date +%Y-%m-%d-%H%M%S)";
  out="${backups}/${doc_name}/${PROJECT_NAME}";
  mkdir -p "${out}" ;
  dump="${out}/${PROJECT_NAME}-acquia-${env}-${stamp}.sql.gz";
  safety="${out}/${PROJECT_NAME}-before-acquia-pull-${stamp}.sql.gz";
  echo "";
  echo "Pulling the ${env} database of Acquia application ${app}.";
  echo "  This is client data: it lands on this machine and in ${out}.";
  echo "";
  acquia_safety_export "${project_path}" "${safety}" ;
  env_id="$(acquia_env_id "${app}" "${env}")";
  echo "Downloading ${env} from Acquia (acli pull:db --no-import).";
  # acli downloads the dump into its own temp dir and names the file; the newest .sql.gz there is it.
  local tmp; tmp="$(mktemp -d)";
  (cd "${project_path}" && TMPDIR="${tmp}" acli pull:db --no-import --no-interaction "${env_id:-${env}}") || return 1 ;
  local got; got="$(find "${tmp}" "${project_path}" -maxdepth 3 -name '*.sql.gz' -newer "${safety}" 2>/dev/null | head -1)";
  if [ -z "${got}" ] ; then
    echo "acli finished but no .sql.gz was found — look at its output above for where the dump went.";
    return 1 ;
  fi
  mv "${got}" "${dump}" ;
  acquia_import_dump "${project_path}" "${dump}" || return 1 ;
  echo "";
  echo "  Imported ${env} into ${doc_name}/${PROJECT_NAME}.";
  echo "    pulled dump:   ${dump}";
  echo "    local backup:  ${safety}";
}

function acquia_pull_files() {
  local project_path="$1" app="$2" env="$3" env_id;
  env_id="$(acquia_env_id "${app}" "${env}")";
  echo "";
  echo "Syncing the ${env} public files of Acquia application ${app} into the local docroot (acli pull:files).";
  echo "  This is client data. rsync-style: it adds and overwrites, and does not delete.";
  (cd "${project_path}" && acli pull:files --no-interaction "${env_id:-${env}}") || return 1 ;
  echo "  If Drupal still shows broken images: ddev drush cr";
}

function acquia_do_push() {
  local project_path="$1" app="$2" env="$3";
  echo "Building an artifact from ${doc_name}/${PROJECT_NAME} and pushing it to the ${env} environment of ${app}…" ;
  echo "  (acli push:artifact; the environment's code is then switched to the pushed tag or branch)" ;
  (cd "${project_path}" && acli push:artifact "$(acquia_env_id "${app}" "${env}")") || return 1 ;
}

function acquia_do_logs() {
  local project_path="$1" app="$2" env="$3";
  [ -z "${env}" ] && { echo "Select an environment first (--select) to tail its logs."; return 1; }
  acli log:tail --no-interaction "$(acquia_env_id "${app}" "${env}")" ;
}

function acquia_do_activities() {
  acli api:applications:notification-list "$2" --limit=10 --no-interaction 2>/dev/null | python3 -c 'import json,sys
for n in json.load(sys.stdin)[:10]:
    print("  %-20s %-10s %s" % ((n.get("created_at") or "")[:19], n.get("status",""), n.get("label","")))' \
    || echo "  (could not list the notifications)" ;
}

function acquia_status() {
  local project_path="$1" app="$2";
  if [ -z "${app}" ] ; then
    echo "    (find the application UUID with: acli app:list)";
    return 0 ;
  fi
  echo "";
  acquia_do_environments "${project_path}" "${app}" ;
  echo "";
  echo "  Console: https://cloud.acquia.com/a/applications/${app}";
  echo "  Data: --pull-db and --pull-files bring the selected environment down into DDEV; --push deploys an artifact.";
}
