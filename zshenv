if [ -e ${HOME}/.nix-profile/etc/profile.d/nix.sh ]; then
    source ${HOME}/.nix-profile/etc/profile.d/nix.sh;
fi
archive_path="${HOME}/.nix-profile/lib/locale/locale-archive"
if [[ -e ${archive_path} ]]; then
    export LOCALE_ARCHIVE=${archive_path}
fi
. "$HOME/.cargo/env"
