# LilHouse agent operating model

LilHouse agents are intended to become router helpers, not uncontrolled root automation.

## Default mode

```text
read_only_observe
```

Agents may read state, summaries, indexed history, and raw evidence with line limits. They must not assume write or execute authority.

## Required workflow

1. Run read-only status checks.
2. Read the storage maintenance dry-run report.
3. Read additive storage summaries when available.
4. Query hot and archived history for relevant evidence.
5. Preview raw evidence with bounded line limits.
6. Classify the situation as observe, watch, propose, alert, guarded execute request, or blocked.
7. Execute only through guarded commands after required approval.

## Storage rule

Summaries are useful, but raw history remains the source of truth.

```text
summary -> query -> show raw evidence
```

## Forbidden for agents

Agents must not delete arbitrary files, truncate active ledgers, clear archive indexes, overwrite raw history, disable firewall without rollback, change DHCP/NAT/firewall live without guarded approval, or run live deployment without the required operator phrase.

## Agent-readable status

Future agents should start with the compact read-only status report:

```bash
lilhouse-agent-status --json
```

This combines agent readiness, policy source, storage status, storage maintenance planning, and router status into one machine-readable report.
