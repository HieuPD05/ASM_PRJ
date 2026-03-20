<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="model.User"%>
<%@page import="dal.AdminDAO"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>

<%
  User u = (User) session.getAttribute("user");
  String ok      = nvl(request.getParameter("ok"));
  String err     = nvl(request.getParameter("err"));
  int openThread = parseInt(request.getParameter("thread"));

  String name = "", email = "", phone = "";
  if(u != null){
    if(u.getFullName() != null) name  = u.getFullName();
    if(u.getEmail()    != null) email = u.getEmail();
    if(u.getPhone()    != null) phone = u.getPhone();
  }

  // Danh sách thread của user
  List<Map<String,Object>> threads = new ArrayList<>();
  Map<String,Object> activeThread = null;
  if(u != null){
    try{
      AdminDAO dao = new AdminDAO();
      threads = dao.listThreadsByUser(u.getId());
      if(openThread > 0){
        activeThread = dao.getContactThreadWithReplies(openThread);
        // Chỉ hiển thị thread thuộc về user này
        if(activeThread != null){
          Object tid = activeThread.get("user_id");
          if(tid == null || ((Number)tid).intValue() != u.getId()) activeThread = null;
        }
      }
    } catch(Exception e){ /* ignore */ }
  }

  SimpleDateFormat sdf = new SimpleDateFormat("HH:mm dd/MM/yyyy");
%>
<%!
  private String nvl(String s){ return s==null?"":s; }
  private int parseInt(String s){ try{ return Integer.parseInt(s); }catch(Exception e){ return 0; } }
%>

