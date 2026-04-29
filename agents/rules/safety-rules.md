# Safety Rules

- Do not store secrets, tokens, passwords, or private keys in this repository.
- Configuration examples must use placeholders or documented secure lookup
  methods.
- Any workflow that touches credential storage or secret retrieval must document
  its security assumptions.
- Plaintext password files should default to user-state or system paths, not
  tracked repo paths. If a repo-local plaintext convenience path is offered, it
  must stay gitignored and be documented as a convenience tradeoff rather than
  the preferred secure default.
- Scripts that replace live config or secret files should prefer atomic
  replacement and recoverable backups over destructive in-place mutation.
- When interruption behavior can leave external state in question, document the
  verification or recovery path rather than claiming a change is fully
  transactional.
- When platform-specific behavior differs between Linux and macOS, document the
  difference instead of hiding it inside an undocumented script.
- Avoid destructive repository actions unless explicitly requested.
