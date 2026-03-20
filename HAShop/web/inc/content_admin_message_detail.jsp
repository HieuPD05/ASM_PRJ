<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="dal.AdminDAO"%>
<%@page import="java.text.SimpleDateFormat"%>

<%
  int threadId = 0;
  try { threadId = Integer.parseInt(request.getParameter("id")); } catch(Exception e){}

  String filter = request.getParameter("filter");
  if(filter == null || filter.trim().isEmpty()) filter = "all";
  int pageNo = 1;
  try { pageNo = Integer.parseInt(request.getParameter("page")); } catch(Exception e){}
  if(pageNo < 1) pageNo = 1;

  String backUrl = "index.jsp?module=admin_messages&filter=" + filter + "&page=" + pageNo;

  AdminDAO dao = new AdminDAO();

  // Đánh dấu READ khi admin mở lần đầu
  dao.markThreadRead(threadId);

  // Lấy thread + toàn bộ replies
  Map<String,Object> thread = dao.getContactThreadWithReplies(threadId);

  String ok  = request.getParameter("ok");
  String err = request.getParameter("err");

  SimpleDateFormat sdf = new SimpleDateFormat("HH:mm, dd/MM/yyyy");
%>
<%!
  private String nvl(String s){ return s==null?"":s; }
%>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">

    <!-- Header -->
    <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
      <h2>Chi tiết hội thoại #<%=threadId%></h2>
      <a class="ad-btn gray" href="<%=backUrl%>">&larr; Quay lại danh sách</a>
    </div>

    <% if("replied".equals(ok)){ %>
      <div class="ad-msg ok">✅ Đã gửi phản hồi!</div>
    <% } else if("missing".equals(err)){ %>
      <div class="ad-msg warn">⚠️ Vui lòng nhập nội dung phản hồi.</div>
    <% } %>

    <% if(thread == null){ %>
      <div class="ad-msg warn">⚠️ Không tìm thấy hội thoại.</div>
    <% } else {
        String senderName  = nvl((String)thread.get("sender_name"));
        String senderEmail = nvl((String)thread.get("sender_email"));
        String senderPhone = nvl((String)thread.get("sender_phone"));
        String subject     = nvl((String)thread.get("subject"));
        if(subject.isEmpty()) subject = "(Không có tiêu đề)";
        String status      = nvl((String)thread.get("status"));
        Object createdAt   = thread.get("created_at");
        boolean isClosed   = "CLOSED".equalsIgnoreCase(status);

        @SuppressWarnings("unchecked")
        List<Map<String,Object>> replies = (List<Map<String,Object>>) thread.get("replies");
    %>

    <div class="detail-layout">

      <!-- CỘT TRÁI: Cửa sổ chat -->
      <div class="detail-chat-col">

        <!-- Subject + status -->
        <div class="detail-chat-header">
          <div>
            <div class="detail-subject"><%=subject%></div>
            <span class="msg-status-badge <%=status.toLowerCase()%>">
              <% if("NEW".equalsIgnoreCase(status)){ %>⚡ Chờ xử lý
              <% } else if("READ".equalsIgnoreCase(status)){ %>👁 Đã đọc
              <% } else if("REPLIED".equalsIgnoreCase(status)){ %>✅ Đã phản hồi
              <% } else { %>🔒 Đã đóng<% } %>
            </span>
          </div>
          <!-- Nút đóng thread -->
          <% if(!isClosed){ %>
          <form action="<%=request.getContextPath()%>/admin/message" method="post"
                style="display:inline"
                onsubmit="return confirm('Đóng hội thoại này? Admin sẽ không nhận thêm tin nhắn từ user.')">
            <input type="hidden" name="action"    value="close"/>
            <input type="hidden" name="thread_id" value="<%=threadId%>"/>
            <input type="hidden" name="filter"    value="<%=filter%>"/>
            <input type="hidden" name="page"      value="<%=pageNo%>"/>
            <button class="ad-btn gray" type="submit" style="font-size:12px">🔒 Đóng hội thoại</button>
          </form>
          <% } %>
        </div>

        <!-- Vùng chat messages -->
        <div class="admin-chat-messages" id="adminChatMessages">

          <!-- Tin nhắn đầu tiên của user -->
          <div class="achat-msg user-side">
            <div class="achat-avatar user-av">
              <%=senderName.isEmpty() ? "?" : String.valueOf(senderName.charAt(0)).toUpperCase()%>
            </div>
            <div class="achat-bubble-wrap">
              <div class="achat-sender"><%=senderName%></div>
              <div class="achat-bubble user-bubble">
                <%=nvl((String)thread.get("message_content")).replace("\n","<br/>")%>
              </div>
              <div class="achat-time"><%=(createdAt!=null?sdf.format(createdAt):"")%></div>
            </div>
          </div>

          <!-- Các reply (user + admin xen kẽ) -->
          <% if(replies != null){
               for(Map<String,Object> rep : replies){
                 boolean isAdmin = "ADMIN".equalsIgnoreCase(nvl((String)rep.get("sender_role")));
                 String repName  = nvl((String)rep.get("sender_name"));
                 if(repName.isEmpty()) repName = isAdmin ? "HA SHOP" : "Khách hàng";
                 Object repTime  = rep.get("created_at");
          %>
          <div class="achat-msg <%=isAdmin?"achat-admin-side":"user-side"%>">
            <% if(!isAdmin){ %>
            <div class="achat-avatar user-av">
              <%=repName.isEmpty() ? "?" : String.valueOf(repName.charAt(0)).toUpperCase()%>
            </div>
            <% } %>
            <div class="achat-bubble-wrap <%=isAdmin?"admin-wrap-align":""%>">
              <div class="achat-sender"><%=isAdmin ? "🛒 HA SHOP (Admin)" : repName%></div>
              <div class="achat-bubble <%=isAdmin?"admin-bubble":"user-bubble"%>">
                <%=nvl((String)rep.get("message_content")).replace("\n","<br/>")%>
              </div>
              <div class="achat-time <%=isAdmin?"text-right":""%>">
                <%=(repTime!=null?sdf.format(repTime):"")%>
              </div>
            </div>
            <% if(isAdmin){ %>
            <div class="achat-avatar admin-av">🛒</div>
            <% } %>
          </div>
          <% }} %>

        </div><!-- /admin-chat-messages -->

        <!-- Form reply của admin -->
        <% if(!isClosed){ %>
        <div class="admin-reply-area">
          <form action="<%=request.getContextPath()%>/admin/message" method="post" id="replyForm">
            <input type="hidden" name="action"    value="reply"/>
            <input type="hidden" name="thread_id" value="<%=threadId%>"/>
            <input type="hidden" name="filter"    value="<%=filter%>"/>
            <input type="hidden" name="page"      value="<%=pageNo%>"/>

            <div class="reply-input-row">
              <textarea name="content" id="replyContent" rows="3"
                        placeholder="Nhập nội dung phản hồi..." required
                        onkeydown="handleReplyKey(event)"></textarea>
              <div class="reply-actions">
                <span class="reply-hint">Ctrl+Enter để gửi</span>
                <button class="ad-btn" type="submit">📤 Gửi phản hồi</button>
              </div>
            </div>
          </form>
        </div>
        <% } else { %>
        <div class="chat-closed-admin">🔒 Hội thoại đã đóng. Không thể gửi thêm phản hồi.</div>
        <% } %>

      </div><!-- /detail-chat-col -->

      <!-- CỘT PHẢI: Thông tin khách hàng -->
      <div class="detail-info-col">
        <div class="sender-card">
          <div class="sender-card-avatar">
            <%=senderName.isEmpty() ? "?" : String.valueOf(senderName.charAt(0)).toUpperCase()%>
          </div>
          <div class="sender-card-name"><%=senderName%></div>

          <div class="sender-card-fields">
            <div class="sender-field">
              <span class="sender-field-label">📧 Email</span>
              <span class="sender-field-val">
                <% if(!senderEmail.isEmpty()){ %>
                  <a href="mailto:<%=senderEmail%>"><%=senderEmail%></a>
                <% } else { %>—<% } %>
              </span>
            </div>
            <div class="sender-field">
              <span class="sender-field-label">📞 Điện thoại</span>
              <span class="sender-field-val">
                <% if(!senderPhone.isEmpty()){ %>
                  <a href="tel:<%=senderPhone%>"><%=senderPhone%></a>
                <% } else { %>—<% } %>
              </span>
            </div>
            <div class="sender-field">
              <span class="sender-field-label">📅 Gửi lúc</span>
              <span class="sender-field-val"><%=(createdAt!=null?sdf.format(createdAt):"")%></span>
            </div>
            <div class="sender-field">
              <span class="sender-field-label">💬 Số tin</span>
              <span class="sender-field-val"><%=(replies!=null?replies.size():0)+1%> tin nhắn</span>
            </div>
            <div class="sender-field">
              <span class="sender-field-label">📌 Trạng thái</span>
              <span class="sender-field-val">
                <span class="msg-status-badge <%=status.toLowerCase()%>">
                  <%="NEW".equalsIgnoreCase(status)?"Chờ xử lý"
                   :"READ".equalsIgnoreCase(status)?"Đã đọc"
                   :"REPLIED".equalsIgnoreCase(status)?"Đã phản hồi"
                   :"Đã đóng"%>
                </span>
              </span>
            </div>
          </div>
        </div>

        <!-- Quick actions -->
        <% if(!isClosed){ %>
        <div class="quick-replies">
          <div class="quick-replies-title">💡 Phản hồi nhanh</div>
          <button class="quick-btn" onclick="setReply('Cảm ơn bạn đã liên hệ với HA SHOP! Chúng tôi sẽ xử lý yêu cầu của bạn trong thời gian sớm nhất.')">Cảm ơn đã liên hệ</button>
          <button class="quick-btn" onclick="setReply('Sản phẩm bạn hỏi hiện còn hàng. Bạn có thể đặt mua trực tiếp trên website hoặc liên hệ hotline 0123 456 789 để được hỗ trợ thêm.')">Còn hàng</button>
          <button class="quick-btn" onclick="setReply('Rất tiếc, sản phẩm này hiện đã hết hàng. Chúng tôi sẽ thông báo ngay khi có hàng trở lại. Bạn có thể để lại số điện thoại để chúng tôi liên hệ.')">Hết hàng</button>
          <button class="quick-btn" onclick="setReply('Đơn hàng của bạn đang được xử lý và sẽ được giao trong vòng 2–3 ngày làm việc. Cảm ơn bạn đã mua hàng tại HA SHOP!')">Xác nhận đơn hàng</button>
        </div>
        <% } %>
      </div><!-- /detail-info-col -->

    </div><!-- /detail-layout -->

    <% } %>
  </div>
