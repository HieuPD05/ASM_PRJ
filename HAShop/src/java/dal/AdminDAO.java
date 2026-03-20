package dal;

import java.sql.*;
import java.util.*;

public class AdminDAO extends DBContext {

    // ===================== HELPERS =====================
    private boolean columnExists(String table, String column) throws Exception {
        String sql =
            "SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS " +
            "WHERE TABLE_NAME = ? AND COLUMN_NAME = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, table);
            ps.setString(2, column);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    private String toSlug(String s) {
        if (s == null) return "";
        String slug = s.trim().toLowerCase();
        slug = slug.replaceAll("[^a-z0-9\\s-]", "");
        slug = slug.replaceAll("\\s+", "-");
        slug = slug.replaceAll("-{2,}", "-");
        return slug;
    }

    // ===================== BRANDS =====================
    public List<Map<String, Object>> listBrands() throws Exception {
        String sql = "SELECT brand_id, brand_name FROM brands ORDER BY brand_name";
        List<Map<String, Object>> list = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> it = new HashMap<>();
                it.put("brand_id", rs.getInt("brand_id"));
                it.put("brand_name", rs.getString("brand_name"));
                list.add(it);
            }
        }
        return list;
    }

    // ===================== PRODUCTS LIST (main_image + total_stock) =====================
    public List<Map<String, Object>> listProducts() throws Exception {
        String sql =
            "SELECT p.product_id, p.name, p.price, p.thumbnail, " +
            "       (SELECT TOP 1 pi.image_url FROM product_images pi " +
            "        WHERE pi.product_id = p.product_id " +
            "        ORDER BY pi.sort_order ASC, pi.image_id ASC) AS main_image, " +
            "       (SELECT ISNULL(SUM(ps.quantity),0) FROM product_sizes ps WHERE ps.product_id=p.product_id) AS total_stock " +
            "FROM products p " +
            "ORDER BY p.product_id DESC";

        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> it = new HashMap<>();
                it.put("product_id", rs.getInt("product_id"));
                it.put("name", rs.getString("name"));
                it.put("price", rs.getInt("price"));

                // ưu tiên main_image trong product_images, fallback sang thumbnail
                String mainImage = rs.getString("main_image");
                if (mainImage == null || mainImage.trim().isEmpty()) {
                    mainImage = rs.getString("thumbnail");
                }
                it.put("main_image", mainImage);

                it.put("total_stock", rs.getInt("total_stock"));
                list.add(it);
            }
        }
        return list;
    }

    // ===================== GET PRODUCT =====================
    public Map<String, Object> getProduct(int productId) throws Exception {
        String sql =
            "SELECT product_id, category_id, brand_id, name, slug, price, target, description, thumbnail " +
            "FROM products WHERE product_id=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;

                Map<String, Object> p = new HashMap<>();
                p.put("product_id", rs.getInt("product_id"));
                p.put("category_id", (Integer) rs.getObject("category_id")); // nullable
                p.put("brand_id", rs.getInt("brand_id"));
                p.put("name", rs.getString("name"));
                p.put("slug", rs.getString("slug"));
                p.put("price", rs.getInt("price"));
                p.put("target", rs.getString("target"));
                p.put("description", rs.getString("description"));
                p.put("thumbnail", rs.getString("thumbnail"));
                return p;
            }
        }
    }

    // ===================== IMAGES =====================
    public List<String> getProductImages(int productId) throws Exception {
        String sql =
            "SELECT image_url FROM product_images " +
            "WHERE product_id=? " +
            "ORDER BY sort_order ASC, image_id ASC";

        List<String> imgs = new ArrayList<>();
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) imgs.add(rs.getString("image_url"));
            }
        }
        return imgs;
    }

    private void insertImages(Connection con, int productId,
                              String mainImage, String img1, String img2, String img3) throws Exception {

        String ins = "INSERT INTO product_images(product_id, image_url, sort_order) VALUES(?,?,?)";

        // MAIN = sort_order 0
        if (mainImage != null && !mainImage.trim().isEmpty()) {
            try (PreparedStatement ps = con.prepareStatement(ins)) {
                ps.setInt(1, productId);
                ps.setString(2, mainImage.trim());
                ps.setInt(3, 0);
                ps.executeUpdate();
            }
        }

        // EXTRA images sort_order 1..3
        String[] extras = new String[]{img1, img2, img3};
        int order = 1;

        for (String url : extras) {
            if (url == null) continue;
            url = url.trim();
            if (url.isEmpty()) continue;

            try (PreparedStatement ps = con.prepareStatement(ins)) {
                ps.setInt(1, productId);
                ps.setString(2, url);
                ps.setInt(3, order++);
                ps.executeUpdate();
            }
        }
    }

    // ===================== SIZES =====================
    public Map<Integer, Integer> getProductSizeMap(int productId) throws Exception {
        String sql =
            "SELECT size, quantity FROM product_sizes " +
            "WHERE product_id=? ORDER BY size ASC";

        Map<Integer, Integer> map = new LinkedHashMap<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    map.put(rs.getInt("size"), rs.getInt("quantity"));
                }
            }
        }
        return map;
    }

    private void insertSizes(Connection con, int productId, Map<Integer, Integer> sizeQty) throws Exception {
        String ins = "INSERT INTO product_sizes(product_id, size, quantity) VALUES(?,?,?)";

        try (PreparedStatement ps = con.prepareStatement(ins)) {
            for (Map.Entry<Integer, Integer> e : sizeQty.entrySet()) {
                ps.setInt(1, productId);
                ps.setInt(2, e.getKey());
                ps.setInt(3, e.getValue());
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    // ===================== CREATE PRODUCT (products + images + sizes) =====================
    public int createProduct(Integer categoryId, int brandId,
                             String name, int price, String target, String description,
                             String thumbnail, String img1, String img2, String img3,
                             Map<Integer, Integer> sizeQty) throws Exception {

        if (brandId <= 0) throw new Exception("brand_id is required");
        if (name == null || name.trim().isEmpty()) throw new Exception("name is required");
        if (target == null || target.trim().isEmpty()) target = "both";
        if (thumbnail == null || thumbnail.trim().isEmpty()) thumbnail = "images/products/demo/sp1.jpg";
        if (sizeQty == null || sizeQty.isEmpty()) throw new Exception("product_sizes is required");

        String slug = toSlug(name);

        String sql =
            "INSERT INTO products(category_id, brand_id, name, slug, price, target, description, thumbnail) " +
            "VALUES(?,?,?,?,?,?,?,?)";

        try (Connection con = getConnection()) {
            con.setAutoCommit(false);

            int newId;

            try (PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                if (categoryId == null) ps.setNull(1, Types.INTEGER); else ps.setInt(1, categoryId);
                ps.setInt(2, brandId);
                ps.setString(3, name);
                ps.setString(4, slug);
                ps.setInt(5, price);
                ps.setString(6, target);
                ps.setString(7, description);
                ps.setString(8, thumbnail);

                ps.executeUpdate();
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (!rs.next()) throw new Exception("Cannot get new product_id");
                    newId = rs.getInt(1);
                }
            }

            // images: thumbnail là main, + 0-3 ảnh phụ
            insertImages(con, newId, thumbnail, img1, img2, img3);

            // sizes
            insertSizes(con, newId, sizeQty);

            con.commit();
            return newId;
        }
    }
    public Map<String,Object> getProductAdmin(int productId) throws Exception {
    String sql =
        "SELECT product_id, brand_id, name, price, target, description, thumbnail " +
        "FROM products WHERE product_id = ?";

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, productId);

        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("product_id", rs.getInt("product_id"));
                m.put("brand_id", rs.getInt("brand_id"));
                m.put("name", rs.getString("name"));
                m.put("price", rs.getInt("price"));
                m.put("target", rs.getString("target"));
                m.put("description", rs.getString("description"));
                m.put("thumbnail", rs.getString("thumbnail"));
                return m;
            }
        }
    }
    return null;
}


    // ===================== UPDATE PRODUCT (replace images + replace sizes) =====================
    public void updateProduct(int productId, Integer categoryId, int brandId,
                              String name, int price, String target, String description,
                              String thumbnail, String img1, String img2, String img3,
                              Map<Integer, Integer> sizeQty) throws Exception {

        if (productId <= 0) throw new Exception("product_id is required");
        if (brandId <= 0) throw new Exception("brand_id is required");
        if (name == null || name.trim().isEmpty()) throw new Exception("name is required");
        if (target == null || target.trim().isEmpty()) target = "both";
        if (thumbnail == null || thumbnail.trim().isEmpty()) thumbnail = "images/products/demo/sp1.jpg";
        if (sizeQty == null || sizeQty.isEmpty()) throw new Exception("product_sizes is required");

        String slug = toSlug(name);

        String sql =
            "UPDATE products SET category_id=?, brand_id=?, name=?, slug=?, price=?, target=?, description=?, thumbnail=? " +
            "WHERE product_id=?";

        try (Connection con = getConnection()) {
            con.setAutoCommit(false);

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                if (categoryId == null) ps.setNull(1, Types.INTEGER); else ps.setInt(1, categoryId);
                ps.setInt(2, brandId);
                ps.setString(3, name);
                ps.setString(4, slug);
                ps.setInt(5, price);
                ps.setString(6, target);
                ps.setString(7, description);
                ps.setString(8, thumbnail);
                ps.setInt(9, productId);
                ps.executeUpdate();
            }

            // replace images
            try (PreparedStatement del = con.prepareStatement("DELETE FROM product_images WHERE product_id=?")) {
                del.setInt(1, productId);
                del.executeUpdate();
            }
            insertImages(con, productId, thumbnail, img1, img2, img3);

            // replace sizes
            try (PreparedStatement del2 = con.prepareStatement("DELETE FROM product_sizes WHERE product_id=?")) {
                del2.setInt(1, productId);
                del2.executeUpdate();
            }
            insertSizes(con, productId, sizeQty);

            con.commit();
        }
    }
