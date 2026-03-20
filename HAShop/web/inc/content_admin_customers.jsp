<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="dal.AdminDAO"%>
<%@page import="java.sql.Timestamp"%>
<%@page import="java.text.SimpleDateFormat"%>

<%
    AdminDAO dao = new AdminDAO();
    List<Map<String,Object>> list = dao.listCustomersSummary();
    DecimalFormat df = new DecimalFormat("#,###");
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

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

    String baseUrl = "index.jsp?module=admin_customers";
%>

<div class="admin-wrap">
    <%@include file="admin_left.jsp" %>

    <div class="admin-main">
        <div class="ad-head">
            <h2>Quản lý khách hàng</h2>
        </div>

        <table class="ad-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Khách hàng</th>
                    <th>Email</th>
                    <th>Phone</th>
                    <th>Tổng đơn</th>
                    <th>Tổng tiền</th>
                    <th>Thao tác</th>
                </tr>
            </thead>

            <tbody>
            <% if(pageList == null || pageList.isEmpty()){ %>
                <tr>
                    <td colspan="7" style="text-align:center;padding:18px">Chưa có khách hàng</td>
                </tr>
            <% } else { %>

            <% for(Map<String,Object> c : pageList){

                int uid = (c.get("user_id") instanceof Number) ? ((Number)c.get("user_id")).intValue() : 0;

                String fullName = String.valueOf(c.get("full_name"));
                String email = String.valueOf(c.get("email"));
                String phone = String.valueOf(c.get("phone"));

                int totalOrders = (c.get("total_orders") instanceof Number) ? ((Number)c.get("total_orders")).intValue() : 0;
                long totalSpent = (c.get("total_spent") instanceof Number) ? ((Number)c.get("total_spent")).longValue() : 0;

                if("null".equalsIgnoreCase(fullName)) fullName = "";
                if("null".equalsIgnoreCase(email)) email = "";
                if("null".equalsIgnoreCase(phone)) phone = "";
            %>
                <tr>
                    <td>#<%= uid %></td>
                    <td><%= fullName %></td>
                    <td><%= email %></td>
                    <td><%= phone %></td>
                    <td><%= totalOrders %></td>
                    <td><%= df.format(totalSpent) %> đ</td>

                    <td style="white-space:nowrap">
                        <button class="ad-btn gray" type="button"
                                onclick="openCustomerModal(<%=uid%>)">
                            Chi tiết
                        </button>
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

        <!-- ===== MODALS (để ngoài table cho khỏi vỡ layout) ===== -->
        <% if(pageList != null){ %>
        <% for(Map<String,Object> c : pageList){

            int uid = (c.get("user_id") instanceof Number) ? ((Number)c.get("user_id")).intValue() : 0;

            String fullName = String.valueOf(c.get("full_name"));
            String email = String.valueOf(c.get("email"));
            String phone = String.valueOf(c.get("phone"));

            int totalOrders = (c.get("total_orders") instanceof Number) ? ((Number)c.get("total_orders")).intValue() : 0;
            long totalSpent = (c.get("total_spent") instanceof Number) ? ((Number)c.get("total_spent")).longValue() : 0;

            if("null".equalsIgnoreCase(fullName)) fullName = "";
            if("null".equalsIgnoreCase(email)) email = "";
            if("null".equalsIgnoreCase(phone)) phone = "";

            // 5 đơn gần đây (cần bạn đã thêm hàm listRecentOrdersByUser trong AdminDAO)
            List<Map<String,Object>> recentOrders = dao.listRecentOrdersByUser(uid, 5);
        %>

        <div id="cusModal_<%=uid%>" class="ad-modal" style="display:none;">
            <div class="ad-modal-backdrop" onclick="closeCustomerModal(<%=uid%>)"
                 style="position:fixed;inset:0;background:rgba(0,0,0,.35);z-index:999;"></div>

            <div class="ad-modal-box"
                 style="position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);
                        width:min(820px, calc(100% - 24px));
                        background:#fff;border:1px solid #eee;border-radius:16px;
                        box-shadow:0 10px 30px rgba(0,0,0,.15);
                        z-index:1000;">

                <div style="display:flex;justify-content:space-between;align-items:center;
                            padding:14px 16px;border-bottom:1px solid #f1f1f1;">
                    <div style="font-weight:900;font-size:18px;">
                        Chi tiết khách hàng #<%=uid%>
                    </div>
                    <button class="ad-btn red" type="button" onclick="closeCustomerModal(<%=uid%>)">
                        Đóng
                    </button>
                </div>

                <div style="padding:16px;">
                    <!-- PROFILE CARD -->
                    <div style="display:flex;gap:14px;align-items:center;
                                padding:14px;border:1px solid #eee;border-radius:14px;background:#fafafa;">
                        <div style="width:54px;height:54px;border-radius:50%;
                                    display:flex;align-items:center;justify-content:center;
                                    border:1px solid #e9e9e9;background:#fff;font-weight:900;">
                            <%= (fullName != null && fullName.trim().length() > 0)
                                    ? fullName.trim().substring(0,1).toUpperCase()
                                    : "U" %>
                        </div>

                        <div style="flex:1;">
                            <div style="font-size:16px;font-weight:900;"><%=fullName%></div>
                            <div style="opacity:.85;"><b>Email:</b> <%=email%></div>
                            <div style="opacity:.85;"><b>Phone:</b> <%=phone%></div>
                        </div>

                        <div style="text-align:right;">
                            <div class="ad-badge ok" style="display:inline-block;">ACTIVE</div>
                        </div>
                    </div>

                    <!-- STATS -->
                    <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-top:12px;">
                        <div style="border:1px solid #eee;border-radius:14px;padding:14px;">
                            <div style="opacity:.7;font-size:13px;">Tổng đơn hàng</div>
                            <div style="font-size:22px;font-weight:900;margin-top:6px;"><%=totalOrders%></div>
                        </div>
                        <div style="border:1px solid #eee;border-radius:14px;padding:14px;">
                            <div style="opacity:.7;font-size:13px;">Tổng chi tiêu</div>
                            <div style="font-size:22px;font-weight:900;margin-top:6px;"><%=df.format(totalSpent)%> đ</div>
                        </div>
                    </div>

                    <!-- RECENT ORDERS -->
                    <div style="margin-top:14px;">
                        <div style="display:flex;justify-content:space-between;align-items:center;gap:10px;">
                            <div style="font-weight:900;">Đơn gần đây</div>
                            <a class="ad-btn gray"
   href="index.jsp?module=admin_orders&user_id=<%=uid%>">
   Xem tất cả
</a>
                        </div>

                        <% if(recentOrders == null || recentOrders.isEmpty()){ %>
                            <div class="ad-msg warn" style="margin-top:10px;">⚠️ Chưa có đơn hàng.</div>
                        <% } else { %>

                        <table class="ad-table" style="margin-top:10px;">
                            <thead>
                                <tr>
                                    <th>Mã</th>
                                    <th>Ngày</th>
                                    <th>Trạng thái</th>
                                    <th style="text-align:right;">Tổng</th>
                                    <th></th>
                                </tr>
                            </thead>
                            <tbody>
                            <% for(Map<String,Object> o : recentOrders){

                                int oid = (o.get("order_id") instanceof Number) ? ((Number)o.get("order_id")).intValue() : 0;
                                String st = String.valueOf(o.get("status"));
                                Object createdAt = o.get("created_at");
                                long tot = (o.get("total_amount") instanceof Number) ? ((Number)o.get("total_amount")).longValue() : 0;

                                // format created_at
                                String timeText = "";
                                if(createdAt instanceof Timestamp){
                                    timeText = sdf.format((Timestamp)createdAt);
                                } else if(createdAt != null){
                                    String s = String.valueOf(createdAt);
                                    int dot = s.indexOf('.');
                                    timeText = (dot > 0) ? s.substring(0, dot) : s;
                                }

                                if(st == null || "null".equalsIgnoreCase(st)) st = "";
                                String ST = st.trim().toUpperCase();

                                String badgeCls = "ad-badge";
                                if("PENDING".equals(ST)) badgeCls += " warn";
                                else if("PAID".equals(ST)) badgeCls += " ok";
                                else if("SHIPPING".equals(ST)) badgeCls += " blue";
                                else if("DONE".equals(ST)) badgeCls += " ok";
                                else if("CANCEL".equals(ST)) badgeCls += " red";
                            %>
                                <tr>
                                    <td>#<%=oid%></td>
                                    <td><%=timeText%></td>
                                    <td><span class="<%=badgeCls%>"><%=ST%></span></td>
                                    <td style="text-align:right;"><%=df.format(tot)%> đ</td>
                                    <td style="text-align:right;white-space:nowrap;">
                                        <a class="ad-btn gray" href="index.jsp?module=admin_order_detail&id=<%=oid%>">Xem</a>
                                    </td>
                                </tr>
                            <% } %>
                            </tbody>
                        </table>

                        <% } %>
                    </div>
                </div>
            </div>
        </div>

        <% } %>
        <% } %>

    </div>
</div>

<script>
  function openCustomerModal(uid){
    var el = document.getElementById("cusModal_" + uid);
    if(el) el.style.display = "block";
  }
  function closeCustomerModal(uid){
    var el = document.getElementById("cusModal_" + uid);
    if(el) el.style.display = "none";
  }
</script>
