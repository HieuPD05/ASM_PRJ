package dal;

import java.sql.*;
import java.util.*;
import java.util.List;
import java.util.Map;

public class OrderDAO extends DBContext {

    // return order_id vừa tạo
    public int createOrder(
            int userId,
            String receiverName,
            String receiverPhone,
            String receiverAddr,
            String email,
            String note,
            String paymentMethod,
            List<Map<String, Object>> cartItems
    ) throws Exception {

        if (cartItems == null || cartItems.isEmpty()) {
            throw new Exception("Cart is empty");
        }

        Connection con = null;
        try {
            con = getConnection();
            con.setAutoCommit(false);

            // 1) Parse size của từng item một lần (dùng lại ở bước kiểm kho và insert)
            List<Integer> parsedSizes = new ArrayList<>();
            for (Map<String, Object> it : cartItems) {
                int size = 0;
                try {
                    String sizeStr = (String) it.get("size");
                    if (sizeStr != null) size = (int) Math.round(Double.parseDouble(sizeStr));
                } catch (Exception ex) { size = 0; }
                parsedSizes.add(size);
            }

            // 2) Kiểm tra tồn kho trước (UPDLOCK tránh race condition)
            String sqlStock =
                "SELECT quantity FROM dbo.product_sizes WITH (UPDLOCK) " +
                "WHERE product_id = ? AND size = ?";
            for (int i = 0; i < cartItems.size(); i++) {
                Map<String, Object> it = cartItems.get(i);
                int productId = (Integer) it.get("id");
                int qty       = (Integer) it.get("qty");
                int size      = parsedSizes.get(i);
                String name   = it.get("name") != null ? (String) it.get("name") : ("ID " + productId);

                try (PreparedStatement ps = con.prepareStatement(sqlStock)) {
                    ps.setInt(1, productId);
                    ps.setInt(2, size);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
                            throw new Exception("Sản phẩm \"" + name + "\" (size " + size
                                    + ") không tìm thấy trong kho.");
                        }
                        int stock = rs.getInt("quantity");
                        if (stock < qty) {
                            throw new Exception("Sản phẩm \"" + name + "\" (size " + size
                                    + ") chỉ còn " + stock + " chiếc trong kho, "
                                    + "không đủ số lượng yêu cầu (" + qty + ").");
                        }
                    }
                }
            }

            // 3) Tính total
            int total = 0;
            for (Map<String, Object> it : cartItems) {
                int price = (Integer) it.get("price");
                int qty   = (Integer) it.get("qty");
                total += price * qty;
            }

            // 4) INSERT dbo.orders
            String sqlOrder =
                    "INSERT INTO dbo.orders(user_id, receiver_name, receiver_phone, receiver_addr, email, note, total_amount, payment_method) "
                  + "VALUES (?,?,?,?,?,?,?,?)";

