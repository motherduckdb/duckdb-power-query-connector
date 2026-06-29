// CI smoke test: prove the built .mez can open a connection and read a table.
// DuckDB.Contents returns an ODBC navigation table, so we select a table by name
// (Value.NativeQuery isn't supported on it). The "Seed test database" CI step creates
// table `smoke` = range(10) (rows 0..9) in test.db next to where PQTest runs.
let
    src = DuckDB.Contents("test.db", "", true, false, "single", [custom_user_agent="ci-smoke"]),
    data = src{[Item="smoke"]}[Data]
in
    data
