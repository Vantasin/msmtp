# Safety Rules

- Do not store secrets, tokens, passwords, or private keys in this repository.
- Configuration examples must use placeholders or documented secure lookup
  methods.
- Any workflow that touches credential storage or secret retrieval must document
  its security assumptions.
- Scripts that replace live config or secret files should prefer atomic
  replacement and recoverable backups over destructive in-place mutation.
- When interruption behavior can leave external state in question, document the
  verification or recovery path rather than claiming a change is fully
  transactional.
- When platform-specific behavior differs between Linux and macOS, document the
  difference instead of hiding it inside an undocumented script.
- Avoid destructive repository actions unless explicitly requested.
