// Regression test for the optional-token fix: a local DuckDB file must connect with
// no MotherDuck token. Passing null for the token errors on the pre-fix connector
// ("We cannot convert the value null to type Text", since motherduck_token was a
// required text argument) and succeeds once it's optional. The options record is
// passed as Power BI does, so this isolates the token change from anything else.
// The "Seed test database" step creates smoke = range(10) in test.db; __DB_PATH__ is
// replaced with its absolute path.
let
    src = DuckDB.Contents("__DB_PATH__", null, true, false, "single", [custom_user_agent="ci-no-token"]),
    data = src{[Item="smoke"]}[Data]
in
    data
