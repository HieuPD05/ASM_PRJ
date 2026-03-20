<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
  String err = request.getParameter("error");
  String msg = request.getParameter("msg");
  String ret = request.getParameter("return");
  if(ret == null) ret = "";
%>

<div class="auth-wrap auth-wrap--login">
  <div class="auth-card">

    <h2 class="auth-title">Đăng nhập</h2>
    <div class="auth-rule"></div>

    <% if("1".equals(err)) { %>
      <div class="auth-msg auth-msg--err">Sai username hoặc mật khẩu.</div>
    <% } %>

    <% if("registered".equals(msg)) { %>
      <div class="auth-msg auth-msg--ok">Đăng ký thành công, hãy đăng nhập.</div>
    <% } %>

    <form method="post" action="login">
      <input type="hidden" name="return" value="<%=ret%>"/>

      <div class="auth-field">
        <input class="auth-input" type="text" name="username" required placeholder="Email">
      </div>

      <div class="auth-field">
        <input class="auth-input" type="password" name="password" required placeholder="Mật khẩu">
      </div>

      <button class="auth-btn" type="submit">ĐĂNG NHẬP</button>

      <div class="auth-links">
        <a href="#" class="">Quên mật khẩu</a>
        <span class="sep">•</span>
        <a class="accent" href="index.jsp?module=register">Đăng ký tại đây</a>
      </div>
    </form>

  </div>
</div>
