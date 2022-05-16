SELECT to_semver('1.2.3') < to_semver('1.2.2'); -- FALSE
SELECT to_semver('1.2.3') < to_semver('1.2.3'); -- FALSE
SELECT to_semver('1.2.3') < to_semver('1.2.4'); -- TRUE
SELECT to_semver('1.2.3') < to_semver('1.2.3-beta'); -- FALSE
SELECT to_semver('1.0.0-alpha') < to_semver('1.0.0-alpha.1'); -- TRUE
SELECT to_semver('1.0.0-alpha.1') < to_semver('1.0.0-alpha.beta'); -- TRUE
SELECT to_semver('1.0.0-alpha.beta') < to_semver('1.0.0-beta'); -- TRUE
SELECT to_semver('1.0.0-beta') < to_semver('1.0.0-beta.2'); -- TRUE
SELECT to_semver('1.0.0-beta.2') < to_semver('1.0.0-beta.11'); -- TRUE
SELECT to_semver('1.0.0-beta.11') < to_semver('1.0.0-rc.1'); -- TRUE
SELECT to_semver('1.0.0-rc.1') < to_semver('1.0.0'); -- TRUE
SELECT to_semver('1.0.0') < to_semver('1.0.1'); -- TRUE
SELECT to_semver('1.0.0-alpha.1.b.2') < to_semver('1.0.0-alpha.1.b.2'); -- FALSE
SELECT to_semver('1.0.0-alpha.1.b.2') < to_semver('1.0.0-alpha.1.b.3'); -- TRUE
SELECT to_semver('1.0.0-alpha.1.b') < to_semver('1.0.0-alpha.1.b.3'); -- TRUE
