<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.ProductDAO"%>
<%@page import="model.Product"%>

<%
  request.setCharacterEncoding("UTF-8");
  DecimalFormat df = new DecimalFormat("#,###");

  List<Product> featured = new ArrayList<>();
  String dbError = null;

  try {
    ProductDAO dao = new ProductDAO();
    featured = dao.listLatestProducts(8); // 8 sp mới nhất
  } catch (Exception e) {
    dbError = e.getMessage();
  }
%>

<div class="home">

  <!-- ===== BANNER ===== -->
  <div class="banner slideshow home-banner">
    <img src="images/promotion-01.jpg" class="slide active" alt="Promotion 1">
    <img src="images/promotion-02.jpg" class="slide" alt="Promotion 2">
    <img src="images/promotion-03.jpg" class="slide" alt="Promotion 3">
  </div>

  <!-- ===== SẢN PHẨM NỔI BẬT ===== -->
  <div class="home-section">
    <div class="home-section__head">
      <h2>Sản phẩm nổi bật</h2>
    </div>

    <% if (dbError != null) { %>
      <div style="padding:12px; margin:12px 0; background:#ffecec; border:1px solid #ffd1d1; border-radius:10px;">
        Lỗi DB: <%=dbError%>
      </div>
    <% } %>

    <div class="product-grid">
      <% if (featured == null || featured.isEmpty()) { %>
        <div style="padding:12px 0;">Chưa có sản phẩm.</div>
      <% } else { %>
        <% for (Product pr : featured) { %>
          <div class="product-card">
            <a class="product-link" href="index.jsp?module=product_detail&id=<%=pr.getId()%>">
              <img src="<%= (pr.getThumbnail()!=null && !pr.getThumbnail().trim().isEmpty())
                          ? pr.getThumbnail().trim()
                          : "images/products/demo/sp1.jpg" %>"
                   alt="<%=pr.getName()%>">
              <h4><%=pr.getName()%></h4>
            </a>
            <div class="price"><%=df.format(pr.getPrice())%>đ</div>
          </div>
        <% } %>
      <% } %>
    </div>

    <div class="home-more-text">
      <a href="index.jsp?module=product">Xem thêm</a>
    </div>
  </div>

  <!-- ===== VÌ SAO CHỌN ===== -->
  <div class="home-section">
    <div class="home-section__head">
      <h2>Vì sao chọn HA SHOP?</h2>
    </div>

    <div class="home-benefits">
      <div class="benefit">
        <div class="benefit__icon"><i class="fa fa-check-circle"></i></div>
        <div class="benefit__text">
          <h4>Hàng chính hãng</h4>
          <p>Cam kết nguồn gốc rõ ràng, kiểm tra trước khi nhận.</p>
        </div>
      </div>

      <div class="benefit">
        <div class="benefit__icon"><i class="fa fa-truck"></i></div>
        <div class="benefit__text">
          <h4>Giao nhanh</h4>
          <p>Đóng gói cẩn thận, hỗ trợ giao nhanh nội thành.</p>
        </div>
      </div>

      <div class="benefit">
        <div class="benefit__icon"><i class="fa fa-exchange"></i></div>
        <div class="benefit__text">
          <h4>Đổi trả dễ</h4>
          <p>Hỗ trợ đổi size (theo chính sách shop).</p>
        </div>
      </div>

      <div class="benefit">
        <div class="benefit__icon"><i class="fa fa-headphones"></i></div>
        <div class="benefit__text">
          <h4>Tư vấn tận tình</h4>
          <p>Gợi ý size – form – lối chơi phù hợp.</p>
        </div>
      </div>
    </div>
  </div>

</div>
