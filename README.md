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

## Quick SSH Setup

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

## TODO

- [ ] Document how to use the key. Possible usages:
  - [x] ssh
  - [ ] git signature
  - [ ] secrets encryption and transport
- [ ] Make a powershell script for Windows.
- [ ] Document how to transfer private keys to a Yubikey.

## References

- https://github.com/lfit/itpol/blob/master/protecting-code-integrity.md
- https://github.com/drduh/YubiKey-Guide
- https://github.com/antoinemartin/wsl2-ssh-pageant-oh-my-zsh-plugin
- https://mlohr.com/gpg-agent-for-ssh-authentication-update/
- https://wiki.archlinux.org/title/GnuPG