public Map<Integer,Integer> getProductSizesMap(int productId) throws Exception {
    String sql = "SELECT size, quantity FROM product_sizes WHERE product_id = ?";
    Map<Integer,Integer> map = new LinkedHashMap<>();

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, productId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                map.put(rs.getInt("size"), rs.getInt("quantity"));
            }
        }
    }
    return map;
}

    // ===================== FK CHECKS =====================
    public boolean hasCartItems(int productId) throws Exception {
        String sql = "SELECT TOP 1 1 FROM cart_items WHERE product_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    public boolean hasOrderItems(int productId) throws Exception {
        String sql = "SELECT TOP 1 1 FROM order_items WHERE product_id = ?";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, productId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // ===================== DELETE PRODUCT =====================
    // Nếu sản phẩm đang nằm trong cart_items hoặc order_items -> chặn và throw message để hiện thông báo trên UI
    public void deleteProduct(int productId) throws Exception {
        if (productId <= 0) return;

        if (hasOrderItems(productId)) {
            throw new Exception("Không thể xóa: sản phẩm đã phát sinh trong đơn hàng (order_items).");
        }
        if (hasCartItems(productId)) {
            throw new Exception("Không thể xóa: sản phẩm đang nằm trong giỏ hàng của khách (cart_items).");
        }

        try (Connection con = getConnection()) {
            con.setAutoCommit(false);

            try (PreparedStatement ps0 = con.prepareStatement("DELETE FROM product_sizes WHERE product_id=?")) {
                ps0.setInt(1, productId);
                ps0.executeUpdate();
            }

            try (PreparedStatement ps1 = con.prepareStatement("DELETE FROM product_images WHERE product_id=?")) {
                ps1.setInt(1, productId);
                ps1.executeUpdate();
            }

            try (PreparedStatement ps2 = con.prepareStatement("DELETE FROM products WHERE product_id=?")) {
                ps2.setInt(1, productId);
                ps2.executeUpdate();
            }

            con.commit();
        }
    }
public List<Map<String, Object>> listRecentOrdersByUser(int userId, int limit) throws Exception {
    if (userId <= 0) return new ArrayList<>();
    if (limit <= 0) limit = 5;
    if (limit > 50) limit = 50; // chặn cho an toàn

    // SQL Server: dùng TOP
    String sql =
        "SELECT TOP " + limit + " " +
        "   o.order_id, o.total_amount, o.status, o.created_at " +
        "FROM orders o " +
        "WHERE o.user_id = ? " +
        "ORDER BY o.order_id DESC";

    List<Map<String, Object>> list = new ArrayList<>();

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, userId);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("order_id", rs.getInt("order_id"));
                m.put("total_amount", rs.getInt("total_amount"));
                m.put("status", rs.getString("status"));
                m.put("created_at", rs.getTimestamp("created_at"));
                list.add(m);
            }
        }
    }
    return list;
}
public List<Map<String,Object>> listOrdersByUser(int userId) throws Exception {

    String sql =
        "SELECT o.order_id, o.user_id, o.receiver_name, o.receiver_phone, " +
        "       o.total_amount, o.status, o.created_at " +
        "FROM orders o " +
        "WHERE o.user_id = ? " +
        "ORDER BY o.order_id DESC";

    List<Map<String,Object>> list = new ArrayList<>();

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, userId);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("order_id", rs.getInt("order_id"));
                m.put("user_id", rs.getInt("user_id"));
                m.put("receiver_name", rs.getString("receiver_name"));
                m.put("receiver_phone", rs.getString("receiver_phone"));
                m.put("total_amount", rs.getInt("total_amount"));
                m.put("status", rs.getString("status"));
                m.put("created_at", rs.getTimestamp("created_at"));
                list.add(m);
            }
        }
    }
    return list;
}


    // ===================== DASHBOARD STATS =====================
    public Map<String, Object> dashboardStats() throws Exception {
        Map<String, Object> m = new HashMap<>();
        m.put("products", 0);
        m.put("customers", 0);
        m.put("orders", 0);
        m.put("revenue", 0L);

        try (Connection con = getConnection()) {

            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM products");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) m.put("products", rs.getInt(1));
            }

            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM users WHERE role_id = 1");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) m.put("customers", rs.getInt(1));
            }

            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM orders");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) m.put("orders", rs.getInt(1));
            }

            // doanh thu theo order_items (quantity * unit_price)
            try (PreparedStatement ps = con.prepareStatement(
                "SELECT ISNULL(SUM(CAST(quantity AS BIGINT) * CAST(unit_price AS BIGINT)),0) FROM order_items");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) m.put("revenue", rs.getLong(1));
            }
        }

        return m;
    }

    // ===================== ORDERS (ADMIN LIST: có customer full_name) =====================
    public List<Map<String, Object>> listOrdersAdmin() throws Exception {
        boolean hasStatus = columnExists("orders", "status");
        boolean hasCreated = columnExists("orders", "created_at");

        String sql =
            "SELECT o.order_id, o.user_id, o.receiver_name, o.receiver_phone, o.receiver_addr, o.email, o.note, o.total_amount, " +
            (hasStatus ? " o.status, " : " NULL AS status, ") +
            (hasCreated ? " o.created_at, " : " NULL AS created_at, ") +
            "       u.full_name AS customer_name " +
            "FROM orders o " +
            "LEFT JOIN users u ON u.user_id = o.user_id " +
            "ORDER BY o.order_id DESC";

        List<Map<String, Object>> list = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("order_id", rs.getInt("order_id"));
                m.put("user_id", rs.getInt("user_id"));
                m.put("customer_name", rs.getString("customer_name"));
                m.put("receiver_name", rs.getString("receiver_name"));
                m.put("receiver_phone", rs.getString("receiver_phone"));
                m.put("receiver_addr", rs.getString("receiver_addr"));
                m.put("email", rs.getString("email"));
                m.put("note", rs.getString("note"));
                m.put("total_amount", rs.getInt("total_amount"));
                m.put("status", rs.getString("status"));
                m.put("created_at", rs.getTimestamp("created_at"));
                m.put("has_status", hasStatus);
                m.put("has_created", hasCreated);
                list.add(m);
            }
        }

        return list;
    }

    public Map<String, Object> getOrderHeader(int orderId) throws Exception {
        if (orderId <= 0) return new HashMap<>();

        boolean hasStatus = columnExists("orders", "status");
        boolean hasCreated = columnExists("orders", "created_at");

        String sql =
            "SELECT o.order_id, o.user_id, o.receiver_name, o.receiver_phone, o.receiver_addr, o.email, o.note, o.total_amount, " +
            (hasStatus ? " o.status, " : " NULL AS status, ") +
            (hasCreated ? " o.created_at, " : " NULL AS created_at, ") +
            "       u.full_name AS customer_name " +
            "FROM orders o " +
            "LEFT JOIN users u ON u.user_id = o.user_id " +
            "WHERE o.order_id = ?";

        Map<String, Object> m = new HashMap<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, orderId);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    m.put("order_id", rs.getInt("order_id"));
                    m.put("user_id", rs.getInt("user_id"));
                    m.put("customer_name", rs.getString("customer_name"));
                    m.put("receiver_name", rs.getString("receiver_name"));
                    m.put("receiver_phone", rs.getString("receiver_phone"));
                    m.put("receiver_addr", rs.getString("receiver_addr"));
                    m.put("email", rs.getString("email"));
                    m.put("note", rs.getString("note"));
                    m.put("total_amount", rs.getInt("total_amount"));
                    m.put("status", rs.getString("status"));
                    m.put("created_at", rs.getTimestamp("created_at"));
                }
            }
        }

        return m;
    }

    public List<Map<String, Object>> getOrderItems(int orderId) throws Exception {
        List<Map<String, Object>> list = new ArrayList<>();
        if (orderId <= 0) return list;

        String sql =
            "SELECT " +
            "  p.name AS product_name, " +
            "  p.thumbnail, " +
            "  oi.size, " +
            "  oi.quantity, " +
            "  oi.unit_price, " +
            "  oi.line_total " +
            "FROM order_items oi " +
            "JOIN products p ON p.product_id = oi.product_id " +
            "WHERE oi.order_id = ? " +
            "ORDER BY oi.order_item_id ASC";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, orderId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new HashMap<>();
                    m.put("product_name", rs.getString("product_name"));
                    m.put("thumbnail", rs.getString("thumbnail"));

                    int sizeVal = rs.getInt("size");
                    m.put("size", rs.wasNull() ? null : sizeVal);

                    int qty = rs.getInt("quantity");
                    int unitPrice = rs.getInt("unit_price");

                    int lineTotal = rs.getInt("line_total");
                    if (rs.wasNull()) lineTotal = qty * unitPrice;

                    m.put("quantity", qty);
                    m.put("unit_price", unitPrice);
                    m.put("line_total", lineTotal);

                    list.add(m);
                }
            }
        }

        return list;
    }

    // ===================== UPDATE ORDER STATUS =====================
    // Chỉ update nếu DB có cột status (vì schema orders bạn gửi hiện chưa có status)
   // ===================== UPDATE ORDER STATUS =====================
