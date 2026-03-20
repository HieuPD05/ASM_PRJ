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

  OrderDAO dao = new OrderDAO();
  List<Map<String,Object>> orders = dao.getOrdersByUser(u.getId());

  DecimalFormat df = new DecimalFormat("#,###");
%>

<div class="admin-main" style="max-width:1100px;margin:0 auto; padding:16px 0;">
  <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
    <h2 style="margin:0">Tra cứu đơn hàng</h2>
    <a class="ad-btn gray" href="index.jsp">&larr; Trang chủ</a>
  </div>

  <div class="ad-card" style="margin-top:12px;background:#fff;border:1px solid #eee;border-radius:14px;padding:16px">
    <% if(orders == null || orders.isEmpty()){ %>
      <div class="ad-msg warn">⚠️ Bạn chưa có đơn hàng nào.</div>
    <% } else { %>

      <table class="ad-table">
        <thead>
          <tr>
            <th>Mã</th>
            <th>Ngày tạo</th>
            <th>Trạng thái</th>
            <th>Tổng</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
        <% for(Map<String,Object> od : orders){
             int id = ((Number)od.get("order_id")).intValue();
             int total = ((Number)od.get("total_amount")).intValue();
             String st = String.valueOf(od.get("status"));
        %>
          <tr>
            <td>#<%=id%></td>
            <td><%=od.get("created_at")%></td>
            <td><%=st%></td>
            <td><%=df.format(total)%> đ</td>
            <td style="text-align:right">
              <a class="ad-btn" href="index.jsp?module=order_detail&id=<%=id%>">Chi tiết</a>
            </td>
          </tr>
        <% } %>
        </tbody>
      </table>

    <% } %>
  </div>
</div>