            int orderId;
            try (PreparedStatement ps = con.prepareStatement(sqlOrder, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, userId);
                ps.setString(2, receiverName);
                ps.setString(3, receiverPhone);
                ps.setString(4, receiverAddr);

                if (email == null || email.trim().isEmpty()) ps.setNull(5, Types.NVARCHAR);
                else ps.setString(5, email.trim());

                if (note == null || note.trim().isEmpty()) ps.setNull(6, Types.NVARCHAR);
                else ps.setString(6, note.trim());

                ps.setInt(7, total);
                ps.setString(8, paymentMethod == null ? "COD" : paymentMethod);

                ps.executeUpdate();

                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (!rs.next()) throw new Exception("Cannot get generated order_id");
                    orderId = rs.getInt(1);
                }
            }

            // 5) INSERT dbo.order_items
            String sqlItem =
                    "INSERT INTO dbo.order_items(order_id, product_id, size, quantity, unit_price) "
                  + "VALUES (?,?,?,?,?)";

            try (PreparedStatement ps = con.prepareStatement(sqlItem)) {
                for (int i = 0; i < cartItems.size(); i++) {
                    Map<String, Object> it = cartItems.get(i);
                    int productId = (Integer) it.get("id");
                    int price     = (Integer) it.get("price");
                    int qty       = (Integer) it.get("qty");
                    int size      = parsedSizes.get(i);

                    ps.setInt(1, orderId);
                    ps.setInt(2, productId);
                    ps.setInt(3, size);
                    ps.setInt(4, qty);
                    ps.setInt(5, price);
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            // 6) Trừ tồn kho — AND quantity >= qty đảm bảo không xuống âm (race condition safety)
            String sqlDeduct =
                "UPDATE dbo.product_sizes SET quantity = quantity - ? " +
                "WHERE product_id = ? AND size = ? AND quantity >= ?";

            for (int i = 0; i < cartItems.size(); i++) {
                Map<String, Object> it = cartItems.get(i);
                int productId = (Integer) it.get("id");
                int qty       = (Integer) it.get("qty");
                int size      = parsedSizes.get(i);
                String name   = it.get("name") != null ? (String) it.get("name") : ("ID " + productId);

                try (PreparedStatement ps = con.prepareStatement(sqlDeduct)) {
                    ps.setInt(1, qty);
                    ps.setInt(2, productId);
                    ps.setInt(3, size);
                    ps.setInt(4, qty);
                    int updated = ps.executeUpdate();
                    if (updated == 0) {
                        throw new Exception("Sản phẩm \"" + name + "\" (size " + size
                                + ") vừa hết hàng trong quá trình xử lý. Vui lòng thử lại.");
                    }
                }
            }

            con.commit();
            return orderId;

        } catch (Exception e) {
            if (con != null) try { con.rollback(); } catch (Exception ignore) {}
            throw e;
        } finally {
            if (con != null) try { con.close(); } catch (Exception ignore) {}
        }
    }

    // ==========================================================
    // lấy danh sách sản phẩm của 1 đơn hàng theo user
    // ==========================================================
    public List<Map<String, Object>> getOrderItemsByUser(int orderId, int userId) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        if (orderId <= 0 || userId <= 0) return list;

        String sql =
            "SELECT oi.product_id, oi.size, oi.quantity, oi.unit_price, " +
            "       p.name AS product_name, p.thumbnail " +
            "FROM dbo.order_items oi " +
            "JOIN dbo.orders o ON o.order_id = oi.order_id " +
            "JOIN dbo.products p ON p.product_id = oi.product_id " +
            "WHERE oi.order_id = ? AND o.user_id = ? " +
            "ORDER BY oi.product_id ASC";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("product_name", rs.getString("product_name"));
                    m.put("thumbnail", rs.getString("thumbnail"));
                    int s = rs.getInt("size");
                    m.put("size", rs.wasNull() ? null : s);
                    m.put("quantity", rs.getInt("quantity"));
                    m.put("unit_price", rs.getInt("unit_price"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    // ==========================================================
    // ORDER LOOKUP (USER)
    // ==========================================================
    public List<Map<String, Object>> getOrdersByUser(int userId) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql =
            "SELECT order_id, user_id, total_amount, status, payment_method, created_at " +
            "FROM dbo.orders WHERE user_id = ? ORDER BY order_id DESC";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("order_id", rs.getInt("order_id"));
                    m.put("user_id", rs.getInt("user_id"));
                    m.put("total_amount", rs.getInt("total_amount"));
                    m.put("status", rs.getString("status"));
                    m.put("payment_method", rs.getString("payment_method"));
                    m.put("created_at", rs.getTimestamp("created_at"));
                    list.add(m);
                }
            }
        }
        return list;
    }

    public Map<String, Object> getOrderHeaderByUser(int orderId, int userId) throws Exception {
        String sql =
            "SELECT order_id, user_id, receiver_name, receiver_phone, receiver_addr, email, note, " +
            "       total_amount, status, payment_method, created_at " +
            "FROM dbo.orders WHERE order_id = ? AND user_id = ?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("order_id", rs.getInt("order_id"));
                    m.put("user_id", rs.getInt("user_id"));
                    m.put("receiver_name", rs.getString("receiver_name"));
                    m.put("receiver_phone", rs.getString("receiver_phone"));
                    m.put("receiver_addr", rs.getString("receiver_addr"));
                    m.put("email", rs.getString("email"));
                    m.put("note", rs.getString("note"));
                    m.put("total_amount", rs.getInt("total_amount"));
                    m.put("status", rs.getString("status"));
                    m.put("payment_method", rs.getString("payment_method"));
                    m.put("created_at", rs.getTimestamp("created_at"));
                    return m;
                }
            }
        }
        return null;
    }

    public List<Map<String, Object>> getOrderItemsDetailByUser(int orderId, int userId) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();

        String sql =
            "SELECT oi.size, oi.quantity, oi.unit_price, oi.line_total, " +
            "       p.name AS product_name, p.thumbnail " +
            "FROM dbo.order_items oi " +
            "JOIN dbo.orders o ON o.order_id = oi.order_id " +
            "JOIN dbo.products p ON p.product_id = oi.product_id " +
            "WHERE oi.order_id = ? AND o.user_id = ? " +
            "ORDER BY oi.order_item_id ASC";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, orderId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("product_name", rs.getString("product_name"));
                    m.put("thumbnail", rs.getString("thumbnail"));
                    m.put("size", rs.getInt("size"));
                    m.put("quantity", rs.getInt("quantity"));
                    m.put("unit_price", rs.getInt("unit_price"));
                    m.put("line_total", rs.getInt("line_total"));
                    list.add(m);
                }
            }
        }
        return list;
    }
}
