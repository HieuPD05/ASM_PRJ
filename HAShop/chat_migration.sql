-- ============================================================
-- MIGRATION: Nâng cấp hệ thống chat contact lên Thread+Replies
-- Chạy script này 1 lần trên SQL Server
-- ============================================================

-- 1. Thêm cột parent_id vào contact_messages để nhóm thread
--    (không xóa cột admin_reply cũ để giữ data cũ)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('contact_messages') AND name = 'parent_id'
)
BEGIN
    ALTER TABLE contact_messages ADD parent_id INT NULL;
    ALTER TABLE contact_messages ADD CONSTRAINT FK_contact_parent
        FOREIGN KEY (parent_id) REFERENCES contact_messages(message_id);
    PRINT 'Added parent_id to contact_messages';
END

-- 2. Thêm cột sender_role: 'USER' hoặc 'ADMIN'
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('contact_messages') AND name = 'sender_role'
)
BEGIN
    ALTER TABLE contact_messages ADD sender_role NVARCHAR(10) NOT NULL DEFAULT 'USER';
    PRINT 'Added sender_role to contact_messages';
END

-- 3. Index để truy vấn thread nhanh
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_contact_parent')
BEGIN
    CREATE INDEX IX_contact_parent ON contact_messages(parent_id);
    PRINT 'Created index IX_contact_parent';
END

-- 4. Migrate data cũ: nếu admin_reply đang có giá trị
--    => tạo bản ghi reply của admin vào bảng (dưới dạng tin nhắn con)
INSERT INTO contact_messages
    (user_id, sender_name, sender_email, sender_phone, subject,
     message_content, status, sender_role, parent_id, created_at)
SELECT
    NULL,                      -- admin không có user_id
    N'HA SHOP',
    N'hashop@gmail.com',
    NULL,
    N'RE: ' + ISNULL(subject, N''),
    admin_reply,
    'REPLIED',
    'ADMIN',
    message_id,
    ISNULL(replied_at, GETDATE())
FROM contact_messages
WHERE admin_reply IS NOT NULL
  AND admin_reply <> ''
  AND parent_id IS NULL        -- chỉ migrate thread gốc
  AND sender_role = 'USER';

PRINT 'Migrated old admin_reply data into message_replies pattern';
