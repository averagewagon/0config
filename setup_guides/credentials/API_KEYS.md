# API keys

API tokens are stored in Bitwarden under a flat name (e.g. `hcloud`,
`openrouter`) inside the `api-keys` folder. The password field holds the
token.

## Storing a key

Create or update via the Bitwarden GUI. Use a Login item; put the token in
the password field.

## Retrieving a key

```fish
set -gx BW_SESSION (bw unlock --raw)
set -gx HCLOUD_TOKEN (bw get password hcloud)
bw lock
```
