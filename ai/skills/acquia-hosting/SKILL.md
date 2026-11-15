---
name: acquia-hosting
description: Work with a Webship Workspace site on Acquia Cloud through the Acquia Cloud plugin (`@webship.co/workspace-acquia`) — the ACQUIA menu of a project row and the command behind every entry, `cmd-tools-acquia.sh`, with each of its options, how a project is linked, the keys of `plugin.acquia.settings.yml` and the credential they hold, and what the command says when something is missing. Use when asked "is this site linked to Acquia Cloud", "link this project", "list the environments", "what was deployed last", "get the live database", "deploy this site", "the menu says not linked", or "where does the Acquia Cloud token go".
argument-hint: '<project>'
---

# acquia-hosting

Acquia Cloud for a site of a Webship Workspace (`~/workspace`, container-based, DDEV by default). It comes
with the Acquia Cloud plugin (`@webship.co/workspace-acquia`), a provider of the hosting family (`@webship.co/workspace-hosting`),
like the agent `acquia-deployer`, the command `/acquia-status` and the prompt `acquia-test-then-deploy`.

## The ACQUIA menu

The ACQUIA menu is on the project rows of the sites folders. The caption beside it says `linked`
or `not linked`. A project that is not linked is shown how to link it; a linked one gets these
entries, and each of them runs the command of the plugin in a terminal session, from the sites
folder:

| Menu entry | The command |
| --- | --- |
| **Link and environments** | `bash cmd-tools-acquia.sh <project>` |
| **Last 10 notifications** | `bash cmd-tools-acquia.sh <project> --activities` |
| **Tail the environment logs** | `bash cmd-tools-acquia.sh <project> --logs` |
| **Deploy an artifact (acli push:artifact)…** | `bash cmd-tools-acquia.sh <project> --push` |

The menu ends with the note "Linking stays on the command line; a deploy opens a terminal and acli asks before pushing".

### Get the live data

The menu also offers to get the database and the files of an environment into the local site. From a terminal:

| What | The command | What it does |
| --- | --- | --- |
| The database | `bash cmd-tools-acquia.sh <project> --environment <environment> --pull-db` | Download the selected environment's database (acli pull:db --no-import) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data. |
| The files | `bash cmd-tools-acquia.sh <project> --environment <environment> --pull-files` | Sync the selected environment's public files into the local docroot (acli pull:files; adds and overwrites, never deletes). Client data. |

## The command

`cmd-tools-acquia.sh` is placed in every sites folder of the workspace. The first word after it is the
project; with nothing else it says whether the project is linked, and to what.

```bash
cd ~/workspace/<folder>
bash cmd-tools-acquia.sh <project>
bash cmd-tools-acquia.sh <project> --link <application-uuid>
bash cmd-tools-acquia.sh <project> --environments
```

| Option | What it does |
| --- | --- |
| `--link <value>` | Link the project to an Acquia application (its UUID, or its name as acli resolves it). Find them with: acli app:list |
| `--push` | Deploy: build an artifact from the current code and push it to the selected environment (acli push:artifact). Outward-facing: acli asks for confirmation. |
| `--environment <value>` | Environment for THIS run: the --push target, and the source --pull-db/--pull-files take data from. Default: the one remembered by --select. |
| `--environments` | List the environments of the linked Acquia application, with their domains. |
| `--select <value>` | Remember which environment this project works against (in .acquia/workspace.yml, git-excluded). Checked against the real environment list. |
| `--pull-db` | Download the selected environment's database (acli pull:db --no-import) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data. |
| `--pull-files` | Sync the selected environment's public files into the local docroot (acli pull:files; adds and overwrites, never deletes). Client data. |
| `--logs` | Tail the selected environment's logs (acli log:tail). |
| `--activities` | List the last 10 notifications of the application (deploys, copies, backups). |
| `--no-safety-backup` | Skip exporting the local database before --pull-db replaces it. |
| `--force` | Allow --link to relink a project that already points at a different application. |

With no project the command says that `PROJECT_NAME` is required; with a project that is not in
the folder, "No such project"; with an option that needs a link on a project that has none, "Not
linked to Acquia Cloud".

## Link a project

A project is linked to an Acquia Cloud application by its UUID, or by its name as `acli` resolves it. The link is written to `.acquia/workspace.yml` in the project, which git does not track. An Acquia application id is a UUID (cloud.acquia.com → the application → the id in its URL, or acli app:list).

```bash
bash cmd-tools-acquia.sh <project> --link <application-uuid>
```

## The settings: `core/config/plugin.acquia.settings.yml`

| Key | What it is |
| --- | --- |
| `api_key:` | The key of an API token from cloud.acquia.com (Account → API tokens). Read by acli as ACLI_KEY. |
| `api_secret:` | The secret of that token. Read by acli as ACLI_SECRET. |

The dashboard reaches Acquia Cloud with api_key and api_secret in core/config/plugin.acquia.settings.yml. The file is created mode 600 and its secrets are
masked on the Settings page. Never print them, never copy them into another file, and never commit
the file.

## Turn it on, and check it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require @webship.co/workspace-acquia
bash core/scripts/plugins.sh --activate acquia --with-needs     # adds a sites folder and the AI folders when they are missing
bash core/scripts/plugins.sh --install acquia
bash core/scripts/plugins.sh --configure acquia
bash core/scripts/plugins.sh --check acquia                     # the commands it needs on the machine
```

## Traps

- **A 401, "unauthorized" or "invalid_client"**: the dashboard reaches Acquia with `api_key:` and `api_secret:`, an API token from cloud.acquia.com, Account, API tokens.
- **The log entry follows**: it runs `acli log:tail`, which goes on until it is interrupted. It is for a terminal.
- **A deploy builds an artifact** from the current code and pushes it to the selected environment (`acli push:artifact`); acli asks before it does.
- **A database pull replaces the local database.** The current one is exported to `backups/` first, unless `--no-safety-backup` was given.
- **A deploy is outward-facing.** The command asks before it sends anything, in a terminal: it is
  not a step for an AI assistant to take on its own.
