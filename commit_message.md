## Fix: Prevent redis-server zombie process leak on startup

The container was leaking a defunct (zombie) `[redis-server]` process on the host system upon startup.

This was due to Redis being configured to **daemonize**, causing a temporary parent process to terminate. Since the final PID 1 process (AdGuardHome via `exec`) is not an init system, it failed to reap this terminated parent, turning it into a zombie.

**Changes:**

* Updated `entrypoint.sh` to explicitly run Redis with `--daemonize no` to force foreground execution, preventing the creation of the temporary parent process.
* Ensured `tini` is used in the `ENTRYPOINT` (without the unnecessary `-g` flag) for proper signal handling.
