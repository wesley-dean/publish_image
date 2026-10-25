# Publish Image to Various Registries

[![Dependabot Updates](https://github.com/wesley-dean/publish_image/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/wesley-dean/publish_image/actions/workflows/dependabot/dependabot-updates)
[![MegaLinter](https://github.com/wesley-dean/publish_image/actions/workflows/megalinter.yml/badge.svg)](https://github.com/wesley-dean/publish_image/actions/workflows/megalinter.yml)
[![Scorecard supply-chain security](https://github.com/wesley-dean/publish_image/actions/workflows/scorecard.yml/badge.svg)](https://github.com/wesley-dean/publish_image/actions/workflows/scorecard.yml)

## Description

This project is a GitHub Action that builds a Docker-compatible image on
various platforms, tags the image, and then publishes a Docker image to various
registries. The action can be triggered by a push to a branch, a pull request,
a release, a schedule, or a manual trigger.

The images are tagged with SBOM attestations and OCI metadata.

The goal is to make it easy to build and publish images to various registries
without a lot of configuration.  When the project started, it was just to
build for DockerHub with an image name based on the user's DockerHub username
and the name of the repository.  The project then grew to support the GitHub
Container Registry (GHCR).  Labels and tags were added, followed by multiple
platforms (e.g., AMD64 and various ARM platforms that Single-Board Computers
(SBCs) like Raspberry Pis and such).

The project then grew to support more registries, including Quay, Harbor, ECR,
and custom registries.

The first use case was to build and publish images that could be used to run
containers that would run on a laptop, shortly followed by images that could
run on a Raspberry Pi.

### Features

#### Image Labels

The action will add OCI metadata to the image, including the following:

- title
- description
- url
- source
- version
- created
- revision
- license

#### Image Descriptions

The action will also update the description of the image on DockerHub, Quay,
and Harbor using the README.md file in the repository.

#### Image Attestations

The action will also generate Software Bill of Materials (SBOM) files in
SPDX format and use them to generate attestations for each image that
is built.

#### Composite Action Components

The action is a composite action that uses several other actions to build and
publish images. The action uses the following actions:

- [docker/build-push-action](https://github.com/docker/build-push-action)
- [docker/login-action](https://github.com/docker/login-action)
- [docker/setup-qemu-action](https://github.com/docker/setup-qemu-action)
- [docker/setup-buildx-action](https://github.com/docker/setup-buildx-action)
- [docker/metadata-action](https://github.com/docker/metadata-action)
- [docker/build-push-action](https://github.com/docker/build-push-action)
- [anchore/sbom-action](https://github.com/anchore/sbom-action)
- [actions/attest-sbom](https://github.com/actions/attest-sbom)
- [christian-korneck/update-container-description-action](https://github.com/christian-korneck/update-container-description-action)

#### Image Platforms

By default, the action builds images for the following platforms:

- linux/amd64
- linux/arm64
- linux/arm/v6
- linux/arm/v7

The action can be configured to build images for other platforms by setting the
`platforms` input.  The input should be a comma-separated list of platforms.

The `arm` images are built using QEMU emulation so that they can run on
ARM-based devices such as the Raspberry Pi.

#### Supported Registries

The action can be configured to publish images to the following registries:

- DockerHub (docker.io)
- GitHub Container Registry (ghcr.io)
- Quay (quay.io)
- Harbor (goharbor.io)
- Amazon Elastic Container Registry (ECR)
- custom registry

The action can be configured to publish images to other registries by setting
`_username` and `_token` inputs for the respective registries:

- **DockerHub**: `dockerhub_username` and `dockerhub_token`
- **GitHub Container Registry**: `ghcr_username` and `ghcr_token`
- **Quay**: `quay_username` and `quay_token`
- **Harbor**: `harbor_username` and `harbor_token`
- **Amazon Elastic Container Registry (ECR)**: `ecr_access_key_id` and `ecr_secret_access_key`
- **Custom Registry**: `custom_registry_username` and `custom_registry_token`

#### Image Tags

The action adds various tags to the image, including the following:

- every build
  - `edge`
  - `{short sha}`: (short SHA hash of the commit)
  - `{long sha}` (long SHA hash of the commit)
- when the action is triggered by a push to a branch
  - `latest`
  - `{major}.{minor}.{patch}`
  - `{major}.{minor}`
  - `{major}`

## Usage

To use the action, add the following to your GitHub Actions workflow:

```yaml
  - name: Publish Image to Various Registries
    uses: wesdean/publish-image-to-various-registries@v1
    with:
      platforms: 'linux/amd64,linux/arm64,linux/arm/v6,linux/arm/v7'
      dockerfile: 'Dockerfile'
      context: '.'
      github_ref: ${{ github.ref }}
      repository_name: ${{ github.repository }}

      # to push to DockerHub, use:
      dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
      dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}

      # to push to GitHub Container Registry (GHCR), use:
      ghcr_username: ${{ secrets.GHCR_USERNAME }}

      # to push to Quay, use:
      quay_username: ${{ secrets.QUAY_USERNAME }}
      quay_token: ${{ secrets.QUAY_TOKEN }}

      # to push to Harbor, use:
      harbor_username: ${{ secrets.HARBOR_USERNAME }}
      harbor_token: ${{ secrets.HARBOR_TOKEN }}

      # to push to Amazon Elastic Container Registry (ECR), use:
      ecr_access_key_id: ${{ secrets.ECR_ACCESS_KEY_ID }}
      ecr_secret_access_key: ${{ secrets.ECR_SECRET_ACCESS_KEY }}
      ecr_region: 'us-east-1'

      # to push to a custom registry, use:
      custom_registry_username: ${{ secrets.CUSTOM_REGISTRY_USERNAME }}
      custom_registry_token: ${{ secrets.CUSTOM_REGISTRY_TOKEN }}
      custom_registry: 'registry.example.com'
```

All of the registry-specific inputs are optional.  That said, if none of the
registry inputs are set, the action will build the image and tag it, but it
will not publish the image.  It'll just eat your billing minutes.  I
recommend against that.

### Inputs

The following inputs are available:

- **basic**
  - context: The build context for the Docker build. Default: `.`.
  - dockerfile: The path to the Dockerfile. Default: `Dockerfile`.
  - platforms: The platforms to build images for. Default: `linux/amd64,linux/arm64,linux/arm/v6,linux/arm/v7`.
  - repository_name: The name of the repository.  Consider using
    `${{ github.repository }}` to get the repository name.  **REQUIRED**
  - github_ref: The GitHub ref that triggered the action.  Consider using
    `${{ github.ref }}` to get the ref that triggered the action. **REQUIRED**
  - force_release: If `true`, the action will treat any build as a release and
    tag the image with the appropriate tags.  Default: `false`.
- **DockerHub**
  - dockerhub_image: The name of the image on DockerHub. Default:
    `{ dockerhub username }/{ repository name }`.
  - dockerhub_username: The username for DockerHub.  Required to use DockerHub.
  - dockerhub_token: The token for DockerHub.  Required to use DockerHub.
  - dockerhub_registry: The URL for DockerHub. Default: `docker.io`.
- **GitHub Container Registry (GHCR)**
  - ghcr_image: The name of the image on GHCR. Default:
    `{ ghcr username }/{ repository name }`.
  - ghcr_username: The username for GHCR.  Required to use GHCR.
  - ghcr_token: The token for GHCR.  Required to use GHCR.
  - ghcr_registry: The URL for GHCR. Default: `ghcr.io`.
- **Quay**
  - quay_image: The name of the image on Quay. Default:
    `{ quay username }/{ repository name }`.
  - quay_username: The username for Quay.  Required to use Quay.
  - quay_token: The token for Quay.  Required to use Quay.
  - quay_registry: The URL for Quay. Default: `quay.io`.
- **Harbor**
  - harbor_image: The name of the image on Harbor. Default:
    `{ harbor username }/{ repository name }`.
  - harbor_username: The username for Harbor.  Required to use Harbor.
  - harbor_token: The token for Harbor.  Required to use Harbor.
  - harbor_registry: The registry for Harbor. Default: `goharbor.io`.
- **Amazon Elastic Container Registry (ECR)**:
  - ecr_image: The name of the image on ECR. Default: `{ repository name }`.
  - ecr_access_key_id: The access key ID for ECR.  Required to use ECR.
  - ecr_secret_access_key: The secret access key for ECR.  Required to use ECR.
  - ecr_region: The region for ECR.  Default: `us-east-1`.
  - ecr_registry: The URL to use with ECR.  Default:
    `{ ecr account id }.dkr.ecr.{ region }.amazonaws.com`.
- **Custom Registry**
  - custom_registry_image: The name of the image on the custom registry.
    Default: `{ repository name }`.
  - custom_registry_username: The username for the custom registry.
    Required to use a custom registry.
  - custom_registry_token: The token for the custom registry.  Required to use
    a custom registry.
  - custom_registry: The URL to the custom registry.

### Outputs

The following outputs are available:
- **DockerHub**
  - dockerhub: `true` if the image was published to DockerHub, `false` otherwise.
  - dockerhub_image: The name of the image on DockerHub.
- **GitHub Container Registry (GHCR)**
  - ghcr: `true` if the image was published to GHCR, `false` otherwise.
  - ghcr_image: The name of the image on GHCR.
- **Quay**
  - quay: `true` if the image was published to Quay, `false` otherwise.
  - quay_image: The name of the image on Quay.
- **Harbor**
  - harbor: `true` if the image was published to Harbor, `false` otherwise.
  - harbor_image: The name of the image on Harbor.
- **Amazon Elastic Container Registry (ECR)**
  - ecr: `true` if the image was published to ECR, `false` otherwise.
  - ecr_image: The name of the image on ECR.
  - ecr_image_url: The URL of the image on ECR.
- **Custom Registry**
  - custom_registry: `true` if the image was published to a custom registry,
    `false` otherwise.
  - custom_image: The name of the image on the custom registry.

## Examples

### Build and Publish Image to DockerHub

This is a minimal example that builds an image and publishes it to DockerHub.

The action is triggered by a push to the `main` branch or a tag that starts with
`v` and a version number with a major release level greater than 0 (i.e., it
would run for `v1.0.0`, but not for `v0.1.0`).  The action can also be triggered
manually.

```yaml
---
name: Build an Awesome Image

# yamllint disable-line rule:truthy
on:
  push:
    branches:
      - "main"
    tags:
      - "v[1-9][0-9]*.*"
  workflow_dispatch:

permissions: read-all

jobs:
  publish_image:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4.2.2
        with:
          depth: 0
          tags: true
      - name: Build and Publish Image
        uses: wesley-dean/publish_image@v1
        with:
          # pass the basic data for the build
          github_ref: ${{ github.ref }}
          repository_name: ${{ github.repository }}

          # just push to DockerHub and nowhere else
          dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
```

### Build and Publish Image to DockerHub and GHCR

This example pushes to both DockerHub and GHCR.  The image is given different
names on each registry.

```yaml
---
name: Build an Awesome Image

# yamllint disable-line rule:truthy
on:
  push:
    branches:
      - "main"
    tags:
      - "v[1-9][0-9]*.*"
  workflow_dispatch:

permissions: read-all

jobs:
  publish_image:
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4.2.2
        with:
          depth: 0
          tags: true
      - name: Build and Publish Image
        uses: wesley-dean/publish_image@v1
        with:

          # basic inputs
          github_ref: ${{ github.ref }}
          repository_name: ${{ github.repository }}

          # DockerHub inputs
          dockerhub_username: ${{ secrets.DOCKERHUB_USERNAME }}
          dockerhub_token: ${{ secrets.DOCKERHUB_TOKEN }}
          dockerhub_image: "myname/awesomeimage"

          # GHCR inputs
          ghcr_username: ${{ secrets.GHCR_USERNAME }}
          ghcr_token: ${{ secrets.GHCR_TOKEN }}
          ghcr_image: "my-name/awesome-image"
```

## Verified release and dual-registry publishing (opt-in)

Existing callers retain the historical behavior when the new inputs are not
provided. A previously validated tagged-release pipeline (including
`v0.x.y`) can supply an **explicit** release ref and source SHA; this
prevents the `workflow_run` event's ambient `main` ref from silently
controlling release tags.

| Input | Default | Contract |
| --- | --- | --- |
| `verified_release_ref` | empty | Exact independently verified `refs/tags/vMAJOR.MINOR.PATCH` |
| `verified_source_sha` | empty | Independently verified lowercase full 40-character commit SHA |
| `build_args` | empty | Nonsecret newline-separated `NAME=VALUE` Buildx args |
| `push` | `true` | Set `false` to build/load locally without registry credentials |
| `required_registries` | empty | Required names `dockerhub,ghcr` (or a subset) with fail-closed credential checks |

Both verified inputs are required together. Verified mode refuses
`force_release` and generates **only** the intended tags:
`latest`, exact version (e.g., `0.2.3`), major/minor (`0.2`), major
(`0`), short SHA (`sha-abcdef0`), and long SHA (`sha-abcdef0123...`).
It also writes `org.opencontainers.image.version`,
`org.opencontainers.image.revision` and
`org.opencontainers.image.ref.name` from the explicit identity, not from
the ambient GitHub event. **No `edge` tag** is generated in verified
mode. Ordinary (unverified-mode) callers continue to use the historical
docker/metadata-action tag and branch policy.

**Verification boundary:** These inputs do not themselves prove a release
is genuine. The invoking workflow MUST independently validate the
successful trusted workflow run, protected source history, signed tag,
release assets, attestations, exact immutable hashes, and no-push gate
before granting registry credentials. Never use PR or arbitrary webhook
strings as verified release authority. The action validates formatting
and fail-closed selection; it cannot independently authenticate a
caller-supplied upstream release.

Build arguments are forwarded to `docker/build-push-action` and must be
**nonsecret**. The action rejects common credential-like key names, but
cannot recognize secret values disguised as ordinary settings. Never
place tokens, passwords or GPG keys in args, image labels, metadata
or logs. certbotbot's required verified build-identity arguments are
`SOURCE_COMMIT`, `RELEASE_VERSION`, `PRODUCER_SHA256`,
`HANDOFF_MANIFEST_SHA256`, and `BUILD_KIND=release`. Derive them from
the validated release artifact handoff, not from a fresh checkout.

### Example downstream invocation after independent release verification

This example is a fragment for a **separate protected release-correlated
workflow** after its own release validation and exact OCI context
preparation. The SHA pin for this action must be replaced with the
reviewed full commit **after** this PR merges.

~~~yaml
- name: Publish verified certificate producer
  uses: wesley-dean/publish_image@REPLACE_WITH_REVIEWED_40_CHAR_COMMIT
  with:
    github_ref: ${{ github.ref }}
    repository_name: certbotbot
    context: ${{ runner.temp }}/verified-oci-context
    dockerfile: ${{ runner.temp }}/verified-oci-context/Dockerfile
    platforms: linux/amd64
    push: 'true'
    required_registries: dockerhub,ghcr
    verified_release_ref: ${{ steps.verify-release.outputs.release_ref }}
    verified_source_sha: ${{ steps.verify-release.outputs.source_sha }}
    build_args: |
      SOURCE_COMMIT=${{ steps.verify-release.outputs.source_sha }}
      RELEASE_VERSION=${{ steps.verify-release.outputs.version }}
      PRODUCER_SHA256=${{ steps.verify-release.outputs.producer_sha256 }}
      HANDOFF_MANIFEST_SHA256=${{ steps.verify-release.outputs.manifest_sha256 }}
      BUILD_KIND=release
    dockerhub_image: wesleydean/certbotbot
    dockerhub_username: ${{ secrets.dockerhub_username }}
    dockerhub_token: ${{ secrets.dockerhub_token }}
    ghcr_image: wesley-dean/certbotbot
    ghcr_username: ${{ secrets.ghcr_username }}
    ghcr_token: ${{ secrets.ghcr_token }}
~~~

The named `verify-release` step is **illustrative**; this reusable
action does not create that step, verify release signing, or provide
registry credentials. For a no-push acceptance build, pass
`push: 'false'` and the two registry image names without tokens,
and choose `platforms: linux/amd64`. Registry logins, description
updates and publication are skipped; one image is loaded locally
for inspecting its OCI labels and Buildx argument effects.
A Dockerfile may still require network access to fetch base images.
See the [no-push contract CI](.github/workflows/megalinter.yml).

### Outcomes and limits

With `required_registries: dockerhub,ghcr`, absent credentials for
either target cause failure **before** any login or build. Both
targets participate in one Buildx push; an error fails the action.
Multi-registry publishing is **not transactional**: one destination
may accept tags even if another push fails. There is no rollback.
Independently inspect each registry and verify its actual digest,
platforms, source provenance, tags and SBOM.

The new **nonsecret outputs** are `tags`, `digest`, `release_ref`,
`source_sha`, `dockerhub_digest_ref` and `ghcr_digest_ref`.
Digest references are the intended target names paired with the
Buildx-reported digest; they are **not** remote verification evidence.
The original enabled-registry/image outputs remain available. Passwords,
registry tokens, and ECR access keys are never written to step outputs.

## Questions

### Why do we need to provide the repo name?

Because the action is a composite action, it doesn't have access to the
`github.repository` context.  The action needs the repository name to build the
image name for the various registries.

### Why do we need to provide the ref?

The action needs the ref to determine the version of the image.  The ref is
used to determine the version of the image.  The ref is also used to determine
the tags for the image.  Like with the repository name, the action doesn't have
access to the `github.ref` data.

### What is the context variable?

The context variable is the path to the build context for the Docker build.
The default is the root of the repository (`.`).

### Why do we need to provide the Dockerfile?

The action needs to know the path to the Dockerfile to build the image.  The
default is `Dockerfile` in the root of the build context (so, `./Dockerfile`).

### Can we build images for other platforms?

Yes, the action can build images for other platforms.  The `platforms` input
is a comma-separated list of platforms.  The default is
`linux/amd64,linux/arm64,linux/arm/v6,linux/arm/v7`.

### Can we publish images to multiple registries?

Yes, images can be pushed to multiple registries.  The action can be configured
to push images to DockerHub, GHCR, Quay, Harbor, ECR, and custom registries.

### Can images on different registries have different names?

Yes, images on different registries can have different names.  The action
supports setting the image name for each registry.  For example, the image
name on DockerHub can be `myname/awesomeimage`, while the image name on GHCR
can be `my-name/awesome-image`.  This can be done by setting the
`dockerhub_image` and `ghcr_image` inputs, respectively.

### How are versions handled?

The action uses the `github_ref` to determine the version of the image.  If the
ref starts with `refs/tags/v[1-9]` (e.g., `v1.0.0`), the action considers this
run to be a "release" and sets the version to the tag.

#### What about version 0.x.x?

Good eye.  The action won't consider a tag that starts with `v0` to be a
release.  It will still build and push the image, but it'll only tag the image
with the `edge` tag plus the short and long hashes.

If, however, the `force_release` input is set to `true`, the action will treat
any build -- v0.x.x or otherwise -- as a release and tag the image with the
appropriate tags.

### What secrets, credentials, tokens, etc. are stored after runs?

Nothing.  Nothing is stored.  The action uses the credentials to authenticate
to DockerHub, GHCR, etc. and when updating image descriptions on DockerHub,
Quay, and Harbor.  The credentials aren't used for anything else.  When they're
passed to the action as secrets, they're stored in the GitHub Actions
environment and are not persisted, even in the logs.  It is recommended that
credentials be stored in GitHub Secrets, not as plain text or repository
environment variables.

Want to be sure?  Check the code.  It's all there.  Here's a link:

[https://github.com/wesley-dean/publish_image/blob/main/action.yml](https://github.com/wesley-dean/publish_image/blob/main/action.yml)

#### Release tags

Images associated with releases are given the following tags:

- latest
- edge
- `{major}.{minor}.{patch}`
- `{major}.{minor}`
- `{major}`
- `{short sha}`
- `{long sha}`

So, if the tag is `v1.2.3`, the image will be tagged with the following:

- latest
- edge
- v1.2.3
- v1.2
- v1
- abc123
- abc123def456aaa7890123456789abcdef012345

(the SHA hashes are made up)

#### Non-release tags

Images that are not associated with a release are given the following tags:

- edge
- `{short sha}`
- `{long sha}`

### Image descriptions

For images on DockerHub, Quay, and Harbor, the action updates the description
of the image using the README.md file in the repository.

### What if I need to override the image's labels?  Customize build parameters?

Yeah, no, this action just handles the most basic stuff.  If you need to
customize the build, you'll need to use the underlying actions directly.  If
you want to provide a PR to include those variables, I'm open to it.

## License

This project is licensed under the Creative Commons License 1.0 Universal
License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome. Please read the [CONTRIBUTING.md](CONTRIBUTING.md)
file for details.

### Code of Conduct

Please read the [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) file for details on
the code of conduct.  Long story short, be nice to each other and treat each
other with respect, compassion, and empathy, especially when you disagree.

## Authors

- Wes Dean
