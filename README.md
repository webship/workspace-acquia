# @webship.co/workspace-acquia

Acquia Cloud for the [Webship Workspace](https://github.com/webship/workspace) dashboard: the **ACQUIA**
menu on every site row, a live-site chip on the project card, "Link to Acquia Cloud" when a new folder is
made, and the `cmd-tools-acquia.sh` command in every site workspace. A provider of
[`@webship.co/workspace-hosting`](https://github.com/webship/workspace-hosting), which draws the menu,
the environments modal, the get-database-and-files flow and the New-folder section for every host.

The link is `acli link` (it writes `.acquia-cli.yml` for acli and `.acquia/workspace.yml` for the dashboard); environments come from the Cloud API through acli; the pulls are `acli pull:db --no-import` into `ddev import-db` and `acli pull:files`; a deploy is `acli push:artifact`. The dashboard container reaches Acquia with an API key and secret (`ACLI_KEY`/`ACLI_SECRET`), the host with its own `acli auth:login`.

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require github:webship/workspace-acquia
bash core/scripts/plugins.sh --activate acquia
bash core/scripts/plugins.sh --install acquia
bash core/scripts/plugins.sh --configure acquia      # core/config/plugin.acquia.settings.yml
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page.

## The command

```bash
cd ~/workspace/dev
bash cmd-tools-acquia.sh <project> [verb]
```

| Verb | What it does |
| --- | --- |
| `--link` <value> | Link the project to an Acquia application (its UUID, or its name as acli resolves it). Find them with: acli app:list |
| `--push` | Deploy: build an artifact from the current code and push it to the selected environment (acli push:artifact). Outward-facing: acli asks for confirmation. |
| `--environment` <value> | Environment for THIS run: the --push target, and the source --pull-db/--pull-files take data from. Default: the one remembered by --select. |
| `--environments` | List the environments of the linked Acquia application, with their domains. |
| `--select` <value> | Remember which environment this project works against (in .acquia/workspace.yml, git-excluded). Checked against the real environment list. |
| `--pull-db` | Download the selected environment's database (acli pull:db --no-import) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data. |
| `--pull-files` | Sync the selected environment's public files into the local docroot (acli pull:files; adds and overwrites, never deletes). Client data. |
| `--logs` | Tail the selected environment's logs (acli log:tail). |
| `--activities` | List the last 10 notifications of the application (deploys, copies, backups). |
| `--no-safety-backup` | Skip exporting the local database before --pull-db replaces it. |
| `--force` | Allow --link to relink a project that already points at a different application. |

The link lives in the project's `.acquia/workspace.yml` (git-excluded); the dashboard reads it to know
the project is linked and which environment it works against.

## What the package holds

| Path | What it is |
| --- | --- |
| `src/index.ts` | `register(api)`: `registerHosting(api, acquiaProvider(api))` |
| `src/lib/provider.ts` | The Acquia Cloud provider: the credentials, the environments and their URLs, the verbs, the pulls, the console |
| `src/lib/link.ts` | The link file reader |
| `commands/cmd-tools-acquia.sh` | The per-workspace command |
| `scripts/functions/fun-acquia.sh` | The provider's bash hooks (acli) |
| `scripts/functions/fun-acquia-tool.sh` | The family's dispatcher: link file, environment selection, safety export, status |
| `scripts/args/arg-acquia.sh` | Its argparse |
| `scripts/host-install.sh` | The host side: the CLI and the credential check |
| `config/plugin.acquia.settings.yml` | The settings template |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.
