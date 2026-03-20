<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="java.util.*"%>
<%@page import="dal.ProductDAO"%>
<%@page import="model.Product"%>

<%
  request.setCharacterEncoding("UTF-8");

  int id = 1;
  try { if (request.getParameter("id") != null) id = Integer.parseInt(request.getParameter("id")); }
  catch (Exception e) { id = 1; }

  ProductDAO pdao = new ProductDAO();
  Product pr = null;

  List<String> imgs = new ArrayList<>();
  List<String> sizes = new ArrayList<>();
  String dbErr = null;

  try {
    pr = pdao.getById(id); // DAO đã lọc status=1 bên trong (hoặc bạn lọc ở đây)
    if (pr != null) {
      imgs = pdao.listImageUrls(id);
      sizes = pdao.listSizes(id);
    }
  } catch (Exception ex) {
    dbErr = ex.getMessage();
  }

  DecimalFormat df = new DecimalFormat("#,###");

  // ===== modal add-to-cart success (query string) =====
  String added = request.getParameter("added");
  String addedName = request.getParameter("addedName");
  String addedPrice = request.getParameter("addedPrice");
  String addedSize = request.getParameter("addedSize");
  String addedImg = request.getParameter("addedImg");
  String addedQty = request.getParameter("addedQty");
  String addedCount = request.getParameter("addedCount");

  // ===== main image fallback =====
  String mainImg = "images/products/demo/sp1.jpg";
  if (pr != null) {
    if (pr.getThumbnail() != null && !pr.getThumbnail().trim().isEmpty()) {
      mainImg = pr.getThumbnail().trim();
    } else if (imgs != null && !imgs.isEmpty() && imgs.get(0) != null && !imgs.get(0).trim().isEmpty()) {
      mainImg = imgs.get(0).trim();
    }
  }
%>

<div class="pd-page">

  <a class="back-link" href="index.jsp?module=product">&larr; Quay lại sản phẩm</a>

  <%-- HIỂN THỊ LỖI DB THẬT (không nuốt lỗi) --%>
  <% if (dbErr != null) { %>
    <div style="padding:12px; margin:12px 0; background:#ffecec; border:1px solid #ffd1d1; border-radius:10px;">
      Lỗi DB: <%=dbErr%>
    </div>
  <% } %>

  <% if (pr == null) { %>
    <div style="padding:14px; margin:14px 0; background:#ffecec; border:1px solid #ffd1d1; border-radius:10px;">
      Không tìm thấy sản phẩm (id=<%=id%>).
    </div>

  <% } else { %>

  <div class="pd-wrap">

    <!-- LEFT: IMAGE -->
    <div class="pd-left">
      <div class="pd-main">
        <img id="pdMainImg" src="<%=mainImg%>" alt="<%=pr.getName()%>">
      </div>

      <div class="pd-thumbs">
        <%
          // danh sách thumb: thumbnail + images phụ (không trùng)
          List<String> thumbList = new ArrayList<>();
          if (pr.getThumbnail() != null && !pr.getThumbnail().trim().isEmpty()) {
            thumbList.add(pr.getThumbnail().trim());
          }
          if (imgs != null) {
            for (String u : imgs) {
              if (u == null) continue;
              String t = u.trim();
              if (!t.isEmpty() && !thumbList.contains(t)) thumbList.add(t);
            }
          }

          if (thumbList.isEmpty()) {
        %>
            <img src="<%=mainImg%>" alt="thumb">
        <%
          } else {
            int maxThumb = Math.min(6, thumbList.size());
            for (int i = 0; i < maxThumb; i++) {
              String t = thumbList.get(i);
        %>
              <img src="<%=t%>" alt="thumb" style="cursor:pointer;" onclick="setMainImg('<%=t%>')">
        <%
            }
          }
        %>
      </div>
    </div>

    <!-- RIGHT: INFO -->
    <div class="pd-right">
      <h2 class="pd-title"><%=pr.getName()%></h2>
      <div class="pd-price"><%=df.format(pr.getPrice())%>đ</div>

      <div class="pd-row">
        <div class="pd-label">Size:</div>
        <div class="pd-size" id="sizeBox">
          <% if (sizes == null || sizes.isEmpty()) { %>
            <span style="opacity:.7;">Hết size</span>
          <% } else { for (String s : sizes) { %>
            <label><input type="radio" name="size" value="<%=s%>"> <%=s%></label>
          <% } } %>
        </div>
      </div>

      <div class="pd-row">
        <div class="pd-label">Số lượng:</div>
        <div class="pd-qty">
          <button type="button" onclick="decQty()">-</button>
          <input id="qty" type="number" value="1" min="1">
          <button type="button" onclick="incQty()">+</button>
        </div>
      </div>

      <div class="pd-actions">
        <button class="pd-btn buy-now" type="button" onclick="goCheckout(<%=id%>)"
                <%= (sizes == null || sizes.isEmpty()) ? "disabled" : "" %>>
          Mua ngay
        </button>

        <button class="pd-btn add-cart" type="button" onclick="addToCart(<%=id%>)"
                <%= (sizes == null || sizes.isEmpty()) ? "disabled" : "" %>>
          Thêm vào giỏ hàng
        </button>
      </div>

      <div class="pd-desc">
        <h3>Mô tả</h3>
        <p><%= (pr.getDescription() == null || pr.getDescription().trim().isEmpty())
                ? "Chưa có mô tả sản phẩm."
                : pr.getDescription() %></p>
        <ul>
          <li>Thương hiệu: <%= (pr.getBrandName() == null ? "Đang cập nhật" : pr.getBrandName()) %></li>
        </ul>
      </div>

    </div>
  </div>

  <% } %>

  <!-- SIZE MODAL -->
  <div class="modal-overlay" id="sizeModal" style="display:none;">
    <div class="modal-box">
      <div class="modal-title">Thông báo</div>
      <div class="modal-msg">Vui lòng chọn size trước khi tiếp tục.</div>
      <button type="button" class="modal-ok" onclick="closeSizeModal()">OK</button>
    </div>
  </div>

  <!-- ADD TO CART SUCCESS MODAL -->
  <div class="modal-overlay" id="cartModal" style="display:none;">
    <div class="cart-modal">
      <div class="cart-modal__top">
        <div class="cart-modal__ok">
          <i class="fa fa-check-circle"></i>
          <span>Thêm sản phẩm vào giỏ hàng thành công</span>
        </div>
        <button class="cart-modal__close" type="button" onclick="closeCartModal()">×</button>
      </div>

      <div class="cart-modal__body">
        <div class="cart-modal__img">
          <img id="cartModalImg" src="" alt="">
        </div>

        <div class="cart-modal__info">
          <div class="cart-modal__name" id="cartModalName"></div>
          <div class="cart-modal__meta">
            <b id="cartModalPrice"></b>
            <span>Size: <span id="cartModalSize"></span></span>
          </div>
          <div class="cart-modal__count" id="cartModalCount"></div>
        </div>
      </div>

      <div class="cart-modal__btns">
        <a class="cartm-btn cartm-btn--gray" href="javascript:void(0)" onclick="closeCartModal()">Tiếp tục mua hàng</a>
        <a class="cartm-btn cartm-btn--orange" href="index.jsp?module=cart">Xem giỏ hàng</a>
      </div>
    </div>
  </div>

