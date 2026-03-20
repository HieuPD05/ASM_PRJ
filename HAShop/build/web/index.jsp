<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
  // ====== CART ACTION CONTROLLER ======
  String module2 = request.getParameter("module");
  String action2 = request.getParameter("action");
  if ("cart".equalsIgnoreCase(module2) && action2 != null && action2.trim().length() > 0) {
    request.getRequestDispatcher("inc/cart_action.jsp").forward(request, response);
    return;
  }

  // ====== ROUTER MODULE ======
  String module = request.getParameter("module");
  if (module == null || module.trim().length() == 0) module = "home";

  String pagePath = "inc/content_home.jsp";

  if ("product".equalsIgnoreCase(module)) pagePath = "inc/content_product.jsp";
  else if ("product_detail".equalsIgnoreCase(module)) pagePath = "inc/content_productdetail.jsp";
  else if ("news".equalsIgnoreCase(module)) pagePath = "inc/content_news.jsp";
  else if ("news_detail".equalsIgnoreCase(module)) pagePath = "inc/content_newsdetail.jsp";
  else if ("contact".equalsIgnoreCase(module)) pagePath = "inc/content_contact.jsp";
  else if ("checkout".equalsIgnoreCase(module)) pagePath = "inc/content_checkout.jsp";
  else if ("cart".equalsIgnoreCase(module)) pagePath = "inc/content_cart.jsp";
  else if ("login".equalsIgnoreCase(module)) pagePath = "inc/content_login.jsp";
  else if ("register".equalsIgnoreCase(module)) pagePath = "inc/content_register.jsp";
  else if ("order_success".equalsIgnoreCase(module)) pagePath = "inc/content_order_success.jsp";

  // ADMIN: messages
  else if ("admin_messages".equalsIgnoreCase(module)) pagePath = "inc/content_admin_messages.jsp";
  else if ("admin_message_detail".equalsIgnoreCase(module)) pagePath = "inc/content_admin_message_detail.jsp";

  // USER: tra cứu đơn + chi tiết đơn
  else if ("order_lookup".equalsIgnoreCase(module)) pagePath = "inc/content_order_lookup.jsp";
  else if ("my_messages".equalsIgnoreCase(module))   pagePath = "inc/content_my_messages.jsp";
  else if ("order_detail".equalsIgnoreCase(module)) pagePath = "inc/content_order_detail.jsp";

  // ADMIN MODULES
  else if ("admin_dashboard".equalsIgnoreCase(module)) pagePath = "inc/content_admin_dashboard.jsp";
  else if ("admin_products".equalsIgnoreCase(module)) pagePath = "inc/content_admin_products.jsp";
  else if ("admin_orders".equalsIgnoreCase(module)) pagePath = "inc/content_admin_orders.jsp";
  else if ("admin_customers".equalsIgnoreCase(module)) pagePath = "inc/content_admin_customers.jsp";
  else if ("admin_order_detail".equalsIgnoreCase(module)) pagePath = "inc/content_admin_order_detail.jsp";
  else if ("admin_news".equalsIgnoreCase(module)) pagePath = "inc/content_admin_news.jsp";
  else if ("admin_news_form".equalsIgnoreCase(module)) pagePath = "inc/content_admin_news_form.jsp";

  // Checkout + tra cứu đơn yêu cầu đăng nhập
  Object uObj = session.getAttribute("user");
  if (("checkout".equalsIgnoreCase(module)
        || "order_lookup".equalsIgnoreCase(module)
        || "order_detail".equalsIgnoreCase(module)
        || "my_messages".equalsIgnoreCase(module))
      && uObj == null) {

    String qs = request.getQueryString();
    String fullUrl = "index.jsp" + (qs != null ? ("?" + qs) : "");
    session.setAttribute("afterLoginUrl", fullUrl);

    response.sendRedirect("index.jsp?module=login");
    return;
  }
%>

<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Badminton Shoes Shop</title>

  <!-- Font Awesome -->
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">

  <!-- CSS chung -->
  <link rel="stylesheet" href="CSS/Style.css">
  <link rel="stylesheet" href="CSS/Menu.css">

  <!-- ✅ SearchSuggest dùng ở header -->
  <link rel="stylesheet" href="CSS/SearchSuggest.css">

  <!-- CSS cho LOGIN + REGISTER -->
  <% if ("login".equalsIgnoreCase(module) || "register".equalsIgnoreCase(module)) { %>
    <link rel="stylesheet" href="CSS/Auth.css">
  <% } %>

  <!-- ✅ CSS ADMIN (luôn có để admin + order_detail giống admin) -->
  <link rel="stylesheet" href="CSS/Admin.css">

  <!-- CSS HOME + PRODUCT + PRODUCT_DETAIL -->
  <% if ("home".equalsIgnoreCase(module)
      || "product".equalsIgnoreCase(module)
      || "product_detail".equalsIgnoreCase(module)) { %>
    <link rel="stylesheet" href="CSS/Sanpham.css">
    <link rel="stylesheet" href="CSS/SlideShow.css">
  <% } %>

  <!-- CSS PRODUCT -->
  <% if ("product".equalsIgnoreCase(module)) { %>
    <link rel="stylesheet" href="CSS/Filter.css">
  <% } %>

  <!-- CSS cart + checkout + product_detail -->
  <% if ("cart".equalsIgnoreCase(module)
      || "checkout".equalsIgnoreCase(module)
      || "product_detail".equalsIgnoreCase(module)) { %>
    <link rel="stylesheet" href="CSS/Cart.css">
  <% } %>

  <!-- ✅ Order success -->
  <% if ("order_success".equalsIgnoreCase(module)) { %>
    <link rel="stylesheet" href="CSS/OrderSuccess.css">
  <% } %>

  <!-- ✅ Order lookup + order detail -->
  <% if ("order_lookup".equalsIgnoreCase(module) || "order_detail".equalsIgnoreCase(module)) { %>
    <link rel="stylesheet" href="CSS/OrderLookup.css">
  <% } %>

</head>

<body>
<div id="wrapper">

  <%@include file="inc/header.jsp" %>

  <div id="content">
    <div class="container">

      <% if ("product".equalsIgnoreCase(module)) { %>
        <div class="content-row">
          <%@include file="inc/left.jsp" %>
          <jsp:include page="<%=pagePath%>" />
        </div>
      <% } else { %>
        <jsp:include page="<%=pagePath%>" />
      <% } %>

    </div>
  </div>

  <%@include file="inc/footer.jsp" %>

</div>

<!-- JS -->
<script src="JS/search-suggest.js"></script>

<% if ("home".equalsIgnoreCase(module) || "product".equalsIgnoreCase(module)) { %>
  <script src="JS/SlideShow.js"></script>
<% } %>

<% if ("product".equalsIgnoreCase(module)) { %>
  <script src="JS/filter-title.js"></script>
<% } %>

</body>
</html>
