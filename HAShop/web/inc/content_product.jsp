<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.ProductDAO"%>
<%@page import="model.Product"%>

<%
  request.setCharacterEncoding("UTF-8");
  DecimalFormat df = new DecimalFormat("#,###");

  int p = 1;
  try { if (request.getParameter("p") != null) p = Integer.parseInt(request.getParameter("p")); } catch(Exception e){ p=1; }
  if (p < 1) p = 1;

  // ====== IMPORTANT FIX #1: chỉ giữ q khi user thật sự bấm "Tìm" (search=1) ======
  String searchFlag = request.getParameter("search"); // header submit nên set search=1
  boolean keepSearch = "1".equals(searchFlag);

  String qRaw = request.getParameter("q");
  String q = (keepSearch ? qRaw : null); // nếu không search=1 => bỏ q (tránh q cũ bám theo)

  // ===== sort =====
  String sort = request.getParameter("sort");
  if (sort == null || sort.trim().isEmpty()) sort = "price-asc";

  String price = request.getParameter("price");
  String brand = request.getParameter("brand");   // brand_name
  String sizeS = request.getParameter("size");    // int
  String target = request.getParameter("target"); // nam | nu | both

  Integer minPrice = null, maxPrice = null;
  if ("under500".equals(price)) { minPrice = null; maxPrice = 500000; }
  else if ("500-1m".equals(price)) { minPrice = 500000; maxPrice = 1000000; }
  else if ("1-2m".equals(price)) { minPrice = 1000000; maxPrice = 2000000; }
  else if ("2-3m".equals(price)) { minPrice = 2000000; maxPrice = 3000000; }
  else if ("over3m".equals(price)) { minPrice = 3000000; maxPrice = null; }

  Integer size = null;
  try { if (sizeS != null && !sizeS.trim().isEmpty()) size = Integer.parseInt(sizeS.trim()); } catch(Exception e){ size = null; }

  // map target UI -> DB (DB: both | men | women)
  String targetDb = null;
  if ("both".equalsIgnoreCase(target)) targetDb = "both";
  else if ("nam".equalsIgnoreCase(target)) targetDb = "men";
  else if ("nu".equalsIgnoreCase(target)) targetDb = "women";

  int pageSize = 12;

  ProductDAO dao = new ProductDAO();
  int total = 0;
  int totalPages = 1;
  List<Product> list = new ArrayList<>();
  String dbErr = null;

  try{
    total = dao.countProductsFiltered(q, brand, minPrice, maxPrice, size, targetDb);
    totalPages = (int)Math.ceil(total * 1.0 / pageSize);
    if (totalPages < 1) totalPages = 1;
    if (p > totalPages) p = totalPages;

    list = dao.listProductsFiltered(p, pageSize, q, brand, minPrice, maxPrice, size, targetDb, sort);
  }catch(Exception ex){
    dbErr = ex.getMessage();
  }

  // ====== IMPORTANT FIX #2: build base URL KHÔNG chứa sort để tránh trùng sort ======
  String baseNoSort = "index.jsp?module=product";

  // chỉ giữ q nếu keepSearch=true và q không rỗng
  if (keepSearch && q != null && !q.trim().isEmpty()) {
    baseNoSort += "&search=1&q=" + java.net.URLEncoder.encode(q.trim(), "UTF-8");
  }

  if (price != null && !price.isEmpty()) baseNoSort += "&price=" + java.net.URLEncoder.encode(price, "UTF-8");
  if (brand != null && !brand.isEmpty()) baseNoSort += "&brand=" + java.net.URLEncoder.encode(brand, "UTF-8");
  if (sizeS != null && !sizeS.isEmpty()) baseNoSort += "&size=" + java.net.URLEncoder.encode(sizeS, "UTF-8");
  if (target != null && !target.isEmpty()) baseNoSort += "&target=" + java.net.URLEncoder.encode(target, "UTF-8");

  // base có sort (dùng cho paging link)
  String baseWithSort = baseNoSort + "&sort=" + java.net.URLEncoder.encode(sort, "UTF-8");

  // ====== TITLE theo brand ======
  String titleText = "Giày cầu lông";
  if (brand != null && !brand.trim().isEmpty()) {
      String b = brand.trim();
      b = b.substring(0,1).toUpperCase() + b.substring(1);
      titleText = "Giày cầu lông " + b;
  }
%>

<div id="content_center_2">

  <div class="banner slideshow">
    <img src="images/promotion-01.jpg" class="slide active" alt="Promotion 1">
    <img src="images/promotion-02.jpg" class="slide" alt="Promotion 2">
    <img src="images/promotion-03.jpg" class="slide" alt="Promotion 3">
  </div>

  <div class="sort-bar">
    <div class="sort-left">
      <span id="categoryTitle"><%=titleText%></span>
    </div>

    <!-- SORT: chỉ 2 option, và FIX trùng sort -->
    <div class="sort-right">
      Sắp xếp:
      <select onchange="location.href='<%=baseNoSort%>&p=1&sort=' + encodeURIComponent(this.value);">
        <option value="price-asc"  <%= "price-asc".equalsIgnoreCase(sort) ? "selected":"" %>>Giá tăng dần</option>
        <option value="price-desc" <%= "price-desc".equalsIgnoreCase(sort) ? "selected":"" %>>Giá giảm dần</option>
      </select>
    </div>
  </div>

  <% if(dbErr != null){ %>
    <div style="padding:12px; margin:12px 0; background:#ffecec; border:1px solid #ffd1d1; border-radius:10px;">
      Lỗi DB: <%=dbErr%>
    </div>
  <% } %>

  <div class="product-grid">
    <% if(list == null || list.isEmpty()){ %>
      <div style="padding:12px 0;">Chưa có sản phẩm.</div>
    <% } else { for(Product pr : list){ %>
      <div class="product-card">
        <a class="product-link" href="index.jsp?module=product_detail&id=<%=pr.getId()%>">
          <img src="<%= (pr.getThumbnail()!=null && !pr.getThumbnail().trim().isEmpty())
                      ? pr.getThumbnail().trim()
                      : "images/products/demo/sp1.jpg" %>" alt="<%=pr.getName()%>">
          <h4><%=pr.getName()%></h4>
        </a>
        <div class="price"><%=df.format(pr.getPrice())%>đ</div>
      </div>
    <% } } %>
  </div>

  <!-- PAGINATION -->
  <div class="paging">
    <a class="page-btn <%= (p==1 ? "disabled" : "") %>"
       href="<%=baseWithSort%>&p=<%=Math.max(1, p-1)%>">&laquo;</a>

    <% for (int k = 1; k <= totalPages; k++) { %>
      <a class="page-btn <%= (k==p ? "active" : "") %>"
         href="<%=baseWithSort%>&p=<%=k%>"><%=k%></a>
    <% } %>

    <a class="page-btn <%= (p==totalPages ? "disabled" : "") %>"
       href="<%=baseWithSort%>&p=<%=Math.min(totalPages, p+1)%>">&raquo;</a>
  </div>

</div>
