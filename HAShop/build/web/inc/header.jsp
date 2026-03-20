<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>

<%
    User u = (User) session.getAttribute("user");
    String fullName = (u != null && u.getFullName() != null) ? u.getFullName() : "";
    String email    = (u != null && u.getEmail()    != null) ? u.getEmail()    : "";
    String role     = (u != null && u.getRole()     != null) ? u.getRole()     : "";

    Integer cartCount = (Integer) session.getAttribute("cartCount");
    if (cartCount == null) cartCount = 0;

    String searchFlag = request.getParameter("search");
    boolean keepSearch = "1".equals(searchFlag);
    String q = request.getParameter("q");
    if (q == null) q = "";
    if (!keepSearch) q = "";
%>

<div id="header">
  <div class="container header-row">

    <!-- LOGO -->
    <div class="brand">
      <img class="brand-logo" src="images/logo.png" alt="logo">
      <span class="brand-name">HA SHOP</span>
    </div>

    <%@include file="menu.jsp" %>

    <!-- ACTIONS bên phải -->
    <div class="actions">

      <!-- SEARCH -->
      <div class="search ss-wrap">
        <form class="ss-form" method="get" action="index.jsp" autocomplete="off">
          <input type="hidden" name="module" value="product"/>
          <input type="hidden" name="search" value="1"/>
          <input id="ssInput" name="q" type="text" placeholder="Tìm kiếm..." value="<%=q%>">
          <button type="submit"><i class="fa fa-search"></i></button>
        </form>
        <div id="ssDropdown" class="ss-dropdown" style="display:none;">
          <div id="ssList"></div>
          <a id="ssViewAll" class="ss-viewall" href="index.jsp?module=product&search=1&q=">Xem tất cả</a>
        </div>
      </div>

      <!-- ICON BUTTONS -->
      <div class="hdr-icons">

        <!-- Tra cứu đơn -->
        <a href="index.jsp?module=order_lookup" class="hdr-icon-btn" title="Tra cứu đơn hàng">
          <i class="fa fa-truck"></i>
        </a>

        <!-- Giỏ hàng -->
        <a href="index.jsp?module=cart" class="hdr-icon-btn hdr-cart" title="Giỏ hàng">
          <i class="fa fa-shopping-cart"></i>
          <% if (cartCount > 0) { %>
            <span class="hdr-badge"><%=cartCount%></span>
          <% } %>
        </a>

        <% if (u != null && "ADMIN".equalsIgnoreCase(role)) { %>
        <!-- Admin panel -->
        <a href="index.jsp?module=admin_dashboard" class="hdr-icon-btn hdr-admin" title="Quản lí">
          <i class="fa fa-cog"></i>
        </a>
        <% } %>

      </div>

      <!-- AUTH / USER -->
      <% if (u == null) { %>
        <div class="user-actions">
          <a href="index.jsp?module=login"    class="auth login">Đăng nhập</a>
          <a href="index.jsp?module=register" class="auth register">Đăng ký</a>
        </div>
      <% } else { %>
        <div class="user-actions">
          <span class="auth user">
            Xin chào, <b class="user-name"><%= !fullName.isEmpty() ? fullName : email %></b>
          </span>
          <a href="logout" class="auth logout">Đăng xuất</a>
        </div>
      <% } %>

    </div>
  </div>
</div>
