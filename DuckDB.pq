// This file contains your Data Connector logic
[Version = "0.1.7"]
section DuckDB;

// When set to true, additional trace information will be written out to the User log.
// This should be set to false before release. Tracing is done through a call to
// Diagnostics.LogValue(). When EnableTraceOutput is set to false, the call becomes a
// no-op and simply returns the original value.
EnableTraceOutput = true;

// The name of the ODBC driver
Config_DriverName = "DuckDB Driver";

// Set to null to determine the value from the driver.
Config_SqlConformance = null;

// DuckDB only supports OFFSET when LIMIT is also specified,
// so we will use LimitClauseKind.Limit.
Config_LimitClauseKind = LimitClauseKind.Limit;

// DuckDB does not support standard username/password
// handling through the UID and PWD connection string parameters.
Config_DefaultUsernamePasswordHandling = false;

// If the driver supports parameter bindings, then set this to true.
Config_UseParameterBindings = null;

// Override this setting to force the character escape value.
Config_StringLiterateEscapeCharacters = null;

// Override this if the driver expects the use of CAST instead of CONVERT.
Config_UseCastInsteadOfConvert = null;

// Set this to true to enable Direct Query in addition to Import mode.
Config_EnableDirectQuery = true;

// Default custom user agent
DefaultCustomUserAgent = "powerbi/v0.0(DuckDB)";

[DataSource.Kind="DuckDB", Publish="DuckDB.Publish"]
shared DuckDB.Contents = (
    database as text,
    motherduck_token as text,
    optional read_only as logical,
    optional saas_mode as logical,
    optional attach_mode as text,
    optional options as record
) =>
    let
        Config_DriverName = Config_DriverName,
        // Read-only
        AccessMode = if (read_only = true)
        then
            "read_only"
        else if (read_only = false)
        then
            "read_write"
        else if (Record.HasFields(options, "access_mode") = true)
        then
            options[access_mode]
        else
            "automatic",
        // Custom user agent
        CustomUserAgent = if (Record.HasFields(options, "custom_user_agent") = true)
        then
            Text.Combine({DefaultCustomUserAgent, options[custom_user_agent]}, " ")
        else
            DefaultCustomUserAgent,
        Credential = Extension.CurrentCredential(),
        token = try Credential[Password] otherwise motherduck_token,
        // The ODBC connection string
        ConnectionString = options & [
            Driver = Config_DriverName,
            Database = GetFullPath(database, token, saas_mode, attach_mode),
            access_mode = AccessMode,
            custom_user_agent = CustomUserAgent
        ],
        //
        // Configuration options for the call to Odbc.DataSource
        //
        defaultConfig = Diagnostics.LogValue("BuildOdbcConfig", BuildOdbcConfig()),
        SqlCapabilities = Diagnostics.LogValue(
            "SqlCapabilities_Options", defaultConfig[SqlCapabilities] & [
                SupportsTop = false,
                SupportsDerivedTable = true,
                Sql92Conformance = 8 /* SQL_SC_SQL92_FULL */,
                GroupByCapabilities = 4 /* SQL_GB_NO_RELATION */,
                FractionalSecondsScale = 3,
                // Enable Native query
                Sql92Translation = "PassThrough"
            ]
        ),
        // Please refer to the ODBC specification for SQLGetInfo properties and values.
        // https://github.com/Microsoft/ODBC-Specification/blob/master/Windows/inc/sqlext.h
        SQLGetInfo = Diagnostics.LogValue(
            "SQLGetInfo_Options",
            defaultConfig[SQLGetInfo]
                & [
                    // Place custom overrides here
                    // The values below are required for the SQL Native Client ODBC driver, but might
                    // not be required for your data source.
                    SQL_SQL92_PREDICATES = ODBC[SQL_SP][All],
                    SQL_AGGREGATE_FUNCTIONS = ODBC[SQL_AF][All]
                ]
        ),
        // SQLGetTypeInfo can be specified in two ways:
        // 1. A #table() value that returns the same type information as an ODBC
        //    call to SQLGetTypeInfo.
        // 2. A function that accepts a table argument, and returns a table. The
        //    argument will contain the original results of the ODBC call to SQLGetTypeInfo.
        //    Your function implementation can modify/add to this table.
        //
        // For details of the format of the types table parameter and expected return value,
        // please see: https://docs.microsoft.com/en-us/sql/odbc/reference/syntax/sqlgettypeinfo-function
        //
        // The sample implementation provided here will simply output the original table
        // to the user trace log, without any modification.
        SQLGetTypeInfo = (types) =>
            if (EnableTraceOutput <> true) then
                types
            else
                let
                    // Outputting the entire table might be too large, and result in the value being truncated.
                    // We can output a row at a time instead with Table.TransformRows()
                    rows = Table.TransformRows(types, each Diagnostics.LogValue("SQLGetTypeInfo " & _[TYPE_NAME], _)),
                    toTable = Table.FromRecords(rows)
                in
                    Value.ReplaceType(toTable, Value.Type(types)),
        Options = [
                // A logical (true/false) that sets whether to view the tables grouped by their schema names
                HierarchicalNavigation = false,
                // Allows upconversion of numeric types
                SoftNumbers = true,
                // Allow upconversion / resizing of numeric and string types
                TolerateConcatOverflow = true,
                // Enables connection pooling via the system ODBC manager
                ClientConnectionPooling = false,
                // Other configuration options
                SqlCapabilities = SqlCapabilities,
                SQLGetInfo = SQLGetInfo,
                SQLGetTypeInfo = SQLGetTypeInfo
            ],
        // Create and return the ODBC data source
        OdbcDatasource = Odbc.DataSource(
            ConnectionString,
            Options
        )
    in
        OdbcDatasource;

