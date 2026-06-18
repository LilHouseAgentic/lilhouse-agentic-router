# LilHouse Agent Coordination Model

LilHouse agents are cooperating layers, not one unrestricted autonomous process.

## Core rule

No agent may directly change router-impacting state unless the action goes through a guarded command and the operator has given the required approval.

Router-impacting state includes firewall, NAT, DHCP, DNS, CAKE/SQM, interface configuration, service activation, live deployment, rollback cancellation, and production root changes.

## Agent layers

### Readiness agent
Defines the safety contract.
Primary command: `lilhouse-agent-readiness --check --json`

### Status agent
Checks whether the agent toolchain is available and healthy.
Primary command: `lilhouse-agent-status --json`

### Doctor agent
Diagnoses current router state.
Primary command: `lilhouse-router-doctor --json`

### Proposal agent
Turns diagnosis into proposals. It does not execute changes.
Primary commands: `lilhouse-agent-propose --json` and `sudo lilhouse-agent-propose --write-proposal --yes`

### Proposal review agent
Reviews proposal history so agents can notice repeats and avoid proposing the same issue forever.
Primary command: `lilhouse-agent-proposal-review --json`

### Future planner agent
A future planner may turn a proposal into a guarded plan. It must not execute the plan.

### Future executor agent
A future executor may only run guarded commands after the exact required approval path has been satisfied.

## Schema contract

Agent-facing commands should emit JSON with schema, mode, writes_files, executes_router_changes, agent_may_execute_changes, decision/status fields, evidence, safe next commands, and approval requirements.

When a new agent is added, update the agent policy, readiness required tools, safe next commands, installer wiring, smoke tests, README, and this coordination model if the role changes.

## Compatibility rule

Future agents should consume stable JSON schemas, not human text output.
If an agent-facing schema changes incompatibly, use a new schema name or version.
