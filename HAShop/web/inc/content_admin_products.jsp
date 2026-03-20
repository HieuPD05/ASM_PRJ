<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.AdminDAO"%>

<%
    request.setCharacterEncoding("UTF-8");
    AdminDAO dao = new AdminDAO();
    DecimalFormat df = new DecimalFormat("#,###");

    // ===== PAGING =====
    int p = 1;
    try { if(request.getParameter("p") != null) p = Integer.parseInt(request.getParameter("p")); }
    catch(Exception e){ p = 1; }
    if(p < 1) p = 1;

    int pageSize = 5;
    int total = 0;
    int totalPages = 1;
    List<Map<String,Object>> list = new ArrayList<>();
// ===== SEARCH =====
String kw = request.getParameter("q");
if(kw == null) kw = "";
kw = kw.trim();


    String msg = request.getParameter("msg");

    try{
        if(kw.isEmpty()){
    total = dao.countProductsAdmin();
    totalPages = (int)Math.ceil(total * 1.0 / pageSize);
    if(totalPages < 1) totalPages = 1;
    if(p > totalPages) p = totalPages;

    list = dao.listProductsAdminPaged(p, pageSize);
} else {
    // cần 2 method search trong AdminDAO (mình sẽ đưa ở cuối)
    total = dao.countProductsAdminSearch(kw);
    totalPages = (int)Math.ceil(total * 1.0 / pageSize);
    if(totalPages < 1) totalPages = 1;
    if(p > totalPages) p = totalPages;

    list = dao.listProductsAdminSearchPaged(kw, p, pageSize);
}

    }catch(Exception ex){
        msg = "db_error";
        request.setAttribute("dbError", ex.getMessage());
    }

    // ===== BRAND LIST =====
    List<Map<String,Object>> brands = new ArrayList<>();
    try{ brands = dao.listBrands(); }catch(Exception e){ brands = new ArrayList<>(); }

    // ===== EDIT MODE =====
    int editId = 0;
    try { if(request.getParameter("edit_id") != null) editId = Integer.parseInt(request.getParameter("edit_id")); }
    catch(Exception e){ editId = 0; }

    Map<String,Object> edit = null;
    if(editId > 0){
        try{ edit = dao.getProductAdmin(editId); }catch(Exception e){ edit = null; }
        if(edit == null) editId = 0;
    }
    List<String> extraImages = new ArrayList<>();
if(editId > 0){
    extraImages = dao.getProductImages(editId);
}


    // show modal?
    boolean showForm = "1".equals(request.getParameter("showForm")) || (editId > 0);

    // ===== size prefill =====
    Map<Integer,Integer> sizeMap = new LinkedHashMap<>();
    if(editId > 0){
        try{ sizeMap = dao.getProductSizesMap(editId); }catch(Exception e){ sizeMap = new LinkedHashMap<>(); }
    }

    // ===== image prefill (product_images) =====
    // Quy ước: products.thumbnail là ảnh chính.
    // product_images: sort_order=1 thường là ảnh chính/đầu tiên, ảnh phụ tiếp theo.
    String fImg1 = "";
    String fImg2 = "";
    String fImg3 = "";
    if(editId > 0){
        try{
            List<String> imgs = dao.getProductImages(editId);
            // bỏ ảnh chính nếu nó trùng thumbnail ở đầu danh sách
            // => lấy 3 ảnh sau đó làm ảnh phụ
            int idx = 0;

            String thumb = (edit!=null && edit.get("thumbnail")!=null) ? String.valueOf(edit.get("thumbnail")) : "";
            // nếu imgs[0] trùng thumbnail, bắt đầu từ 1
            if(imgs.size() > 0 && thumb != null && !thumb.trim().isEmpty()){
                if(thumb.trim().equalsIgnoreCase(imgs.get(0).trim())){
                    idx = 1;
                }
            }

            if(idx < imgs.size()) fImg1 = imgs.get(idx++);
            if(idx < imgs.size()) fImg2 = imgs.get(idx++);
            if(idx < imgs.size()) fImg3 = imgs.get(idx++);
        }catch(Exception e){
            // ignore
        }
    }

    // ===== form values =====
    String fName = (edit!=null && edit.get("name")!=null) ? String.valueOf(edit.get("name")) : "";
    String fDesc = (edit!=null && edit.get("description")!=null) ? String.valueOf(edit.get("description")) : "";
    String fMain = (edit!=null && edit.get("thumbnail")!=null) ? String.valueOf(edit.get("thumbnail")) : "";
    String fTarget = (edit!=null && edit.get("target")!=null) ? String.valueOf(edit.get("target")) : "both";

    int fPrice = 0;
    if(edit!=null && edit.get("price") instanceof Number) fPrice = ((Number)edit.get("price")).intValue();

    int fBrandId = 0;
    if(edit!=null && edit.get("brand_id") instanceof Number) fBrandId = ((Number)edit.get("brand_id")).intValue();