</div>

<script>
  function setMainImg(url){
    const im = document.getElementById("pdMainImg");
    if(im) im.src = url;
  }

  function incQty() {
    const ip = document.getElementById('qty');
    ip.value = parseInt(ip.value || '1', 10) + 1;
  }
  function decQty() {
    const ip = document.getElementById('qty');
    const v = parseInt(ip.value || '1', 10);
    if (v > 1) ip.value = v - 1;
  }

  function requireSizeOrShowModal() {
    const r = document.querySelector('input[name="size"]:checked');
    if (!r) {
      openSizeModal();
      return "";
    }
    return r.value;
  }
  function openSizeModal() { const m = document.getElementById("sizeModal"); if (m) m.style.display = "flex"; }
  function closeSizeModal(){ const m = document.getElementById("sizeModal"); if (m) m.style.display = "none"; }

  // Mua ngay (không add vào cart session)
  function goCheckout(id) {
    const size = requireSizeOrShowModal();
    if (!size) return;
    const qtyEl = document.getElementById('qty');
    const qty = qtyEl ? qtyEl.value : 1;

    window.location.href =
      "index.jsp?module=checkout&mode=buynow&id=" + id +
      "&size=" + encodeURIComponent(size) +
      "&qty=" + encodeURIComponent(qty);
  }

  // Thêm giỏ
  function addToCart(id) {
    const size = requireSizeOrShowModal();
    if (!size) return;
    const qtyEl = document.getElementById('qty');
    const qty = qtyEl ? qtyEl.value : 1;

    window.location.href =
      "index.jsp?module=cart&action=add&id=" + id +
      "&size=" + encodeURIComponent(size) +
      "&qty=" + encodeURIComponent(qty) +
      "&idBack=" + id;
  }

  function openCartModal(){ const m = document.getElementById("cartModal"); if (m) m.style.display = "flex"; }
  function closeCartModal(){ const m = document.getElementById("cartModal"); if (m) m.style.display = "none"; }

  (function () {
    const added = "<%= (added == null ? "" : added) %>";
    if (added !== "1") return;

    const nm = "<%= (addedName == null ? "" : addedName) %>";
    const pr = "<%= (addedPrice == null ? "" : addedPrice) %>";
    const sz = "<%= (addedSize == null ? "" : addedSize) %>";
    const im = "<%= (addedImg == null ? "" : addedImg) %>";
    const q  = "<%= (addedQty == null ? "" : addedQty) %>";
    const ct = "<%= (addedCount == null ? "" : addedCount) %>";

    document.getElementById("cartModalName").innerText = nm;
    document.getElementById("cartModalPrice").innerText = pr;
    document.getElementById("cartModalSize").innerText = sz;
    document.getElementById("cartModalImg").src = im;

    let line = "";
    if (q) line += ("Số lượng: " + q + ". ");
    if (ct) line += ct;
    document.getElementById("cartModalCount").innerText = line || "Đã thêm vào giỏ hàng.";

    openCartModal();

    // remove query params to avoid showing again after refresh
    try {
      const url = new URL(window.location.href);
      ["added","addedName","addedPrice","addedSize","addedImg","addedQty","addedCount"]
        .forEach(k => url.searchParams.delete(k));
      window.history.replaceState({}, "", url.toString());
    } catch (e) {}
  })();
</script>
