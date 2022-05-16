CREATE TYPE semver AS (
	major int,
	minor int,
	patch int,
	prerelease text,
	identifiers text[],
	build text
);

CREATE OR REPLACE FUNCTION to_int(v text)
RETURNS int
AS $$
BEGIN
	RETURN v::int;
EXCEPTION
	WHEN invalid_text_representation THEN
		RETURN NULL::int;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION text_to_semver(version text)
RETURNS semver
AS $$
DECLARE
	parts text[];
	major int;
	minor int;
	patch int;
	prerelease text;
	prerelease_parts text[];
	identifiers text[] DEFAULT '{}';
	build text;
	intval int;
BEGIN
	-- posix regex from: https://github.com/T5CC/semver-regex#posix-compliant
	SELECT regexp_matches(
		version,
		'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-((0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*)){0,1}(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*)){0,1}$',
		'gm'
	) INTO parts;
	IF parts[1] IS NULL THEN
		RAISE EXCEPTION 'Invalid SemVer 2.0.0: %', version;
	END IF;
	major := parts[1]::int;
	minor := parts[2]::int;
	patch := parts[3]::int;
	prerelease := parts[5];
	build := parts[10];

	SELECT string_to_array(prerelease, '.') INTO prerelease_parts;
	IF array_length(prerelease_parts, 1) > 0 THEN
		FOR i IN 1..ARRAY_UPPER(prerelease_parts, 1) LOOP
			identifiers := identifiers || prerelease_parts[i];
		END LOOP;
	END IF;
	
	RETURN ROW(major, minor, patch, prerelease, identifiers, build);
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION semver_to_text(semver1 semver)
RETURNS text
AS $$
DECLARE
	version text;
