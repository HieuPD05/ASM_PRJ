package dal;

import java.sql.*;
import java.util.*;
import model.Product;

public class ProductDAO extends DBContext {

    // ===== COUNT =====
    public int countActiveProducts() throws Exception {
        String sql = "SELECT COUNT(*) FROM dbo.products WHERE status = 1";
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            rs.next();
            return rs.getInt(1);
        }
    }

    // ===== LIST PAGED (PRODUCT PAGE) =====
    // sort: price-asc | price-desc
    public List<Product> listProductsPaged(int page, int pageSize, String sort) throws Exception {
        if (page < 1) page = 1;
        int offset = (page - 1) * pageSize;

        String orderBy = "p.product_id DESC";
        if ("price-asc".equalsIgnoreCase(sort)) orderBy = "p.price ASC";
        else if ("price-desc".equalsIgnoreCase(sort)) orderBy = "p.price DESC";

        String sql =
            "SELECT p.product_id, p.name, p.price, p.thumbnail, p.description, p.target, p.slug, " +
            "       b.brand_name AS brand_name " +
            "FROM dbo.products p " +
            "LEFT JOIN dbo.brands b ON p.brand_id = b.brand_id " +
            "WHERE p.status = 1 " +
            "ORDER BY " + orderBy + " " +
            "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

        List<Product> list = new ArrayList<>();
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, offset);
            ps.setInt(2, pageSize);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("product_id"));
                    p.setName(rs.getString("name"));
                    p.setPrice(rs.getInt("price"));
                    p.setThumbnail(rs.getString("thumbnail"));
                    p.setDescription(rs.getString("description"));
                    p.setBrandName(rs.getString("brand_name"));
                    list.add(p);
                }
            }
        }
        return list;
    }

    // ===== HOME: LATEST PRODUCTS =====
    public List<Product> listLatestProducts(int limit) throws Exception {
        if (limit < 1) limit = 8;

        String sql =
            "SELECT TOP (?) p.product_id, p.name, p.price, p.thumbnail, p.description, p.target, p.slug, " +
            "       b.brand_name AS brand_name " +
            "FROM dbo.products p " +
            "LEFT JOIN dbo.brands b ON p.brand_id = b.brand_id " +
            "WHERE p.status = 1 " +
            "ORDER BY p.product_id DESC";

        List<Product> list = new ArrayList<>();
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, limit);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("product_id"));
                    p.setName(rs.getString("name"));
                    p.setPrice(rs.getInt("price"));
                    p.setThumbnail(rs.getString("thumbnail"));
                    p.setDescription(rs.getString("description"));
                    p.setBrandName(rs.getString("brand_name"));
                    list.add(p);
                }
            }
        }
        return list;
    }

    // ===== GET BY ID (DETAIL PAGE) =====
    public Product getById(int id) throws Exception {
        String sql =
            "SELECT p.product_id, p.name, p.price, p.thumbnail, p.description, p.status, " +
            "       b.brand_name AS brand_name " +
            "FROM dbo.products p " +
            "LEFT JOIN dbo.brands b ON p.brand_id = b.brand_id " +
            "WHERE p.product_id = ?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;

                int st = rs.getInt("status");
                if (st != 1) return null;

                Product p = new Product();
                p.setId(rs.getInt("product_id"));
                p.setName(rs.getString("name"));
                p.setPrice(rs.getInt("price"));
                p.setThumbnail(rs.getString("thumbnail"));
                p.setDescription(rs.getString("description"));
                p.setBrandName(rs.getString("brand_name"));
                return p;
            }
        }
    }

    // ===== PRODUCT IMAGES (DETAIL THUMBS) =====
    public List<String> listImageUrls(int productId) throws Exception {
        String sql =
            "SELECT image_url FROM dbo.product_images " +
            "WHERE product_id = ? ORDER BY sort_order ASC, image_id ASC";
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

    // ===== PRODUCT SIZES (IN STOCK) =====
    public List<String> listSizes(int productId) throws Exception {
        String sql =
            "SELECT size FROM dbo.product_sizes " +
            "WHERE product_id = ? AND quantity > 0 " +
            "ORDER BY size ASC";

        List<String> sizes = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, productId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    sizes.add(String.valueOf(rs.getInt("size")));
                }
            }
        }
        return sizes;
    }

    // ===== COUNT FILTERED =====
    public int countProductsFiltered(String q,
                                     String brandName,
                                     Integer minPrice, Integer maxPrice,
                                     Integer size,
                                     String target) throws Exception {

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT COUNT(DISTINCT p.product_id) ")
           .append("FROM dbo.products p ")
           .append("LEFT JOIN dbo.brands b ON p.brand_id = b.brand_id ")
           .append("LEFT JOIN dbo.product_sizes ps ON p.product_id = ps.product_id ")
           .append("WHERE p.status = 1 ");

        List<Object> params = new ArrayList<>();

        if (q != null && !q.trim().isEmpty()) {
            sql.append(" AND p.name LIKE ? ");
            params.add("%" + q.trim() + "%");
        }

        if (brandName != null && !brandName.trim().isEmpty()) {
            sql.append(" AND b.brand_name = ? ");
            params.add(brandName.trim());
        }

        if (minPrice != null) {
            sql.append(" AND p.price >= ? ");
            params.add(minPrice);
        }
        if (maxPrice != null) {
            sql.append(" AND p.price <= ? ");
            params.add(maxPrice);
        }

        if (target != null && !target.trim().isEmpty()) {
            sql.append(" AND p.target = ? ");
            params.add(target.trim());
        }

        if (size != null) {
            sql.append(" AND ps.quantity > 0 AND ps.size = ? ");
            params.add(size);
        }

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1);
            }
        }
    }

    // ===== LIST FILTERED =====
    public List<Product> listProductsFiltered(int page, int pageSize,
                                             String q,
                                             String brandName,
                                             Integer minPrice, Integer maxPrice,
                                             Integer size,
                                             String target,
                                             String sort) throws Exception {

        if (page < 1) page = 1;
        int offset = (page - 1) * pageSize;

        String orderBy = "p.product_id DESC";
        if ("price-asc".equalsIgnoreCase(sort)) orderBy = "p.price ASC";
        else if ("price-desc".equalsIgnoreCase(sort)) orderBy = "p.price DESC";

        StringBuilder sql = new StringBuilder();
        sql.append("SELECT DISTINCT p.product_id, p.name, p.price, p.thumbnail, p.description, ")
           .append("       b.brand_name AS brand_name ")
           .append("FROM dbo.products p ")
           .append("LEFT JOIN dbo.brands b ON p.brand_id = b.brand_id ")
           .append("LEFT JOIN dbo.product_sizes ps ON p.product_id = ps.product_id ")
           .append("WHERE p.status = 1 ");

        List<Object> params = new ArrayList<>();

        if (q != null && !q.trim().isEmpty()) {
            sql.append(" AND p.name LIKE ? ");
            params.add("%" + q.trim() + "%");
        }

        if (brandName != null && !brandName.trim().isEmpty()) {
            sql.append(" AND b.brand_name = ? ");
            params.add(brandName.trim());
        }

        if (minPrice != null) {
            sql.append(" AND p.price >= ? ");
            params.add(minPrice);
        }
        if (maxPrice != null) {
            sql.append(" AND p.price <= ? ");
            params.add(maxPrice);
        }

        if (target != null && !target.trim().isEmpty()) {
            sql.append(" AND p.target = ? ");
            params.add(target.trim());
        }

        if (size != null) {
            sql.append(" AND ps.quantity > 0 AND ps.size = ? ");
            params.add(size);
        }

        sql.append(" ORDER BY ").append(orderBy)
           .append(" OFFSET ? ROWS FETCH NEXT ? ROWS ONLY ");

        params.add(offset);
        params.add(pageSize);

        List<Product> list = new ArrayList<>();
        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {

            for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("product_id"));
                    p.setName(rs.getString("name"));
                    p.setPrice(rs.getInt("price"));
                    p.setThumbnail(rs.getString("thumbnail"));
                    p.setDescription(rs.getString("description"));
                    p.setBrandName(rs.getString("brand_name"));
                    list.add(p);
                }
            }
        }
        return list;
    }

    // ===== SEARCH SUGGEST (TOP N) =====
    public List<Product> searchSuggest(String keyword, int limit) throws Exception {
        if (limit < 1) limit = 3;
        if (keyword == null || keyword.trim().isEmpty()) return new ArrayList<>();

        String sql =
            "SELECT TOP (?) p.product_id, p.name, p.price, p.thumbnail " +
            "FROM dbo.products p " +
            "WHERE p.status = 1 AND p.name LIKE ? " +
            "ORDER BY p.product_id DESC";

        List<Product> list = new ArrayList<>();

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, limit);
            ps.setString(2, "%" + keyword.trim() + "%");

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Product p = new Product();
                    p.setId(rs.getInt("product_id"));
                    p.setName(rs.getString("name"));
                    p.setPrice(rs.getInt("price"));
                    p.setThumbnail(rs.getString("thumbnail"));
                    list.add(p);
                }
            }
        }

        return list;
    }
}
