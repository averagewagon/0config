# 0config
My personal computer configuration using Home Manager.

## Helpful Commands

Reloading the Nix Home Manager:
```
home-manager switch --flake ~/0config
```

Registering my personal key (each boot):
```
ssh-add ~/.ssh/personal_key
```

Configuring the git user in this repo (once per clone):
```
git config user.name "Joni Hendrickson"
git config user.email "contact@joni.site"
```

Setting my remote (once per clone):
```
git remote set-url origin git@github-personal:averagewagon/0config.git
```
