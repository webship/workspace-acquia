#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The project directory in this workspace.')
parser.add_argument('-l', '--link',
                    default="_none_",
                    help='Link the project to an Acquia application (its UUID, or its name as acli resolves it). Find them with: acli app:list')
parser.add_argument('-p', '--push',
                    action='store_true',
                    default=False,
                    help='Deploy: build an artifact from the current code and push it to the selected environment (acli push:artifact). Outward-facing: acli asks for confirmation.')
parser.add_argument('-e', '--environment',
                    default="_none_",
                    help='Environment for THIS run: the --push target, and the source --pull-db/--pull-files take data from. Default: the one remembered by --select.')
parser.add_argument('-E', '--environments',
                    action='store_true',
                    default=False,
                    help='List the environments of the linked Acquia application, with their domains.')
parser.add_argument('-s', '--select',
                    default="_none_",
                    help='Remember which environment this project works against (in .acquia/workspace.yml, git-excluded). Checked against the real environment list.')
parser.add_argument('-D', '--pull-db',
                    action='store_true',
                    default=False,
                    help='Download the selected environment's database (acli pull:db --no-import) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data.')
parser.add_argument('-F', '--pull-files',
                    action='store_true',
                    default=False,
                    help='Sync the selected environment's public files into the local docroot (acli pull:files; adds and overwrites, never deletes). Client data.')
parser.add_argument('-g', '--logs',
                    action='store_true',
                    default=False,
                    help='Tail the selected environment's logs (acli log:tail).')
parser.add_argument('-a', '--activities',
                    action='store_true',
                    default=False,
                    help='List the last 10 notifications of the application (deploys, copies, backups).')
parser.add_argument('-B', '--no-safety-backup',
                    action='store_true',
                    default=False,
                    help='Skip exporting the local database before --pull-db replaces it.')
parser.add_argument('-f', '--force',
                    action='store_true',
                    default=False,
                    help='Allow --link to relink a project that already points at a different application.')
ARGEOF