/**
 * Cập nhật trạng thái đơn hàng theo luồng 1 chiều:
 *   PENDING -> PAID -> SHIPPING -> DONE
 *                               -> CANCEL (chỉ khi chưa DONE)
 * DONE và CANCEL là trạng thái cuối, không thể thay đổi.
 *
 * @throws Exception nếu chuyển trạng thái không hợp lệ
 */
public void updateOrderStatus(int orderId, String newStatus) throws Exception {
    if (orderId <= 0) return;

    newStatus = (newStatus == null ? "" : newStatus.trim().toUpperCase());

    // Các trạng thái hợp lệ
    java.util.List<String> FLOW = java.util.Arrays.asList(
        "PENDING", "PAID", "SHIPPING", "DONE"
    );
    Set<String> VALID = new HashSet<>(java.util.Arrays.asList(
        "PENDING", "PAID", "SHIPPING", "DONE", "CANCEL"
    ));

    if (!VALID.contains(newStatus)) {
        throw new Exception("Trạng thái không hợp lệ: " + newStatus);
    }

    // Lấy trạng thái hiện tại
    String currentStatus = "";
    String sqlGet = "SELECT status FROM orders WHERE order_id = ?";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sqlGet)) {
        ps.setInt(1, orderId);
        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) throw new Exception("Không tìm thấy đơn hàng #" + orderId);
            currentStatus = rs.getString("status");
            if (currentStatus == null) currentStatus = "PENDING";
            currentStatus = currentStatus.trim().toUpperCase();
        }
    }

    // DONE và CANCEL là trạng thái cuối — không được đổi
    if ("DONE".equals(currentStatus) || "CANCEL".equals(currentStatus)) {
        throw new Exception("Đơn hàng đã ở trạng thái " + currentStatus + ", không thể thay đổi.");
    }

    // Kiểm tra chiều tiến: chỉ cho phép tiến về phía trước trong FLOW
    if ("CANCEL".equals(newStatus)) {
        // Cho phép CANCEL từ bất kỳ trạng thái nào chưa DONE/CANCEL
        // (đã xử lý ở trên rồi)
    } else {
        int curIdx = FLOW.indexOf(currentStatus);
        int newIdx = FLOW.indexOf(newStatus);
        if (newIdx <= curIdx) {
            throw new Exception("Không thể chuyển từ " + currentStatus + " về " + newStatus
                    + ". Trạng thái chỉ được tiến về phía trước.");
        }
    }

    // Thực hiện cập nhật
    String sqlUpdate = "UPDATE orders SET status = ? WHERE order_id = ?";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sqlUpdate)) {
        ps.setString(1, newStatus);
        ps.setInt(2, orderId);
        ps.executeUpdate();
    }
}

