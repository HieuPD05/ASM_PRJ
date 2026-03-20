package controller;

import dal.CartDAO;
import dal.OrderDAO;
import dal.ProductDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.*;

import model.Product;
import model.User;

public class PlaceOrderServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession();

        User u = (User) session.getAttribute("user");
        if (u == null) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp?module=login");
            return;
        }

        String receiverName  = req.getParameter("receiver_name");
        String receiverPhone = req.getParameter("receiver_phone");
        String receiverAddr  = req.getParameter("receiver_addr");
        String email         = req.getParameter("email");
        String note          = req.getParameter("note");
        String pay           = req.getParameter("payment_method");
        if (pay == null || pay.trim().isEmpty()) pay = "COD";

        if (receiverName == null || receiverName.trim().isEmpty()
                || receiverPhone == null || receiverPhone.trim().isEmpty()
                || receiverAddr == null || receiverAddr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/index.jsp?module=checkout&error=missing");
            return;
        }

        String mode = req.getParameter("mode");
        if (mode == null) mode = "cart";
        mode = mode.trim().toLowerCase();

        List<Map<String, Object>> orderItems = new ArrayList<>();

        try {
            if ("buynow".equals(mode)) {
                int id = 0, qty = 1;
                String size = req.getParameter("size");

                try { id = Integer.parseInt(req.getParameter("id")); } catch (Exception e) { id = 0; }
                try { qty = Integer.parseInt(req.getParameter("qty")); } catch (Exception e) { qty = 1; }
                if (qty < 1) qty = 1;

                ProductDAO pdao = new ProductDAO();
                Product pr = pdao.getById(id);

                if (pr == null) {
                    resp.sendRedirect(req.getContextPath()
                            + "/index.jsp?module=checkout&mode=buynow&id=" + id + "&error=notfound");
                    return;
                }

                Map<String, Object> one = new HashMap<>();
                one.put("id", pr.getId());
                one.put("name", pr.getName());
                one.put("price", pr.getPrice());
                one.put("img", (pr.getThumbnail() != null && !pr.getThumbnail().trim().isEmpty())
                        ? pr.getThumbnail().trim()
                        : "images/products/demo/sp1.jpg");
                one.put("size", (size == null ? "" : size));
                one.put("qty", qty);

                orderItems.add(one);

            } else {
                CartDAO cdao = new CartDAO();
                orderItems = cdao.listItems(u.getId());

                if (orderItems == null || orderItems.isEmpty()) {
                    resp.sendRedirect(req.getContextPath() + "/index.jsp?module=cart");
                    return;
                }
            }

            OrderDAO dao = new OrderDAO();
            int orderId = dao.createOrder(
                    u.getId(),
                    receiverName.trim(),
                    receiverPhone.trim(),
                    receiverAddr.trim(),
                    email,
                    note,
                    pay,
                    orderItems
            );

            // Clear giỏ hàng sau khi đặt thành công
            if (!"buynow".equals(mode)) {
                CartDAO cdao = new CartDAO();
                cdao.clearCart(u.getId());
                session.setAttribute("cartCount", 0);
                session.setAttribute("cart", new ArrayList<Map<String,Object>>());
            }

            resp.sendRedirect(req.getContextPath() + "/index.jsp?module=order_success&id=" + orderId);

        } catch (Exception e) {
            // Lỗi tồn kho hoặc nghiệp vụ: redirect về checkout với thông báo lỗi thân thiện
            String errMsg = e.getMessage();
            if (errMsg != null && (errMsg.contains("kho") || errMsg.contains("hết hàng")
                    || errMsg.contains("không đủ") || errMsg.contains("race"))) {
                String encoded = java.net.URLEncoder.encode(errMsg, "UTF-8");
                String backModule = "buynow".equals(mode)
                        ? "checkout&mode=buynow&id=" + req.getParameter("id")
                        : "checkout";
                resp.sendRedirect(req.getContextPath()
                        + "/index.jsp?module=" + backModule + "&error=stock&msg=" + encoded);
            } else {
                throw new ServletException(e);
            }
        }
    }
}
