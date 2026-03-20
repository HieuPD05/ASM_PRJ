package controller;

import dal.AdminDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import model.User;

import java.io.IOException;

public class ContactServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        User u = (User) session.getAttribute("user");
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp?module=login&return=contact");
            return;
        }

        String action = nvl(req.getParameter("action")).trim();

        try {
            AdminDAO dao = new AdminDAO();

            // ===== User reply tiếp vào thread đã có =====
            if ("user_reply".equalsIgnoreCase(action)) {
                int threadId   = parseInt(req.getParameter("thread_id"), 0);
                String content = nvl(req.getParameter("content")).trim();

                if (threadId > 0 && !content.isEmpty()) {
                    dao.userReplyThread(threadId, u.getId(), u.getFullName(), content);
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=contact&thread=" + threadId + "&ok=replied");
                } else {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=contact&thread=" + threadId + "&err=missing");
                }
                return;
            }

            // ===== Tạo thread liên hệ mới =====
            String name    = nvl(req.getParameter("name")).trim();
            String email   = nvl(req.getParameter("email")).trim();
            String phone   = nvl(req.getParameter("phone")).trim();
            String subject = nvl(req.getParameter("subject")).trim();
            String message = nvl(req.getParameter("message")).trim();

            if (name.isEmpty() || email.isEmpty() || message.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/index.jsp?module=contact&err=missing");
                return;
            }

            int newThreadId = dao.createContactThread(u.getId(), name, email, phone, subject, message);
            resp.sendRedirect(req.getContextPath()
                    + "/index.jsp?module=contact&thread=" + newThreadId + "&ok=sent");

        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private String nvl(String s) { return s == null ? "" : s; }
    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }
}
