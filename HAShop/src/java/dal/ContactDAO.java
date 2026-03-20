package dal;

import java.sql.Connection;
import java.sql.PreparedStatement;

public class ContactDAO extends DBContext {

    public void createMessage(Integer userId,
                              String senderName,
                              String senderEmail,
                              String senderPhone,
                              String subject,
                              String messageContent) throws Exception {

        String sql =
            "INSERT INTO contact_messages(user_id, sender_name, sender_email, sender_phone, subject, message_content, status, created_at) " +
            "VALUES(?,?,?,?,?,?, 'NEW', GETDATE())";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            if (userId == null) ps.setNull(1, java.sql.Types.INTEGER);
            else ps.setInt(1, userId);

            ps.setString(2, senderName);
            ps.setString(3, senderEmail);
            ps.setString(4, senderPhone);
            ps.setString(5, subject);
            ps.setString(6, messageContent);

            ps.executeUpdate();
        }
    }
}
