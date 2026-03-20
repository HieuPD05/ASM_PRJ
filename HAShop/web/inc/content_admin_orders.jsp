<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.AdminDAO"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.text.SimpleDateFormat"%>

<%
  SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

  AdminDAO dao = new AdminDAO();
  DecimalFormat df = new DecimalFormat("#,###");

  String msg = request.getParameter("msg");

  // ===== FILTER BY USER (từ nút "Xem tất cả" bên customer modal) =====
  int filterUserId = 0;
  try { filterUserId = Integer.parseInt(request.getParameter("user_id")); } catch(Exception e){ filterUserId = 0; }

  // ===== LOAD LIST (lọc nếu có user_id) =====
  List<Map<String,Object>> list;
  if(filterUserId > 0){
      // bạn đã thêm hàm này trong AdminDAO
      list = dao.listOrdersByUser(filterUserId);
  }else{
      list = dao.listOrdersAdmin();
  }

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

  // baseUrl phải giữ user_id nếu đang lọc
  String baseUrl = "index.jsp?module=admin_orders";
  if(filterUserId > 0){
      baseUrl += "&user_id=" + filterUserId;
  }
%>

<div class="admin-wrap">
  <%@include file="admin_left.jsp" %>

  <div class="admin-main">
    <div class="ad-head" style="display:flex;justify-content:space-between;align-items:center">
      <h2>Quản lý đơn hàng</h2>
    </div>

    <%-- đang lọc theo khách nào đó thì hiện banner + link quay lại --%>
    <% if(filterUserId > 0){ %>
      <div class="ad-msg" style="margin-bottom:12px">
        Đang xem đơn của khách hàng #<%=filterUserId%>
        &nbsp;·&nbsp;
        
      </div>
    <% } %>

    <% if("updated".equals(msg)){ %><div class="ad-msg ok">✅ Đã cập nhật trạng thái</div><% } %>
    <% if("deleted".equals(msg)){ %><div class="ad-msg ok">✅ Đã xóa đơn</div><% } %>
    <% if("delete_fail".equals(msg)){ %><div class="ad-msg warn">⚠️ Xóa thất bại</div><% } %>
    <% if("status_error".equals(msg)){
         String errMsg = request.getParameter("errmsg");
         if(errMsg == null) errMsg = "Không thể cập nhật trạng thái.";
    %><div class="ad-msg warn">⚠️ <%=errMsg%></div><% } %>

    <table class="ad-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Khách</th>
          <th>SĐT</th>
          <th>Tổng</th>
          <th>Trạng thái</th>
          <th>Ngày</th>
          <th>Hành động</th>
        </tr>
      </thead>

      <tbody>
      <% if(pageList == null || pageList.isEmpty()){ %>
        <tr>
          <td colspan="7" style="text-align:center;padding:18px">Chưa có đơn hàng</td>
        </tr>
      <% } else { %>

      <% for(Map<String,Object> o : pageList){

          int id = (o.get("order_id") instanceof Number) ? ((Number)o.get("order_id")).intValue() : 0;

          // ưu tiên receiver_name (bảng orders có receiver_name) nếu customer_name null
          String customerName = String.valueOf(o.get("customer_name"));
          if(customerName == null || "null".equalsIgnoreCase(customerName) || customerName.trim().isEmpty()){
              customerName = String.valueOf(o.get("receiver_name"));
          }

          String receiverPhone = String.valueOf(o.get("receiver_phone"));
          String status = String.valueOf(o.get("status"));
          Object created = o.get("created_at");

          long totalAmount = 0;
          try{
            Object t = o.get("total_amount");
            if(t instanceof Number) totalAmount = ((Number)t).longValue();
            else totalAmount = Long.parseLong(String.valueOf(t));
          }catch(Exception e){ totalAmount = 0; }

          if(customerName == null || "null".equalsIgnoreCase(customerName)) customerName = "";
          if(receiverPhone == null || "null".equalsIgnoreCase(receiverPhone)) receiverPhone = "";
          if(status == null || "null".equalsIgnoreCase(status)) status = "";
      %>

        <tr>
          <td>#<%=id%></td>
          <td><%=customerName%></td>
          <td><%=receiverPhone%></td>
          <td><%=df.format(totalAmount)%> đ</td>
          <td><%=status%></td>

          <td>
            <%
              String createdStr = "";
              if(created instanceof Timestamp){
                createdStr = sdf.format((Timestamp)created);
              }else if(created != null){
                String s = created.toString();
                int dot = s.indexOf('.');
                createdStr = (dot > 0) ? s.substring(0, dot) : s;
              }
            %>
            <%=createdStr%>
          </td>

          <td style="white-space:nowrap">

            <!-- UPDATE STATUS -->
            <form action="<%=request.getContextPath()%>/admin/order" method="post" style="display:inline-block">
              <input type="hidden" name="action" value="status"/>
              <input type="hidden" name="order_id" value="<%=id%>"/>
              <input type="hidden" name="page" value="<%=pageNo%>"/>

              <%-- GIỮ filter khi submit --%>
              <% if(filterUserId > 0){ %>
                <input type="hidden" name="user_id" value="<%=filterUserId%>"/>
              <% } %>

<%
              // Luồng hợp lệ: PENDING->PAID->SHIPPING->DONE | CANCEL (cuối)
              // Chỉ cho phép chọn trạng thái tiến về phía trước
              java.util.List<String> STATUS_FLOW = java.util.Arrays.asList(
                  "PENDING","PAID","SHIPPING","DONE"
              );
              String ST = (status == null ? "PENDING" : status.trim().toUpperCase());
              int curIdx = STATUS_FLOW.indexOf(ST);
              boolean isFinal = "DONE".equals(ST) || "CANCEL".equals(ST);
            %>
              <select name="status" class="ad-select"
                      <%= isFinal ? "disabled title='Đơn đã kết thúc, không thể thay đổi'" : "" %>>
                <%-- Hiển thị từng option: disable nếu là trạng thái trước hoặc hiện tại (trừ CANCEL) --%>
                <% for(String opt : STATUS_FLOW) {
                     int optIdx = STATUS_FLOW.indexOf(opt);
                     boolean isSelected = opt.equalsIgnoreCase(ST);
                     // Disable: option trước hoặc bằng trạng thái hiện tại (không cho lùi)
                     boolean isDisabled = optIdx < curIdx;
                %>
                <option value="<%=opt%>"
                        <%= isSelected ? "selected" : "" %>
                        <%= isDisabled ? "disabled" : "" %>><%=opt%></option>
                <% } %>
                <%-- CANCEL: chỉ hiện khi chưa DONE/CANCEL --%>
                <% if(!isFinal) { %>
                <option value="CANCEL" <%= "CANCEL".equalsIgnoreCase(ST) ? "selected" : "" %>>
                  CANCEL
                </option>
                <% } %>
              </select>

              <% if(!isFinal) { %>
              <button class="ad-btn gray" type="submit">Lưu</button>
              <% } %>
            </form>

            <!-- VIEW DETAIL -->
            <a class="ad-btn black"
               href="index.jsp?module=admin_order_detail&id=<%=id%>&page=<%=pageNo%><%= (filterUserId>0 ? "&user_id="+filterUserId : "") %>">Xem</a>

            <!-- DELETE -->
            <form action="<%=request.getContextPath()%>/admin/order" method="post" style="display:inline-block"
                  onsubmit="return confirm('Xóa đơn #<%=id%>?')">
              <input type="hidden" name="action" value="delete"/>
              <input type="hidden" name="order_id" value="<%=id%>"/>
              <input type="hidden" name="page" value="<%=pageNo%>"/>

              <%-- GIỮ filter khi submit --%>
              <% if(filterUserId > 0){ %>
                <input type="hidden" name="user_id" value="<%=filterUserId%>"/>
              <% } %>

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