</div>

<style>
/* ===== DETAIL LAYOUT ===== */
.detail-layout{
  display:flex; gap:18px; align-items:flex-start;
}
.detail-chat-col{
  flex:1; min-width:0;
  background:#fff; border:1px solid #e0e0e0;
  border-radius:14px; overflow:hidden;
  display:flex; flex-direction:column;
}
.detail-info-col{
  width:260px; flex-shrink:0;
  display:flex; flex-direction:column; gap:14px;
}

/* Chat header */
.detail-chat-header{
  display:flex; justify-content:space-between; align-items:flex-start;
  padding:14px 18px; border-bottom:1px solid #eee; background:#fafafa;
}
.detail-subject{ font-weight:800; font-size:15px; margin-bottom:5px; }

/* Chat messages vùng scroll */
.admin-chat-messages{
  flex:1; overflow-y:auto; padding:20px 18px;
  display:flex; flex-direction:column; gap:16px;
  min-height:300px; max-height:500px;
  background:#f7f7f9;
}

/* Từng message */
.achat-msg{
  display:flex; gap:10px; align-items:flex-end;
  max-width:80%;
}
.user-side{ align-self:flex-start; }
.achat-admin-side{ align-self:flex-end; flex-direction:row-reverse; }

.achat-avatar{
  width:36px; height:36px; border-radius:50%; flex-shrink:0;
  display:flex; align-items:center; justify-content:center;
  font-size:14px; font-weight:800;
}
.user-av{ background:#dde; color:#555; }
.admin-av{ background:#27ae60; color:#fff; font-size:16px; }

.achat-bubble-wrap{ display:flex; flex-direction:column; }
.admin-wrap-align{ align-items:flex-end; }

.achat-sender{ font-size:11px; color:#aaa; margin-bottom:4px; padding:0 4px; }

.achat-bubble{
  padding:10px 14px; border-radius:16px;
  font-size:14px; line-height:1.6; word-break:break-word;
  max-width:420px;
}
.user-bubble{
  background:#fff; border:1px solid #e0e0e0;
  border-bottom-left-radius:4px;
}
.admin-bubble{
  background:#0084ff; color:#fff;
  border-bottom-right-radius:4px;
}
.achat-time{
  font-size:11px; color:#bbb; margin-top:4px; padding:0 4px;
}
.text-right{ text-align:right; }

/* Reply area */
.admin-reply-area{
  border-top:2px solid #e8f0fe; padding:14px 16px;
  background:#fff;
}
.reply-input-row{ display:flex; flex-direction:column; gap:8px; }
.reply-input-row textarea{
  width:100%; box-sizing:border-box;
  padding:10px 13px; border:1px solid #ddd; border-radius:10px;
  font-family:inherit; font-size:14px; resize:vertical;
  transition:border-color .2s;
}
.reply-input-row textarea:focus{ border-color:#0084ff; outline:none; }
.reply-actions{
  display:flex; justify-content:space-between; align-items:center;
}
.reply-hint{ font-size:12px; color:#aaa; }

.chat-closed-admin{
  padding:14px 16px; text-align:center;
  color:#888; background:#f9f9f9; font-size:13px;
  border-top:1px solid #eee;
}

/* ===== INFO CARD ===== */
.sender-card{
  background:#fff; border:1px solid #eee;
  border-radius:12px; padding:18px; text-align:center;
}
.sender-card-avatar{
  width:56px; height:56px; border-radius:50%;
  background:#0084ff; color:#fff;
  display:flex; align-items:center; justify-content:center;
  font-size:22px; font-weight:800; margin:0 auto 10px;
}
.sender-card-name{ font-weight:800; font-size:15px; margin-bottom:14px; }

.sender-card-fields{ text-align:left; display:flex; flex-direction:column; gap:10px; }
.sender-field{ display:flex; flex-direction:column; gap:2px; }
.sender-field-label{ font-size:11px; color:#aaa; font-weight:600; text-transform:uppercase; }
.sender-field-val{ font-size:13px; color:#333; }
.sender-field-val a{ color:#0084ff; text-decoration:none; }
.sender-field-val a:hover{ text-decoration:underline; }

/* Quick replies */
.quick-replies{
  background:#fff; border:1px solid #eee;
  border-radius:12px; padding:14px;
}
.quick-replies-title{
  font-size:12px; font-weight:700; color:#888;
  text-transform:uppercase; margin-bottom:10px;
}
.quick-btn{
  display:block; width:100%; margin-bottom:7px;
  padding:8px 10px; text-align:left;
  background:#f5f5f5; border:1px solid #ddd;
  border-radius:8px; font-size:12px; color:#333;
  cursor:pointer; transition:background .15s;
  line-height:1.4;
}
.quick-btn:last-child{ margin-bottom:0; }
.quick-btn:hover{ background:#e8f0fe; border-color:#aac; }

/* Status badges (shared) */
.msg-status-badge{
  padding:2px 9px; border-radius:999px; font-size:11px; font-weight:700;
}
.msg-status-badge.new     { background:#fde8e8; color:#c0392b; }
.msg-status-badge.read    { background:#cce5ff; color:#004085; }
.msg-status-badge.replied { background:#d4edda; color:#155724; }
.msg-status-badge.closed  { background:#e2e3e5; color:#555; }

@media(max-width:900px){
  .detail-layout{ flex-direction:column; }
  .detail-info-col{ width:100%; }
  .admin-chat-messages{ max-height:350px; }
}
</style>

<script>
// Auto-scroll xuống cuối
(function(){
  var el = document.getElementById('adminChatMessages');
  if(el) el.scrollTop = el.scrollHeight;
})();

// Ctrl+Enter để submit
function handleReplyKey(e){
  if(e.ctrlKey && e.key === 'Enter'){
    document.getElementById('replyForm').submit();
  }
}

// Quick reply: điền vào textarea và focus
function setReply(text){
  var ta = document.getElementById('replyContent');
  if(!ta) return;
  ta.value = text;
  ta.focus();
  ta.scrollIntoView({behavior:'smooth', block:'center'});
}
</script>
