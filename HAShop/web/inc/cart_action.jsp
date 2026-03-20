<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="java.net.URLEncoder"%>
<%@page import="dal.ProductDAO"%>
<%@page import="dal.CartDAO"%>
<%@page import="model.Product"%>
<%@page import="model.User"%>

<%
    request.setCharacterEncoding("UTF-8");

    User u = (User) session.getAttribute("user");
    boolean loggedIn = (u != null);

    // session cart để guest dùng + merge sau login
    List<Map<String,Object>> cart = (List<Map<String,Object>>) session.getAttribute("cart");
    if (cart == null) {
        cart = new ArrayList<>();
        session.setAttribute("cart", cart);
    }

    String action = request.getParameter("action");
    if (action == null) action = "";

    int id = 0, qty = 1;
    String sizeStr = "";

    try { if (request.getParameter("id") != null) id = Integer.parseInt(request.getParameter("id")); } catch(Exception e){}
    try { if (request.getParameter("qty") != null) qty = Integer.parseInt(request.getParameter("qty")); } catch(Exception e){ qty = 1; }
    if (qty < 1) qty = 1;

    if (request.getParameter("size") != null) sizeStr = request.getParameter("size");

    DecimalFormat df = new DecimalFormat("#,###");

    // ===== ADD =====
    if ("add".equalsIgnoreCase(action)) {

        if (id <= 0 || sizeStr == null || sizeStr.trim().isEmpty()) {
            response.sendRedirect("index.jsp?module=product_detail&id=" + id);
            return;
        }

        int size = 0;
        try { size = Integer.parseInt(sizeStr); } catch(Exception e){ size = 0; }
        if (size <= 0) {
            response.sendRedirect("index.jsp?module=product_detail&id=" + id + "&error=size");
            return;
        }

        ProductDAO pdao = new ProductDAO();
        Product pr = null;
        try { pr = pdao.getById(id); } catch(Exception e){ pr = null; }

        if (pr == null) {
            response.sendRedirect("index.jsp?module=product_detail&id=" + id + "&error=notfound");
            return;
        }

        String name = pr.getName();
        int price = pr.getPrice();
        String img = (pr.getThumbnail() != null && !pr.getThumbnail().trim().isEmpty())
                ? pr.getThumbnail()
                : "images/products/demo/sp1.jpg";

        if (loggedIn) {
            CartDAO cdao = new CartDAO();
            cdao.addOrMergeItem(u.getId(), id, size, qty, price);

            // clear guest cart để tránh lệch
            cart.clear();

            int count = cdao.countItems(u.getId());
            session.setAttribute("cartCount", count);

            String idBack = request.getParameter("idBack");
            if (idBack == null || idBack.trim().isEmpty()) idBack = String.valueOf(id);

            String url = "index.jsp?module=product_detail&id=" + idBack
                    + "&added=1"
                    + "&addedName=" + URLEncoder.encode(name, "UTF-8")
                    + "&addedPrice=" + URLEncoder.encode(df.format(price) + "đ", "UTF-8")
                    + "&addedSize=" + URLEncoder.encode(sizeStr, "UTF-8")
                    + "&addedImg=" + URLEncoder.encode(img, "UTF-8")
                    + "&addedQty=" + URLEncoder.encode(String.valueOf(qty), "UTF-8")
                    + "&addedCount=" + URLEncoder.encode("Giỏ hàng của bạn hiện có " + count + " sản phẩm", "UTF-8");

            response.sendRedirect(url);
            return;

        } else {
            // guest: dùng session cart như cũ
            boolean merged = false;
            for (Map<String,Object> it : cart) {
                int pid = (Integer) it.get("id");
                String psz = (String) it.get("size");
                if (pid == id && psz != null && psz.equals(sizeStr)) {
                    int old = (Integer) it.get("qty");
                    it.put("qty", old + qty);
                    merged = true;
                    break;
                }
            }

            if (!merged) {
                Map<String,Object> item = new HashMap<>();
                item.put("id", id);
                item.put("name", name);
                item.put("price", price);
                item.put("img", img);
                item.put("size", sizeStr);
                item.put("qty", qty);
                cart.add(item);
            }

            int count = 0;
            for (Map<String,Object> it : cart) count += (Integer) it.get("qty");
            session.setAttribute("cartCount", count);

            String idBack = request.getParameter("idBack");
            if (idBack == null || idBack.trim().isEmpty()) idBack = String.valueOf(id);

            String url = "index.jsp?module=product_detail&id=" + idBack
                    + "&added=1"
                    + "&addedName=" + URLEncoder.encode(name, "UTF-8")
                    + "&addedPrice=" + URLEncoder.encode(df.format(price) + "đ", "UTF-8")
                    + "&addedSize=" + URLEncoder.encode(sizeStr, "UTF-8")
                    + "&addedImg=" + URLEncoder.encode(img, "UTF-8")
                    + "&addedQty=" + URLEncoder.encode(String.valueOf(qty), "UTF-8")
                    + "&addedCount=" + URLEncoder.encode("Giỏ hàng của bạn hiện có " + count + " sản phẩm", "UTF-8");

            response.sendRedirect(url);
            return;
        }
    }

    // ===== REMOVE =====
    if ("remove".equalsIgnoreCase(action)) {
        if (loggedIn) {
            int pid = 0, size = 0;
            try { pid = Integer.parseInt(request.getParameter("id")); } catch(Exception e){}
            try { size = Integer.parseInt(request.getParameter("size")); } catch(Exception e){}

            if (pid > 0 && size > 0) {
                CartDAO cdao = new CartDAO();
                cdao.removeItem(u.getId(), pid, size);
                session.setAttribute("cartCount", cdao.countItems(u.getId()));
            }
        } else {
            int idx = -1;
            try { idx = Integer.parseInt(request.getParameter("idx")); } catch(Exception e){}
            if (idx >= 0 && idx < cart.size()) cart.remove(idx);

            int count = 0;
            for (Map<String,Object> it : cart) count += (Integer) it.get("qty");
            session.setAttribute("cartCount", count);
        }

        response.sendRedirect("index.jsp?module=cart");
        return;
    }

    // ===== UPDATE =====
    if ("update".equalsIgnoreCase(action)) {
        int newQty = 1;
        try { newQty = Integer.parseInt(request.getParameter("qty")); } catch(Exception e){ newQty = 1; }
        if (newQty < 1) newQty = 1;

        if (loggedIn) {
            int pid = 0, size = 0;
            try { pid = Integer.parseInt(request.getParameter("id")); } catch(Exception e){}
            try { size = Integer.parseInt(request.getParameter("size")); } catch(Exception e){}

            if (pid > 0 && size > 0) {
                CartDAO cdao = new CartDAO();
                cdao.updateQty(u.getId(), pid, size, newQty);
                session.setAttribute("cartCount", cdao.countItems(u.getId()));
            }
        } else {
            int idx = -1;
            try { idx = Integer.parseInt(request.getParameter("idx")); } catch(Exception e){}
            if (idx >= 0 && idx < cart.size()) cart.get(idx).put("qty", newQty);

            int count = 0;
            for (Map<String,Object> it : cart) count += (Integer) it.get("qty");
            session.setAttribute("cartCount", count);
        }

        response.sendRedirect("index.jsp?module=cart");
        return;
    }

    // ===== CLEAR =====
    if ("clear".equalsIgnoreCase(action)) {
        if (loggedIn) {
            CartDAO cdao = new CartDAO();
            cdao.clearCart(u.getId());
            session.setAttribute("cartCount", 0);
        } else {
            cart.clear();
            session.setAttribute("cartCount", 0);
        }

        response.sendRedirect("index.jsp?module=cart");
        return;
    }

    response.sendRedirect("index.jsp?module=cart");
%>