<div class="page-box">

  <div class="page-head">
    <h2>Liên hệ với HA SHOP</h2>
    <p>Gửi thắc mắc, chúng tôi sẽ phản hồi trong vòng 24 giờ làm việc.</p>
  </div>

  <div class="contact-layout">

    <!-- CỘT TRÁI: Thông tin + Form tạo liên hệ mới -->
    <div class="contact-sidebar">
      <div class="store-info">
        <h3>HA SHOP</h3>
        <p>📍 123 Hòa Lạc, Thạch Thất, Hà Nội</p>
        <p>📞 0123 456 789</p>
        <p>📧 hashop@gmail.com</p>
        <p>⏰ 8:00 – 22:00 (T2 – CN)</p>
      </div>

      <div class="new-thread-box">
        <h3>+ Tạo liên hệ mới</h3>

        <% if(u == null){ %>
          <div class="ad-msg warn">⚠️ Vui lòng đăng nhập để gửi liên hệ.</div>
          <a class="btn btn-primary" href="index.jsp?module=login&return=contact">Đăng nhập</a>
        <% } else { %>

          <form action="<%=request.getContextPath()%>/contact" method="post" class="new-thread-form">
            <input class="ip" type="text"  name="name"    placeholder="Họ và tên *" required value="<%=name%>">
            <input class="ip" type="email" name="email"   placeholder="Email *"      required value="<%=email%>">
            <input class="ip" type="text"  name="phone"   placeholder="Số điện thoại" value="<%=phone%>">
            <input class="ip" type="text"  name="subject" placeholder="Tiêu đề">
            <textarea class="ip" name="message" rows="4" placeholder="Nội dung *" required></textarea>

            <% if("missing".equals(err) && openThread == 0){ %>
              <div class="ad-msg warn">⚠️ Vui lòng nhập đủ Họ tên / Email / Nội dung.</div>
            <% } %>

            <button class="btn btn-primary" type="submit" style="width:100%">Gửi liên hệ</button>
          </form>

        <% } %>
      </div>
    </div><!-- /contact-sidebar -->

    <!-- CỘT PHẢI: Hộp thư + Cửa sổ chat -->
    <% if(u != null){ %>
    <div class="contact-main">

      <!-- Nếu đang mở 1 thread cụ thể: hiển thị cửa sổ chat -->
      <% if(activeThread != null){ 
           String threadSubj    = nvl((String)activeThread.get("subject"));
           if(threadSubj.isEmpty()) threadSubj = "(Không có tiêu đề)";
           String threadStatus  = nvl((String)activeThread.get("status"));
           @SuppressWarnings("unchecked")
           List<Map<String,Object>> replies = (List<Map<String,Object>>) activeThread.get("replies");
           boolean isClosed = "CLOSED".equalsIgnoreCase(threadStatus);
      %>
      <div class="chat-window">
        <!-- Chat header -->
        <div class="chat-win-header">
          <div>
            <div class="chat-win-title"><%=threadSubj%></div>
            <div class="chat-win-meta">
              <span class="thread-badge <%=threadStatus.toLowerCase()%>">
                <% if("NEW".equalsIgnoreCase(threadStatus)){ %>⏳ Chờ phản hồi
                <% } else if("READ".equalsIgnoreCase(threadStatus)){ %>👁 Admin đang xem
                <% } else if("REPLIED".equalsIgnoreCase(threadStatus)){ %>✅ Đã phản hồi
                <% } else if("CLOSED".equalsIgnoreCase(threadStatus)){ %>🔒 Đã đóng
                <% } %>
              </span>
            </div>
          </div>
          <a class="btn-back-threads" href="index.jsp?module=contact">← Quay lại</a>
        </div>

        <!-- Bong bóng chat -->
        <div class="chat-messages" id="chatMessages">
          <!-- Tin nhắn gốc (user) -->
          <div class="chat-msg user-msg">
            <div class="chat-msg-body">
              <%=nvl((String)activeThread.get("message_content")).replace("\n","<br/>")%>
            </div>
            <div class="chat-msg-meta">
              Bạn · <%=(activeThread.get("created_at") != null ? sdf.format(activeThread.get("created_at")) : "")%>
            </div>
          </div>

          <!-- Các reply theo thứ tự thời gian -->
          <% if(replies != null){
               for(Map<String,Object> rep : replies){
                 boolean isAdmin = "ADMIN".equalsIgnoreCase(nvl((String)rep.get("sender_role")));
                 String repName  = isAdmin ? "HA SHOP" : "Bạn";
                 String repClass = isAdmin ? "admin-msg" : "user-msg";
          %>
          <div class="chat-msg <%=repClass%>">
            <% if(isAdmin){ %>
            <div class="chat-msg-avatar">🛒</div>
            <% } %>
            <div class="chat-msg-body">
              <%=nvl((String)rep.get("message_content")).replace("\n","<br/>")%>
            </div>
            <div class="chat-msg-meta">
              <%=repName%> · <%=(rep.get("created_at") != null ? sdf.format(rep.get("created_at")) : "")%>
            </div>
          </div>
          <% }} %>

          <% if("sent".equals(ok)){ %>
            <div class="chat-system-msg">✅ Đã gửi liên hệ! Chúng tôi sẽ phản hồi sớm nhất.</div>
          <% } else if("replied".equals(ok)){ %>
            <div class="chat-system-msg">✅ Tin nhắn của bạn đã được gửi.</div>
          <% } %>
        </div><!-- /chat-messages -->

        <!-- Input gửi reply (chỉ hiện khi chưa CLOSED) -->
        <% if(!isClosed){ %>
        <div class="chat-input-area">
          <form action="<%=request.getContextPath()%>/contact" method="post" class="chat-reply-form">
            <input type="hidden" name="action"    value="user_reply"/>
            <input type="hidden" name="thread_id" value="<%=((Number)activeThread.get("message_id")).intValue()%>"/>
            <% if("missing".equals(err)){ %>
              <div style="color:#c0392b;font-size:12px;margin-bottom:4px">⚠️ Vui lòng nhập nội dung.</div>
            <% } %>
            <div class="chat-input-row">
              <textarea name="content" rows="2" placeholder="Nhắn thêm cho HA SHOP..." required></textarea>
              <button class="btn btn-primary" type="submit">Gửi</button>
            </div>
          </form>
        </div>
        <% } else { %>
          <div class="chat-closed-notice">🔒 Hội thoại này đã được đóng. Hãy tạo liên hệ mới nếu cần hỗ trợ thêm.</div>
        <% } %>
      </div><!-- /chat-window -->

      <% } else { %>
      <!-- Danh sách các thread (hộp thư) -->
      <div class="inbox-box">
        <div class="inbox-header">
          <h3>💬 Hội thoại của tôi</h3>
          <span class="inbox-hint">Nhấn vào một hội thoại để xem chi tiết và tiếp tục nhắn tin</span>
        </div>

        <% if(threads == null || threads.isEmpty()){ %>
          <div class="inbox-empty">Bạn chưa có liên hệ nào. Hãy tạo liên hệ mới ở bên trái.</div>
        <% } else { %>

        <div class="inbox-list">
          <% for(Map<String,Object> t : threads){
               int tid      = ((Number)t.get("message_id")).intValue();
               String tsubj = nvl((String)t.get("subject"));
               if(tsubj.isEmpty()) tsubj = "(Không có tiêu đề)";
               String tstat = nvl((String)t.get("status"));
               int repCnt   = ((Number)t.get("reply_count")).intValue();
               String lastAdminReply = nvl((String)t.get("last_admin_reply"));
               Object tCreated = t.get("created_at");
               Object tLastReply = t.get("last_reply_at");
               boolean hasUnread = "NEW".equalsIgnoreCase(tstat) && repCnt == 0; // chưa có admin reply
               boolean adminReplied = "REPLIED".equalsIgnoreCase(tstat);
          %>
          <a class="inbox-item <%=adminReplied ? "has-reply" : ""%>" href="index.jsp?module=contact&thread=<%=tid%>">
            <div class="inbox-item-icon">
              <% if("CLOSED".equalsIgnoreCase(tstat)){ %>🔒
              <% } else if(adminReplied){ %>💬
              <% } else { %>📩<% } %>
            </div>
            <div class="inbox-item-body">
              <div class="inbox-item-subject"><%=tsubj%></div>
              <div class="inbox-item-preview">
                <% if(!lastAdminReply.isEmpty()){ %>
                  <span class="preview-admin">HA SHOP: <%=lastAdminReply.length()>60 ? lastAdminReply.substring(0,60)+"…" : lastAdminReply%></span>
                <% } else { %>
                  <span class="preview-waiting">Đang chờ phản hồi...</span>
                <% } %>
              </div>
              <div class="inbox-item-meta">
                <span class="thread-badge-sm <%=tstat.toLowerCase()%>">
                  <%=("NEW".equalsIgnoreCase(tstat)&&repCnt==0) ? "Chờ phản hồi"
                   : "READ".equalsIgnoreCase(tstat) ? "Admin đang xem"
                   : "REPLIED".equalsIgnoreCase(tstat) ? "Đã phản hồi"
                   : "Đã đóng" %>
                </span>
                <span class="inbox-item-time">
                  <%=(tLastReply!=null ? sdf.format(tLastReply) : (tCreated!=null?sdf.format(tCreated):""))%>
                </span>
              </div>
            </div>
          </a>
          <% } %>
        </div>
        <% } %>
      </div><!-- /inbox-box -->
      <% } %>

    </div><!-- /contact-main -->
    <% } %>

  </div><!-- /contact-layout -->
