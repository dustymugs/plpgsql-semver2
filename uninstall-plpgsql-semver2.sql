DROP OPERATOR CLASS IF EXISTS hash_semver_ops USING hash;
DROP OPERATOR CLASS IF EXISTS btree_semver_ops USING btree;

DROP OPERATOR IF EXISTS = (semver, semver);
DROP OPERATOR IF EXISTS <> (semver, semver);
DROP OPERATOR IF EXISTS < (semver, semver);
DROP OPERATOR IF EXISTS <= (semver, semver);
DROP OPERATOR IF EXISTS > (semver, semver);
DROP OPERATOR IF EXISTS >= (semver, semver);

DROP FUNCTION IF EXISTS semver_eq(semver, semver);
DROP FUNCTION IF EXISTS semver_ne(semver, semver);
DROP FUNCTION IF EXISTS semver_lt(semver, semver);
DROP FUNCTION IF EXISTS semver_le(semver, semver);
DROP FUNCTION IF EXISTS semver_gt(semver, semver);
DROP FUNCTION IF EXISTS semver_ge(semver, semver);
DROP FUNCTION IF EXISTS semver_cmp(semver, semver);
DROP FUNCTION IF EXISTS text_to_semver(text);
DROP FUNCTION IF EXISTS semver_to_text(semver);
DROP FUNCTION IF EXISTS hash_semver(semver);

DROP TYPE IF EXISTS semver;

DROP FUNCTION IF EXISTS to_int(text);