// Data Source Kind description
DuckDB = [
    // Set the TestConnection handler to enable gateway support.
    // The TestConnection handler will invoke your data source function to
    // validate the credentials the user has provider. Ideally, this is not
    // an expensive operation to perform. By default, the dataSourcePath value
    // will be a json string containing the required parameters of your data
    // source function. These should be parsed and parsed as individual parameters
    // to the specified data source function.
    TestConnection = (dataSourcePath) =>
        let
            params = Json.Document(dataSourcePath),
            database = params[database],
            motherduck_token = params[motherduck_token],
            // optional parameters are not stored in dataSourcePath so we will set default values here
            read_only = true,
            saas_mode = false,
            attach_mode = "single",
            options = try params[options] otherwise [custom_user_agent="On-premises Data Gateway Test Connection"]
        in
            {"DuckDB.Contents", database, motherduck_token, read_only, saas_mode, attach_mode, options},
    // Set supported types of authentication
    Authentication = [
        Anonymous = [],
        UsernamePassword = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
DuckDB.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SupportsDirectQuery = Config_EnableDirectQuery,
    SourceImage = DuckDB.Icons,
    SourceTypeImage = DuckDB.Icons
];

DuckDB.Icons = [
    Icon16 = { Extension.Contents("duckdb-logo-16.png"), Extension.Contents("duckdb-logo-20.png"), Extension.Contents("duckdb-logo-24.png"), Extension.Contents("duckdb-logo-32.png") },
    Icon32 = { Extension.Contents("duckdb-logo-32.png"), Extension.Contents("duckdb-logo-40.png"), Extension.Contents("duckdb-logo-48.png"), Extension.Contents("duckdb-logo-64.png") }
];

// Get the full DuckDB path to pass to the ODBC driver
GetFullPath = (database as text, optional motherduck_token as text, optional saas_mode as logical, optional attach_mode as text) as text =>
    let
        attach_mode = if (attach_mode = null or attach_mode = "")
            then "single"
            else attach_mode,
        path = if IsMotherDuckDatabase(database) and saas_mode = true
            then database & "?motherduck_token=" & motherduck_token & "&saas_mode=true&attach_mode=" & attach_mode
            else if IsMotherDuckDatabase(database)
            then database & "?motherduck_token=" & motherduck_token & "&attach_mode=" & attach_mode
            else database
    in
        if IsMotherDuckDatabase(database) and (motherduck_token = null or motherduck_token = "")
        then
            error Error.Record("Expression.Error",
            "Cannot connect to MotherDuck database:
            Please enter your connection token.
            Go to http://app.motherduck.com/ and copy
            it from your User Settings.")
        else
            path;

// Check if the database is a MotherDuck database
IsMotherDuckDatabase = (database as text) as logical =>
    let
        result = Text.StartsWith(database, "md:")
    in
        result;

// build settings based on configuration variables
BuildOdbcConfig = () as record =>
    let
        Merge = (previous as record, optional caps as record, optional funcs as record, optional getInfo as record) as record =>
            let
                newCaps = if (caps <> null) then previous[SqlCapabilities] & caps else previous[SqlCapabilities],
                newFuncs = if (funcs <> null) then previous[SQLGetFunctions] & funcs else previous[SQLGetFunctions],
                newGetInfo = if (getInfo <> null) then previous[SQLGetInfo] & getInfo else previous[SQLGetInfo]
            in
                [SqlCapabilities = newCaps, SQLGetFunctions = newFuncs, SQLGetInfo = newGetInfo],
        defaultConfig = [
            SqlCapabilities = [],
            SQLGetFunctions = [],
            SQLGetInfo = []
        ],
        withParams =
            if (Config_UseParameterBindings = false) then
                let
                    caps = [
                        SupportsNumericLiterals = true,
                        SupportsStringLiterals = true,
                        SupportsOdbcDateLiterals = true,
                        SupportsOdbcTimeLiterals = true,
                        SupportsOdbcTimestampLiterals = true
                    ],
                    funcs = [
                        SQL_API_SQLBINDPARAMETER = false
                    ]
                in
                    Merge(defaultConfig, caps, funcs)
            else
                defaultConfig,
        withEscape =
            if (Config_StringLiterateEscapeCharacters <> null) then
                let
                    caps = [
                        StringLiteralEscapeCharacters = Config_StringLiterateEscapeCharacters
                    ]
                in
                    Merge(withParams, caps)
            else
                withParams,
        withLimitClauseKind = let caps = [
            LimitClauseKind = Config_LimitClauseKind
        ] in Merge(withEscape, caps),
        withCastOrConvert =
            if (Config_UseCastInsteadOfConvert <> null) then
                let
                    value =
                        if (Config_UseCastInsteadOfConvert = true) then
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CAST]
                        else
                            ODBC[SQL_FN_CVT][SQL_FN_CVT_CONVERT],
                    getInfo = [
                        SQL_CONVERT_FUNCTIONS = value
                    ]
                in
                    Merge(withLimitClauseKind, null, null, getInfo)
            else
                withLimitClauseKind,
        withSqlConformance =
            if (Config_SqlConformance <> null) then
                let
                    getInfo = [
                        SQL_SQL_CONFORMANCE = Config_SqlConformance
                    ]
                in
                    Merge(withCastOrConvert, null, null, getInfo)
            else
                withCastOrConvert
    in
        withSqlConformance;

ValidateOptions = (options as nullable record, validOptionsMap as table) as record =>
    let
        ValidKeys = Table.Column(validOptionsMap, "Name"),
        InvalidKeys = List.Difference(Record.FieldNames(options), ValidKeys),
        InvalidKeysText =
            if List.IsEmpty(InvalidKeys) then
                null
            else
                Text.Format(
                    "'#{0}' are not valid options. Valid options are: '#{1}'",
                    {Text.Combine(InvalidKeys, ", "), Text.Combine(ValidKeys, ", ")}
                ),
        ValidateValue = (name, optionType, description, default, validate, value) =>
            if
                (value is null and (Type.IsNullable(optionType) or default <> null))
                or (Type.Is(Value.Type(value), optionType) and validate(value))
            then
                null
            else
                Text.Format(
                    "This function does not support the option '#{0}' with value '#{1}'. Valid value is #{2}.",
                    {name, value, description}
                ),
        InvalidValues = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    ValidateValue(
                        [Name],
                        [Type],
                        [Description],
                        [Default],
                        [Validate],
                        Record.FieldOrDefault(options, [Name], [Default])
                    )
            )
        ),
        DefaultOptions = Record.FromTable(
            Table.RenameColumns(Table.SelectColumns(validOptionsMap, {"Name", "Default"}), {"Default", "Value"})
        ),
        NullNotAllowedFields = List.RemoveNulls(
            Table.TransformRows(
                validOptionsMap,
                each
                    if not Type.IsNullable([Type]) and null = Record.FieldOrDefault(options, [Name], [Default]) then
                        [Name]
                    else
                        null
            )
        ),
        NormalizedOptions = DefaultOptions & Record.RemoveFields(options, NullNotAllowedFields, MissingField.Ignore)
    in
        if null = options then
            DefaultOptions
        else if not List.IsEmpty(InvalidKeys) then
            error Error.Record("Expression.Error", InvalidKeysText)
        else if not List.IsEmpty(InvalidValues) then
            error Error.Record("Expression.Error", Text.Combine(InvalidValues, ", "))
        else
            NormalizedOptions;

//
// Load common library functions
//
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name), asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);

// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");

Diagnostics.LogValue = if (EnableTraceOutput) then Diagnostics[LogValue] else (prefix, value) => value;

// OdbcConstants contains numeric constants from the ODBC header files, and a
// helper function to create bitfield values.
ODBC = Extension.LoadFunction("OdbcConstants.pqm");
