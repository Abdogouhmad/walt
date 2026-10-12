# Security Policy

## Supported versions

Walt ships from `main`; the latest GitHub release is the only supported
version. Older releases do not receive security fixes.

## Reporting a vulnerability

Please **do not** report security vulnerabilities through public GitHub
issues, discussions, or pull requests.

Instead, report them privately using GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
("Report a vulnerability" under the repository's Security tab), or email the
maintainer at **<!-- TODO: add a security contact email -->**.

Please include:

- A description of the vulnerability and its impact.
- Steps to reproduce, or a proof of concept.
- Affected version(s) and platform.
- Any suggested remediation.

We will acknowledge your report as soon as possible and keep you informed as we
investigate and prepare a fix. Please give us a reasonable amount of time to
address the issue before any public disclosure.

## Scope notes

Walt is an offline-first app: it has no backend and stores all data locally on
the device. The most relevant areas are release signing, the OTA update
download/verification path, and on-device data handling. Reports about the
release pipeline are in scope and appreciated.