/**
 * Lấy trạng thái hiện tại của đơn hàng (dùng cho JSP để disable option)
 */
public String getOrderStatus(int orderId) throws Exception {
    String sql = "SELECT status FROM orders WHERE order_id = ?";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, orderId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                String s = rs.getString("status");
                return (s == null ? "PENDING" : s.trim().toUpperCase());
            }
        }
    }
    return "PENDING";
}



    // ===================== CUSTOMERS SUMMARY =====================
    public List<Map<String, Object>> listCustomersSummary() throws Exception {
        String sql =
            "SELECT u.user_id, u.full_name, u.email, u.phone, " +
            "       COUNT(o.order_id) AS total_orders, " +
            "       ISNULL(SUM(CAST(o.total_amount AS BIGINT)),0) AS total_spent " +
            "FROM users u " +
            "LEFT JOIN orders o ON o.user_id = u.user_id " +
            "WHERE u.role_id = 1 " +
            "GROUP BY u.user_id, u.full_name, u.email, u.phone " +
            "ORDER BY u.user_id DESC";

        List<Map<String, Object>> list = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> m = new HashMap<>();
                m.put("user_id", rs.getInt("user_id"));
                m.put("full_name", rs.getString("full_name"));
                m.put("email", rs.getString("email"));
                m.put("phone", rs.getString("phone"));
                m.put("total_orders", rs.getInt("total_orders"));
                m.put("total_spent", rs.getLong("total_spent"));
                list.add(m);
            }
        }

        return list;
    }
    // ===================== DELETE ORDER =====================
