SELECT text_to_semver('1.2.3');
SELECT text_to_semver('1.2.3-alpha');
SELECT text_to_semver('1.2.3-alpha.beta');
SELECT text_to_semver('1.2.3-alpha.beta.1');
SELECT text_to_semver('1.2.3-alpha.beta.1+amd64');
SELECT text_to_semver('1.2.3+amd64');
