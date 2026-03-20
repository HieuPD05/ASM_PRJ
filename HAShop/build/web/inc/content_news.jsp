<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.sql.*"%>
<%@page import="dal.DBContext"%>

<%
  // ====== paging ======
  int p = 1;
  try { if(request.getParameter("p") != null) p = Integer.parseInt(request.getParameter("p")); }
  catch(Exception e){ p = 1; }

  int pageSize = 4;
  if(p < 1) p = 1;

  // ====== query DB ======
  List<Map<String,Object>> rows = new ArrayList<>();
  int totalNews = 0;

  String sqlCount = "SELECT COUNT(*) FROM news_posts WHERE is_active=1";
  String sqlList =
      "SELECT post_id, title, summary, thumbnail, created_at " +
      "FROM news_posts WHERE is_active=1 " +
      "ORDER BY created_at DESC, post_id DESC " +
      "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

  try(Connection con = new DBContext().getConnection()){
      // count
      try(PreparedStatement ps = con.prepareStatement(sqlCount);
          ResultSet rs = ps.executeQuery()){
          if(rs.next()) totalNews = rs.getInt(1);
      }

      int totalPages = (int)Math.ceil(totalNews * 1.0 / pageSize);
      if(totalPages < 1) totalPages = 1;
      if(p > totalPages) p = totalPages;

      int offset = (p - 1) * pageSize;

      try(PreparedStatement ps = con.prepareStatement(sqlList)){
          ps.setInt(1, offset);
          ps.setInt(2, pageSize);
          try(ResultSet rs = ps.executeQuery()){
              while(rs.next()){
                  Map<String,Object> m = new HashMap<>();
                  m.put("post_id", rs.getInt("post_id"));
                  m.put("title", rs.getString("title"));
                  m.put("summary", rs.getString("summary"));
                  m.put("thumbnail", rs.getString("thumbnail"));
                  m.put("created_at", rs.getTimestamp("created_at"));
                  rows.add(m);
              }
          }
      }

      // đưa totalPages ra JSP
      request.setAttribute("totalPages", totalPages);

  }catch(Exception ex){
      // nếu lỗi DB, bạn có thể in ra để debug
      request.setAttribute("dbError", ex.getMessage());
  }

  Integer totalPagesObj = (Integer)request.getAttribute("totalPages");
  int totalPages = (totalPagesObj == null ? 1 : totalPagesObj);

  SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy");
%>

<div class="page-box">

  <div class="page-head">
    <h2>Tin tức</h2>
    
  </div>

  <% String dbError = (String)request.getAttribute("dbError"); %>
  <% if(dbError != null){ %>
    <div class="ad-msg warn">⚠️ Lỗi DB: <%=dbError%></div>
  <% } %>

  <div class="news-grid news-grid-2">
    <% if(rows.isEmpty()){ %>
      <div class="ad-msg warn" style="width:100%">⚠️ Chưa có bài viết.</div>
    <% } %>

    <% for(Map<String,Object> n : rows){
        int id = (Integer)n.get("post_id");
        String title = (String)n.get("title");
        String summary = (String)n.get("summary");
        String thumb = (String)n.get("thumbnail");
        if(thumb == null || thumb.trim().isEmpty()) thumb = "images/news/news-01.jpg";

        Timestamp ts = (Timestamp)n.get("created_at");
        String date = (ts == null ? "" : sdf.format(ts));
        if(summary == null) summary = "";
    %>

      <div class="news-card3">
        <div class="news-img3">
          <img src="<%=thumb%>" alt="<%=title%>">
        </div>

        <div class="news-float">
          <h3 class="news-title3"><%=title%></h3>

          <div class="news-date3">
            <span class="line"></span>
            <span class="pill"><%=date%></span>
            <span class="line"></span>
          </div>

          <p class="news-desc3"><%=summary%></p>

          <a class="news-link3" href="index.jsp?module=news_detail&id=<%=id%>">Xem chi tiết</a>
        </div>
      </div>

    <% } %>
  </div>

  <!-- PAGINATION -->
  <div class="paging">
    <a class="page-btn <%= (p==1 ? "disabled" : "") %>"
       href="index.jsp?module=news&p=<%=Math.max(1, p-1)%>">&laquo;</a>

    <% for (int k = 1; k <= totalPages; k++) { %>
      <a class="page-btn <%= (k==p ? "active" : "") %>"
         href="index.jsp?module=news&p=<%=k%>"><%=k%></a>
    <% } %>

    <a class="page-btn <%= (p==totalPages ? "disabled" : "") %>"
       href="index.jsp?module=news&p=<%=Math.min(totalPages, p+1)%>">&raquo;</a>
  </div>

</div>
