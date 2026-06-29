let
    src = DuckDB.Contents(":memory:", "", false, false, "single", [custom_user_agent="ci-smoke"]),
    result = Value.NativeQuery(src, "SELECT count(*) AS n FROM range(10)")
in
    result