public boolean deleteOrder(int orderId) throws Exception {
    if (orderId <= 0) return false;

    try (Connection con = getConnection()) {
        con.setAutoCommit(false);

        // 1. Xóa order_items trước (an toàn dù có cascade)
        try (PreparedStatement ps = con.prepareStatement(
                "DELETE FROM order_items WHERE order_id=?")) {
            ps.setInt(1, orderId);
            ps.executeUpdate();
        }

        // 2. Xóa orders
        int affected;
        try (PreparedStatement ps = con.prepareStatement(
                "DELETE FROM orders WHERE order_id=?")) {
            ps.setInt(1, orderId);
            affected = ps.executeUpdate();
        }

        con.commit();
        return affected > 0;
    }
}
// ===================== NEWS (ADMIN) =====================

private String toSlugVN(String s){
    if(s == null) return "";
    String t = s.trim().toLowerCase();

    // bỏ dấu tiếng Việt cơ bản
    t = java.text.Normalizer.normalize(t, java.text.Normalizer.Form.NFD)
            .replaceAll("\\p{InCombiningDiacriticalMarks}+", "");
    t = t.replace("đ","d");

    t = t.replaceAll("[^a-z0-9\\s-]", "");
    t = t.replaceAll("\\s+", "-");
    t = t.replaceAll("-{2,}", "-");
    return t;
}

public List<Map<String,Object>> listNewsAdmin() throws Exception{
    String sql = "SELECT post_id, title, thumbnail, is_active, created_at " +
                 "FROM news_posts ORDER BY created_at DESC, post_id DESC";
    List<Map<String,Object>> list = new ArrayList<>();
    try(Connection con = getConnection();
        PreparedStatement ps = con.prepareStatement(sql);
        ResultSet rs = ps.executeQuery()){
        while(rs.next()){
            Map<String,Object> m = new HashMap<>();
            m.put("post_id", rs.getInt("post_id"));
            m.put("title", rs.getString("title"));
            m.put("thumbnail", rs.getString("thumbnail"));
            m.put("is_active", rs.getBoolean("is_active"));
            m.put("created_at", rs.getTimestamp("created_at"));
            list.add(m);
        }
    }
    return list;
}

public Map<String,Object> getNews(int postId) throws Exception{
    String sql = "SELECT post_id, title, slug, summary, content, thumbnail, is_active, created_at " +
                 "FROM news_posts WHERE post_id=?";
    try(Connection con = getConnection();
        PreparedStatement ps = con.prepareStatement(sql)){
        ps.setInt(1, postId);
        try(ResultSet rs = ps.executeQuery()){
            if(!rs.next()) return null;
            Map<String,Object> m = new HashMap<>();
            m.put("post_id", rs.getInt("post_id"));
            m.put("title", rs.getString("title"));
            m.put("slug", rs.getString("slug"));
            m.put("summary", rs.getString("summary"));
            m.put("content", rs.getString("content"));
            m.put("thumbnail", rs.getString("thumbnail"));
            m.put("is_active", rs.getBoolean("is_active"));
            m.put("created_at", rs.getTimestamp("created_at"));
            return m;
        }
    }
}

