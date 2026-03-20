<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
  String qLeft = request.getParameter("q");
  if (qLeft == null) qLeft = "";

  String sortLeft = request.getParameter("sort");
  if (sortLeft == null || sortLeft.trim().isEmpty()) sortLeft = "price-asc";

  String priceLeft  = request.getParameter("price");   // under500 | 500-1m | 1-2m | 2-3m | over3m
  String brandLeft  = request.getParameter("brand");   // Yonex | Lining | Victor | Taro | Kawasaki
  String sizeLeft   = request.getParameter("size");    // 38..45
  String targetLeft = request.getParameter("target");  // nam | nu | both
%>

<div id="content_left">

  <form id="filterForm" method="get" action="index.jsp">
    <input type="hidden" name="module" value="product"/>
    <input type="hidden" name="q" value="<%=qLeft%>"/>
    <input type="hidden" name="sort" value="<%=sortLeft%>"/>
    <input type="hidden" name="p" value="1"/>

    <!-- ===== GIÁ ===== -->
    <div class="filter-box">
      <h3>CHỌN MỨC GIÁ</h3>

      <label class="ck radio-box">
        <input type="radio" name="price" value="under500" <%= "under500".equals(priceLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>
        Giá dưới 500.000đ
      </label>

      <label class="ck radio-box">
        <input type="radio" name="price" value="500-1m" <%= "500-1m".equals(priceLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>
        500.000đ - 1 triệu
      </label>

      <label class="ck radio-box">
        <input type="radio" name="price" value="1-2m" <%= "1-2m".equals(priceLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>
        1 - 2 triệu
      </label>

      <label class="ck radio-box">
        <input type="radio" name="price" value="2-3m" <%= "2-3m".equals(priceLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>
        2 - 3 triệu
      </label>

      <label class="ck radio-box">
        <input type="radio" name="price" value="over3m" <%= "over3m".equals(priceLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>
        Giá trên 3 triệu
      </label>
    </div>

    <!-- ===== BRAND ===== -->
    <div class="filter-box">
      <h3>THƯƠNG HIỆU</h3>

      <div class="scroll-list">
        <label class="ck radio-box">
          <input type="radio" name="brand" value="Yonex" <%= "Yonex".equalsIgnoreCase(brandLeft) ? "checked":"" %>>
          <span class="custom-radio"></span> Yonex
        </label>

        <label class="ck radio-box">
          <input type="radio" name="brand" value="Lining" <%= "Lining".equalsIgnoreCase(brandLeft) ? "checked":"" %>>
          <span class="custom-radio"></span> Lining
        </label>

        <label class="ck radio-box">
          <input type="radio" name="brand" value="Victor" <%= "Victor".equalsIgnoreCase(brandLeft) ? "checked":"" %>>
          <span class="custom-radio"></span> Victor
        </label>

        <label class="ck radio-box">
          <input type="radio" name="brand" value="Taro" <%= "Taro".equalsIgnoreCase(brandLeft) ? "checked":"" %>>
          <span class="custom-radio"></span> Taro
        </label>

        <label class="ck radio-box">
          <input type="radio" name="brand" value="Kawasaki" <%= "Kawasaki".equalsIgnoreCase(brandLeft) ? "checked":"" %>>
          <span class="custom-radio"></span> Kawasaki
        </label>
      </div>
    </div>

    <!-- ===== SIZE ===== -->
    <div class="filter-box">
      <h3>LỌC THEO SIZE</h3>

      <div class="scroll-list">
        <div class="size-grid">
          <% for(int s=38; s<=45; s++){ %>
            <label class="ck radio-box">
              <input type="radio" name="size" value="<%=s%>" <%= String.valueOf(s).equals(sizeLeft) ? "checked":"" %>>
              <span class="custom-radio"></span><%=s%>
            </label>
          <% } %>
        </div>
      </div>
    </div>

    <!-- ===== TARGET ===== -->
    <div class="filter-box">
      <h3>ĐỐI TƯỢNG</h3>

      <label class="ck radio-box">
        <input type="radio" name="target" value="nam" <%= "nam".equalsIgnoreCase(targetLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>Nam
      </label>

      <label class="ck radio-box">
        <input type="radio" name="target" value="nu" <%= "nu".equalsIgnoreCase(targetLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>Nữ
      </label>

      <label class="ck radio-box">
        <input type="radio" name="target" value="both" <%= "both".equalsIgnoreCase(targetLeft) ? "checked":"" %>>
        <span class="custom-radio"></span>Cả Nam lẫn Nữ
      </label>

      <div style="margin-top:12px;">
        <a href="index.jsp?module=product"
           style="display:inline-block; padding:8px 10px; border:1px solid #eee; border-radius:10px; text-decoration:none;">
          Xóa lọc
        </a>
      </div>
    </div>

  </form>
</div>

<script>
(function(){
  const f = document.getElementById('filterForm');
  if(!f) return;
  f.addEventListener('change', function(){
    f.submit();
  });
})();
</script>
