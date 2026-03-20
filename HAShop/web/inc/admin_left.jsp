<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
  String curModule = request.getParameter("module");
  if(curModule == null) curModule = "";
%>

<div class="admin-side">
  <div class="ad-title">ADMIN PANEL</div>

  <a class="<%= "admin_dashboard".equals(curModule) ? "active" : "" %>"
     href="index.jsp?module=admin_dashboard">Dashboard</a>

  <a class="<%= "admin_products".equals(curModule) ? "active" : "" %>"
     href="index.jsp?module=admin_products">Quản lý sản phẩm</a>

  <a class="<%= "admin_orders".equals(curModule) ? "active" : "" %>"
     href="index.jsp?module=admin_orders">Quản lý đơn hàng</a>

  <a class="<%= "admin_customers".equals(curModule) ? "active" : "" %>"
     href="index.jsp?module=admin_customers">Quản lý khách hàng</a>

  <a class="<%= "admin_messages".equals(curModule) || "admin_message_detail".equals(curModule) ? "active" : "" %>"
     href="index.jsp?module=admin_messages"> Quản lý tin nhắn</a>

  <a class="<%= ("admin_news".equals(curModule) || "admin_news_form".equals(curModule)) ? "active" : "" %>"
     href="index.jsp?module=admin_news">Quản lý tin tức</a>
</div>