public int createNews(String title, String summary, String content, String thumbnail, boolean isActive) throws Exception{
    if(title == null || title.trim().isEmpty()) throw new Exception("Title is required");
    if(content == null || content.trim().isEmpty()) throw new Exception("Content is required");

    String slug = toSlugVN(title);
    if(slug.isEmpty()) slug = "post";

    // tránh trùng slug: thêm timestamp nếu cần
    slug = slug + "-" + System.currentTimeMillis();

    String sql = "INSERT INTO news_posts(title, slug, summary, content, thumbnail, is_active) " +
                 "VALUES(?,?,?,?,?,?)";

    try(Connection con = getConnection();
        PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)){
        ps.setString(1, title.trim());
        ps.setString(2, slug);
        ps.setString(3, summary);
        ps.setString(4, content);
        ps.setString(5, thumbnail);
        ps.setBoolean(6, isActive);
        ps.executeUpdate();

        try(ResultSet rs = ps.getGeneratedKeys()){
            if(rs.next()) return rs.getInt(1);
        }
    }
    return 0;
}

public void updateNews(int postId, String title, String summary, String content, String thumbnail, boolean isActive) throws Exception{
    if(postId <= 0) return;
    if(title == null || title.trim().isEmpty()) throw new Exception("Title is required");
    if(content == null || content.trim().isEmpty()) throw new Exception("Content is required");

    String sql = "UPDATE news_posts SET title=?, summary=?, content=?, thumbnail=?, is_active=? WHERE post_id=?";

    try(Connection con = getConnection();
        PreparedStatement ps = con.prepareStatement(sql)){
        ps.setString(1, title.trim());
        ps.setString(2, summary);
        ps.setString(3, content);
        ps.setString(4, thumbnail);
        ps.setBoolean(5, isActive);
        ps.setInt(6, postId);
        ps.executeUpdate();
    }
}

public boolean deleteNews(int postId) throws Exception{
    if(postId <= 0) return false;
    String sql = "DELETE FROM news_posts WHERE post_id=?";
    try(Connection con = getConnection();
        PreparedStatement ps = con.prepareStatement(sql)){
        ps.setInt(1, postId);
        return ps.executeUpdate() > 0;
    }
}
// ===================== ADMIN PRODUCTS PAGING =====================
// ===================== ADMIN PRODUCTS PAGING =====================
public int countProductsAdmin() throws Exception {
    String sql = "SELECT COUNT(*) FROM products";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {
        return rs.next() ? rs.getInt(1) : 0;
    }
}

public List<Map<String,Object>> listProductsAdminPaged(int page, int pageSize) throws Exception {
    if (page < 1) page = 1;
    if (pageSize < 1) pageSize = 5;

    int offset = (page - 1) * pageSize;

    // ✅ SỬA Ở ĐÂY: dùng p.thumbnail thay vì p.main_image
    String sql =
        "SELECT p.product_id, p.name, p.price, p.thumbnail, " +
        "       ISNULL(SUM(ps.quantity),0) AS total_stock " +
        "FROM products p " +
        "LEFT JOIN product_sizes ps ON p.product_id = ps.product_id " +
        "GROUP BY p.product_id, p.name, p.price, p.thumbnail " +
        "ORDER BY p.product_id DESC " +
        "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

    List<Map<String,Object>> list = new ArrayList<>();

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setInt(1, offset);
        ps.setInt(2, pageSize);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("product_id", rs.getInt("product_id"));
                m.put("name", rs.getString("name"));
                m.put("price", rs.getInt("price"));
                m.put("thumbnail", rs.getString("thumbnail"));
                m.put("total_stock", rs.getInt("total_stock"));
                list.add(m);
            }
        }
    }
    return list;
}

// ===================== CONTACT MESSAGES (Thread + Replies Pattern) =====================
// Mỗi contact tạo 1 thread (parent_id = NULL, sender_role = 'USER').
// Các reply (user hoặc admin) là bản ghi con với parent_id = message_id của thread gốc.
// Status trên thread gốc: NEW -> READ -> REPLIED -> CLOSED

/**
 * Tạo thread liên hệ mới từ user.
 * Trả về message_id của thread vừa tạo.
 */
public int createContactThread(int userId, String name, String email,
                                String phone, String subject, String content) throws Exception {
    String sql =
        "INSERT INTO contact_messages(user_id, sender_name, sender_email, sender_phone, " +
        "  subject, message_content, status, sender_role) " +
        "OUTPUT INSERTED.message_id " +
        "VALUES(?, ?, ?, ?, ?, ?, 'NEW', 'USER')";

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, userId);
        ps.setString(2, name);
        ps.setString(3, email);
        ps.setString(4, (phone == null || phone.trim().isEmpty()) ? null : phone.trim());
        ps.setString(5, (subject == null || subject.trim().isEmpty()) ? null : subject.trim());
        ps.setString(6, content);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        }
    }
    return 0;
}

/**
 * Lấy danh sách thread gốc (parent_id IS NULL) cho admin — có phân trang.
 */
