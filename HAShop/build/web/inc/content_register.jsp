<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
  String err = request.getParameter("error");
%>

<div class="auth-wrap auth-wrap--register">
  <div class="auth-card">

    <h2 class="auth-title">Đăng ký</h2>
    <div class="auth-rule"></div>

    <div class="auth-subtext">
      Đã có tài khoản, đăng nhập <a href="index.jsp?module=login">tại đây</a>
    </div>

    <% if("exists".equals(err)) { %>
      <div class="auth-msg auth-msg--err">Email đã tồn tại.</div>
    <% } %>

    <% if("missing".equals(err)) { %>
      <div class="auth-msg auth-msg--err">Vui lòng nhập đủ các trường bắt buộc.</div>
    <% } %>

    <% if("notmatch".equals(err)) { %>
      <div class="auth-msg auth-msg--err">Mật khẩu nhập lại không khớp.</div>
    <% } %>

    <form method="post" action="register">
      <div class="auth-field">
        <input class="auth-input" type="text" name="full_name" required placeholder="Nhập tên của bạn (*)">
      </div>

      <div class="auth-field">
        <input class="auth-input" type="text" name="username" required placeholder="Nhập email của bạn (*)">
      </div>

      <div class="auth-field">
        <input class="auth-input" type="text" name="phone" placeholder="Số điện thoại">
      </div>

      <div class="auth-field">
        <input class="auth-input" type="password" name="password" required placeholder="Mật khẩu">
      </div>

      <div class="auth-field">
        <input class="auth-input" type="password" name="repassword" placeholder="Nhập lại mật khẩu">
      </div>

      <button class="auth-btn" type="submit">ĐĂNG KÝ</button>
    </form>

  </div>
</div>
