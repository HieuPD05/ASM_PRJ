package controller;

import dal.UserDAO;
import dal.CartDAO;
import model.User;
import util.HashUtil;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String email = req.getParameter("username");
        String password = req.getParameter("password");

        try {
            UserDAO dao = new UserDAO();
            String hash = HashUtil.sha256Hex(password == null ? "" : password);

            User u = dao.findByEmailAndPass(email, hash);

            if (u == null) {
                resp.sendRedirect("index.jsp?module=login&error=1");
                return;
            }

            HttpSession session = req.getSession();
            session.setAttribute("user", u);
            session.setAttribute("username", u.getEmail());
            session.setAttribute("role", u.getRole());
            session.setAttribute("fullname", u.getFullName());

            // ===== MERGE SESSION CART -> DB CART =====
            CartDAO cdao = new CartDAO();

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> sessionCart =
                    (List<Map<String, Object>>) session.getAttribute("cart");

            cdao.mergeSessionCartToUser(u.getId(), sessionCart);

            if (sessionCart != null) sessionCart.clear();

            session.setAttribute("cartCount", cdao.countItems(u.getId()));

            // quay lại URL trước khi login
            String afterLoginUrl = (String) session.getAttribute("afterLoginUrl");
            if (afterLoginUrl != null && !afterLoginUrl.trim().isEmpty()) {
                session.removeAttribute("afterLoginUrl");
                resp.sendRedirect(afterLoginUrl);
                return;
            }

            if ("ADMIN".equalsIgnoreCase(u.getRole())) {
                resp.sendRedirect("index.jsp?module=admin_dashboard");
            } else {
                resp.sendRedirect("index.jsp?module=home");
            }

        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
