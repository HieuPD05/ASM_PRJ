package controller;

import dal.AdminDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize       = 10 * 1024 * 1024,
    maxRequestSize    = 50 * 1024 * 1024
)
public class AdminProductServlet extends HttpServlet {

    private static final int[] DEFAULT_SIZES = {38, 39, 40, 41, 42, 43};

    // Lưu ảnh vào webroot/images/products/upload/ — tồn tại cùng project
    private static final String IMG_REL = "images/products/upload/";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        if (action == null) action = "";

        String p = req.getParameter("p");
        if (p == null || p.trim().isEmpty()) p = "1";

        // Thư mục lưu ảnh: dùng getRealPath để ghi file vào đúng webroot
        String uploadDir = getServletContext().getRealPath("/" + IMG_REL);
        new File(uploadDir).mkdirs();

        try {
            AdminDAO dao = new AdminDAO();

            if ("create".equalsIgnoreCase(action)) {

                int brandId = parseInt(req.getParameter("brand_id"), 0);
                if (brandId <= 0) {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=admin_products&showForm=1&p=" + p + "&msg=brand_required");
                    return;
                }

                Integer categoryId = parseIntObj(req.getParameter("category_id"));
                String name    = req.getParameter("name");
                int    price   = parseInt(req.getParameter("price"), 0);
                String target  = req.getParameter("target");
                String desc    = req.getParameter("description");

                // fieldName trong form: main_image, img_extra_1/2/3 (file input)
                // old_* = hidden fallback (khi create thường rỗng)
                String mainImg = uploadFile(req, "main_image",  uploadDir, req.getParameter("old_main_image"));
                String img1    = uploadFile(req, "img_extra_1", uploadDir, req.getParameter("old_img1"));
                String img2    = uploadFile(req, "img_extra_2", uploadDir, req.getParameter("old_img2"));
                String img3    = uploadFile(req, "img_extra_3", uploadDir, req.getParameter("old_img3"));

                Map<Integer, Integer> sizeQty = readSizeQty(req);

                dao.createProduct(categoryId, brandId, name, price, target, desc,
                        mainImg, img1, img2, img3, sizeQty);

                resp.sendRedirect(req.getContextPath()
                        + "/index.jsp?module=admin_products&msg=created&p=" + p);

            } else if ("update".equalsIgnoreCase(action)) {

                int id      = parseInt(req.getParameter("product_id"), 0);
                int brandId = parseInt(req.getParameter("brand_id"), 0);
                if (brandId <= 0) {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=admin_products&edit_id=" + id
                            + "&showForm=1&p=" + p + "&msg=brand_required");
                    return;
                }

                Integer categoryId = parseIntObj(req.getParameter("category_id"));
                String name    = req.getParameter("name");
                int    price   = parseInt(req.getParameter("price"), 0);
                String target  = req.getParameter("target");
                String desc    = req.getParameter("description");

                // Nếu không upload ảnh mới → giữ nguyên đường dẫn ảnh cũ
                String mainImg = uploadFile(req, "main_image",  uploadDir, req.getParameter("old_main_image"));
                String img1    = uploadFile(req, "img_extra_1", uploadDir, req.getParameter("old_img1"));
                String img2    = uploadFile(req, "img_extra_2", uploadDir, req.getParameter("old_img2"));
                String img3    = uploadFile(req, "img_extra_3", uploadDir, req.getParameter("old_img3"));

                Map<Integer, Integer> sizeQty = readSizeQty(req);

                dao.updateProduct(id, categoryId, brandId, name, price, target, desc,
                        mainImg, img1, img2, img3, sizeQty);

                resp.sendRedirect(req.getContextPath()
                        + "/index.jsp?module=admin_products&msg=updated&p=" + p);

            } else if ("delete".equalsIgnoreCase(action)) {

                int id = parseInt(req.getParameter("product_id"), 0);

                if (dao.hasOrderItems(id)) {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=admin_products&msg=delete_blocked_order&p=" + p);
                    return;
                }
                if (dao.hasCartItems(id)) {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=admin_products&msg=delete_blocked_cart&p=" + p);
                    return;
                }

                dao.deleteProduct(id);
                resp.sendRedirect(req.getContextPath()
                        + "/index.jsp?module=admin_products&msg=deleted&p=" + p);

            } else {
                resp.sendRedirect(req.getContextPath() + "/index.jsp?module=admin_products&p=" + p);
            }

        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    /**
     * Nếu admin chọn file mới → upload và trả về đường dẫn mới.
     * Nếu không → trả về fallback (đường dẫn ảnh cũ từ hidden field).
     */
    private String uploadFile(HttpServletRequest req,
                               String fieldName,
                               String uploadDir,
                               String fallback) throws IOException, ServletException {

        Part part = null;
        try { part = req.getPart(fieldName); } catch (Exception e) { /* không có part */ }

        if (part != null && part.getSize() > 0) {
            String original = Paths.get(part.getSubmittedFileName()).getFileName().toString();
            String ext = ".jpg";
            int dot = original.lastIndexOf('.');
            if (dot >= 0) {
                String e = original.substring(dot).toLowerCase();
                if (e.matches("\\.(jpg|jpeg|png|gif|webp|bmp)")) ext = e;
            }

            String savedName = UUID.randomUUID().toString().replace("-", "") + ext;
            String fullPath  = uploadDir + File.separator + savedName;

            try (InputStream in = part.getInputStream()) {
                Files.copy(in, Paths.get(fullPath), StandardCopyOption.REPLACE_EXISTING);
            }

            return IMG_REL + savedName;   // đường dẫn tương đối lưu vào DB
        }

        // Không có file mới → giữ ảnh cũ
        return (fallback != null) ? fallback.trim() : "";
    }

    private Map<Integer, Integer> readSizeQty(HttpServletRequest req) {
        Map<Integer, Integer> map = new LinkedHashMap<>();
        for (int s : DEFAULT_SIZES) {
            int q = parseInt(req.getParameter("qty_" + s), 0);
            map.put(s, Math.max(0, q));
        }
        return map;
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }

    private Integer parseIntObj(String s) {
        try {
            if (s == null || s.trim().isEmpty()) return null;
            return Integer.parseInt(s.trim());
        } catch (Exception e) { return null; }
    }
}