</div>

<style>
/* ===== LAYOUT ===== */
.contact-layout{
  display:flex; gap:22px; align-items:flex-start;
  margin-top:18px;
}
.contact-sidebar{
  width:300px; flex-shrink:0;
  display:flex; flex-direction:column; gap:16px;
}
.contact-main{ flex:1; min-width:0; }

.store-info{
  background:#f8f8f8; border:1px solid #eee;
  border-radius:12px; padding:16px; font-size:14px; line-height:1.8;
}
.store-info h3{ margin:0 0 8px; font-size:15px; color:#333; }

.new-thread-box{
  background:#fff; border:1px solid #eee;
  border-radius:12px; padding:16px;
}
.new-thread-box h3{ margin:0 0 12px; font-size:15px; }
.new-thread-form{ display:flex; flex-direction:column; gap:8px; }
.new-thread-form .ip{ width:100%; box-sizing:border-box; }

/* ===== INBOX ===== */
.inbox-box{
  background:#fff; border:1px solid #eee;
  border-radius:14px; overflow:hidden;
}
.inbox-header{
  padding:14px 18px; border-bottom:1px solid #f0f0f0;
  background:#fafafa;
}
.inbox-header h3{ margin:0 0 2px; font-size:16px; font-weight:900; }
.inbox-hint{ font-size:12px; color:#999; }
.inbox-empty{ padding:24px 18px; color:#aaa; font-style:italic; text-align:center; }

.inbox-list{ padding:10px 12px; display:flex; flex-direction:column; gap:8px; }

.inbox-item{
  display:flex; gap:12px; align-items:flex-start;
  padding:12px 14px; border:1px solid #eee; border-radius:10px;
  text-decoration:none; color:inherit;
  transition:background .15s, border-color .15s;
}
.inbox-item:hover{ background:#f5f5f5; border-color:#ddd; }
.inbox-item.has-reply{ border-color:#d4edda; background:#f8fff9; }

.inbox-item-icon{ font-size:20px; margin-top:2px; flex-shrink:0; }
.inbox-item-body{ flex:1; min-width:0; }
.inbox-item-subject{ font-weight:700; font-size:14px; margin-bottom:3px;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.inbox-item-preview{ font-size:13px; color:#666; margin-bottom:5px;
  white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.preview-admin{ color:#27ae60; }
.preview-waiting{ color:#e67e22; font-style:italic; }
.inbox-item-meta{ display:flex; justify-content:space-between; align-items:center; }
.inbox-item-time{ font-size:11px; color:#aaa; }

/* ===== THREAD BADGES ===== */
.thread-badge{
  display:inline-block; padding:3px 10px; border-radius:999px;
  font-size:12px; font-weight:700;
}
.thread-badge.new     { background:#fff3cd; color:#856404; }
.thread-badge.read    { background:#cce5ff; color:#004085; }
.thread-badge.replied { background:#d4edda; color:#155724; }
.thread-badge.closed  { background:#e2e3e5; color:#383d41; }

.thread-badge-sm{
  display:inline-block; padding:2px 8px; border-radius:999px;
  font-size:11px; font-weight:700;
}
.thread-badge-sm.new     { background:#fff3cd; color:#856404; }
.thread-badge-sm.read    { background:#cce5ff; color:#004085; }
.thread-badge-sm.replied { background:#d4edda; color:#155724; }
.thread-badge-sm.closed  { background:#e2e3e5; color:#383d41; }

/* ===== CHAT WINDOW ===== */
.chat-window{
  background:#fff; border:1px solid #e0e0e0;
  border-radius:14px; overflow:hidden;
  display:flex; flex-direction:column;
  max-height:680px;
}

.chat-win-header{
  display:flex; justify-content:space-between; align-items:center;
  padding:14px 18px; border-bottom:1px solid #eee;
  background:#fafafa;
}
.chat-win-title{ font-weight:800; font-size:15px; }
.chat-win-meta{ margin-top:3px; }
.btn-back-threads{
  font-size:13px; color:#888; text-decoration:none;
  padding:5px 10px; border:1px solid #ddd; border-radius:8px;
  transition:background .15s;
}
.btn-back-threads:hover{ background:#f0f0f0; }

.chat-messages{
  flex:1; overflow-y:auto; padding:16px 18px;
  display:flex; flex-direction:column; gap:14px;
  min-height:200px;
}

/* Bong bóng chat */
.chat-msg{ display:flex; flex-direction:column; max-width:75%; }
.user-msg{ align-self:flex-end; align-items:flex-end; }
.admin-msg{ align-self:flex-start; align-items:flex-start; flex-direction:row; gap:8px; }

.chat-msg-avatar{
  width:34px; height:34px; border-radius:50%;
  background:#e8f5e9; display:flex; align-items:center;
  justify-content:center; font-size:16px; flex-shrink:0; margin-top:2px;
}

.admin-msg .chat-msg-body-wrap{ display:flex; flex-direction:column; align-items:flex-start; }

.chat-msg-body{
  padding:10px 14px; border-radius:16px;
  font-size:14px; line-height:1.6; word-break:break-word;
}
.user-msg  .chat-msg-body{
  background:#0084ff; color:#fff;
  border-bottom-right-radius:4px;
}
.admin-msg .chat-msg-body{
  background:#f0f0f0; color:#222;
  border-bottom-left-radius:4px;
}

.chat-msg-meta{
  font-size:11px; color:#aaa; margin-top:4px; padding:0 4px;
}

.chat-system-msg{
  text-align:center; font-size:12px; color:#27ae60;
  background:#f0fff4; border:1px solid #c3e6cb;
  border-radius:8px; padding:8px 14px; align-self:center;
}

/* Chat input */
.chat-input-area{
  border-top:1px solid #eee; padding:12px 16px;
  background:#fff;
}
.chat-input-row{ display:flex; gap:8px; align-items:flex-end; }
.chat-input-row textarea{
  flex:1; padding:10px 13px;
  border:1px solid #ddd; border-radius:10px;
  font-family:inherit; font-size:14px; resize:none;
  transition:border-color .2s;
}
.chat-input-row textarea:focus{ border-color:#0084ff; outline:none; }
.chat-input-row .btn{ height:40px; white-space:nowrap; flex-shrink:0; }

.chat-closed-notice{
  text-align:center; padding:14px 16px;
  font-size:13px; color:#888; background:#f9f9f9;
  border-top:1px solid #eee;
}

/* Responsive */
@media(max-width:768px){
  .contact-layout{ flex-direction:column; }
  .contact-sidebar{ width:100%; }
  .chat-msg{ max-width:88%; }
}
</style>

<script>
// Auto-scroll chat xuống cuối khi mở
(function(){
  var cm = document.getElementById('chatMessages');
  if(cm) cm.scrollTop = cm.scrollHeight;
})();
</script>
