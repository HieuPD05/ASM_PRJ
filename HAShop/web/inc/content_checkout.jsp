<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.ProductDAO"%>
<%@page import="dal.CartDAO"%>
<%@page import="model.Product"%>
<%@page import="model.User"%>

<%
  request.setCharacterEncoding("UTF-8");
  DecimalFormat df = new DecimalFormat("#,###");

  User u = (User) session.getAttribute("user");
  boolean loggedIn = (u != null);

  String mode = request.getParameter("mode");
  if (mode == null || mode.trim().isEmpty()) mode = "cart";
  mode = mode.trim().toLowerCase();
  boolean isBuyNow = "buynow".equals(mode);

  // ===== LẤY GIỎ HÀNG ĐÚNG (DB nếu login, session nếu guest) =====
  List<Map<String, Object>> cartSession = (List<Map<String, Object>>) session.getAttribute("cart");
  if (cartSession == null) {
    cartSession = new ArrayList<>();
    session.setAttribute("cart", cartSession);
  }

  List<Map<String, Object>> orderItems = new ArrayList<>();
  long total = 0;

  int id = 0;
  int qty = 1;
  String size = "";

  if (isBuyNow) {
    try { id = Integer.parseInt(request.getParameter("id")); } catch (Exception e) { id = 0; }
    try { qty = Integer.parseInt(request.getParameter("qty")); } catch (Exception e) { qty = 1; }
    if (qty < 1) qty = 1;
    if (request.getParameter("size") != null) size = request.getParameter("size");

    ProductDAO pdao = new ProductDAO();
    Product pr = null;
    try { pr = pdao.getById(id); } catch (Exception e) { pr = null; }

    if (pr != null) {
      Map<String, Object> one = new HashMap<>();
      one.put("id", pr.getId());
      one.put("name", pr.getName());
      one.put("price", pr.getPrice());
      one.put("img", (pr.getThumbnail() != null && !pr.getThumbnail().trim().isEmpty())
              ? pr.getThumbnail().trim()
              : "images/products/demo/sp1.jpg");
      one.put("size", size);
      one.put("qty", qty);

      orderItems.add(one);
      total = (long) pr.getPrice() * qty;
    }

  } else {
    if (loggedIn) {
      CartDAO cdao = new CartDAO();
      orderItems = cdao.listItems(u.getId());                 // ✅ lấy từ DB
      session.setAttribute("cartCount", cdao.countItems(u.getId()));
    } else {
      orderItems = cartSession;                               // ✅ guest dùng session
    }

    for (Map<String, Object> it : orderItems) {
      int pr = (Integer) it.get("price");
      int q = (Integer) it.get("qty");
      total += (long) pr * q;
    }
  }

  int itemCount = 0;
  for (Map<String, Object> it : orderItems) {
    try { itemCount += (Integer) it.get("qty"); } catch (Exception e) {}
  }

  String err = request.getParameter("error");
%>

