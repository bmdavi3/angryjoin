\i install_functions.sql

DROP TABLE IF EXISTS benchmark_results;
CREATE TABLE benchmark_results (
    tables integer NOT NULL,
    rows integer NOT NULL,
    max_id integer,
    duration interval NOT NULL
);

DROP TYPE IF EXISTS benchmark CASCADE;
CREATE TYPE benchmark AS (
    tables integer,
    rows integer,
    max_id integer,
    iterations integer
);

DROP FUNCTION IF EXISTS run_benchmarks;
CREATE FUNCTION run_benchmarks(benchmarks benchmark[]) RETURNS void AS $function_text$
DECLARE
    benchmark benchmark;
    begin_time timestamptz;
    query_text text;
BEGIN


FOREACH benchmark IN ARRAY benchmarks LOOP
    PERFORM create_tables(benchmark.tables, benchmark.rows);

    SELECT get_query(benchmark.tables, benchmark.max_id) INTO query_text;
    RAISE NOTICE '%', query_text;

    FOR i IN 1..benchmark.iterations LOOP
        begin_time := clock_timestamp();
        EXECUTE query_text;

        INSERT INTO benchmark_results (tables, rows, max_id, duration)
        SELECT
            benchmark.tables,
            benchmark.rows,
            benchmark.max_id,
            clock_timestamp() - begin_time;
    END LOOP;
END LOOP;
END;
$function_text$ LANGUAGE plpgsql;


select run_benchmarks(ARRAY[
    ROW(10, 100, Null, 10)::benchmark,
    ROW(10, 1000, Null, 10)::benchmark,
    ROW(10, 10000, Null, 10)::benchmark
]);


WITH results AS (
SELECT
    *,
    row_number() over (partition by tables, rows, max_id order by duration)
FROM
    benchmark_results
)
SELECT
    tables,
    rows,
    max_id,
    avg(duration)
FROM
    results
WHERE
    row_number > 1
GROUP BY
    tables,
    rows,
    max_id
ORDER BY
    tables,
    rows,
    max_id