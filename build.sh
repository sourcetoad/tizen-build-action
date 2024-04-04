#
# Set up Tizen Studio
#
TIZEN_STUDIO="$GITHUB_WORKSPACE/tizen-studio"
INSTALLER="$GITHUB_WORKSPACE/tizen-studio_5.1.bin"

wget -nc -O "$INSTALLER"  http://download.tizen.org/sdk/Installer/tizen-studio_5.1/web-cli_Tizen_Studio_5.1_ubuntu-64.bin
chmod a+x "$INSTALLER"
"$INSTALLER" --accept-license $TIZEN_STUDIO

PATH="$TIZEN_STUDIO/tools/ide/bin:$PATH"

#
# Parse arguments
#
if [ "$8" = "partner" ]; then
    PRIVILEGE=parner
else
    PRIVILEGE=public
fi

PROJECT_DIR="$1"

AUTHOR_KEY="$GITHUB_WORKSPACE/author-key.p12"
echo -n "$2" | base64 -d >"$AUTHOR_KEY"

AUTHOR_PASSWORD="$3"

#tizen cli-config -g "profiles.path=/home/runner/work/tizen_novel/tizen_novel/tizen-studio-data/profile/profiles.xml"
#tizen cli-config "profiles.path=/home/runner/work/tizen_novel/tizen_novel/tizen-studio-data/profile/profiles.xml"
CUSTOM_DISTRIBUTOR_CERT="$GITHUB_WORKSPACE/distributor-cert.p12"
echo -n "$4" | base64 -d >"$CUSTOM_DISTRIBUTOR_CERT"


DISTRIBUTOR_PASSWORD="$5"

tizen security-profiles add -a $AUTHOR_KEY -n sourcetoad-tizen-public -p $AUTHOR_PASSWORD -d $CUSTOM_DISTRIBUTOR_CERT -dp $DISTRIBUTOR_PASSWORD
echo <<EOF
Build and signing parameters:
 - project-dir: $PROJECT_DIR
 - author-cert: $AUTHOR_CERT
 - author-key: $AUTHOR_KEY
 - author-password: ***
 - distributor-cert: $DISTRIBUTOR_CERT
 - distributor-key: $DISTRIBUTOR_KEY
 - distributor-password: ***
 - privilege: $PRIVILEGE
EOF

#
# Create profiles.xml

#
# Build and sign
#
PACKAGE_OUTPUT_PATH="$PROJECT_DIR/output.wgt"
ERROR_LOG="$GITHUB_WORKSPACE/tizen-studio-data/cli/logs/cli.log"
rm -rf $PROJECT_DIR/.git
rm -rf $PROJECT_DIR/.github
cd $PROJECT_DIR
tizen build-web -e .git/* -e .github -e .git -e .github/* -- "$PROJECT_DIR" 
tizen package -t wgt -s sourcetoad-tizen-public -o "$PACKAGE_OUTPUT_PATH" -- "$PROJECT_DIR"

if [ $? -eq 0 ]; then
    SUCCESS=true
    echo "package-artifact=$PACKAGE_OUTPUT_PATH" >> $GITHUB_OUTPUT
else
    SUCCESS=false
    cat "$ERROR_LOG"
fi

#
# Clean up
#
tizen clean -- "$PROJECT_DIR"

rm -rf "$GLOBAL_PROFILES_PATH" \
    "$CUSTOM_AUTHOR_CERT" \
    "$CUSTOM_DISTRIBUTOR_CERT" \
    "$CUSTOM_DISTRIBUTOR_KEY"

if $SUCCESS; then
    exit 0;
else
    exit 1;
fi
