# DuckDB Power Query Connector by MotherDuck

This is the Power Query Custom Connector for DuckDB. Use this to connect to a DuckDB database in memory, from a local file or on MotherDuck with Power BI and Excel.

1. [Installing](#installing)
2. [How to use with Power BI](#how-to-use-with-power-bi)
3. [Turning on UTF-8 support in the Language & Region settings](#turning-on-utf-8-support-in-the-language--region-settings)
4. [[Experimental] Power BI Service](#experimental-power-bi-service)

## Installing

1. Download the latest DuckDB ODBC driver from the [DuckDB Power Query Connector GitHub Releases](https://github.com/MotherDuck-Open-Source/duckdb-power-query-connector/releases) for Windows:
      - [duckdb_odbc-windows-amd64.zip](https://github.com/MotherDuck-Open-Source/duckdb-power-query-connector/releases/latest/download/duckdb_odbc-windows-amd64.zip)
1. Extract the `.zip` archive into a permanent location, such as `C:\Program Files\duckdb_odbc`, and install the latest DuckDB driver by running `odbc_install.exe`.
1. Check that the correct version was installed. To do this, open the Registry Editor by running `regedit` in the command prompt or `Run` dialog. Browse to the `HKEY_LOCAL_MACHINE\SOFTWARE\ODBC\ODBCINST.INI\DuckDB Driver` entry and check that the Driver field contains the version you installed. If not, delete the `DuckDB Driver` registry key and rerun the installer.

1. Open Power BI, go to File -> Options and settings -> Options -> Security -> Data Extensions. Enable "Allow any extensions to load without validation or warning".
![Dialog window showing Power BI Options -> Security -> Data Extensions](images/power_bi_options.png)

1. Download the latest version of the DuckDB Power Query extension:
      - [duckdb-power-query-connector.mez](https://github.com/MotherDuck-Open-Source/duckdb-power-query-connector/releases/latest/download/duckdb-power-query-connector.mez)

1. Create this folder if it does not yet exist: `[Documents]\Power BI Desktop\Custom Connectors`.

1. Move or copy the `duckdb-power-query-connector.mez` file into `[Documents]\Power BI Desktop\Custom Connectors`. Note that if this location does not work, you may need to place this in your OneDrive Documents folder.


## How to use with Power BI

1. Click on Get Data -> More...
1. Search for `DuckDB` and click "Connect"
![Find DuckDB connector](images/find-connector.png)
1. Enter your database location. This can be a local file path (e.g. `~\my_database.db`) or a MotherDuck database location (e.g. `md:my_database`). (Optional) enter your [MotherDuck token](https://app.motherduck.com/token-request?appName=PowerBI). If you want to access the database in `read_only` mode, you can set it to `true`.
![Connect to your DuckDB database](images/connect-duckdb.png)

> From version 0.1.7, the `motherduck_token` is a required parameter, in order to enable usage with Power BI Service. If you are using DuckDB, you can enter any value (e.g. `ducks`) into the MotherDuck token field.

Click "OK".
1. Click "Connect".
![Connect dialog](images/connect.png)
1. Select the table(s) you want to import. Click "Load".
![Navigator dialog to preview and select your table(s)](images/navigator.png)
1. You can now query your data and create visualizations!
![Power BI example usage](images/power-bi-example.png)


## Turning on UTF-8 support in the Language & Region settings

UTF-8 is currently not supported in the DuckDB ODBC driver. As a workaround, you can turn on UTF-8 decoding in Windows. Note that this may change behavior for other applications, so please use with caution.

1. Open start menu and type "Language settings". Open the "Language & region" settings
2. Click on "Administrative language settings"
3. Click on "Change system locale"
4. Check the "Beta: Use Unicode UTF-8 for worldwide language support" and click OK

![Screenshot 2024-05-03 165950](https://github.com/MotherDuck-Open-Source/duckdb-power-query-connector/assets/4041805/3251d212-0cde-44be-b3a5-68a0d3d434cf)

5. This prompts Windows to restart.
6. Next, open Power BI, click on "Options and settings" -> "Options" -> "Data Load" and click the "Clear cache" button.

Now, you should be able to load your UTF-8 encoded database with Power BI directly:

<img width="653" alt="image" src="https://github.com/MotherDuck-Open-Source/duckdb-power-query-connector/assets/4041805/bc83d199-317b-4142-a180-579a9b9d8a05">

## [Experimental] Power BI Service

To use the [Power BI Service](https://app.powerbi.com/) with DuckDB, you can use the [On-Premises Data Gateway](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-onprem) application. Note that data will only be available when the gateway is on and connected to the internet. This will enable features like automated refresh, and let you share your PowerBI dashboards online.

1. Follow these instructions to install the on-premises data gateway: [Download and install a standard gateway](https://learn.microsoft.com/en-us/data-integration/gateway/service-gateway-install#download-and-install-a-standard-gateway).
2. Open Services, and find the On-premises data gateway service. Double click to open the Properties dialog.

<img width="500" src="https://github.com/user-attachments/assets/64bfbefe-933d-413d-80d3-dd4c4e95775a">

Go to the "Log On" tab and click "Local System Account" and check "Allow service to interact with Desktop".

<img width="500" src="https://github.com/user-attachments/assets/73e7bd49-c3ff-4f7d-9ebc-36052d55b49f">

3. Click on "Restart" to restart the service. Open the "Connectors" tab and wait until "DuckDB" shows up in Custom Connectors. If it does not, please follow the Custom Connector installation instructions above.

<img width="500" src="https://github.com/user-attachments/assets/72bd701b-0ace-4dbb-a63b-ddbb848e50af">

4. Go to [Power BI Service](https://app.powerbi.com/) and click on the "Settings" icon in the top right. Navigate to the "Manage connections and gateways" page.

<img width="300" src="https://github.com/user-attachments/assets/e366b74c-30b3-43e3-bdcb-eb8fdc459bf8">

5. Click on the dots menu next to the gateway you configured in step 1. and click on "Settings"

<img width="500" src="https://github.com/user-attachments/assets/b591c89e-e4bc-480f-9f5f-3f20958ea3e9">

6. Click the "Allow user's cloud data sources to refresh through this gateway cluster" and "Allow user's custom data connectors to refresh through this gateway cluster."

<img width="300" src="https://github.com/user-attachments/assets/3c8ef4e3-afdd-41de-ad2d-bdd169ae04c2">

7. On the "Manage connections and gateways" page, click on the "Connections" tab and click "+ New"

<img width="500" src="https://github.com/user-attachments/assets/66061365-9969-4600-a5dd-96435bad37f8">

8. Enter your connection details. You can enter any local file name here, or use MotherDuck. If you do, make sure to enter a valid [MotherDuck token](https://app.motherduck.com/token-request?appName=powerbi).

      > From version 0.1.7, the `motherduck_token` is a required parameter, in order to enable usage with Power BI Service. If you are using DuckDB, you can enter any value (e.g. `ducks`) into the MotherDuck token field.

      > If you are using MotherDuck, make sure that the MotherDuck extension is installed under `C:\WINDOWS\system32\config\systemprofile\.duckdb\extensions\`. To do so, you can download the [DuckDB CLI client for Windows](https://duckdb.org/docs/installation/?version=stable&environment=cli&platform=win&download_method=direct&architecture=x86_64), and run `INSTALL motherduck`. Then, you can copy over the extension files via PowerShell:
      ```
      cp -R '~\.duckdb\extensions\v1.2.0\' "C:\WINDOWS\system32\config\systemprofile\.duckdb\extensions\"
      ```

      > Optionally, you can override the `motherduck_token` field by setting a Username and Password using Basic Authentication. This is useful if you need to replace the token, but don't want to recreate the connection. You can set the Username to any value and the Password to the token value.

Enable the "Skip test connection" check box.

<img width="300" src="https://github.com/user-attachments/assets/68f8afc0-d8f3-4e88-b3d6-73ef0acbfc4d">

Click "Create".

<img width="300" src="https://github.com/user-attachments/assets/065f8fba-7d36-4ebe-9e80-8fafee38aa81">

9. Now you can create a Power BI report and publish it to Power BI Service.
On your report, click "Publish".

<img width="400" src="https://github.com/user-attachments/assets/52757a6a-1564-4a1a-9187-4ecc6a8550a3">

10. Done! Now you can click on the URL in the Publishing to Power BI dialog to access the online report.

<img width="400" src="https://github.com/user-attachments/assets/fd43f6d5-9747-4fe3-87e7-59798b89d615">
