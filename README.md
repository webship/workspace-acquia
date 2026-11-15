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

## The items it carries

The workspace is container-based (DDEV by default). Each item lands in the folder of its kind, when
that folder is an active workspace folder, is listed there like any other item, and is installed
into Claude Code from there:

| What | Lands in | What it is for |
| --- | --- | --- |
| The agent `acquia-deployer` | `ai-agents/` | Says whether a site is linked to Acquia Cloud and to what, reads its environments and its log, brings the live data here when asked, tests it before a deploy, and hands over the deploy line |
| The skill `acquia-hosting` | `ai-skills/` | Every entry of the ACQUIA menu and the command behind it, each option of `cmd-tools-acquia.sh`, the link, the keys of `plugin.acquia.settings.yml` |
| The command `/acquia-status` | `ai-commands/` | `/acquia-status <project>`: the link and the environments. Read-only |
| The prompt `acquia-test-then-deploy` | `ai-prompts/` | The launch command of a session that checks a site, runs its webship-js suite when it has one, and gives the deploy line |

The plugin keeps its one command, `cmd-tools-acquia.sh`; no other was added. The item bodies are plain Markdown any AI command-line assistant can follow; Claude Code is the default shape (frontmatter, the launch command of the prompt). A site that carries a webship-js suite is tested by the workspace's own `cmd-tools-testing.sh <project> --run` before a deploy, when it is there.

How the items are laid out and checked: [docs/plugin-items-pattern.md](docs/plugin-items-pattern.md).

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder: `dev`, `test`, `demos`, `sandboxes`, `projects` (`dev` is the one added when none is there). `cmd-tools-acquia.sh`, which the menu's verbs run, is placed in it, and the menu is on its project rows.
- on the machine: `acli`, the provider's CLI (https://docs.acquia.com/acquia-cli/install).

`--require` says so, `--activate` and `--install` stop until the workspace has a sites folder, and `--with-needs` adds it first. A missing command is said and never added:

```bash
bash core/scripts/plugins.sh --activate acquia --with-needs
bash core/scripts/plugins.sh --check acquia      # each command: found, with its version, or missing, with how to install it
```

A workspace that knows none of this (Webship Workspace 1.0.8 and older) ignores the keys: add a sites folder yourself, then `--install acquia` again.

It also needs the AI folders its items are placed in (`needs.plugins`): `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`, beside the sites folder. `--with-needs` adds what is missing first. A kind whose folder is not an active workspace folder is skipped, and the install says so.

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
| `ai/agents/acquia-deployer.md` | The agent `acquia-deployer` |
| `ai/skills/acquia-hosting/` | The skill `acquia-hosting` |
| `ai/commands/acquia-status.md` | The command `/acquia-status` |
| `ai/prompts/acquia-test-then-deploy.md` | The prompt `acquia-test-then-deploy` |
| `tests/items.test.ts` | The shape of every item, and that it names nothing the plugin does not have |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.
