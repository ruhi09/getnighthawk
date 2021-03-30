PREFIX="" # ask otto
ARCH=$INPUT_ARCHITECTURE
DISTRO=""
OS=$INPUT_OS

if [[ "$OS" = *"ubuntu"* ]]; then
  DISTRO="ubuntu"
elif [[ "$OS" = *"macos"* ]]; then
  DISTRO="darwin"
else
  printf "ERROR\tOperating system %s not supported\n" "$OS"
  exit 1
fi

if [ -z "$DISTRO" ]; then
  printf "ERROR\tUnable to detect the operating system\n"
  exit 1
fi

ASSET_NAME="nighthawk-$DISTRO-$ARCH-$INPUT_VERSION.tar.gz"

printf "INFO\tBAZEL FOLDER\n"
bazel info -c opt bazel-bin

ROOT_FOLDER=$(bazel info -c opt bazel-bin)
CLIENT_BINARY="$ROOT_FOLDER/nighthawk_client"
SERVICE_BINARY="$ROOT_FOLDER/nighthawk_service"
TEST_SERVER_BINARY="$ROOT_FOLDER/nighthawk_test_server"
OUTPUT_TRANSFORM_BINARY="$ROOT_FOLDER/nighthawk_output_transform"

# Optional personal access token for external repository
TOKEN=$GITHUB_TOKEN
if ! [[ -z ${INPUT_TOKEN} ]]; then
  TOKEN=$INPUT_TOKEN
fi

if ! [[ -f "$CLIENT_BINARY" ]]; then
    printf "$CLIENT_BINARY does not exist"
fi

if ! [[ -f "$SERVICE_BINARY" ]]; then
    printf "$SERVICE_BINARY does not exist"
fi

if ! [[ -f "$TEST_SERVER_BINARY" ]]; then
    printf "$TEST_SERVER_BINARY does not exist"
fi

if ! [[ -f "$OUTPUT_TRANSFORM_BINARY" ]]; then
    printf "$OUTPUT_TRANSFORM_BINARY does not exist"
fi

# bundle the binaries
if ! type "tar" > /dev/null 2>&1; then
  printf "ERROR\ttar not found\n"
  exit 1;
fi

if ! tar -zcvf $ASSET_NAME $CLIENT_BINARY $SERVICE_BINARY $TEST_SERVER_BINARY $OUTPUT_TRANSFORM_BINARY; then
    printf "ERROR\tUnable to create bundle\n"
fi

# Upload artifact
GITHUB_API_URL="api.github.com"
RELEASE_URL="https://$GITHUB_API_URL/repos/$INPUT_REPO/releases"
RELEASE_UPLOAD_URL=$(curl -H "Authorization: token $TOKEN" $RELEASE_URL | jq -r '.[] | select(.tag_name == "'${INPUT_VERSION}'")' | jq -r .upload_url)
pattern="{?"
RELEASE_ASSET_URL="${RELEASE_UPLOAD_URL%$pattern*}"
printf "INFO\tJQ VERSION \n"
jq --version
printf "INFO\tRELEASE UPLOAD URL ${RELEASE_URL}\n"
printf "INFO\tRELEASE UPLOAD URL ${TOKEN}\n"
printf "INFO\tRELEASE UPLOAD URL ${INPUT_VERSION}\n"
printf "INFO\tRELEASE UPLOAD URL ${RELEASE_UPLOAD_URL}\n"
printf "INFO\tRelease URL ${RELEASE_URL}\n"
printf "INFO\tUploading to ${RELEASE_ASSET_URL}\n"

curl \
    -X POST \
    -H "Content-Type: application/tar" \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    --data-binary @${ASSET_NAME} \
    "$RELEASE_ASSET_URL?name=$ASSET_NAME"

printf "INFO\tAction ran succesfully!!\n"