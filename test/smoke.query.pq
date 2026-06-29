// CI smoke test: prove the built .mez can open a connection and read a table.
// DuckDB.Contents returns an ODBC navigation table, so we select a table by name
// (Value.NativeQuery isn't supported on it). The "Seed test database" CI step creates
// table `smoke` = range(10) (rows 0..9) in test.db, and the smoke step replaces
// __DB_PATH__ with its absolute path (PQTest runs from its own working dir, so a
// relative path won't resolve).
let
    src = DuckDB.Contents("__DB_PATH__", "", true, false, "single", [custom_user_agent="ci-smoke"]),
    data = src{[Item="smoke"]}[Data]
in
    data
