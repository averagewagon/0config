# SSH keys

# Activating an SSH key

Load it into ssh-agent for the current session (8h):

```bash
ssh-add -t 8h ~/.ssh/personal_key
```

Re-run this each session, or after the timeout expires.

## One-Time Setup (per key)

Each machine gets its own key. Keys never leave the device they were generated on.

In the Proton Pass GUI, create a Login item named `ssh-keys/<hostname>_<keyname>` with a generated
strong password in the password field.

Generate the key on the device:

```bash
ssh-keygen -t ed25519 -C "contact@joni.site" -f ~/.ssh/personal_key
```

Copy the public key:

```bash
cat ~/.ssh/personal_key.pub
```

Add the public key to the Proton Pass Login item as a note and upload it anywhere else it's needed
(e.g GitHub).
