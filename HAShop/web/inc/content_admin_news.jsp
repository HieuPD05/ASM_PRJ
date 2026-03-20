<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="dal.AdminDAO"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.text.SimpleDateFormat"%>

<%
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  AdminDAO dao = new AdminDAO();
  List<Map<String,Object>> list = dao.listNewsAdmin();
  String msg = request.getParameter("msg");

  // ===== PAGINATION (5 item / page) =====
  int pageSize = 5;
  int pageNo = 1;
  try { pageNo = Integer.parseInt(request.getParameter("page")); } catch(Exception e){ pageNo = 1; }
  if(pageNo < 1) pageNo = 1;

  int total = (list == null) ? 0 : list.size();
  int totalPages = (int)Math.ceil(total * 1.0 / pageSize);
  if(totalPages < 1) totalPages = 1;
  if(pageNo > totalPages) pageNo = totalPages;

  int start = (pageNo - 1) * pageSize;
  int end = Math.min(start + pageSize, total);

  List<Map<String,Object>> pageList = new ArrayList<>();
  if(list != null && total > 0 && start < end){
      pageList = list.subList(start, end);
  }

  String baseUrl = "index.jsp?module=admin_news";
%>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">
    <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
      <h2>Quản lý tin tức</h2>
      <a class="ad-btn black" href="index.jsp?module=admin_news_form&page=<%=pageNo%>">+ Thêm bài</a>
    </div>

    <% if("created".equals(msg)){ %><div class="ad-msg ok">✅ Đã thêm bài</div><% } %>
    <% if("updated".equals(msg)){ %><div class="ad-msg ok">✅ Đã cập nhật</div><% } %>
    <% if("deleted".equals(msg)){ %><div class="ad-msg ok">✅ Đã xóa bài</div><% } %>
    <% if("delete_fail".equals(msg)){ %><div class="ad-msg warn">⚠️ Xóa thất bại</div><% } %>

    <table class="ad-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Tiêu đề</th>
          <th>Hiển thị</th>
          <th>Ngày tạo</th>
          <th>Hành động</th>
        </tr>
      </thead>

      <tbody>
        <% if(pageList == null || pageList.isEmpty()){ %>
          <tr>
            <td colspan="5" style="text-align:center;padding:18px">Chưa có bài viết</td>
          </tr>
        <% } else { %>

        <% for(Map<String,Object> n: pageList){

            int id = (n.get("post_id") instanceof Number) ? ((Number)n.get("post_id")).intValue() : 0;
            String title = String.valueOf(n.get("title"));

            boolean active = false;
            try{
              Object a = n.get("is_active");
              if(a instanceof Boolean) active = (Boolean)a;
              else if(a instanceof Number) active = ((Number)a).intValue() == 1;
              else active = "true".equalsIgnoreCase(String.valueOf(a)) || "1".equals(String.valueOf(a));
            }catch(Exception e){ active = false; }

            Object created = n.get("created_at");
        %>

        <tr>
          <td>#<%=id%></td>
          <td><%=title%></td>
          <td><%= active ? "ON" : "OFF" %></td>
         <td>
  <%
    String createdStr = "";
    if(created instanceof Timestamp){
      createdStr = sdf.format((Timestamp)created);
    }else if(created != null){
      createdStr = created.toString();
    }
  %>
  <%=createdStr%>
</td>

          <td style="white-space:nowrap">
            <a class="ad-btn gray"
               href="index.jsp?module=admin_news_form&id=<%=id%>&page=<%=pageNo%>">Sửa</a>

            <form action="<%=request.getContextPath()%>/admin/news" method="post"
                  style="display:inline-block"
                  onsubmit="return confirm('Xóa bài #<%=id%>?')">
              <input type="hidden" name="action" value="delete"/>
              <input type="hidden" name="post_id" value="<%=id%>"/>
              <input type="hidden" name="page" value="<%=pageNo%>"/>
              <button class="ad-btn red" type="submit">Xóa</button>
            </form>
          </td>
        </tr>

        <% } %>
        <% } %>
      </tbody>
    </table>

    <!-- PAGING -->
    <div class="ad-paging">
      <% if(pageNo > 1){ %>
        <a class="ad-page" href="<%=baseUrl%>&page=<%=pageNo-1%>">&laquo;</a>
      <% } else { %>
        <span class="ad-page disabled">&laquo;</span>
      <% } %>

      <% for(int p=1; p<=totalPages; p++){ %>
        <a class="ad-page <%= (p==pageNo?"active":"") %>"
           href="<%=baseUrl%>&page=<%=p%>"><%=p%></a>
      <% } %>

      <% if(pageNo < totalPages){ %>
        <a class="ad-page" href="<%=baseUrl%>&page=<%=pageNo+1%>">&raquo;</a>
      <% } else { %>
        <span class="ad-page disabled">&raquo;</span>
      <% } %>
    </div>

  </div>
</div>
