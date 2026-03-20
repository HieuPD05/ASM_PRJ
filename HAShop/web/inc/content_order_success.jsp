<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.OrderDAO"%>
<%@page import="model.User"%>

<%
  int oid = 0;
  try { oid = Integer.parseInt(request.getParameter("id")); } catch(Exception e){}

  User u = (User) session.getAttribute("user");
  DecimalFormat df = new DecimalFormat("#,###");

  List<Map<String,Object>> items = new ArrayList<>();
  long total = 0;

  if (u != null && oid > 0) {
    OrderDAO dao = new OrderDAO();
    items = dao.getOrderItemsByUser(oid, u.getId());
    for (Map<String,Object> it : items) {
      total += (Integer) it.get("unit_price") * (Integer) it.get("quantity");
    }
  }
%>

<div class="page-box">
  <div class="os2">

    <!-- LEFT SUMMARY -->
    <div class="os2-left">
      <div class="os2-badge">
        <span class="os2-check">✓</span>
        <div>
          <div class="os2-title">Đặt hàng thành công</div>
          <div class="os2-sub">Đơn hàng của bạn đã được ghi nhận.</div>
        </div>
      </div>

      <div class="os2-box">
        <div class="os2-row">
          <span>Mã đơn</span>
          <b>#<%=oid%></b>
        </div>
        <div class="os2-row">
          <span>Số sản phẩm</span>
          <b><%=items.size()%></b>
        </div>
        <div class="os2-row">
          <span>Tổng tiền</span>
          <b class="os2-total"><%=df.format(total)%> đ</b>
        </div>
      </div>

      <div class="os2-note">
        Cảm ơn bạn đã mua hàng tại <b>HA SHOP</b>.
        Bạn có thể tra cứu đơn ở mục <b>Tra cứu đơn</b>.
      </div>

      <div class="os2-actions">
        <a class="os2-btn primary" href="index.jsp?module=product">Tiếp tục mua sắm</a>
        <a class="os2-btn" href="index.jsp?module=home">Về trang chủ</a>
      </div>
    </div>

    <!-- RIGHT ITEMS -->
    <div class="os2-right">
      <div class="os2-card">
        <div class="os2-cardhead">
          <h3>Sản phẩm đã mua</h3>
          <div class="os2-mini">#<%=oid%></div>
        </div>

        <div class="os2-tableWrap">
          <table class="os2-table">
            <thead>
              <tr>
                <th>Sản phẩm</th>
                <th>Size</th>
                <th>SL</th>
                <th class="tr">Giá</th>
              </tr>
            </thead>
            <tbody>
              <% for(Map<String,Object> it : items){
                   String thumb = String.valueOf(it.get("thumbnail"));
                   if(thumb == null || "null".equalsIgnoreCase(thumb) || thumb.trim().isEmpty()){
                     thumb = "images/products/demo/sp1.jpg";
                   }
              %>
              <tr>
                <td>
                  <div class="os2-prod">
                    <img src="<%=thumb%>" alt="">
                    <div class="os2-prodText">
                      <div class="os2-name"><%=it.get("product_name")%></div>
                      <div class="os2-muted">Mã đơn: #<%=oid%></div>
                    </div>
                  </div>
                </td>
                <td><b><%=it.get("size")%></b></td>
                <td><b><%=it.get("quantity")%></b></td>
                <td class="tr"><b><%=df.format(it.get("unit_price"))%> đ</b></td>
              </tr>
              <% } %>
            </tbody>
          </table>
        </div>

        <div class="os2-foot">
          <span>Tổng cộng</span>
          <b class="os2-total"><%=df.format(total)%> đ</b>
        </div>
      </div>
    </div>

  </div>
</div>
