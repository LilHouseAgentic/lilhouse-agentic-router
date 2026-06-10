# Architecture

LilHouse uses a worker, brain, proposal, approval, executor model.

Workers collect evidence.

Brains summarize and decide whether the system should observe, warn, propose, or request approval.

Approval gates prevent risky changes from being applied automatically.

Executors should only run known, allowlisted actions.
