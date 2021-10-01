# Tizen Build GitHub Action
Build and package a Tizen app.

It currently only works for Web applications (.wgt). If you want native app support, please upstream a fix :)

## Usage
### Inputs

Following inputs can be used as `step.with` keys

| Name                   | Required | Default                     | Type   | Description                                                                 |
|------------------------|----------|-----------------------------|--------|-----------------------------------------------------------------------------|
| `project-dir`          | Yes      |                             | String | Absolute path to your Tizen project.                                        |
| `author-cert`          | No       | Tizen developer cert        | String | Author certificate for signing. Base64-encoded.                             |
| `author-key`           | Yes      |                             | String | Author key used for signing. Base64-encoded.                                |
| `author-password`      | Yes      |                             | String | Password for `author-key`                                                   |
| `distributor-cert`     | No       | Tizen distributor cert      | String | Distributor certificate used for signing. Base64-encoded.                   |
| `distributor-key`      | No       | Tizen distributor key       | String | Distributor key used for signing. Base64-encoded.                           |
| `distributor-password` | No       | Default for distributor key | String | Password for `distributor-key`                                              |
| `privilege`            | No       | `public`                    | String | `public` or `partner`&mdash;Which distributor cert/key is used if not provided. |

You can encode your certificates and keys in base64 via:

    openssl base64 -in {INPUT_FILE}

Then you can store them in GitHub Secrets to securely pass to the action.

### Outputs
| Name               | Description                       |
|--------------------|-----------------------------------|
| `package-artifact` | Absolute path to the package.     |

### Example usage

```yaml
- name: Build Tizen app
  id: tizen-build-action
  uses: sourcetoad/tizen-build-action@v1.0.0
  with:
    project-dir: ${{ github.workspace }}/TizenApp
    author-key: ${{ secrets.TIZEN_AUTHOR_KEY }}
    author-password: ${{ secrets.TIZEN_AUTHOR_KEY_PW }}

- name: Upload Tizen package artifact
  uses: actions/upload-artifact@v2
  with:
     name: app-${{ github.sha }}.wgt
     path: ${{ steps.tizen-build-action.outputs.package-artifact }}
```

#### Cache Tizen Studio installer file
It's recommended to cache the Tizen Studio installer
so it doesn't have to be downloaded over the internet on every run.
To do so, invoke the cache action **before** the build.
The important part is the `path`.
```yaml
- name: Cache Tizen Studio installer
  uses: actions/cache@v2
  with:
    path: ${{ github.workspace }}/tizen-studio_*.bin
    key: tizen-studio-installer
```

---

### Install as Local Action
For quicker troubleshooting cycles, the action can be copied directly into another project.
This way, changes to the action and its usage can happen simultaneously, in a single commit.

1. Copy this repository into your other project as `.github/actions/tizen-build-action`.
   Be careful: simply cloning in place will likely install it as a submodule&mdash;make sure to copy the files without `.git` unless you know what you're doing.
2. In your other project's workflow, in the action step, set\
   `uses: ./.github/actions/tizen-build-action`
