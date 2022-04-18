#!/bin/sh
#
# Script for the creation of a well-behaving GPG key.
# 
# Please see https://github.com/lfit/itpol/blob/master/protecting-code-integrity.md

# Transform mbox identifier to slug
slugify () {
    echo "$1" | iconv -t us_ascii | sed -r s/[~\^]+//g | sed -r s/[^a-zA-Z0-9]+/-/g | sed -r s/^-+\|-+$//g | tr A-Z a-z
}

# Read secret string
read_secret()
{
    # Disable echo.
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT

    # Read secret.
    read "$@"

    # Enable echo.
    stty echo
    trap - EXIT

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}

# Get user information
printf "Enter user name: "
read USER_NAME
printf "Enter user email: "
read USER_EMAIL

USER_ID="${USER_NAME} <${USER_EMAIL}>"
echo "Using user id $USER_ID"

# Get and verify password
printf "Enter password (hard to guess, easy to remember and use): "
read_secret PASSWORD
printf "Enter again for confirmation: "
read_secret PASSWORD_CONFIRMATION

if [ "$PASSWORD" != "$PASSWORD_CONFIRMATION" ]; then 
    echo "ERROR! Passwords don't match. Please restart"
    exit 1
fi

# Create a temporary directory for working
export GNUPGHOME=$(mktemp -d)
echo "Working in $GNUPGHOME"
# Delete working directory on exit
trap 'rm -rf $GNUPGHOME' EXIT

# Create the key without passphrase
gpg --batch --passphrase '' \
    --quick-generate-key "${USER_ID}" rsa4096 cert 2y >/dev/null 2>&1

# Retrieve fingerprint and email
MBOX="$(gpg --list-options show-only-fpr-mbox --list-secret-keys 2>/dev/null)"

# Get the fingerprint of the key (this is the only one of the keyring)
FPR=$(echo "$MBOX" | awk '{print $1}')

# Add the 3 keys with 1 year lifetime
gpg --batch --passphrase '' --quick-add-key $FPR rsa4096 sign 1y >/dev/null 2>&1
gpg --batch --passphrase '' --quick-add-key $FPR rsa4096 encrypt 1y >/dev/null 2>&1
gpg --batch --passphrase '' --quick-add-key $FPR rsa4096 auth 1y >/dev/null 2>&1

# Display generated key information
echo ""
echo "Generated key information:"
gpg -K --keyid-format short

# Generate filenames
FILENAME="$(slugify "$MBOX")"
KEYFILE="$FILENAME.key.asc"
SUBKEYSFILE="${FILENAME}.sub.asc"
PUBFILE="${FILENAME}.pub.asc"
SSHFILE="${FILENAME}_rsa.pub"
RVKFILE="${FILENAME}.rev.asc"

# Protect the key with the passphrase. It needs to be done after the subkeys 
# have been added in order for export to work without having to enter the 
# passphrase for each subkeys.
gpg --batch --yes --pinentry-mode loopback --passphrase "$PASSWORD" \
    --change-passphrase "$FPR"

# Output the secret key
gpg --batch --yes  --no-tty --pinentry-mode loopback --passphrase "$PASSWORD" \
    --output "${KEYFILE}" --armor --export-secret-key "$USER_ID"
# Output the subkeys to protect the master key
gpg --batch --yes  --no-tty --pinentry-mode loopback --passphrase "$PASSWORD" \
    --output "${SUBKEYSFILE}" --armor --export-secret-subkeys "$USER_ID"
# Output the public key
gpg --output "$PUBFILE" --armor --export $FPR
# Output the public ssh key
gpg --output "$SSHFILE" --export-ssh-key $FPR
# Output the revocation certificate
# gpg --yes --output "$RVKFILE" --gen-revoke $FPR
cp $GNUPGHOME/openpgp-revocs.d/$FPR.rev $RVKFILE

echo ""
echo "Saved private key in file $KEYFILE"
echo "Saved private key with only private subkeys in file $SUBKEYSFILE"
echo "Saved public key in file $PUBFILE"
echo "Saved revocation certificate in file $RVKFILE"
echo "Saved public SSH key in file $SSHFILE"
echo ""
echo "Now you should:"
echo "- Save the private key and revocation certificate in an encrypted portable drive or a safe."
echo "- Import the secret subkeys where you want to use them."
echo "- Distribute and/or publish the public key (keys.openpgp.org for instance)."
echo "- Export the ssh key to the authorized_keys file of servers."
echo ""
echo "For more information: https://github.com/lfit/itpol/blob/master/protecting-code-integrity.md"
