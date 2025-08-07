# Norad `.github` Repository

**Status:** Internal Configuration Repository

## Purpose

This repository (`.github`) holds configuration files and assets that apply across the **Norad** GitHub organization. It is used to manage settings, define templates, and control the appearance of our organization's profile page.

## Contents

* **`profile/`**: Contains the files for the public-facing organization profile.
    * `profile/README.md`: The main markdown file displayed on [github.com/noradno](https://github.com/noradno). **Note: This specific file is publicly visible.**
    * `profile/assets/`: Holds images (like the logo) used in the public profile README.
* **`PULL_REQUEST_TEMPLATE.md`**: An organization wide template for creation of pull requests.

## Usage

* Changes to `profile/README.md` directly update the public organization page.
* Adding templates here provides default options when creating issues/PRs in organization repositories (unless overridden locally in a repo).
* Keep assets used by the profile README organized within this repository (e.g., in `profile/assets/`).

---

*Even though this README is for internal informational purposes for Norad staff managing our GitHub presence, please remember that the contents of the `profile/` subdirectory are publicly visible.*
