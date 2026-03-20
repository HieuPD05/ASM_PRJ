package dal;

import java.sql.*;
import model.User;

public class UserDAO extends DBContext {

    public boolean emailExists(String email) throws Exception {
        String sql = "SELECT 1 FROM dbo.[users] WHERE email = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public void register(String fullName, String email, String phone, String passwordHash, int roleId) throws Exception {
        String sql =
            "INSERT INTO dbo.[users] (role_id, full_name, email, phone, password_hash, status, created_at) " +
            "VALUES (?, ?, ?, ?, ?, 1, GETDATE())";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, roleId);
            ps.setString(2, fullName);
            ps.setString(3, email);

            if (phone == null || phone.trim().isEmpty()) {
                ps.setNull(4, Types.VARCHAR);
            } else {
                ps.setString(4, phone.trim());
            }

            ps.setString(5, passwordHash);
            ps.executeUpdate();
        }
    }

    public User findByEmailAndPass(String email, String passwordHash) throws Exception {
        String sql =
            "SELECT user_id, role_id, full_name, email, phone " +
            "FROM dbo.[users] " +
            "WHERE email = ? AND password_hash = ? AND status = 1";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, email);
            ps.setString(2, passwordHash);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;

                User u = new User();
                u.setId(rs.getInt("user_id"));
                u.setRoleId(rs.getInt("role_id"));
                u.setFullName(rs.getString("full_name"));
                u.setEmail(rs.getString("email"));
                u.setPhone(rs.getString("phone"));

                u.setRole(rs.getInt("role_id") == 2 ? "ADMIN" : "USER");
                return u;
            }
        }
    }
}