BEGIN
	version := FORMAT('%s.%s.%s', semver1.major, semver1.minor, semver1.patch);
	IF version IS NULL THEN
		RETURN NULL;
	END IF;

	IF semver1.prerelease IS NOT NULL THEN
		version := FORMAT('%s-%s', version, semver1.prerelease);
	END IF;
	IF semver1.build IS NOT NULL THEN
		version := FORMAT('%s+%s', version, semver1.build);
	END IF;

	RETURN version;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OR REPLACE FUNCTION semver_eq(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
BEGIN
	RETURN (
		COALESCE(semver1.major, 0) = COALESCE(semver2.major, 0) and
		COALESCE(semver1.minor, 0) = COALESCE(semver2.minor, 0) and
		COALESCE(semver1.patch, 0) = COALESCE(semver2.patch, 0) and
		semver1.identifiers = semver2.identifiers and
		COALESCE(semver1.build, '') = COALESCE(semver2.build, '')
	);
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR = (
	FUNCTION = semver_eq,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = =,
	NEGATOR = <>,
 	RESTRICT = eqsel,
 	JOIN = eqjoinsel
);

CREATE OR REPLACE FUNCTION semver_ne(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
BEGIN
	RETURN (
		COALESCE(semver1.major, 0) <> COALESCE(semver2.major, 0) or
		COALESCE(semver1.minor, 0) <> COALESCE(semver2.minor, 0) or
		COALESCE(semver1.patch, 0) <> COALESCE(semver2.patch, 0) or
		semver1.identifiers <> semver2.identifiers or
		COALESCE(semver1.build, '') <> COALESCE(semver2.build, '')
	);
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR <> (
	FUNCTION = semver_ne,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = <>,
	NEGATOR = =,
 	RESTRICT = neqsel,
 	JOIN = neqjoinsel
);

CREATE OR REPLACE FUNCTION semver_lt(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
DECLARE
	len1 int;
	len2 int;
	shorter int;
	text1 text;
	text2 text;
	num1 int;
	num2 int;
BEGIN
	IF semver1.major < semver2.major THEN
		RETURN TRUE;
	ELSIF semver1.major > semver2.major THEN
		RETURN FALSE;
	ELSIF semver1.minor < semver2.minor THEN
		RETURN TRUE;
	ELSIF semver1.minor > semver2.minor THEN
		RETURN FALSE;
	ELSIF semver1.patch < semver2.patch THEN
		RETURN TRUE;
	ELSIF semver1.patch > semver2.patch THEN
		RETURN FALSE;
	ELSIF semver1.prerelease IS NULL AND semver2.prerelease IS NULL THEN
		RETURN FALSE;
	ELSIF semver1.prerelease IS NOT NULL AND semver2.prerelease IS NULL THEN
		RETURN TRUE;
	ELSIF semver1.prerelease IS NULL AND semver2.prerelease IS NOT NULL THEN
		RETURN FALSE;
	END IF;

	len1 := array_length(semver1.identifiers, 1);
	len2 := array_length(semver2.identifiers, 1);
	IF len1 > len2 THEN
		shorter := len2;
	ELSE
		shorter := len1;
	END IF;

	FOR i IN 1..shorter LOOP
		text1 := semver1.identifiers[i];
		text2 := semver2.identifiers[i];
		num1 := to_int(text1);
		num2 := to_int(text2);

		IF num1 IS NOT NULL AND num2 IS NOT NULL THEN
			IF num1 = num2 THEN
				CONTINUE;
			END IF;
			RETURN num1 < num2;
		ELSIF num1 IS NOT NULL AND num2 IS NULL THEN
			RETURN TRUE;
		ELSIF num1 IS NULL AND num2 IS NOT NULL THEN
			RETURN FALSE;
		ELSIF text1 = text2 THEN
			CONTINUE;
		ELSE
			RETURN text1 < text2;
		END IF;		
	END LOOP;

	IF len1 < len2 THEN
		RETURN TRUE;
	END IF;

	RETURN FALSE;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR < (
	FUNCTION = semver_lt,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = >,
	NEGATOR = >=,
 	RESTRICT = scalarltsel,
 	JOIN = scalarltjoinsel
);

CREATE OR REPLACE FUNCTION semver_le(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
BEGIN
	RETURN semver1 = semver2 OR semver1 < semver2;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR <= (
	FUNCTION = semver_le,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = >=,
	NEGATOR = >,
 	RESTRICT = scalarlesel,
 	JOIN = scalarlejoinsel
);

CREATE OR REPLACE FUNCTION semver_gt(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
DECLARE
	len1 int;
	len2 int;
	shorter int;
	text1 text;
	text2 text;
	num1 int;
	num2 int;
BEGIN
	IF semver1.major > semver2.major THEN
		RETURN TRUE;
	ELSIF semver1.major < semver2.major THEN
		RETURN FALSE;
	ELSIF semver1.minor > semver2.minor THEN
		RETURN TRUE;
	ELSIF semver1.minor < semver2.minor THEN
		RETURN FALSE;
	ELSIF semver1.patch > semver2.patch THEN
		RETURN TRUE;
	ELSIF semver1.patch < semver2.patch THEN
		RETURN FALSE;
	ELSIF semver1.prerelease IS NULL AND semver2.prerelease IS NULL THEN
		RETURN FALSE;
	ELSIF semver1.prerelease IS NOT NULL AND semver2.prerelease IS NULL THEN
		RETURN FALSE;
	ELSIF semver1.prerelease IS NULL AND semver2.prerelease IS NOT NULL THEN
		RETURN TRUE;
	END IF;

	len1 := array_length(semver1.identifiers, 1);
	len2 := array_length(semver2.identifiers, 1);
	IF len1 > len2 THEN
		shorter := len2;
	ELSE
		shorter := len1;
	END IF;

	FOR i IN 1..shorter LOOP
		text1 := semver1.identifiers[i];
		text2 := semver2.identifiers[i];
		num1 := to_int(text1);
		num2 := to_int(text2);

		IF num1 IS NOT NULL AND num2 IS NOT NULL THEN
			IF num1 = num2 THEN
				CONTINUE;
			END IF;
			RETURN num1 > num2;
		ELSIF num1 IS NOT NULL AND num2 IS NULL THEN
			RETURN FALSE;
		ELSIF num1 IS NULL AND num2 IS NOT NULL THEN
			RETURN TRUE;
		ELSIF text1 = text2 THEN
			CONTINUE;
		ELSE
			RETURN text1 > text2;
		END IF;
	END LOOP;

	IF len1 > len2 THEN
		RETURN TRUE;
	END IF;

	RETURN FALSE;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR > (
	FUNCTION = semver_gt,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = <,
	NEGATOR = <=,
 	RESTRICT = scalargtsel,
 	JOIN = scalargtjoinsel
);

CREATE OR REPLACE FUNCTION semver_ge(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
DECLARE
BEGIN
	RETURN semver1 = semver2 OR semver1 > semver2;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR >= (
	FUNCTION = semver_ge,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = <=,
	NEGATOR = <,
 	RESTRICT = scalargesel,
 	JOIN = scalargejoinsel
);

CREATE OR REPLACE FUNCTION semver_cmp(semver1 semver, semver2 semver)
RETURNS int
AS $$
BEGIN
	IF semver1 = semver2 THEN
		RETURN 0;
	ELSIF semver1 < semver2 THEN
		RETURN -1;
	ELSE
		RETURN 1;
	END IF;
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS btree_semver_ops
DEFAULT FOR TYPE semver USING btree
AS
	OPERATOR    1    <  ,
	OPERATOR    2    <= ,
	OPERATOR    3    =  ,
	OPERATOR    4    >= ,
	OPERATOR    5    >  ,
	FUNCTION    1    semver_cmp(semver, semver);

CREATE OR REPLACE FUNCTION hash_semver(semver1 semver)
RETURNS int
AS $$
BEGIN
	RETURN hashtext(semver_to_text(semver1));
END;
$$
LANGUAGE plpgsql
IMMUTABLE STRICT PARALLEL SAFE;

CREATE OPERATOR CLASS hash_semver_ops
	DEFAULT FOR TYPE semver USING hash AS
		OPERATOR    1    = ,
		FUNCTION    1    hash_semver(semver);

CREATE CAST (text as semver)
	WITH FUNCTION text_to_semver(text)
	AS IMPLICIT;

CREATE CAST (semver as text)
	WITH FUNCTION semver_to_text(semver)
	AS ASSIGNMENT;
