<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.CartDAO"%>
<%@page import="model.User"%>

<%
  User u = (User) session.getAttribute("user");
  boolean loggedIn = (u != null);

  List<Map<String,Object>> cart;

  if (loggedIn) {
    CartDAO cdao = new CartDAO();
    cart = cdao.listItems(u.getId()); // nếu User class bạn đặt tên khác: đổi lại
    session.setAttribute("cartCount", cdao.countItems(u.getId()));
  } else {
    cart = (List<Map<String,Object>>) session.getAttribute("cart");
    if(cart == null) cart = new ArrayList<>();
  }

  DecimalFormat df = new DecimalFormat("#,###");

  long total = 0;
  for(Map<String,Object> it : cart){
    int pr = (Integer) it.get("price");
    int q  = (Integer) it.get("qty");
    total += (long)pr * q;
  }
%>

<div class="cart2">
  <div class="cart2-head">GIỎ HÀNG CỦA BẠN</div>

  <div class="cart2-box">
    <div class="cart2-bar">GIỎ HÀNG</div>

    <% if(cart.isEmpty()){ %>
      <div class="cart2-empty">Giỏ hàng đang trống. <a href="index.jsp?module=product">Mua ngay</a></div>
    <% } else { %>

      <div class="cart2-list">
        <% for(int i=0; i<cart.size(); i++){
             Map<String,Object> it = cart.get(i);
             String nm = (String) it.get("name");
             int pr = (Integer) it.get("price");
             String im = (String) it.get("img");
             String sz = (String) it.get("size");
             int q  = (Integer) it.get("qty");
             int pid = (Integer) it.get("id");
             long sub = (long)pr * q;

             String removeHref;
             String minusHref;
             String plusHref;

             if (loggedIn) {
               removeHref = "index.jsp?module=cart&action=remove&id=" + pid + "&size=" + sz;
               minusHref  = "index.jsp?module=cart&action=update&id=" + pid + "&size=" + sz + "&qty=" + Math.max(1, q-1);
               plusHref   = "index.jsp?module=cart&action=update&id=" + pid + "&size=" + sz + "&qty=" + (q+1);
             } else {
               removeHref = "index.jsp?module=cart&action=remove&idx=" + i;
               minusHref  = "index.jsp?module=cart&action=update&idx=" + i + "&qty=" + Math.max(1, q-1);
               plusHref   = "index.jsp?module=cart&action=update&idx=" + i + "&qty=" + (q+1);
             }
        %>

        <div class="cart2-row">

          <a class="cart2-x"
             href="<%=removeHref%>"
             title="Xóa"
             onclick="return confirm('Xóa sản phẩm này?')">×</a>

          <div class="cart2-img">
            <img src="<%=im%>" alt="<%=nm%>">
          </div>

          <div class="cart2-info">
            <div class="cart2-name"><%=nm%></div>
            <div class="cart2-size">Size: <%=sz%></div>
          </div>

          <div class="cart2-qty">
            <a class="qbtn" href="<%=minusHref%>">-</a>
            <div class="qval"><%=q%></div>
            <a class="qbtn" href="<%=plusHref%>">+</a>
          </div>

          <div class="cart2-price"><%=df.format(sub)%> đ</div>
        </div>

        <% } %>
      </div>

      <div class="cart2-total">
        <div class="t-left">TỔNG TIỀN:</div>
        <div class="t-right"><%=df.format(total)%> đ</div>
      </div>

      <div class="cart2-actions">
        <a class="cart2-order" style="background:#999;" href="index.jsp?module=cart&action=clear"
           onclick="return confirm('Xóa hết giỏ hàng?')">XÓA HẾT</a>
        <a class="cart2-order" href="index.jsp?module=checkout">MUA HÀNG</a>
      </div>

    <% } %>
  </div>
</div>
