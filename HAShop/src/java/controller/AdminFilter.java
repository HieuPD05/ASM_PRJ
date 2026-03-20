package controller;

import jakarta.servlet.*;
import jakarta.servlet.http.*;
import java.io.IOException;
import model.User;

public class AdminFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String module = req.getParameter("module");
        if (module != null && module.startsWith("admin_")) {

            HttpSession session = req.getSession(false);
            User u = (session != null) ? (User) session.getAttribute("user") : null;

            if (u == null || u.getRole() == null || !"ADMIN".equalsIgnoreCase(u.getRole())) {

                // lưu full URL để login xong quay lại đúng trang (có cả id, p,...)
                String qs = req.getQueryString(); // ví dụ: module=admin_news_form&id=3
                String back = "index.jsp" + (qs != null ? ("?" + qs) : "");

                if (session == null) session = req.getSession(true);
                session.setAttribute("afterLoginUrl", back);

                resp.sendRedirect("index.jsp?module=login&error=need_admin");
                return;
            }
        }

        chain.doFilter(request, response);
    }
}
