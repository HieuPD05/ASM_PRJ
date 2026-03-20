package controller;

import dal.AdminDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

public class AdminMessageServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String action = nvl(req.getParameter("action"));
        String filter = nvl(req.getParameter("filter"));
        if (filter.trim().isEmpty()) filter = "all";

        int page = parseInt(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        int threadId = parseInt(req.getParameter("thread_id"), 0);

        try {
            AdminDAO dao = new AdminDAO();

            // ===== Admin reply vào thread =====
            if ("reply".equalsIgnoreCase(action)) {
                String replyContent = nvl(req.getParameter("content")).trim();

                if (threadId > 0 && !replyContent.isEmpty()) {
                    dao.adminReplyThread(threadId, replyContent);
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=admin_message_detail&id=" + threadId
                            + "&filter=" + filter + "&page=" + page + "&ok=replied");
                } else {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=admin_message_detail&id=" + threadId
                            + "&filter=" + filter + "&page=" + page + "&err=missing");
                }
                return;
            }

            // ===== Admin đóng thread =====
            if ("close".equalsIgnoreCase(action)) {
                if (threadId > 0) {
                    dao.closeContactThread(threadId);
                }
                resp.sendRedirect(req.getContextPath()
                        + "/index.jsp?module=admin_messages&filter=" + filter + "&page=" + page + "&msg=closed");
                return;
            }

            resp.sendRedirect(req.getContextPath()
                    + "/index.jsp?module=admin_messages&filter=" + filter + "&page=" + page);

        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private String nvl(String s) { return s == null ? "" : s; }
    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }
}