%>

<style>
  .ad-msg{ padding:10px 12px; border-radius:12px; font-weight:800; margin:10px 0; border:1px solid #eee; }
  .ad-msg.ok{ background:#f2fff2; border-color:#d7f2d7; }
  .ad-msg.warn{ background:#fff8e6; border-color:#ffe3a4; }
  .ad-msg.err{ background:#ffecec; border-color:#ffd1d1; }

  .ad-card{ background:#fff; border:1px solid #eee; border-radius:16px; padding:14px; margin-bottom:14px; }
  .ad-card-title{ font-weight:900; margin:0 0 10px; }

  .ad-btn{ padding:10px 14px; border-radius:14px; border:0; cursor:pointer; font-weight:900; text-decoration:none; display:inline-flex; align-items:center; justify-content:center; }
  .ad-btn.black{ background:#111; color:#fff; }
  .ad-btn.gray{ background:#888; color:#fff; }
  .ad-btn.red{ background:#e74c3c; color:#fff; }

  .paging{ display:flex; gap:8px; justify-content:center; margin-top:14px; flex-wrap:wrap; }
  .page-btn{ padding:8px 12px; border:1px solid #eee; border-radius:12px; text-decoration:none; color:#111; background:#fff; }
  .page-btn.active{ background:#111; color:#fff; border-color:#111; }
  .page-btn.disabled{ pointer-events:none; opacity:.4; }

  /* ===== FORM: label to + đậm + căn trái ===== */
  .ad-form{ display:grid; grid-template-columns:1fr !important; gap:12px; }
  .ad-form label{
    font-weight:900;         /* đậm hơn */
    font-size:15px;          /* to hơn */
    display:block;
    text-align:left;
    margin:0 0 6px;
    color:#111;
  }
  .ad-form input, .ad-form select, .ad-form textarea{
    width:100%; padding:10px 12px;
    border:1px solid #e6e6e6; border-radius:14px; outline:none;
  }
  .ad-form textarea{ min-height:90px; resize:vertical; }

  .size-grid{ display:grid; grid-template-columns:repeat(6, minmax(0,1fr)); gap:10px; }
  .size-item{ background:#fafafa; border:1px solid #eee; border-radius:12px; padding:8px; }
  .size-lb{ font-weight:900; margin-bottom:6px; font-size:14px; text-align:left; } /* to hơn */
  .size-item input{ width:100%; padding:8px 10px; border:1px solid #e6e6e6; border-radius:10px; }

  /* ===== DRAG DROP IMAGE UPLOAD ===== */
  .img-drop-zone {
    position: relative;
    width: 100%;
    height: 180px;
    border: 2px dashed #ddd;
    border-radius: 14px;
    background: #fafafa;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    overflow: hidden;
    transition: border-color .2s, background .2s;
  }
  .img-drop-zone.drag-over {
    border-color: #ff6a00;
    background: #fff8f4;
  }
  .img-drop-zone img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
    border-radius: 12px;
  }
  .img-drop-zone .drop-hint {
    text-align: center;
    color: #aaa;
    font-size: 13px;
    line-height: 1.6;
    pointer-events: none;
  }
  .img-drop-zone .drop-hint i {
    font-size: 28px;
    display: block;
    margin-bottom: 6px;
    color: #ccc;
  }
  .img-drop-zone:hover {
    border-color: #ff6a00;
  }
  .img-drop-sm {
    height: 120px;
  }
  .modal-mask{
    position:fixed; inset:0;
    background:rgba(0,0,0,.45);
    display:none;
    align-items:flex-start;
    justify-content:center;
    z-index:9999;
    padding:14px;
    overflow:auto;
  }
  .modal-mask.show{ display:flex; }
  .modal-box{
    width:min(760px, calc(100% - 24px));
    background:#fff;
    border-radius:18px;
    border:1px solid #eee;
    padding:14px;
    margin-top:10px;
  }
  .modal-head{
    display:flex; align-items:center; justify-content:space-between; gap:10px;
    margin-bottom:10px;
  }
  .modal-head h3{ margin:0; font-weight:900; }
  .modal-close{
    border:0; cursor:pointer;
    width:40px; height:40px;
    border-radius:12px;
    background:#f3f3f3;
    font-weight:900;
  }
</style>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">
    <h2>Quản lý sản phẩm</h2>

    <% if("created".equals(msg)){ %>
      <div class="ad-msg ok">✅ Thêm sản phẩm thành công</div>
    <% } else if("updated".equals(msg)){ %>
      <div class="ad-msg ok">✅ Cập nhật sản phẩm thành công</div>
    <% } else if("deleted".equals(msg)){ %>
      <div class="ad-msg ok">✅ Xóa sản phẩm thành công</div>
    <% } else if("brand_required".equals(msg)){ %>
      <div class="ad-msg warn">⚠️ Vui lòng chọn thương hiệu</div>
    <% } else if("delete_blocked_order".equals(msg)){ %>
      <div class="ad-msg warn">⚠️ Không thể xóa: sản phẩm đã có trong đơn hàng</div>
    <% } else if("delete_blocked_cart".equals(msg)){ %>
      <div class="ad-msg warn">⚠️ Không thể xóa: sản phẩm đang có trong giỏ hàng</div>
    <% } else if("db_error".equals(msg)){ %>
      <div class="ad-msg err">❌ Lỗi DB: <%=request.getAttribute("dbError")%></div>
    <% } %>

    <div class="ad-card">
     <div style="display:flex;justify-content:space-between;align-items:center;gap:10px;flex-wrap:wrap">
  <h3 class="ad-card-title" style="margin:0">Danh sách sản phẩm</h3>

  <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap">
    <!-- SEARCH -->
    <form method="get" action="index.jsp" style="display:flex;gap:8px;align-items:center">
      <input type="hidden" name="module" value="admin_products"/>
      <input type="hidden" name="p" value="1"/>
      <input class="ip" name="q" value="<%=kw%>" placeholder="Tìm theo tên..." style="width:240px"/>
      <button class="ad-btn gray" type="submit">
        <i class="fa fa-search"></i>
      </button>

      <% if(!kw.isEmpty()){ %>
        <a class="ad-btn gray" href="index.jsp?module=admin_products&p=1">Xóa lọc</a>
      <% } %>
    </form>

    <!-- ADD -->
    <a class="ad-btn black" href="index.jsp?module=admin_products&p=<%=p%>&showForm=1">+ Thêm sản phẩm</a>
  </div>
</div>


      <table class="ad-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Tên</th>
            <th>Giá</th>
            <th>Tồn kho</th>
            <th>Ảnh</th>
            <th>Hành động</th>
          </tr>
        </thead>
        <tbody>
        <% if(list == null || list.isEmpty()){ %>
          <tr><td colspan="6">Chưa có sản phẩm.</td></tr>
        <% } else { for(Map<String,Object> pr : list){
              int id = (Integer)pr.get("product_id");
              String name = String.valueOf(pr.get("name"));
              int price = (Integer)pr.get("price");
              int stock = (Integer)pr.get("total_stock");

              String img = (pr.get("thumbnail") == null) ? "" : String.valueOf(pr.get("thumbnail"));
              if(img == null || img.trim().isEmpty()) img = "images/products/demo/sp1.jpg";
        %>
          <tr>
            <td>#<%=id%></td>
            <td><%=name%></td>
            <td><%=df.format(price)%> đ</td>
            <td><%=stock%></td>
            <td>
              <img src="<%=img%>" style="width:56px;height:56px;object-fit:cover;border-radius:10px;border:1px solid #eee"/>
            </td>
            <td style="white-space:nowrap">
              <a class="ad-btn gray" href="index.jsp?module=admin_products&edit_id=<%=id%>&p=<%=p%>&showForm=1">Sửa</a>

              <form action="<%=request.getContextPath()%>/admin/product" method="post" style="display:inline-block"
                    onsubmit="return confirm('Xóa sản phẩm #<%=id%>?')">
                <input type="hidden" name="action" value="delete"/>
                <input type="hidden" name="product_id" value="<%=id%>"/>
                <input type="hidden" name="p" value="<%=p%>"/>
                <button class="ad-btn red" type="submit">Xóa</button>
              </form>
            </td>
          </tr>
        <% } } %>
        </tbody>
      </table>

    <div class="paging">

  <!-- PREV -->
  <a class="page-btn <%= (p==1 ? "disabled":"") %>"
     href="index.jsp?module=admin_products&p=<%=Math.max(1,p-1)%>&q=<%=java.net.URLEncoder.encode(kw,"UTF-8")%>">
     &laquo;
  </a>

  <!-- PAGE NUMBERS -->
  <% for(int k=1;k<=totalPages;k++){ %>
    <a class="page-btn <%= (k==p ? "active":"") %>"
       href="index.jsp?module=admin_products&p=<%=k%>&q=<%=java.net.URLEncoder.encode(kw,"UTF-8")%>">
       <%=k%>
    </a>
  <% } %>

  <!-- NEXT -->
  <a class="page-btn <%= (p==totalPages ? "disabled":"") %>"
     href="index.jsp?module=admin_products&p=<%=Math.min(totalPages,p+1)%>&q=<%=java.net.URLEncoder.encode(kw,"UTF-8")%>">
     &raquo;
  </a>

</div>

    </div>
  </div>
</div>

<!-- ===== MODAL THÊM / SỬA SẢN PHẨM ===== -->
<div id="modalMask" class="modal-mask" onclick="if(event.target.id==='modalMask'){closeModal()}">
  <div class="modal-box">
    <div class="modal-head">
      <h3><%= (editId>0 ? ("Sửa sản phẩm #"+editId) : "Thêm sản phẩm mới") %></h3>
      <button class="modal-close" type="button" onclick="closeModal()">✕</button>
    </div>

    <%
      String oldImg1 = (extraImages != null && extraImages.size() > 0) ? extraImages.get(0) : "";
      String oldImg2 = (extraImages != null && extraImages.size() > 1) ? extraImages.get(1) : "";
      String oldImg3 = (extraImages != null && extraImages.size() > 2) ? extraImages.get(2) : "";
    %>

    <form class="ad-form" action="<%=request.getContextPath()%>/admin/product" method="post"
          enctype="multipart/form-data">

      <input type="hidden" name="action"     value="<%= (editId>0 ? "update" : "create") %>"/>
      <input type="hidden" name="product_id" value="<%=editId%>"/>
      <input type="hidden" name="p"          value="<%=p%>"/>
      <%-- Giữ ảnh cũ nếu admin không upload ảnh mới --%>
      <input type="hidden" name="old_main_image" value="<%=fMain%>"/>
      <input type="hidden" name="old_img1"       value="<%=oldImg1%>"/>
      <input type="hidden" name="old_img2"       value="<%=oldImg2%>"/>
      <input type="hidden" name="old_img3"       value="<%=oldImg3%>"/>

      <div>
        <label>Tên sản phẩm</label>
        <input name="name" value="<%=fName%>" required/>
      </div>

      <div>
        <label>Giá</label>
        <input name="price" type="number" min="0" value="<%=fPrice%>" required/>
      </div>

      <div>
        <label>Thương hiệu</label>
        <select name="brand_id" required>
          <option value="">-- Chọn brand --</option>
          <%
            for(Map<String,Object> b : brands){
                int bid = (b.get("brand_id") instanceof Number) ? ((Number)b.get("brand_id")).intValue() : 0;
                Object oName = b.get("name");
                if(oName == null) oName = b.get("brand_name");
                String bname = (oName == null) ? ("Brand #" + bid) : String.valueOf(oName);
                if(bname == null || "null".equalsIgnoreCase(bname.trim()) || bname.trim().isEmpty())
                    bname = "Brand #" + bid;
          %>
            <option value="<%=bid%>" <%= (bid==fBrandId ? "selected":"") %>><%=bname%></option>
          <% } %>
        </select>
      </div>

      <div>
        <label>Target</label>
        <select name="target">
          <option value="both"  <%= "both".equalsIgnoreCase(fTarget)  ? "selected":"" %>>Cả hai</option>
          <option value="men"   <%= "men".equalsIgnoreCase(fTarget)   ? "selected":"" %>>Nam</option>
          <option value="women" <%= "women".equalsIgnoreCase(fTarget) ? "selected":"" %>>Nữ</option>
        </select>
      </div>

      <div>
        <label>Mô tả</label>
        <textarea name="description"><%=fDesc%></textarea>
      </div>

      <%-- ===== KHU VỰC ẢNH: NHẤN CHỌN HOẶC KÉO THẢ ===== --%>
      <div>
        <label>Ảnh sản phẩm</label>
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr 1fr;gap:10px;margin-top:8px;">

          <%-- ẢNH CHÍNH --%>
          <div>
            <div style="font-size:11px;color:#888;margin-bottom:4px;text-align:center;">Ảnh chính</div>
            <div class="img-drop-zone" id="dropMain"
                 onclick="document.getElementById('file_main').click()"
                 ondragover="dzOver(event)" ondragleave="dzLeave(event)"
                 ondrop="dzDrop(event,'file_main','prev_main')">
              <% if(fMain != null && !fMain.trim().isEmpty()){ %>
                <img id="prev_main" src="<%=fMain%>" alt=""/>
              <% } else { %>
                <img id="prev_main" style="display:none" src="" alt=""/>
                <span class="dz-hint"><i class="fa fa-camera fa-lg"></i><br>Kéo thả<br>hoặc nhấn</span>
              <% } %>
            </div>
            <input type="file" id="file_main" name="main_image" accept="image/*" style="display:none"
                   onchange="dzPreview(this,'prev_main')"/>
          </div>

          <%-- ẢNH PHỤ 1 --%>
          <div>
            <div style="font-size:11px;color:#888;margin-bottom:4px;text-align:center;">Ảnh phụ 1</div>
            <div class="img-drop-zone img-drop-sm" id="dropE1"
                 onclick="document.getElementById('file_e1').click()"
                 ondragover="dzOver(event)" ondragleave="dzLeave(event)"
                 ondrop="dzDrop(event,'file_e1','prev_e1')">
              <% if(oldImg1 != null && !oldImg1.trim().isEmpty()){ %>
                <img id="prev_e1" src="<%=oldImg1%>" alt=""/>
              <% } else { %>
                <img id="prev_e1" style="display:none" src="" alt=""/>
                <span class="dz-hint"><i class="fa fa-plus"></i><br>Thêm ảnh</span>
              <% } %>
            </div>
            <input type="file" id="file_e1" name="img_extra_1" accept="image/*" style="display:none"
                   onchange="dzPreview(this,'prev_e1')"/>
          </div>

          <%-- ẢNH PHỤ 2 --%>
          <div>
            <div style="font-size:11px;color:#888;margin-bottom:4px;text-align:center;">Ảnh phụ 2</div>
            <div class="img-drop-zone img-drop-sm" id="dropE2"
                 onclick="document.getElementById('file_e2').click()"
                 ondragover="dzOver(event)" ondragleave="dzLeave(event)"
                 ondrop="dzDrop(event,'file_e2','prev_e2')">
              <% if(oldImg2 != null && !oldImg2.trim().isEmpty()){ %>
                <img id="prev_e2" src="<%=oldImg2%>" alt=""/>
              <% } else { %>
                <img id="prev_e2" style="display:none" src="" alt=""/>
                <span class="dz-hint"><i class="fa fa-plus"></i><br>Thêm ảnh</span>
              <% } %>
            </div>
            <input type="file" id="file_e2" name="img_extra_2" accept="image/*" style="display:none"
                   onchange="dzPreview(this,'prev_e2')"/>
          </div>

          <%-- ẢNH PHỤ 3 --%>
          <div>
            <div style="font-size:11px;color:#888;margin-bottom:4px;text-align:center;">Ảnh phụ 3</div>
            <div class="img-drop-zone img-drop-sm" id="dropE3"
                 onclick="document.getElementById('file_e3').click()"
                 ondragover="dzOver(event)" ondragleave="dzLeave(event)"
                 ondrop="dzDrop(event,'file_e3','prev_e3')">
              <% if(oldImg3 != null && !oldImg3.trim().isEmpty()){ %>
                <img id="prev_e3" src="<%=oldImg3%>" alt=""/>
              <% } else { %>
                <img id="prev_e3" style="display:none" src="" alt=""/>
                <span class="dz-hint"><i class="fa fa-plus"></i><br>Thêm ảnh</span>
              <% } %>
            </div>
            <input type="file" id="file_e3" name="img_extra_3" accept="image/*" style="display:none"
                   onchange="dzPreview(this,'prev_e3')"/>
          </div>

        </div>
        <div style="margin-top:6px;font-size:11px;color:#aaa;">JPG, PNG, WEBP — tối đa 10MB/ảnh</div>
      </div>

      <div>
        <label>Số lượng theo size</label>
        <div class="size-grid">
          <% for(int s=38; s<=43; s++){
               int val = 0;
               if(editId > 0){ Integer qq = sizeMap.get(s); val = (qq==null ? 0 : qq); }
          %>
            <div class="size-item">
              <div class="size-lb">Size <%=s%></div>
              <input name="qty_<%=s%>" type="number" min="0" value="<%=val%>"/>
            </div>
          <% } %>
        </div>
      </div>

      <div style="display:flex;gap:10px;align-items:center;margin-top:8px">
        <button class="ad-btn black" type="submit"><%= (editId>0 ? "Cập nhật" : "Thêm sản phẩm") %></button>
        <a class="ad-btn gray" href="index.jsp?module=admin_products&p=<%=p%>">Hủy</a>
      </div>
    </form>
  </div>
</div>

<style>
/* ===== DROP ZONE ===== */
.img-drop-zone {
  width: 100%;
  aspect-ratio: 1/1;
  border: 2px dashed #ddd;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  background: #fafafa;
  overflow: hidden;
  position: relative;
  transition: border-color .2s, background .2s;
}
.img-drop-zone:hover,
.img-drop-zone.drag-over {
  border-color: #ff6a00;
  background: #fff7f0;
}
.img-drop-zone img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
  border-radius: 10px;
}
.dz-hint {
  text-align: center;
  color: #aaa;
  font-size: 12px;
  line-height: 1.6;
  pointer-events: none;
}
</style>

<script>
  function openModal(){ document.getElementById('modalMask').classList.add('show'); }
  function closeModal(){ document.getElementById('modalMask').classList.remove('show'); }

  (function(){
    var show = "<%= showForm ? "1" : "0" %>";
    if(show === "1") openModal();
  })();

  /* ===== DRAG & DROP + PREVIEW ===== */
  function dzOver(e){
    e.preventDefault();
    e.currentTarget.classList.add('drag-over');
  }
  function dzLeave(e){
    e.currentTarget.classList.remove('drag-over');
  }
  function dzDrop(e, fileInputId, previewId){
    e.preventDefault();
    e.currentTarget.classList.remove('drag-over');
    var files = e.dataTransfer.files;
    if(!files || files.length === 0) return;
    var inp = document.getElementById(fileInputId);
    // gán file vào input (DataTransfer trick)
    try {
      var dt = new DataTransfer();
      dt.items.add(files[0]);
      inp.files = dt.files;
    } catch(ex) {}
    showPreview(files[0], previewId);
  }
  function dzPreview(input, previewId){
    if(input.files && input.files[0])
      showPreview(input.files[0], previewId);
  }
  function showPreview(file, previewId){
    if(!file.type.startsWith('image/')) return;
    var reader = new FileReader();
    reader.onload = function(ev){
      var img = document.getElementById(previewId);
      img.src = ev.target.result;
      img.style.display = 'block';
      // ẩn hint text nếu có
      var hint = img.parentElement.querySelector('.dz-hint');
      if(hint) hint.style.display = 'none';
    };
    reader.readAsDataURL(file);
  }
</script>
