# Norad `.github` Repository

**Status:** Internal Configuration Repository

## Purpose

This repository (`.github`) holds configuration files and assets that apply across the **Norad** GitHub organization. It is used to manage settings, define templates, provide reusable workflows, and control the appearance of our organization's profile page.

## Contents

* **`profile/`**: Contains the files for the public-facing organization profile.
    * `profile/README.md`: The main markdown file displayed on [github.com/noradno](https://github.com/noradno). **Note: This specific file is publicly visible.**
    * `profile/assets/`: Holds images (like the logo) used in the public profile README.
* **`PULL_REQUEST_TEMPLATE.md`**: An organization wide template for creation of pull requests.
* **`.github/workflows/`**: Contains reusable workflows for CI/CD pipelines.
    * `build-and-test-reusable.yml`: Builds and tests .NET projects.
    * `sonarqube-scan-reusable.yml`: Performs a SonarQube static code analysis.
    * `semantic-release-reusable.yaml`: Automates versioning and releases.

## Usage

* Changes to `profile/README.md` directly update the public organization page.
* Adding templates here provides default options when creating issues/PRs in organization repositories (unless overridden locally in a repo).
* Keep assets used by the profile README organized within this repository (e.g., in `profile/assets/`).

---

*Even though this README is for internal informational purposes for Norad staff managing our GitHub presence, please remember that the contents of the `profile/` subdirectory are publicly visible.*

## Reusable GitHub Actions Workflows

This repository also contains reusable workflows that can be called by other repositories within the Norad organization to standardize CI/CD processes.

### Build and Test .NET Project

**File:** `.github/workflows/build-and-test-reusable.yml`

This workflow builds, tests, and collects code coverage for a .NET project. It can optionally authenticate to the private GitHub Packages NuGet registry.

#### Inputs

| Name | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| `working-directory` | `string` | The directory where the `dotnet` commands will be run. | `.` |
| `dotnet-version` | `string` | The .NET SDK version to use for the build. | `9.0.303` |
| `authenticate-to-nuget` | `boolean` | Set to `true` to authenticate to the private GitHub NuGet registry. | `true` |

#### Secrets

| Name | Required | Description |
| :--- | :--- | :--- |
| `TOKEN` | `true` | A GitHub token (e.g., `secrets.GITHUB_TOKEN`) for authenticating to the private NuGet registry. |

#### Example Usage

```yaml
# .github/workflows/ci.yml in the calling repository
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    uses: noradno/.github/.github/workflows/build-and-test-reusable.yml@main
    with:
      dotnet-version: '8.0.x'
    secrets:
      TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

### SonarQube Scan

**File:** `.github/workflows/sonarqube-scan-reusable.yml`

This workflow performs a static code analysis using SonarQube. It requires a `sonar-project.properties` file to be present in the root of the calling repository.

#### Inputs

| Name | Type | Description | Default |
| :--- | :--- | :--- | :--- |
| `working-directory` | `string` | The directory where the SonarQube scan will be run. | `.` |

#### Secrets

| Name | Required | Description |
| :--- | :--- | :--- |
| `SONAR_TOKEN` | `true` | An authentication token for the SonarQube server. |

#### Example Usage

```yaml
# .github/workflows/ci.yml in the calling repository
name: CI Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build-and-test:
    # ... build job definition ...

  sonarqube:
    needs: build-and-test
    uses: noradno/.github/.github/workflows/sonarqube-scan-reusable.yml@main
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

### Semantic Release

**File:** `.github/workflows/semantic-release-reusable.yaml`

This workflow automates version management and package publishing using Semantic Release. It generates a GitHub App token for authentication, which allows it to create releases, tags, and comments on pull requests.

#### Prerequisites

For this workflow to function correctly, the calling repository **must** contain two configuration files in its root directory:
1.  `.releaserc.yaml`: The main configuration for releases on the `main` branch.
2.  `.releaserc.prerelease.yaml`: The configuration for prereleases on feature, bugfix, or hotfix branches.

#### Inputs

| Name | Type | Description |
| :--- | :--- | :--- |
| `CSPROJ_PATH` | `string` | **Required.** The relative path to the `.csproj` file whose version will be updated. |
| `ref` | `string` | **Required.** The Git ref (branch or tag) that triggered the workflow. This should be passed from the calling workflow. |

#### Secrets

| Name | Required | Description |
| :--- | :--- | :--- |
| `APP_ID` | `true` | The ID of the GitHub App used for authentication. |
| `APP_PRIVATE_KEY` | `true` | The private key of the GitHub App. |

#### Example Usage

```yaml
# .github/workflows/release.yml in the calling repository
name: Release

on:
  push:
    branches:
      - main
      - feature/*

jobs:
  call-reusable-workflow:
    uses: noradno/.github/.github/workflows/semantic-release-reusable.yaml@main
    secrets:
      APP_ID: ${{ secrets.APP_ID }}
      APP_PRIVATE_KEY: ${{ secrets.APP_PRIVATE_KEY }}
    with:
      CSPROJ_PATH: ${{ vars.CSPROJ_PATH }}
      ref: ${{ github.ref }}
```
