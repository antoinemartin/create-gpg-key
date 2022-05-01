# Create GPG Key Shell Script

This small shell script creates a GPG key suitable for the following usages:

- Sign your commits.
- Do SSH with github or other servers.
- Use of a Yubikey.

## Pre-requisites

You need [gnupg](https://gnupg.org/) installed.

## Usage

The following animation shows a simple usage:

<p align="center">
  <img width="600" src="./examples/simple.svg">
</p>

## Configuration cheat sheets

### Quick SSH Setup

```console
# Create a temporary GPG environment
❯ export GNUPGHOME=$(mktemp -d)
# Import created private key wihtout certificate key
❯ gpg --import acf99e63af801653f12d607c9d029ab4947a0e42-antoine-mrtn-fr.sub.asc
...
# Enable ssh support on the agent
❯ echo "enable-ssh-support" >> $GNUPGHOME/gpg-agent.conf
# Add the Authentication subkey to the agent
❯ echo $(gpg -k --with-keygrip |  awk '/Keygrip/ { a=$3; } END { print a; }') > $GNUPGHOME/sshcontrol
# Make GPG use the agent
❯ echo "use-agent" >>  $GNUPGHOME/gpg.conf
# Start the agent and use this tty for passphrases
❯ gpg-connect-agent updatestartuptty /bye
# Use the GPG ssh socket for ssh
❯ export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
# Alternative to the above
# ❯ echo "IdentityAgent $(gpgconf --list-dirs agent-ssh-socket)" >> ~/.ssh/config && chmod 600 ~/.ssh/config
# List the keys
❯ ssh-add -l
4096 SHA256:JuIXo8eSOoG7O+0IPVpecyTUFpvt86lP1qFsBaM8rLI (none) (RSA)
# SSH public key to add to Github
❯ ssh-add -L
ssh-rsa AAAAB3Nz...
# Test connection
❯ ssh git@github.com
PTY allocation request failed on channel 0
Hi antoinemartin! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.
```

### Quick Git commit signature Setup

```console
# Create a temporary GPG home
❯ export GNUPGHOME=$(mktemp -d)
# Import the produced key with only subkey private keys
❯ gpg --import acf99e63af801653f12d607c9d029ab4947a0e42-antoine-mrtn-fr.sub.asc
...
# Create a test git repo
❯ mkdir repo
❯ cd repo
❯ git init .
Initialized empty Git repository in /root/src/create-gpg-key/repo/.git/
# Set variables (add --global flag to write in ~/.gitconfig instead of ./.git/config)
# Name of the first UID of the key
❯ git config user.name "$(gpg --list-secret-keys --with-colons | awk -F: '$1 == "uid" { print $10; exit; }' | sed -e 's/ <.*$//g')"
# Email of the key
❯ git config user.email $(gpg --list-options show-only-fpr-mbox --list-secret-keys | cut -d ' ' -f 2)
# Set the program used to sign (optional)
❯ git config gpg.program $(which gpg)
# Force GPG signing
❯ git config commit.gpgsign true
# Set the signing key
❯ git config user.signingkey $(gpg --list-options show-only-fpr-mbox --list-secret-keys | cut -d ' ' -f 1)
# Trust our own key (To avoid warnings when checking signatures)
❯ echo "$(git config user.signingkey):6:" | gpg --import-ownertrust
gpg: inserting ownertrust of 6
# Allow entering GPG key password on terminal. This wouldn't work with GUI
❯ echo "pinentry-mode loopback" > $GNUPGHOME/gpg.conf
# Create a test file
❯ echo test > test
# Commit the test file. Will ask for key password.
❯ git add -A . &&  git commit -m "Test with signature"
[main (root-commit) 1817fcf] Test with signature
 1 file changed, 1 insertion(+)
 create mode 100644 test
# Verify the commit
❯ git verify-commit HEAD
gpg: Signature made Sun May  1 11:37:13 2022 UTC
gpg:                using RSA key 1FA5A3409EC8102A97F7043202E918599139CEAA
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: next trustdb check due at 2024-04-17
gpg: Good signature from "Antoine Martin <antoine@mrtn.fr>" [ultimate]
```

## TODO

- [ ] Document how to use the key. Possible usages:
  - [x] ssh
  - [x] git signature
  - [ ] secrets encryption and transport
- [ ] Make a powershell script for Windows.
- [ ] Document how to transfer private keys to a Yubikey.

## References

- https://github.com/lfit/itpol/blob/master/protecting-code-integrity.md
- https://github.com/drduh/YubiKey-Guide
- https://github.com/antoinemartin/wsl2-ssh-pageant-oh-my-zsh-plugin
- https://mlohr.com/gpg-agent-for-ssh-authentication-update/
- https://wiki.archlinux.org/title/GnuPG
