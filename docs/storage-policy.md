# LilHouse lossless storage policy

LilHouse is intended to run continuously on small router-class systems without creating unbounded storage growth.

The storage policy is lossless by default:

- Worker observations should remain available from time of installation onward.
- Raw history may be compressed, archived, indexed, and summarized.
- Summaries are additive and must not become the only copy of important worker observations.
- Cleanup must never silently remove the only copy of useful historical worker data.
- Latest state files must remain plain and easy for humans/tools to read.
- Old raw history should move from hot storage to compressed warm/cold storage.

## Storage tiers

### Hot data

Hot data is immediately useful and should stay uncompressed:

- latest current-state JSON
- latest storage-health JSON
- recent event/action/proposal ledgers
- recent failure reports
- active config files
- current router.env and cake.env

### Warm data

Warm data may be compressed but should remain directly recoverable:

- older JSONL ledgers
- older worker reports
- older successful run reports
- daily archives

### Cold data

Cold data is compact history used by agents for long-term reasoning:

- daily summaries
- indexes pointing to compressed raw archives
- weekly/monthly trend summaries

Cold summaries must not replace raw archives unless the data is explicitly marked disposable.

## Default cleanup behaviour

Cleanup tools must be conservative:

- dry-run first
- only manage LilHouse-owned paths
- preserve latest state
- preserve config
- preserve failure reports
- preserve indexed history
- compress before deleting raw text where practical
- never clean arbitrary system logs or user files

## Agent access requirement

Agents must be able to inspect history from install time onward by using:

1. latest plain JSON state
2. compact summaries
3. indexes
4. compressed raw archives when deeper detail is needed

The goal is low storage growth without blinding the agents.

## Archive dry-run planning

`lilhouse-storage-clean --dry-run` plans storage actions without changing files.

The first alpha implementation is intentionally read-only:

- it does not delete files
- it does not truncate active ledgers
- it does not compress files yet
- it reports what would be compressed or archived later
- it preserves active state, active config, and live ledgers

Future archive execution must preserve agent access to old worker observations by writing compressed archives and indexes before any live ledger checkpointing occurs.

## Archive index

`lilhouse-storage-index` builds a searchable index of hot and archived LilHouse history.

The index is designed so future agents can locate historical worker observations without scanning every file every time.

Index records include:

- original path
- role
- file kind
- compression status
- agent access method
- size
- modification time
- SHA256 checksum
- line count where useful

The index may be previewed with:

    sudo lilhouse-storage-index --dry-run

Writing the index is guarded:

    sudo lilhouse-storage-index --write-index --yes

The index itself is stored under the LilHouse archive directory and must not replace raw archives.

## Guarded archive execution

`lilhouse-storage-archive` performs the first guarded archive execution path.

The first execution scope is intentionally narrow:

- compress/copy logs
- compress/copy old JSON reports
- verify compressed archive payload SHA256
- append archive action records to the archive index
- preserve original source files

It does not:

- delete originals
- truncate active ledgers
- archive active ledgers
- modify config
- clean arbitrary system files

Preview:

    sudo lilhouse-storage-archive --dry-run

Execute:

    sudo lilhouse-storage-archive --execute --yes

This command is a compression/archive primitive, not a cleanup/deletion tool.

## Active ledger checkpoint dry-run

`lilhouse-storage-ledger-checkpoint --dry-run` plans how active JSONL ledgers could be archived later.

It does not write archives, append index records, truncate ledgers, delete files, or modify active history.

The dry-run plan shows the archive target, source SHA256, line count, byte size, and the exact safety order required before a future checkpoint execution can exist.
