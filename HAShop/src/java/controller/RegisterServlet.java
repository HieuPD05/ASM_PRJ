package controller;

import dal.UserDAO;
import util.HashUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import java.io.IOException;

public class RegisterServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect("index.jsp?module=register");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String fullName = req.getParameter("full_name");
        String email    = req.getParameter("username"); // UI đang dùng name="username" để nhập email
        String phone    = req.getParameter("phone");
        String password = req.getParameter("password");
        String repass   = req.getParameter("repassword");

        fullName = (fullName == null) ? "" : fullName.trim();
        email    = (email == null) ? "" : email.trim();
        phone    = (phone == null) ? "" : phone.trim();
        password = (password == null) ? "" : password;

        if (fullName.isEmpty() || email.isEmpty() || password.isEmpty()) {
            resp.sendRedirect("index.jsp?module=register&error=missing");
            return;
        }

        if (repass != null && !repass.isEmpty() && !password.equals(repass)) {
            resp.sendRedirect("index.jsp?module=register&error=notmatch");
            return;
        }

        try {
            UserDAO dao = new UserDAO();

            if (dao.emailExists(email)) {
                resp.sendRedirect("index.jsp?module=register&error=exists");
                return;
            }

            // role_id: 1 = USER
            String passHash = HashUtil.sha256Hex(password);
            dao.register(fullName, email, phone.isEmpty() ? null : phone, passHash, 1);

            resp.sendRedirect("index.jsp?module=login&msg=registered");
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }
}
