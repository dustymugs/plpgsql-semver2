SELECT to_semver('1.2.3');
SELECT to_semver('1.2.3-alpha');
SELECT to_semver('1.2.3-alpha.beta');
SELECT to_semver('1.2.3-alpha.beta.1');
SELECT to_semver('1.2.3-alpha.beta.1+amd64');
SELECT to_semver('1.2.3+amd64');