public List<Map<String,Object>> listContactThreads(String filter, int page, int pageSize) throws Exception {
    String where = " WHERE cm.parent_id IS NULL ";
    if ("new".equalsIgnoreCase(filter))     where += " AND cm.status = 'NEW' ";
    else if ("open".equalsIgnoreCase(filter))    where += " AND cm.status IN ('NEW','READ') ";
    else if ("replied".equalsIgnoreCase(filter)) where += " AND cm.status = 'REPLIED' ";
    else if ("closed".equalsIgnoreCase(filter))  where += " AND cm.status = 'CLOSED' ";

    int offset = (page - 1) * pageSize;
    // Lấy kèm số lượng reply và thời gian reply cuối cùng
    String sql =
        "SELECT cm.message_id, cm.sender_name, cm.sender_email, cm.sender_phone, " +
        "       cm.subject, cm.status, cm.created_at, " +
        "       (SELECT COUNT(*) FROM contact_messages r WHERE r.parent_id = cm.message_id) AS reply_count, " +
        "       (SELECT MAX(r2.created_at) FROM contact_messages r2 WHERE r2.parent_id = cm.message_id) AS last_reply_at " +
        "FROM contact_messages cm " +
        where +
        "ORDER BY cm.created_at DESC " +
        "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

    List<Map<String,Object>> list = new ArrayList<>();
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, offset);
        ps.setInt(2, pageSize);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("message_id",    rs.getInt("message_id"));
                m.put("sender_name",   rs.getString("sender_name"));
                m.put("sender_email",  rs.getString("sender_email"));
                m.put("sender_phone",  rs.getString("sender_phone"));
                m.put("subject",       rs.getString("subject"));
                m.put("status",        rs.getString("status"));
                m.put("created_at",    rs.getTimestamp("created_at"));
                m.put("reply_count",   rs.getInt("reply_count"));
                m.put("last_reply_at", rs.getTimestamp("last_reply_at"));
                list.add(m);
            }
        }
    }
    return list;
}

public int countContactThreads(String filter) throws Exception {
    String where = " WHERE parent_id IS NULL ";
    if ("new".equalsIgnoreCase(filter))     where += " AND status = 'NEW' ";
    else if ("open".equalsIgnoreCase(filter))    where += " AND status IN ('NEW','READ') ";
    else if ("replied".equalsIgnoreCase(filter)) where += " AND status = 'REPLIED' ";
    else if ("closed".equalsIgnoreCase(filter))  where += " AND status = 'CLOSED' ";

    String sql = "SELECT COUNT(*) FROM contact_messages " + where;
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql);
         ResultSet rs = ps.executeQuery()) {
        return rs.next() ? rs.getInt(1) : 0;
    }
}

/**
 * Lấy toàn bộ hội thoại (thread + tất cả reply) theo thứ tự thời gian.
 */
public Map<String,Object> getContactThreadWithReplies(int threadId) throws Exception {
    // Lấy thread gốc
    String sqlThread =
        "SELECT message_id, user_id, sender_name, sender_email, sender_phone, " +
        "       subject, message_content, status, sender_role, created_at " +
        "FROM contact_messages WHERE message_id = ? AND parent_id IS NULL";

    Map<String,Object> thread = null;
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sqlThread)) {
        ps.setInt(1, threadId);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                thread = new HashMap<>();
                thread.put("message_id",    rs.getInt("message_id"));
                thread.put("user_id",       rs.getObject("user_id"));
                thread.put("sender_name",   rs.getString("sender_name"));
                thread.put("sender_email",  rs.getString("sender_email"));
                thread.put("sender_phone",  rs.getString("sender_phone"));
                thread.put("subject",       rs.getString("subject"));
                thread.put("message_content", rs.getString("message_content"));
                thread.put("status",        rs.getString("status"));
                thread.put("sender_role",   rs.getString("sender_role"));
                thread.put("created_at",    rs.getTimestamp("created_at"));
            }
        }
    }
    if (thread == null) return null;

    // Lấy các reply
    String sqlReplies =
        "SELECT message_id, sender_name, sender_role, message_content, created_at " +
        "FROM contact_messages " +
        "WHERE parent_id = ? " +
        "ORDER BY created_at ASC, message_id ASC";

    List<Map<String,Object>> replies = new ArrayList<>();
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sqlReplies)) {
        ps.setInt(1, threadId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> r = new HashMap<>();
                r.put("message_id",      rs.getInt("message_id"));
                r.put("sender_name",     rs.getString("sender_name"));
                r.put("sender_role",     rs.getString("sender_role"));
                r.put("message_content", rs.getString("message_content"));
                r.put("created_at",      rs.getTimestamp("created_at"));
                replies.add(r);
            }
        }
    }
    thread.put("replies", replies);
    return thread;
}

/**
 * Admin reply vào một thread.
 * Thêm bản ghi reply con + cập nhật status thread gốc thành REPLIED.
 */
public void adminReplyThread(int threadId, String replyContent) throws Exception {
    try (Connection con = getConnection()) {
        con.setAutoCommit(false);
        try {
            String sqlInsert =
                "INSERT INTO contact_messages(sender_name, sender_email, message_content, " +
                "  status, sender_role, parent_id) " +
                "VALUES(N'HA SHOP', N'hashop@gmail.com', ?, 'REPLIED', 'ADMIN', ?)";
            try (PreparedStatement ps = con.prepareStatement(sqlInsert)) {
                ps.setString(1, replyContent);
                ps.setInt(2, threadId);
                ps.executeUpdate();
            }

            String sqlUpdate =
                "UPDATE contact_messages SET status = 'REPLIED' " +
                "WHERE message_id = ? AND parent_id IS NULL";
            try (PreparedStatement ps = con.prepareStatement(sqlUpdate)) {
                ps.setInt(1, threadId);
                ps.executeUpdate();
            }
            con.commit();
        } catch (Exception e) {
            con.rollback();
            throw e;
        }
    }
}

/**
 * User reply lại trong thread đã có.
 * Thêm bản ghi reply con + đổi status thread gốc về NEW (chờ admin xử lý tiếp).
 */
