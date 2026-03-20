<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.OrderDAO"%>
<%@page import="model.User"%>

<%
  User u = (User) session.getAttribute("user");
  if(u == null){
    response.sendRedirect("index.jsp?module=login");
    return;
  }

  int oid = 0;
  try { oid = Integer.parseInt(request.getParameter("id")); } catch(Exception e){ oid = 0; }

  OrderDAO dao = new OrderDAO();

  // bảo mật: chỉ lấy đơn của user hiện tại
  Map<String,Object> order = dao.getOrderHeaderByUser(oid, u.getId());
  List<Map<String,Object>> items = (order == null) ? new ArrayList<>() : dao.getOrderItemsByUser(oid, u.getId());

  DecimalFormat df = new DecimalFormat("#,###");
%>

<div class="admin-main" style="max-width:1100px;margin:0 auto; padding:16px 0;">
  <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
    <h2 style="margin:0">Chi tiết đơn hàng #<%=oid%></h2>
    <a class="ad-btn gray" href="index.jsp?module=order_lookup">&larr; Quay lại</a>
  </div>

  <% if(order == null || order.isEmpty()){ %>
    <div class="ad-msg warn" style="margin-top:12px;">⚠️ Không tìm thấy đơn hàng (hoặc bạn không có quyền xem đơn này).</div>
  <% } else { %>

    <div class="ad-card" style="background:#fff;border:1px solid #eee;border-radius:14px;padding:16px;margin-top:12px;margin-bottom:14px">
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
        <div>
          <div><b>Email:</b> <%=order.get("email")%></div>
          <div><b>Ghi chú:</b> <%=order.get("note")%></div>
          <div><b>Thanh toán:</b> <%=order.get("payment_method")%></div>
        </div>
        <div>
          <div><b>Người nhận:</b> <%=order.get("receiver_name")%></div>
          <div><b>SĐT:</b> <%=order.get("receiver_phone")%></div>
          <div><b>Địa chỉ:</b> <%=order.get("receiver_addr")%></div>
        </div>
      </div>

      <div style="margin-top:10px">
        <b>Tổng tiền:</b> <%=df.format(((Number)order.get("total_amount")).intValue())%> đ
        <% if(order.get("status") != null){ %>
          &nbsp; | &nbsp;<b>Trạng thái:</b> <%=order.get("status")%>
        <% } %>
        <% if(order.get("created_at") != null){ %>
          &nbsp; | &nbsp;<b>Ngày tạo:</b> <%=order.get("created_at")%>
        <% } %>
      </div>
    </div>

    <div class="ad-card" style="background:#fff;border:1px solid #eee;border-radius:14px;padding:16px">
      <h3 style="margin:0 0 12px">Sản phẩm trong đơn</h3>

      <% if(items == null || items.isEmpty()){ %>
        <div class="ad-msg warn">⚠️ Đơn này chưa có sản phẩm (order_items trống).</div>
      <% } else { %>
        <table class="ad-table">
          <thead>
            <tr>
              <th>Ảnh</th>
              <th>Sản phẩm</th>
              <th>Size</th>
              <th>Giá</th>
              <th>Số lượng</th>
              <th>Thành tiền</th>
            </tr>
          </thead>
          <tbody>
            <% for(Map<String,Object> it: items){

                 String name = String.valueOf(it.get("product_name"));
                 String thumb = (String)it.get("thumbnail");
                 if(thumb == null || thumb.trim().isEmpty()) thumb = "images/products/demo/sp1.jpg";

                 Integer size = null;
                 Object sizeObj = it.get("size");
                 if(sizeObj instanceof Number) size = ((Number)sizeObj).intValue();

                 int qty   = (it.get("quantity") instanceof Number) ? ((Number)it.get("quantity")).intValue() : 0;
                 int price = (it.get("unit_price") instanceof Number) ? ((Number)it.get("unit_price")).intValue() : 0;

                 // line_total có thể Long/Integer -> reopen safe
                 int line  = (it.get("line_total") instanceof Number) ? ((Number)it.get("line_total")).intValue() : (qty * price);
            %>
              <tr>
                <td>
                  <img src="<%=thumb%>" style="width:54px;height:54px;object-fit:cover;border-radius:10px;border:1px solid #eee"/>
                </td>
                <td><%=name%></td>
                <td><%= (size==null ? "-" : size) %></td>
                <td><%=df.format(price)%> đ</td>
                <td><%=qty%></td>
                <td><%=df.format(line)%> đ</td>
              </tr>
            <% } %>
          </tbody>
        </table>
      <% } %>
    </div>

  <% } %>
</div>
