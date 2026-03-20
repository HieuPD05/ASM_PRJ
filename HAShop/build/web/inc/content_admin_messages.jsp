<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="dal.AdminDAO"%>
<%@page import="java.sql.*"%>
<%@page import="java.text.SimpleDateFormat"%>

<%
    String filter = request.getParameter("filter");
    if (filter == null || filter.trim().isEmpty()) filter = "all";

    int pageSize = 10;
    int pageNo = 1;
    try { pageNo = Integer.parseInt(request.getParameter("page")); } catch(Exception e){ pageNo = 1; }
    if(pageNo < 1) pageNo = 1;

    AdminDAO dao = new AdminDAO();

    int totalAll     = dao.countContactThreads("all");
    int totalNew     = dao.countContactThreads("new");
    int totalOpen    = dao.countContactThreads("open");
    int totalReplied = dao.countContactThreads("replied");
    int totalClosed  = dao.countContactThreads("closed");

    int totalFiltered = dao.countContactThreads(filter);
    int totalPages = (int)Math.ceil(totalFiltered * 1.0 / pageSize);
    if(totalPages < 1) totalPages = 1;
    if(pageNo > totalPages) pageNo = totalPages;

    List<Map<String,Object>> threads = dao.listContactThreads(filter, pageNo, pageSize);

    String flash = request.getParameter("msg");
    SimpleDateFormat sdf = new SimpleDateFormat("HH:mm dd/MM");
    String baseUrl = "index.jsp?module=admin_messages&filter=" + filter;
%>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">

    <div class="ad-head">
      <h2>Quản lý tin nhắn liên hệ</h2>
      <span style="font-size:13px;color:#888">Tổng <%=totalAll%> hội thoại</span>
    </div>

    <% if("replied".equals(flash)){ %>
      <div class="ad-msg ok">✅ Đã trả lời thành công!</div>
    <% } else if("closed".equals(flash)){ %>
      <div class="ad-msg ok">🔒 Đã đóng hội thoại.</div>
    <% } %>

    <!-- Tab filter -->
    <div class="msg-tabs">
      <a class="msg-tab <%="all".equals(filter)?"active":""%>"
         href="index.jsp?module=admin_messages&filter=all">
        Tất cả <span class="tab-count"><%=totalAll%></span>
      </a>
      <a class="msg-tab <%="new".equals(filter)?"active":""%>"
         href="index.jsp?module=admin_messages&filter=new">
        Chờ xử lý <span class="tab-count new-count"><%=totalNew%></span>
      </a>
      <a class="msg-tab <%="open".equals(filter)?"active":""%>"
         href="index.jsp?module=admin_messages&filter=open">
        Đang mở <span class="tab-count"><%=totalOpen%></span>
      </a>
      <a class="msg-tab <%="replied".equals(filter)?"active":""%>"
         href="index.jsp?module=admin_messages&filter=replied">
        Đã phản hồi <span class="tab-count"><%=totalReplied%></span>
      </a>
      <a class="msg-tab <%="closed".equals(filter)?"active":""%>"
         href="index.jsp?module=admin_messages&filter=closed">
        Đã đóng <span class="tab-count"><%=totalClosed%></span>
      </a>
    </div>

    <!-- Danh sách thread -->
    <div class="msg-list-card">
      <% if(threads == null || threads.isEmpty()){ %>
        <div class="msg-empty">
          <div style="font-size:40px;margin-bottom:8px">📭</div>
          <div>Không có hội thoại nào.</div>
        </div>
      <% } else { %>

      <div class="msg-thread-list">
        <% for(Map<String,Object> t : threads){
             int tid       = ((Number)t.get("message_id")).intValue();
             String tname  = nvl((String)t.get("sender_name"));
             String temail = nvl((String)t.get("sender_email"));
             String tphone = nvl((String)t.get("sender_phone"));
             String tsubj  = nvl((String)t.get("subject"));
             if(tsubj.isEmpty()) tsubj = "(Không có tiêu đề)";
             String tstat  = nvl((String)t.get("status"));
             int repCnt    = ((Number)t.get("reply_count")).intValue();
             Object tCreated   = t.get("created_at");
             Object tLastReply = t.get("last_reply_at");
             boolean isNew    = "NEW".equalsIgnoreCase(tstat);
        %>
        <a class="msg-thread-item <%=isNew?"unread":""%>"
           href="index.jsp?module=admin_message_detail&id=<%=tid%>&filter=<%=filter%>&page=<%=pageNo%>">

          <!-- Avatar -->
          <div class="msg-avatar <%=isNew?"avatar-new":""%>">
            <%=tname.isEmpty() ? "?" : String.valueOf(tname.charAt(0)).toUpperCase()%>
          </div>

          <!-- Nội dung chính -->
          <div class="msg-thread-body">
            <div class="msg-thread-top">
              <span class="msg-sender"><%=tname%>
                <% if(!temail.isEmpty()){ %><span class="msg-email">· <%=temail%></span><% } %>
              </span>
              <span class="msg-time">
                <%=(tLastReply != null ? sdf.format(tLastReply) : (tCreated!=null?sdf.format(tCreated):""))%>
              </span>
            </div>
            <div class="msg-thread-subject"><%=tsubj%></div>
            <div class="msg-thread-bottom">
              <% if(repCnt > 0){ %>
                <span class="msg-reply-count">💬 <%=repCnt%> tin nhắn</span>
              <% } else { %>
                <span class="msg-no-reply">Chưa có phản hồi</span>
              <% } %>
              <span class="msg-status-badge <%=tstat.toLowerCase()%>">
                <% if("NEW".equalsIgnoreCase(tstat)){ %>⚡ Mới
                <% } else if("READ".equalsIgnoreCase(tstat)){ %>👁 Đã đọc
                <% } else if("REPLIED".equalsIgnoreCase(tstat)){ %>✅ Đã phản hồi
                <% } else if("CLOSED".equalsIgnoreCase(tstat)){ %>🔒 Đã đóng
                <% } %>
              </span>
            </div>
          </div>
        </a>
        <% } %>
      </div>

      <!-- Phân trang -->
      <% if(totalPages > 1){ %>
      <div class="ad-paging" style="padding:14px 16px;border-top:1px solid #f0f0f0">
        <% if(pageNo > 1){ %>
          <a class="ad-page" href="<%=baseUrl%>&page=<%=pageNo-1%>">&laquo;</a>
        <% } else { %>
          <span class="ad-page disabled">&laquo;</span>
        <% } %>

        <% for(int p=1; p<=totalPages; p++){
             if(p==1 || p==totalPages || Math.abs(p-pageNo)<=1){ %>
          <a class="ad-page <%=(p==pageNo?"active":"")%>" href="<%=baseUrl%>&page=<%=p%>"><%=p%></a>
        <%   } else if(Math.abs(p-pageNo)==2){ %>
          <span class="ad-page disabled">…</span>
        <%   }
           } %>

        <% if(pageNo < totalPages){ %>
          <a class="ad-page" href="<%=baseUrl%>&page=<%=pageNo+1%>">&raquo;</a>
        <% } else { %>
          <span class="ad-page disabled">&raquo;</span>
        <% } %>
      </div>
      <% } %>

      <% } %>
    </div><!-- /msg-list-card -->
  </div>