public void userReplyThread(int threadId, int userId, String senderName, String replyContent) throws Exception {
    // Kiểm tra thread thuộc về user này
    String sqlCheck = "SELECT message_id FROM contact_messages WHERE message_id = ? AND user_id = ? AND parent_id IS NULL";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sqlCheck)) {
        ps.setInt(1, threadId);
        ps.setInt(2, userId);
        try (ResultSet rs = ps.executeQuery()) {
            if (!rs.next()) throw new Exception("Thread không tồn tại hoặc không có quyền.");
        }
    }

    try (Connection con = getConnection()) {
        con.setAutoCommit(false);
        try {
            String sqlInsert =
                "INSERT INTO contact_messages(user_id, sender_name, message_content, " +
                "  status, sender_role, parent_id) " +
                "VALUES(?, ?, ?, 'NEW', 'USER', ?)";
            try (PreparedStatement ps = con.prepareStatement(sqlInsert)) {
                ps.setInt(1, userId);
                ps.setString(2, senderName);
                ps.setString(3, replyContent);
                ps.setInt(4, threadId);
                ps.executeUpdate();
            }

            // Đổi status thread gốc về NEW để admin biết có tin mới từ user
            String sqlUpdate =
                "UPDATE contact_messages SET status = 'NEW' " +
                "WHERE message_id = ? AND parent_id IS NULL";
            try (PreparedStatement ps = con.prepareStatement(sqlUpdate)) {
                ps.setInt(1, threadId);
                ps.executeUpdate();
            }
            con.commit();
        } catch (Exception e) {
            con.rollback();
            throw e;
        }
    }
}

/**
 * Admin đóng thread (không cần reply nữa).
 */
public void closeContactThread(int threadId) throws Exception {
    String sql = "UPDATE contact_messages SET status = 'CLOSED' WHERE message_id = ? AND parent_id IS NULL";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, threadId);
        ps.executeUpdate();
    }
}

/**
 * Đánh dấu thread là READ khi admin mở ra xem lần đầu.
 */
public void markThreadRead(int threadId) throws Exception {
    String sql =
        "UPDATE contact_messages SET status = 'READ' " +
        "WHERE message_id = ? AND parent_id IS NULL AND status = 'NEW'";
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, threadId);
        ps.executeUpdate();
    }
}

/**
 * Lấy danh sách thread của một user (để hiển thị hộp thư phía user).
 */
public List<Map<String,Object>> listThreadsByUser(int userId) throws Exception {
    String sql =
        "SELECT cm.message_id, cm.subject, cm.message_content, cm.status, cm.created_at, " +
        "       (SELECT COUNT(*) FROM contact_messages r WHERE r.parent_id = cm.message_id) AS reply_count, " +
        "       (SELECT MAX(r2.created_at) FROM contact_messages r2 WHERE r2.parent_id = cm.message_id) AS last_reply_at, " +
        "       (SELECT TOP 1 r3.message_content FROM contact_messages r3 " +
        "        WHERE r3.parent_id = cm.message_id AND r3.sender_role = 'ADMIN' " +
        "        ORDER BY r3.created_at DESC) AS last_admin_reply " +
        "FROM contact_messages cm " +
        "WHERE cm.user_id = ? AND cm.parent_id IS NULL " +
        "ORDER BY cm.created_at DESC";

    List<Map<String,Object>> list = new ArrayList<>();
    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, userId);
        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("message_id",       rs.getInt("message_id"));
                m.put("subject",          rs.getString("subject"));
                m.put("message_content",  rs.getString("message_content"));
                m.put("status",           rs.getString("status"));
                m.put("created_at",       rs.getTimestamp("created_at"));
                m.put("reply_count",      rs.getInt("reply_count"));
                m.put("last_reply_at",    rs.getTimestamp("last_reply_at"));
                m.put("last_admin_reply", rs.getString("last_admin_reply"));
                list.add(m);
            }
        }
    }
    return list;
}

// ===== PRODUCT SEARCH (ADMIN) =====
public int countProductsAdminSearch(String kw) throws Exception {
    String sql =
        "SELECT COUNT(*) " +
        "FROM dbo.products p " +
        "WHERE p.name LIKE ?";

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setString(1, "%" + kw + "%");
        try (ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }
}


public List<Map<String,Object>> listProductsAdminSearchPaged(String kw, int page, int pageSize) throws Exception {
    List<Map<String,Object>> list = new ArrayList<>();
    int offset = (page - 1) * pageSize;

    String sql =
        "SELECT p.product_id, p.name, p.price, p.thumbnail, " +
        "       ISNULL(SUM(ps.quantity),0) AS total_stock " +   // ✅ dùng quantity
        "FROM dbo.products p " +
        "LEFT JOIN dbo.product_sizes ps ON ps.product_id = p.product_id " +
        "WHERE p.name LIKE ? " +
        "GROUP BY p.product_id, p.name, p.price, p.thumbnail " +
        "ORDER BY p.product_id DESC " +
        "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

    try (Connection con = getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {

        ps.setString(1, "%" + kw + "%");
        ps.setInt(2, offset);
        ps.setInt(3, pageSize);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("product_id", rs.getInt("product_id"));
                m.put("name", rs.getString("name"));
                m.put("price", rs.getInt("price"));
                m.put("thumbnail", rs.getString("thumbnail"));
                m.put("total_stock", rs.getInt("total_stock"));
                list.add(m);
            }
        }
    }
    return list;
}


}
