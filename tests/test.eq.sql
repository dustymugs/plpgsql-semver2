SELECT text_to_semver('1.2.3') = text_to_semver('1.2.3'); -- TRUE
SELECT text_to_semver('1.2.3-alpha') = text_to_semver('1.2.3-alpha'); -- TRUE
SELECT text_to_semver('1.2.3-alpha.beta') = text_to_semver('1.2.3-alpha.beta'); -- TRUE
SELECT text_to_semver('1.2.3-alpha.beta.1') = text_to_semver('1.2.3-alpha.beta.1'); -- TRUE
SELECT text_to_semver('1.2.3-alpha.beta.1+amd64') = text_to_semver('1.2.3-alpha.beta.1+amd64'); -- TRUE
SELECT text_to_semver('1.2.3+amd64') = text_to_semver('1.2.3+amd64'); -- TRUE
