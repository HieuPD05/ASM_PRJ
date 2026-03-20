package controller;

import dal.AdminDAO;
import jakarta.servlet.*;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.http.*;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize       = 10 * 1024 * 1024,
    maxRequestSize    = 30 * 1024 * 1024
)
public class AdminNewsServlet extends HttpServlet {

    private static final String IMG_REL = "images/news/upload/";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if(action == null) action = "";

        int page = parseInt(req.getParameter("page"), 1);
        String base = req.getContextPath() + "/index.jsp?module=admin_news&page=" + page;

        String uploadDir = getServletContext().getRealPath("/" + IMG_REL);
        new File(uploadDir).mkdirs();

        try {
            AdminDAO dao = new AdminDAO();

            if("create".equalsIgnoreCase(action)){
                String title     = req.getParameter("title");
                String summary   = req.getParameter("summary");
                String content   = req.getParameter("content");
                String thumbnail = uploadFile(req, "thumbnail_file", uploadDir,
                                              req.getParameter("old_thumbnail"));
                boolean isActive = "1".equals(req.getParameter("is_active"));

                dao.createNews(title, summary, content, thumbnail, isActive);
                resp.sendRedirect(base + "&msg=created");
                return;
            }

            if("update".equalsIgnoreCase(action)){
                int id = parseInt(req.getParameter("post_id"), 0);
                String title     = req.getParameter("title");
                String summary   = req.getParameter("summary");
                String content   = req.getParameter("content");
                String thumbnail = uploadFile(req, "thumbnail_file", uploadDir,
                                              req.getParameter("old_thumbnail"));
                boolean isActive = "1".equals(req.getParameter("is_active"));

                dao.updateNews(id, title, summary, content, thumbnail, isActive);
                resp.sendRedirect(base + "&msg=updated");
                return;
            }

            if("delete".equalsIgnoreCase(action)){
                int id = parseInt(req.getParameter("post_id"), 0);
                boolean ok = dao.deleteNews(id);
                resp.sendRedirect(base + "&msg=" + (ok ? "deleted" : "delete_fail"));
                return;
            }

            resp.sendRedirect(base);

        } catch(Exception e){
            throw new ServletException(e);
        }
    }

    private String uploadFile(HttpServletRequest req, String fieldName,
                               String uploadDir, String fallback)
            throws IOException, ServletException {
        Part part = null;
        try { part = req.getPart(fieldName); } catch(Exception e) {}

        if(part != null && part.getSize() > 0){
            String original = Paths.get(part.getSubmittedFileName()).getFileName().toString();
            String ext = ".jpg";
            int dot = original.lastIndexOf('.');
            if(dot >= 0){
                String e = original.substring(dot).toLowerCase();
                if(e.matches("\\.(jpg|jpeg|png|gif|webp|bmp)")) ext = e;
            }
            String savedName = UUID.randomUUID().toString().replace("-","") + ext;
            try(InputStream in = part.getInputStream()){
                Files.copy(in, Paths.get(uploadDir + File.separator + savedName),
                           StandardCopyOption.REPLACE_EXISTING);
            }
            return IMG_REL + savedName;
        }
        return (fallback != null) ? fallback.trim() : "";
    }

    private int parseInt(String s, int def){
        try { return Integer.parseInt(s); } catch(Exception e){ return def; }
    }
}
