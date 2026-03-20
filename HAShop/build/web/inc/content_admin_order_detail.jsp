<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.AdminDAO"%>

<%
  int oid = 0;
  try { oid = Integer.parseInt(request.getParameter("id")); } catch(Exception e){ oid = 0; }

  AdminDAO dao = new AdminDAO();
  Map<String,Object> order = dao.getOrderHeader(oid);
  List<Map<String,Object>> items = dao.getOrderItems(oid);

  DecimalFormat df = new DecimalFormat("#,###");
%>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">
    <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
      <h2>Chi tiết đơn hàng #<%=oid%></h2>
      <a class="ad-btn gray" href="index.jsp?module=admin_orders">&larr; Quay lại</a>
    </div>

    <% if(order == null || order.isEmpty()){ %>
      <div class="ad-msg warn">⚠️ Không tìm thấy đơn hàng.</div>
    <% } else { %>

      <div class="ad-card" style="background:#fff;border:1px solid #eee;border-radius:14px;padding:16px;margin-bottom:14px">
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
          <div>
            <div><b>Khách hàng:</b> <%=order.get("customer_name")%></div>
            <div><b>Email:</b> <%=order.get("email")%></div>
            <div><b>Ghi chú:</b> <%=order.get("note")%></div>
          </div>
          <div>
            <div><b>Người nhận:</b> <%=order.get("receiver_name")%></div>
            <div><b>SĐT:</b> <%=order.get("receiver_phone")%></div>
            <div><b>Địa chỉ:</b> <%=order.get("receiver_addr")%></div>
          </div>
        </div>

        <div style="margin-top:10px">
          <b>Tổng tiền:</b> <%=df.format((Integer)order.get("total_amount"))%> đ
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

        <% if(items.isEmpty()){ %>
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
                   String name = (String)it.get("product_name");
                   String thumb = (String)it.get("thumbnail");
                   if(thumb == null || thumb.trim().isEmpty()) thumb = "images/products/demo/sp1.jpg";

                   Integer size = (Integer)it.get("size"); // có thể null
                   int qty = (Integer)it.get("quantity");
                   int price = (Integer)it.get("unit_price");
                   long sub = (long)qty * price;
              %>
                <tr>
                  <td>
                    <img src="<%=thumb%>" style="width:54px;height:54px;object-fit:cover;border-radius:10px;border:1px solid #eee"/>
                  </td>
                  <td><%=name%></td>
                  <td><%= (size==null ? "-" : size) %></td>
                  <td><%=df.format(price)%> đ</td>
                  <td><%=qty%></td>
                  <td><%=df.format(sub)%> đ</td>
                </tr>
              <% } %>
            </tbody>
          </table>
        <% } %>
      </div>

    <% } %>
  </div>
</div>
