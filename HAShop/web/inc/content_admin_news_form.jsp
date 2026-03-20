<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="dal.AdminDAO"%>

<%
  int id = 0;
  try{ id = Integer.parseInt(request.getParameter("id")); }catch(Exception e){ id = 0; }

  int pageNo = 1;
  try { pageNo = Integer.parseInt(request.getParameter("page")); } catch(Exception e){ pageNo = 1; }
  if(pageNo < 1) pageNo = 1;

  String backUrl = "index.jsp?module=admin_news&page=" + pageNo;

  AdminDAO dao = new AdminDAO();
  Map<String,Object> post = (id>0) ? dao.getNews(id) : null;

  String title     = post==null ? "" : String.valueOf(post.get("title"));
  String summary   = post==null ? "" : String.valueOf(post.get("summary"));
  String content   = post==null ? "" : String.valueOf(post.get("content"));
  String thumbnail = post==null ? "" : String.valueOf(post.get("thumbnail"));
  if("null".equals(thumbnail)) thumbnail = "";

  boolean active = true;
  if(post != null){
    try{
      Object a = post.get("is_active");
      if(a instanceof Boolean) active = (Boolean)a;
      else if(a instanceof Number) active = ((Number)a).intValue() == 1;
      else active = "true".equalsIgnoreCase(String.valueOf(a)) || "1".equals(String.valueOf(a));
    }catch(Exception e){ active = true; }
  }
%>

<style>
/* Drop zone thumbnail */
.news-dz{
  width:100%;
  height:180px;
  border:2px dashed #e0e0e0;
  border-radius:14px;
  display:flex;
  align-items:center;
  justify-content:center;
  cursor:pointer;
  overflow:hidden;
  background:#fafafa;
  position:relative;
  transition:border-color .2s, background .2s;
}
.news-dz:hover{ border-color:#ff6a00; background:#fff8f3; }
.news-dz.drag-over{ border-color:#ff6a00; background:#fff3ec; }
.news-dz img{
  width:100%;
  height:100%;
  object-fit:cover;
  border-radius:12px;
}
.news-dz .dz-hint{
  display:flex;
  flex-direction:column;
  align-items:center;
  gap:8px;
  color:#aaa;
  font-size:13px;
  text-align:center;
  pointer-events:none;
}
.news-dz .dz-hint i{ font-size:28px; color:#ccc; }
.news-dz-label{
  font-size:12px;
  color:#888;
  margin-top:6px;
}
</style>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">
    <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
      <h2><%= (id>0 ? "Sửa bài #" + id : "Thêm bài mới") %></h2>
      <a class="ad-btn gray" href="<%=backUrl%>">&larr; Quay lại</a>
    </div>

    <form action="<%=request.getContextPath()%>/admin/news" method="post"
          enctype="multipart/form-data"
          class="ad-card" style="padding:16px">

      <input type="hidden" name="action"  value="<%= (id>0 ? "update" : "create") %>"/>
      <input type="hidden" name="post_id" value="<%=id%>"/>
      <input type="hidden" name="page"    value="<%=pageNo%>"/>
      <input type="hidden" name="old_thumbnail" value="<%=thumbnail%>"/>

      <!-- Tiêu đề -->
      <div style="margin-bottom:12px">
        <label style="font-weight:800;display:block;margin-bottom:6px">Tiêu đề *</label>
        <input name="title" value="<%=title%>" required
               style="width:100%;padding:10px 12px;border:1px solid #ddd;border-radius:10px;font-family:inherit"/>
      </div>

      <!-- Thumbnail upload -->
      <div style="margin-bottom:12px">
        <label style="font-weight:800;display:block;margin-bottom:6px">Ảnh thumbnail</label>

        <div class="news-dz" id="newsDz"
             onclick="document.getElementById('newsThumbFile').click()"
             ondragover="newsDzOver(event)" ondragleave="newsDzLeave(event)"
             ondrop="newsDzDrop(event)">

          <% if(thumbnail != null && !thumbnail.isEmpty()){ %>
            <img id="newsThumbPrev" src="<%=thumbnail%>" alt="thumbnail"/>
          <% } else { %>
            <img id="newsThumbPrev" src="" alt="" style="display:none"/>
            <div class="dz-hint" id="newsDzHint">
              <i class="fa fa-image"></i>
              <span>Kéo thả ảnh vào đây<br>hoặc nhấn để chọn</span>
            </div>
          <% } %>
        </div>

        <input type="file" id="newsThumbFile" name="thumbnail_file"
               accept="image/*" style="display:none"
               onchange="newsThumbPreview(this)"/>

        <div class="news-dz-label">JPG, PNG, WEBP — tối đa 10MB</div>
      </div>

      <!-- Mô tả ngắn -->
      <div style="margin-bottom:12px">
        <label style="font-weight:800;display:block;margin-bottom:6px">Mô tả ngắn</label>
        <textarea name="summary" rows="3"
                  style="width:100%;padding:10px 12px;border:1px solid #ddd;border-radius:10px;font-family:inherit;resize:vertical"><%=summary%></textarea>
      </div>

      <!-- Nội dung -->
      <div style="margin-bottom:12px">
        <label style="font-weight:800;display:block;margin-bottom:6px">Nội dung *</label>
        <textarea name="content" rows="12" required
                  style="width:100%;padding:10px 12px;border:1px solid #ddd;border-radius:10px;font-family:inherit;resize:vertical"><%=content%></textarea>
      </div>

      <!-- Hiển thị + Lưu -->
      <div style="display:flex;gap:16px;align-items:center;flex-wrap:wrap">
        <label style="display:flex;align-items:center;gap:8px;font-weight:700;cursor:pointer">
          <input type="checkbox" name="is_active" value="1" <%= active ? "checked" : "" %>/>
          Hiển thị bài viết
        </label>
        <button class="ad-btn black" type="submit">Lưu bài</button>
        <a class="ad-btn gray" href="<%=backUrl%>">Hủy</a>
      </div>
    </form>
  </div>
</div>

<script>
function newsThumbPreview(input){
  if(!input.files || !input.files[0]) return;
  var reader = new FileReader();
  reader.onload = function(e){
    var prev = document.getElementById('newsThumbPrev');
    var hint = document.getElementById('newsDzHint');
    prev.src = e.target.result;
    prev.style.display = 'block';
    if(hint) hint.style.display = 'none';
  };
  reader.readAsDataURL(input.files[0]);
}
function newsDzOver(e){
  e.preventDefault();
  document.getElementById('newsDz').classList.add('drag-over');
}
function newsDzLeave(e){
  document.getElementById('newsDz').classList.remove('drag-over');
}
function newsDzDrop(e){
  e.preventDefault();
  document.getElementById('newsDz').classList.remove('drag-over');
  var files = e.dataTransfer.files;
  if(files && files[0]){
    var fi = document.getElementById('newsThumbFile');
    // Gán file vào input
    var dt = new DataTransfer();
    dt.items.add(files[0]);
    fi.files = dt.files;
    newsThumbPreview(fi);
  }
}
</script>
