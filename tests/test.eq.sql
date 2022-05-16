SELECT to_semver('1.2.3') = to_semver('1.2.3'); -- TRUE
SELECT to_semver('1.2.3-alpha') = to_semver('1.2.3-alpha'); -- TRUE
SELECT to_semver('1.2.3-alpha.beta') = to_semver('1.2.3-alpha.beta'); -- TRUE
SELECT to_semver('1.2.3-alpha.beta.1') = to_semver('1.2.3-alpha.beta.1'); -- TRUE
SELECT to_semver('1.2.3-alpha.beta.1+amd64') = to_semver('1.2.3-alpha.beta.1+amd64'); -- TRUE
SELECT to_semver('1.2.3+amd64') = to_semver('1.2.3+amd64'); -- TRUE
