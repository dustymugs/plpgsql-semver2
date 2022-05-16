DROP OPERATOR IF EXISTS < (semver, semver);
DROP OPERATOR IF EXISTS <= (semver, semver);
DROP OPERATOR IF EXISTS > (semver, semver);
DROP OPERATOR IF EXISTS >= (semver, semver);

DROP FUNCTION IF EXISTS to_int(text);

DROP FUNCTION IF EXISTS semver_lt(semver, semver);
DROP FUNCTION IF EXISTS semver_le(semver, semver);
DROP FUNCTION IF EXISTS semver_gt(semver, semver);
DROP FUNCTION IF EXISTS semver_ge(semver, semver);
DROP FUNCTION IF EXISTS to_semver(text);
DROP TYPE IF EXISTS semver;

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
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION to_semver(version text)
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
LANGUAGE plpgsql;

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
	ELSIF semver1.minor < semver2.minor THEN
		RETURN TRUE;
	ELSIF semver1.patch < semver2.patch THEN
		RETURN TRUE;
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
		RAISE NOTICE '% %', text1, text2;
		RAISE NOTICE '% %', num1, num2;

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
LANGUAGE plpgsql;

CREATE OPERATOR < (
	FUNCTION = semver_lt,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = >,
	NEGATOR = >=
);

CREATE OR REPLACE FUNCTION semver_le(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
DECLARE
BEGIN
	RETURN semver1 = semver2 OR semver1 < semver2;
END;
$$
LANGUAGE plpgsql;

CREATE OPERATOR <= (
	FUNCTION = semver_le,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = >=,
	NEGATOR = >
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
	ELSIF semver1.minor > semver2.minor THEN
		RETURN TRUE;
	ELSIF semver1.patch > semver2.patch THEN
		RETURN TRUE;
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
LANGUAGE plpgsql;

CREATE OPERATOR > (
	FUNCTION = semver_gt,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = <,
	NEGATOR = <=
);

CREATE OR REPLACE FUNCTION semver_ge(semver1 semver, semver2 semver)
RETURNS boolean
AS $$
DECLARE
BEGIN
	RETURN semver1 = semver2 OR semver1 > semver2;
END;
$$
LANGUAGE plpgsql;

CREATE OPERATOR >= (
	FUNCTION = semver_ge,
	LEFTARG = semver,
	RIGHTARG = semver,
	COMMUTATOR = <=,
	NEGATOR = <
);
