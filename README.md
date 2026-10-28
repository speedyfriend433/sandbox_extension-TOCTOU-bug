# sandbox_extension TOCTOU bug

`sandbox_extension_issue_file` resolves symlinks at issue time but does not enforce `SANDBOX_EXTENSION_NOFOLLOW`.
An app can issue an extension for a symlink pointing to a sandboxed file, swap the symlink to an out of sandbox target, then consume the extension and read the target.
The kernel does not verify that the access path matches the extension token path.
This is deterministic even TOCTOU so no race timing required.


## NOT Patched
because apple doesn’t see this as a security issue.