</div>

<%!
  private String nvl(String s){ return s==null?"":s; }
%>

<style>
/* ===== TABS ===== */
.msg-tabs{
  display:flex; gap:4px; margin-bottom:16px;
  border-bottom:2px solid #eee; padding-bottom:0;
}
.msg-tab{
  padding:9px 16px; border-radius:8px 8px 0 0;
  text-decoration:none; font-size:13px; font-weight:600;
  color:#666; transition:background .15s, color .15s;
  border:1px solid transparent; border-bottom:none;
  margin-bottom:-2px; position:relative;
}
.msg-tab:hover{ background:#f5f5f5; color:#333; }
.msg-tab.active{
  background:#fff; color:#333;
  border-color:#eee; border-bottom-color:#fff;
}
.tab-count{
  display:inline-block; padding:1px 7px;
  border-radius:999px; background:#eee;
  font-size:11px; font-weight:800; margin-left:4px;
}
.new-count{ background:#c0392b !important; color:#fff !important; }

/* ===== LIST CARD ===== */
.msg-list-card{
  background:#fff; border:1px solid #eee;
  border-radius:14px; overflow:hidden;
}
.msg-empty{
  padding:48px; text-align:center; color:#aaa; font-size:14px;
}

/* ===== THREAD ITEM (giống Gmail) ===== */
.msg-thread-list{ display:flex; flex-direction:column; }

.msg-thread-item{
  display:flex; gap:14px; align-items:center;
  padding:14px 18px; border-bottom:1px solid #f5f5f5;
  text-decoration:none; color:inherit;
  transition:background .15s;
}
.msg-thread-item:last-child{ border-bottom:none; }
.msg-thread-item:hover{ background:#f9f9f9; }
.msg-thread-item.unread{ background:#fffbf0; }
.msg-thread-item.unread:hover{ background:#fff8e1; }

/* Avatar chữ cái */
.msg-avatar{
  width:40px; height:40px; border-radius:50%; flex-shrink:0;
  background:#dde; display:flex; align-items:center;
  justify-content:center; font-size:16px; font-weight:800;
  color:#555;
}
.msg-avatar.avatar-new{ background:#c0392b; color:#fff; }

/* Body */
.msg-thread-body{ flex:1; min-width:0; }

.msg-thread-top{
  display:flex; justify-content:space-between; align-items:baseline;
  margin-bottom:2px;
}
.msg-sender{ font-weight:700; font-size:14px; }
.msg-email{ font-size:12px; color:#aaa; font-weight:400; }
.msg-time{ font-size:12px; color:#aaa; white-space:nowrap; margin-left:8px; }

.msg-thread-subject{
  font-size:13px; color:#555; margin-bottom:4px;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis;
}
.msg-thread-item.unread .msg-thread-subject{ color:#222; font-weight:600; }

.msg-thread-bottom{
  display:flex; align-items:center; gap:10px;
}
.msg-reply-count{ font-size:12px; color:#888; }
.msg-no-reply{ font-size:12px; color:#e67e22; font-style:italic; }

.msg-status-badge{
  padding:2px 9px; border-radius:999px; font-size:11px; font-weight:700;
}
.msg-status-badge.new     { background:#fde8e8; color:#c0392b; }
.msg-status-badge.read    { background:#cce5ff; color:#004085; }
.msg-status-badge.replied { background:#d4edda; color:#155724; }
.msg-status-badge.closed  { background:#e2e3e5; color:#555; }
</style>
