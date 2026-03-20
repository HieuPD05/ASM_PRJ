package dal;

import java.sql.*;
import java.util.*;

public class CartDAO extends DBContext {

    // Tạo hoặc lấy cart_id theo user_id
    public int getOrCreateCartIdByUser(int userId) throws Exception {
        String findSql = "SELECT cart_id FROM carts WHERE user_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(findSql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("cart_id");
            }
        }

        String insSql = "INSERT INTO carts(user_id) VALUES(?)";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(insSql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, userId);
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        throw new Exception("Cannot create cart");
    }

    // Add/merge item (unique by cart_id + product_id + size)
    public void addOrMergeItem(int userId, int productId, int size, int qty, int unitPrice) throws Exception {
        int cartId = getOrCreateCartIdByUser(userId);

        String upsert =
            "MERGE cart_items AS t " +
            "USING (SELECT ? AS cart_id, ? AS product_id, ? AS size) AS s " +
            "ON (t.cart_id = s.cart_id AND t.product_id = s.product_id AND t.size = s.size) " +
            "WHEN MATCHED THEN UPDATE SET quantity = t.quantity + ? " +
            "WHEN NOT MATCHED THEN INSERT (cart_id, product_id, size, quantity, unit_price) " +
            "VALUES (?, ?, ?, ?, ?);";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(upsert)) {
            ps.setInt(1, cartId);
            ps.setInt(2, productId);
            ps.setInt(3, size);
            ps.setInt(4, qty);

            ps.setInt(5, cartId);
            ps.setInt(6, productId);
            ps.setInt(7, size);
            ps.setInt(8, qty);
            ps.setInt(9, unitPrice);

            ps.executeUpdate();
        }
    }

    public void updateQty(int userId, int productId, int size, int newQty) throws Exception {
        int cartId = getOrCreateCartIdByUser(userId);
        String sql = "UPDATE cart_items SET quantity=? WHERE cart_id=? AND product_id=? AND size=?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, newQty);
            ps.setInt(2, cartId);
            ps.setInt(3, productId);
            ps.setInt(4, size);
            ps.executeUpdate();
        }
    }

    public void removeItem(int userId, int productId, int size) throws Exception {
        int cartId = getOrCreateCartIdByUser(userId);
        String sql = "DELETE FROM cart_items WHERE cart_id=? AND product_id=? AND size=?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cartId);
            ps.setInt(2, productId);
            ps.setInt(3, size);
            ps.executeUpdate();
        }
    }

    public void clearCart(int userId) throws Exception {
        int cartId = getOrCreateCartIdByUser(userId);
        String sql = "DELETE FROM cart_items WHERE cart_id=?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cartId);
            ps.executeUpdate();
        }
    }

    // List items ra đúng format bạn đang dùng ở JSP (id,name,price,img,size,qty)
    public List<Map<String, Object>> listItems(int userId) throws Exception {
        int cartId = getOrCreateCartIdByUser(userId);

        String sql =
            "SELECT ci.product_id, ci.size, ci.quantity, ci.unit_price, p.name, p.thumbnail " +
            "FROM cart_items ci " +
            "JOIN products p ON p.product_id = ci.product_id " +
            "WHERE ci.cart_id = ? " +
            "ORDER BY ci.cart_item_id DESC";

        List<Map<String, Object>> list = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cartId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> it = new HashMap<>();
                    it.put("id", rs.getInt("product_id"));
                    it.put("name", rs.getString("name"));
                    it.put("price", rs.getInt("unit_price"));
                    it.put("img", rs.getString("thumbnail"));
                    it.put("size", String.valueOf(rs.getInt("size")));
                    it.put("qty", rs.getInt("quantity"));
                    list.add(it);
                }
            }
        }
        return list;
    }

    public int countItems(int userId) throws Exception {
        int cartId = getOrCreateCartIdByUser(userId);
        String sql = "SELECT ISNULL(SUM(quantity),0) AS c FROM cart_items WHERE cart_id=?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, cartId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("c");
            }
        }
        return 0;
    }

    // Merge session cart (guest) -> DB cart sau khi login
    @SuppressWarnings("unchecked")
    public void mergeSessionCartToUser(int userId, List<Map<String, Object>> sessionCart) throws Exception {
        if (sessionCart == null || sessionCart.isEmpty()) return;

        for (Map<String, Object> it : sessionCart) {
            int pid = (Integer) it.get("id");
            int qty = (Integer) it.get("qty");
            int price = (Integer) it.get("price");
            String sizeStr = (String) it.get("size");
            int size = 0;
            try { size = Integer.parseInt(sizeStr); } catch (Exception e) { size = 0; }
            if (size <= 0) continue;

            addOrMergeItem(userId, pid, size, Math.max(1, qty), price);
        }
    }
    
}
