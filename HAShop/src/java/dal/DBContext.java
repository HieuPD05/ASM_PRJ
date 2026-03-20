package dal;

import java.sql.Connection;
import java.sql.DriverManager;

public class DBContext {

    private static final String DB_URL =
        "jdbc:sqlserver://localhost:1433;databaseName=HAShopDB;encrypt=true;trustServerCertificate=true";
    private static final String DB_USER = "sa";
    private static final String DB_PASS = "123";

    public Connection getConnection() throws Exception {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }
}
