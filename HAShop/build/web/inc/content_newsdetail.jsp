<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.sql.*"%>
<%@page import="dal.DBContext"%>

<%
  int id = 0;
  try { if(request.getParameter("id") != null) id = Integer.parseInt(request.getParameter("id")); }
  catch(Exception e){ id = 0; }

  Map<String,Object> post = null;
  String dbError = null;

  String sql =
      "SELECT post_id, title, summary, content, thumbnail, created_at " +
      "FROM news_posts WHERE is_active=1 AND post_id=?";

  try(Connection con = new DBContext().getConnection();
      PreparedStatement ps = con.prepareStatement(sql)){

      ps.setInt(1, id);

      try(ResultSet rs = ps.executeQuery()){
          if(rs.next()){
              post = new HashMap<>();
              post.put("post_id", rs.getInt("post_id"));
              post.put("title", rs.getString("title"));
              post.put("summary", rs.getString("summary"));
              post.put("content", rs.getString("content"));
              post.put("thumbnail", rs.getString("thumbnail"));
              post.put("created_at", rs.getTimestamp("created_at"));
          }
      }

  }catch(Exception ex){
      dbError = ex.getMessage();
  }

  SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy HH:mm");
%>

<div class="page-box">

  <div class="news-detail-head">
    <a class="back-link" href="index.jsp?module=news">&larr; Quay lại Tin tức</a>

    <% if(dbError != null){ %>
      <div class="ad-msg warn" style="margin-top:10px">⚠️ Lỗi DB: <%=dbError%></div>
    <% } %>

    <% if(post == null){ %>
      <h2 class="news-detail-title">Không tìm thấy bài viết</h2>
    <% } else { 
        String title = (String)post.get("title");
        String content = (String)post.get("content");
        String thumb = (String)post.get("thumbnail");
        if(thumb == null || thumb.trim().isEmpty()) thumb = "images/news/news-01.jpg";

        Timestamp ts = (Timestamp)post.get("created_at");
        String date = (ts == null ? "" : sdf.format(ts));
    %>

      <h2 class="news-detail-title"><%=title%></h2>
      <div class="news-detail-meta">Ngày đăng: <%=date%></div>
  </div>

  <div class="news-detail-cover">
    <img src="<%=thumb%>" alt="<%=title%>">
  </div>

  <div class="news-detail-content">
    <%
      // content lưu NVARCHAR(MAX). Nếu bạn muốn cho phép HTML thì dùng out.print(content) (cẩn thận XSS).
      // Ở đây hiển thị an toàn dạng text + xuống dòng:
      if(content == null) content = "";
      String safe = content.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
      safe = safe.replace("\r\n","<br/>").replace("\n","<br/>");
      out.print(safe);
    %>
  </div>

    <% } %>

</div>
