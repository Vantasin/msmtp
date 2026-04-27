# Safety Rules

- Do not store secrets, tokens, passwords, or private keys in this repository.
- Configuration examples must use placeholders or documented secure lookup
  methods.
- Any workflow that touches credential storage or secret retrieval must document
  its security assumptions.
- When platform-specific behavior differs between Linux and macOS, document the
  difference instead of hiding it inside an undocumented script.
- Avoid destructive repository actions unless explicitly requested.
