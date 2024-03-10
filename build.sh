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

if [ ! -z $2 ]; then
    CUSTOM_AUTHOR_CERT="$GITHUB_WORKSPACE/author-cert.cer"
    echo -n "$2" | base64 -d >"$CUSTOM_AUTHOR_CERT"
fi
DEFAULT_AUTHOR_CERT="$TIZEN_STUDIO/tools/certificate-generator/certificates/developer/tizen-developer-ca.cer"
AUTHOR_CERT="${CUSTOM_AUTHOR_CERT:-"$DEFAULT_AUTHOR_CERT"}"

AUTHOR_KEY="$GITHUB_WORKSPACE/author-key.p12"
echo -n "$3" | base64 -d >"$AUTHOR_KEY"

AUTHOR_PASSWORD="$4"

tizen security-profiles add -a $AUTHOR_KEY -n sourcetoad-tizen-public -p $AUTHOR_PASSWORD
tizen cli-config "profiles.path=/home/runner/work/tizen_novel/tizen_novel/tizen-studio-data/profile/profiles.xml"
if [ ! -z $5 ]; then
    CUSTOM_DISTRIBUTOR_CERT="$GITHUB_WORKSPACE/distributor-cert.cer"
    echo -n "$5" | base64 -d >"$CUSTOM_DISTRIBUTOR_CERT"
fi
DEFAULT_DISTRIBUTOR_CERT="$TIZEN_STUDIO/tools/certificate-generator/certificates/distributor/sdk-$PRIVILEGE/tizen-distributor-ca.cer"
DISTRIBUTOR_CERT="${CUSTOM_DISTRIBUTOR_CERT:-"$DEFAULT_DISTRIBUTOR_CERT"}"

if [ ! -z $6 ]; then
    CUSTOM_DISTRIBUTOR_KEY="$GITHUB_WORKSPACE/distributor-key.p12"
    echo -n "$6" | base64 -d >"$CUSTOM_DISTRIBUTOR_KEY"
fi
DEFAULT_DISTRIBUTOR_KEY="$TIZEN_STUDIO/tools/certificate-generator/certificates/distributor/sdk-$PRIVILEGE/tizen-distributor-signer.p12"
DISTRIBUTOR_KEY="${CUSTOM_DISTRIBUTOR_KEY:-"$DEFAULT_DISTRIBUTOR_KEY"}"

DISTRIBUTOR_PASSWORD="${7:-tizenpkcs12passfordsigner}"

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
tizen build-web -e .git/ -e .github -- "$PROJECT_DIR" \
    && tizen package -t wgt -s sourcetoad-tizen-public -o "$PACKAGE_OUTPUT_PATH" -- "$PROJECT_DIR/.buildResult"

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
