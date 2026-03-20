<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.AdminDAO"%>

<%
  AdminDAO dao = new AdminDAO();
  Map<String,Object> s = dao.dashboardStats();

  DecimalFormat df = new DecimalFormat("#,###");

  int products = (Integer) s.get("products");
  int orders = (Integer) s.get("orders");
  int customers = (Integer) s.get("customers");
  long revenue = (Long) s.get("revenue");
%>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">
    <div class="ad-head">
      <h2>Dashboard tổng quan</h2>
      <a class="ad-btn" href="index.jsp?module=home">Về shop</a>
    </div>

    <div class="ad-grid">
      <div class="ad-card"><div class="k">Sản phẩm</div><div class="v"><%=products%></div></div>
      <div class="ad-card"><div class="k">Đơn hàng</div><div class="v"><%=orders%></div></div>
      <div class="ad-card"><div class="k">Khách hàng (USER)</div><div class="v"><%=customers%></div></div>
      <div class="ad-card"><div class="k">Doanh thu</div><div class="v"><%=df.format(revenue)%> đ</div></div>
    </div>
  </div>
</div>
