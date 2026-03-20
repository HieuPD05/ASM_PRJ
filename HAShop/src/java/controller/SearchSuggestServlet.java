package controller;

import dal.ProductDAO;
import model.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

public class SearchSuggestServlet extends HttpServlet {

    private static String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json; charset=UTF-8");

        String q = req.getParameter("q");
        if (q == null) q = "";
        q = q.trim();

        // nếu gõ quá ngắn thì trả rỗng
        if (q.length() < 1) {
            resp.getWriter().write("{\"items\":[]}");
            return;
        }

        try {
            ProductDAO dao = new ProductDAO();
            List<Product> list = dao.searchSuggest(q, 3);

            StringBuilder sb = new StringBuilder();
            sb.append("{\"items\":[");
            for (int i = 0; i < list.size(); i++) {
                Product p = list.get(i);
                if (i > 0) sb.append(",");

                sb.append("{");
                sb.append("\"id\":").append(p.getId()).append(",");
                sb.append("\"name\":\"").append(escJson(p.getName())).append("\",");
                sb.append("\"price\":").append(p.getPrice()).append(",");
                sb.append("\"thumbnail\":\"").append(escJson(p.getThumbnail())).append("\"");
                sb.append("}");
            }
            sb.append("]}");

            resp.getWriter().write(sb.toString());

        } catch (Exception e) {
            // trả json rỗng để UI không crash
            resp.getWriter().write("{\"items\":[]}");
        }
    }
}