<div class="ck-wrap">

  <form method="post" action="place-order" style="display:contents;">
    <input type="hidden" name="mode" value="<%=isBuyNow ? "buynow" : "cart"%>"/>

    <% if (isBuyNow) { %>
      <input type="hidden" name="id" value="<%=id%>"/>
      <input type="hidden" name="qty" value="<%=qty%>"/>
      <input type="hidden" name="size" value="<%= (size == null ? "" : size) %>"/>
    <% } %>

    <!-- LEFT -->
    <div class="ck-left">

      <div class="ck-card">
        <h2 class="ck-title">Thông tin nhận hàng</h2>

        <% if ("missing".equals(err)) { %>
          <div style="margin:10px 0; padding:10px 12px; background:#ffecec; border:1px solid #ffd1d1; border-radius:10px;">
            Vui lòng nhập đủ họ tên, số điện thoại và địa chỉ.
          </div>
        <% } else if ("stock".equals(err)) {
             String stockMsg = request.getParameter("msg");
             if (stockMsg == null || stockMsg.trim().isEmpty()) stockMsg = "Một sản phẩm trong giỏ hàng không đủ số lượng trong kho.";
        %>
          <div style="margin:10px 0; padding:12px 14px; background:#fff3cd; border:1px solid #ffc107; border-radius:10px; color:#856404;">
            ⚠️ <b>Không thể đặt hàng:</b> <%=stockMsg%>
          </div>
        <% } %>

        <div class="ck-grid2">
          <div class="ck-field">
            <label>Họ và tên</label>
            <input type="text" name="receiver_name" placeholder="Nhập họ tên" required>
          </div>

          <div class="ck-field">
            <label>Số điện thoại</label>
            <input type="text" name="receiver_phone" placeholder="Nhập số điện thoại" required>
          </div>

          <div class="ck-field ck-span2">
            <label>Địa chỉ</label>
            <input type="text" name="receiver_addr" placeholder="Nhập địa chỉ" required>
          </div>

          <div class="ck-field ck-span2">
            <label>Email</label>
            <input type="text" name="email" placeholder="Nhập email">
          </div>

          <div class="ck-field ck-span2">
            <label>Ghi chú (tuỳ chọn)</label>
            <textarea name="note" rows="2" placeholder="Ghi chú..."></textarea>
          </div>
        </div>
      </div>

      <div class="ck-card">
        <h2 class="ck-title">Thanh toán</h2>

        <label class="ck-radio">
          <input type="radio" name="payment_method" value="COD" checked>
          <span>Thanh toán khi nhận hàng (COD)</span>
        </label>
      </div>

    </div>

    <!-- RIGHT -->
    <div class="ck-right">
      <div class="ck-card">

        <% if (orderItems == null || orderItems.isEmpty()) { %>
          <h2 class="ck-title">Đơn hàng (0 sản phẩm)</h2>
          <div style="padding:12px 0;">
            <% if (isBuyNow) { %>
              Không tìm thấy sản phẩm. <a href="index.jsp?module=product">Quay lại mua hàng</a>
            <% } else { %>
              Giỏ hàng đang trống. <a href="index.jsp?module=product">Mua ngay</a>
            <% } %>
          </div>
        <% } else { %>

          <h2 class="ck-title">Đơn hàng (<%=itemCount%> sản phẩm)</h2>

          <% for (Map<String, Object> it : orderItems) {
               String nm = (String) it.get("name");
               int prc = (Integer) it.get("price");
               String im = (String) it.get("img");
               String sz = (String) it.get("size");
               int q = (Integer) it.get("qty");
          %>

          <div class="ck-item">
            <div class="ck-item__img">
              <img src="<%=im%>" alt="<%=nm%>">
              <span class="ck-badge"><%=q%></span>
            </div>

            <div class="ck-item__info">
              <div class="ck-item__name"><%=nm%></div>
              <div class="ck-item__meta">Size: <b><%= (sz == null || sz.isEmpty()) ? "-" : sz %></b></div>
            </div>

            <div class="ck-item__price"><%=df.format(prc)%>đ</div>
          </div>

          <% } %>

          <div class="ck-total">
            <span>Tổng cộng</span>
            <b><%=df.format(total)%>đ</b>
          </div>

          <div class="ck-actions">
            <% if (isBuyNow) { %>
              <a class="ck-btn ck-btn--gray" href="index.jsp?module=product_detail&id=<%=id%>">Sửa</a>
            <% } else { %>
              <a class="ck-btn ck-btn--gray" href="index.jsp?module=cart">Sửa</a>
            <% } %>

            <button class="ck-btn ck-btn--orange" type="submit">ĐẶT HÀNG</button>
          </div>

          <div class="ck-note">
            Giá trên chưa bao gồm phí vận chuyển. Phí vận chuyển sẽ được thông báo khi xác nhận đơn hàng.
          </div>

        <% } %>

      </div>
    </div>

  </form>

</div>
