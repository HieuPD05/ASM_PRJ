package controller;

import dal.AdminDAO;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;

public class AdminOrderServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if (action == null) action = "";

        int page = parseInt(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        // Giữ filter user_id nếu đang lọc theo khách
        String userIdParam = req.getParameter("user_id");
        String base = req.getContextPath() + "/index.jsp?module=admin_orders&page=" + page;
        if (userIdParam != null && !userIdParam.trim().isEmpty()) {
            base += "&user_id=" + userIdParam;
        }

        try {
            AdminDAO dao = new AdminDAO();

            if ("status".equalsIgnoreCase(action)) {
                int orderId = parseInt(req.getParameter("order_id"), 0);
                String newStatus = req.getParameter("status");

                try {
                    dao.updateOrderStatus(orderId, newStatus);
                    resp.sendRedirect(base + "&msg=updated");
                } catch (Exception e) {
                    // Lỗi nghiệp vụ (sai chiều chuyển trạng thái)
                    String errMsg = java.net.URLEncoder.encode(e.getMessage(), "UTF-8");
                    resp.sendRedirect(base + "&msg=status_error&errmsg=" + errMsg);
                }
                return;
            }

            if ("delete".equalsIgnoreCase(action)) {
                int orderId = parseInt(req.getParameter("order_id"), 0);
                boolean ok = dao.deleteOrder(orderId);
                resp.sendRedirect(base + "&msg=" + (ok ? "deleted" : "delete_fail"));
                return;
            }

            resp.sendRedirect(base);

        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }
}
