\set table_num 12
\set num_rows 1000



DROP FUNCTION IF EXISTS create_tables;
CREATE FUNCTION create_tables(integer) RETURNS void AS $function_text$
BEGIN

DROP TABLE IF EXISTS table_1 CASCADE;
CREATE TABLE table_1 (
    id serial primary key
);


FOR i IN 2..$1 LOOP
    EXECUTE 'DROP TABLE IF EXISTS table_' || i || ' CASCADE;';

    EXECUTE format($$
        CREATE TABLE table_%1$s (
            id serial primary key,
            table_%2$s_id integer references table_%2$s (id)
	);
    $$, i, i-1);

END LOOP;
END;
$function_text$ LANGUAGE plpgsql;


SELECT create_tables(:table_num);


INSERT INTO table_1 (id)
SELECT
    nextval('table_1_id_seq')
FROM
    generate_series(1, :num_rows);



DROP FUNCTION IF EXISTS populate_tables;
CREATE FUNCTION populate_tables(integer, integer) RETURNS void AS $function_text$
BEGIN

INSERT INTO table_1 (id)
SELECT
    nextval('table_1_id_seq')
FROM
    generate_series(1, $2);


FOR i IN 2..$1 LOOP
    EXECUTE format($$
        INSERT INTO table_%1$s (table_%2$s_id)
        SELECT
            id
        FROM
            table_%2$s
        ORDER BY
            random();
    $$, i, i-1);
END LOOP;
END;
$function_text$ LANGUAGE plpgsql;


SELECT populate_tables(:table_num, :num_rows);
