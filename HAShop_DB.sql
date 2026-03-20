-- =============================================
-- HAShopDB - Badminton Shoe Shop
-- Tạo lại toàn bộ database từ source code
-- Chạy bằng tài khoản sa / 123
-- =============================================

USE master;
GO

-- Xoá DB cũ nếu có
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'HAShopDB')
BEGIN
    ALTER DATABASE HAShopDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE HAShopDB;
END
GO

CREATE DATABASE HAShopDB;
GO

USE HAShopDB;
GO

-- =============================================
-- 1. ROLES
-- =============================================
CREATE TABLE roles (
    role_id   INT PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL
);

INSERT INTO roles VALUES (1, N'USER'), (2, N'ADMIN');

-- =============================================
-- 2. USERS
-- =============================================
CREATE TABLE users (
    user_id       INT IDENTITY(1,1) PRIMARY KEY,
    role_id       INT NOT NULL DEFAULT 1 REFERENCES roles(role_id),
    full_name     NVARCHAR(100) NOT NULL,
    email         NVARCHAR(150) NOT NULL UNIQUE,
    phone         NVARCHAR(20),
    password_hash NVARCHAR(255) NOT NULL,
    status        TINYINT NOT NULL DEFAULT 1,   -- 1=active, 0=banned
    created_at    DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- Tài khoản Admin mặc định (password: admin123 -> SHA-256)
INSERT INTO users (role_id, full_name, email, phone, password_hash, status)
VALUES (
    2,
    N'Admin',
    'admin@hashop.vn',
    '0900000000',
    -- SHA-256 của "admin123"
    '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9',
    1
);

-- Tài khoản test User (password: 123456)
INSERT INTO users (role_id, full_name, email, phone, password_hash, status)
VALUES (
    1,
    N'Nguyễn Test',
    'user@test.vn',
    '0911111111',
    '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
    1
);

-- =============================================
-- 3. BRANDS
-- =============================================
CREATE TABLE brands (
    brand_id   INT IDENTITY(1,1) PRIMARY KEY,
    brand_name NVARCHAR(100) NOT NULL
);

INSERT INTO brands (brand_name) VALUES
    (N'Yonex'),
    (N'Victor'),
    (N'Lining'),
    (N'Kawasaki'),
    (N'Taro');

-- =============================================
-- 4. CATEGORIES
-- =============================================
CREATE TABLE categories (
    category_id   INT IDENTITY(1,1) PRIMARY KEY,
    category_name NVARCHAR(100) NOT NULL,
    slug          NVARCHAR(100)
);

INSERT INTO categories (category_name, slug) VALUES
    (N'Giày cầu lông nam', 'giay-cau-long-nam'),
    (N'Giày cầu lông nữ', 'giay-cau-long-nu'),
    (N'Giày cầu lông trẻ em', 'giay-cau-long-tre-em');

-- =============================================
-- 5. PRODUCTS
-- =============================================
CREATE TABLE products (
    product_id  INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT REFERENCES categories(category_id),
    brand_id    INT NOT NULL REFERENCES brands(brand_id),
    name        NVARCHAR(200) NOT NULL,
    slug        NVARCHAR(200),
    price       INT NOT NULL DEFAULT 0,
    target      NVARCHAR(20),   -- men / women / kids
    description NVARCHAR(MAX),
    thumbnail   NVARCHAR(500),
    status      TINYINT NOT NULL DEFAULT 1,  -- 1=active, 0=hidden
    created_at  DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

-- =============================================
-- 6. PRODUCT IMAGES
-- =============================================
CREATE TABLE product_images (
    image_id   INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    image_url  NVARCHAR(500) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

-- =============================================
-- 7. PRODUCT SIZES (tồn kho theo size)
-- =============================================
CREATE TABLE product_sizes (
    size_id    INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE CASCADE,
    size       INT NOT NULL,
    quantity   INT NOT NULL DEFAULT 0,
    UNIQUE (product_id, size)
);

-- =============================================
-- 8. CARTS & CART ITEMS
-- =============================================
CREATE TABLE carts (
    cart_id    INT IDENTITY(1,1) PRIMARY KEY,
    user_id    INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    UNIQUE (user_id)
);

CREATE TABLE cart_items (
    cart_item_id INT IDENTITY(1,1) PRIMARY KEY,
    cart_id      INT NOT NULL REFERENCES carts(cart_id) ON DELETE CASCADE,
    product_id   INT NOT NULL REFERENCES products(product_id),
    size         INT NOT NULL DEFAULT 0,
    quantity     INT NOT NULL DEFAULT 1,
    unit_price   INT NOT NULL DEFAULT 0,
    UNIQUE (cart_id, product_id, size)
);

-- =============================================
-- 9. ORDERS & ORDER ITEMS
-- =============================================
CREATE TABLE orders (
    order_id       INT IDENTITY(1,1) PRIMARY KEY,
    user_id        INT REFERENCES users(user_id),
    receiver_name  NVARCHAR(100) NOT NULL,
    receiver_phone NVARCHAR(20)  NOT NULL,
    receiver_addr  NVARCHAR(300) NOT NULL,
    email          NVARCHAR(150),
    note           NVARCHAR(500),
    total_amount   INT NOT NULL DEFAULT 0,
    payment_method NVARCHAR(20)  NOT NULL DEFAULT 'COD',
    status         NVARCHAR(20)  NOT NULL DEFAULT 'PENDING',
    created_at     DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_orders_status CHECK (status IN ('PENDING','PAID','SHIPPING','DONE','CANCEL'))
);

CREATE TABLE order_items (
    order_item_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id      INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id    INT NOT NULL REFERENCES products(product_id),
    size          INT NOT NULL DEFAULT 0,
    quantity      INT NOT NULL DEFAULT 1,
    unit_price    INT NOT NULL DEFAULT 0,
    line_total    AS (quantity * unit_price) PERSISTED
);

-- =============================================
-- 10. NEWS POSTS
-- =============================================
CREATE TABLE news_posts (
    post_id    INT IDENTITY(1,1) PRIMARY KEY,
    title      NVARCHAR(300) NOT NULL,
    slug       NVARCHAR(300),
    summary    NVARCHAR(500),
    content    NVARCHAR(MAX),
    thumbnail  NVARCHAR(500),
    is_active  BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);

INSERT INTO news_posts (title, slug, summary, content, thumbnail, is_active) VALUES
(
    N'Yonex ra mắt dòng giày Aerus Z3 2025',
    'yonex-aerus-z3-2025',
    N'Dòng giày cầu lông cao cấp mới nhất của Yonex với công nghệ Power Cushion vượt trội.',
    N'Yonex Aerus Z3 2025 được thiết kế dành cho các vận động viên chuyên nghiệp. Đế giày sử dụng công nghệ Power Cushion mới giúp giảm chấn tốt hơn 30% so với thế hệ trước.',
    'images/news/news-02.jpg',
    1
);

-- =============================================
-- 11. CONTACT MESSAGES  (Thread + Replies pattern)
-- Mỗi liên hệ là 1 thread (parent_id = NULL).
-- Các reply của user / admin là bản ghi con (parent_id = message_id của thread gốc).
-- sender_role: 'USER' | 'ADMIN'
-- status trên thread gốc: NEW -> READ -> REPLIED -> CLOSED
-- =============================================
CREATE TABLE contact_messages (
    message_id      INT IDENTITY(1,1) PRIMARY KEY,
    user_id         INT REFERENCES users(user_id),
    sender_name     NVARCHAR(100) NOT NULL DEFAULT N'',
    sender_email    NVARCHAR(150),
    sender_phone    NVARCHAR(20),
    subject         NVARCHAR(200),
    message_content NVARCHAR(MAX),
    status          NVARCHAR(20)  NOT NULL DEFAULT 'NEW',
    sender_role     NVARCHAR(10)  NOT NULL DEFAULT 'USER',  -- 'USER' hoặc 'ADMIN'
    parent_id       INT           NULL,                     -- NULL = thread gốc; có giá trị = reply
    created_at      DATETIME2     NOT NULL DEFAULT SYSDATETIME(),

    -- Giữ lại để không break nếu code cũ còn tham chiếu (có thể bỏ sau)
    admin_reply     NVARCHAR(MAX) NULL,
    replied_at      DATETIME2     NULL,

    CONSTRAINT CK_contact_status      CHECK (status      IN ('NEW','READ','REPLIED','CLOSED')),
    CONSTRAINT CK_contact_sender_role CHECK (sender_role IN ('USER','ADMIN')),
    CONSTRAINT FK_contact_parent      FOREIGN KEY (parent_id) REFERENCES contact_messages(message_id)
);

-- Index để query thread nhanh
CREATE INDEX IX_contact_parent   ON contact_messages(parent_id);
CREATE INDEX IX_contact_user     ON contact_messages(user_id);
CREATE INDEX IX_contact_status   ON contact_messages(status) WHERE parent_id IS NULL;

-- =============================================
-- DỮ LIỆU MẪU - CONTACT (để test giao diện chat)
-- =============================================
-- Thread 1: user hỏi về size giày (chưa được trả lời)
INSERT INTO contact_messages (user_id, sender_name, sender_email, sender_phone, subject, message_content, status, sender_role, parent_id)
VALUES (2, N'Nguyễn Test', 'user@test.vn', '0911111111',
        N'Hỏi về size giày Yonex',
        N'Chào shop! Mình thường đi size 42 giày thông thường thì nên chọn size bao nhiêu cho giày Yonex Aerus Z2 ạ?',
        'NEW', 'USER', NULL);

-- Thread 2: user hỏi về đổi trả (đã được admin trả lời, user reply lại)
INSERT INTO contact_messages (user_id, sender_name, sender_email, sender_phone, subject, message_content, status, sender_role, parent_id)
VALUES (2, N'Nguyễn Test', 'user@test.vn', '0911111111',
        N'Chính sách đổi trả hàng',
        N'Shop cho mình hỏi chính sách đổi trả hàng như thế nào ạ? Mình mua online có được đổi size không?',
        'REPLIED', 'USER', NULL);

-- Reply của admin cho thread 2
INSERT INTO contact_messages (user_id, sender_name, sender_email, message_content, status, sender_role, parent_id)
VALUES (NULL, N'HA SHOP', 'hashop@gmail.com',
        N'Chào bạn! HA SHOP hỗ trợ đổi size trong vòng 7 ngày kể từ ngày nhận hàng, với điều kiện sản phẩm chưa qua sử dụng và còn nguyên hộp. Bạn chỉ cần liên hệ hotline 0123 456 789 để được hướng dẫn thêm nhé!',
        'REPLIED', 'ADMIN', 2);

-- User reply lại cho thread 2 (thread đổi về NEW vì có tin mới từ user)
INSERT INTO contact_messages (user_id, sender_name, sender_email, message_content, status, sender_role, parent_id)
VALUES (2, N'Nguyễn Test', 'user@test.vn',
        N'Cảm ơn shop! Vậy nếu giày bị lỗi nhà sản xuất thì có được đổi không ạ?',
        'NEW', 'USER', 2);

UPDATE contact_messages SET status = 'NEW' WHERE message_id = 2;

-- =============================================
-- 12. DỮ LIỆU MẪU - PRODUCTS
-- =============================================
-- Yonex Aerus Z2 (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 1, N'Yonex Aerus Z2 2024', 'yonex-aerus-z2-2024', 2850000, 'men',
    N'Giày cầu lông cao cấp Yonex Aerus Z2, công nghệ Power Cushion, đế TOUGH SLIM.',
    'images/products/yonex/yonex-aerus-z2_red_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (1, 'images/products/yonex/yonex-aerus-z2_red_1.webp', 1),
    (1, 'images/products/yonex/yonex-aerus-z2_red_2.webp', 2);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (1,38,10),(1,39,15),(1,40,20),(1,41,18),(1,42,12),(1,43,8);

-- Yonex SHB 65Z3 (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 1, N'Yonex SHB 65Z3 Power 2', 'yonex-shb-65z3-power-2', 2350000, 'men',
    N'Giày cầu lông Yonex SHB 65Z3, thiết kế nhẹ bền, phù hợp thi đấu.',
    'images/products/yonex/yonex-shb-65z3-powe-2_white_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (2, 'images/products/yonex/yonex-shb-65z3-powe-2_white_1.webp', 1),
    (2, 'images/products/yonex/yonex-shb-65z3-powe-2_white_2.webp', 2),
    (2, 'images/products/yonex/yonex-shb-65z3-powe-2_white_3.webp', 3);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (2,38,8),(2,39,12),(2,40,20),(2,41,15),(2,42,10),(2,43,5);

-- Yonex Aerus Z2 Lady (Nữ)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (2, 1, N'Yonex Aerus Z2 Lady 2024', 'yonex-aerus-z2-lady-2024', 2850000, 'women',
    N'Phiên bản dành cho nữ của Aerus Z2, màu hồng nhạt thanh lịch.',
    'images/products/yonex/yonex-aerus-z2-lady-2024-light-pink_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (3, 'images/products/yonex/yonex-aerus-z2-lady-2024-light-pink_1.webp', 1),
    (3, 'images/products/yonex/yonex-aerus-z2-lady-2024-light-pink_2.webp', 2);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (3,36,10),(3,37,15),(3,38,20),(3,39,18),(3,40,12);

-- Victor A970 (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 2, N'Victor A970 CADV B Blue', 'victor-a970-cadv-b-blue', 1950000, 'men',
    N'Giày cầu lông Victor A970, công nghệ VSR đế cao su siêu bền.',
    'images/products/victor/victor-a970-cadv-b-blue_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (4, 'images/products/victor/victor-a970-cadv-b-blue_1.webp', 1),
    (4, 'images/products/victor/victor-a970-cadv-b-blue_2.webp', 2),
    (4, 'images/products/victor/victor-a970-cadv-b-blue_3.webp', 3);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (4,38,10),(4,39,15),(4,40,20),(4,41,18),(4,42,12),(4,43,8);

-- Victor Doraemon (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 2, N'Victor Doraemon P-DRM White', 'victor-doraemon-p-drm-white', 1750000, 'men',
    N'Phiên bản đặc biệt Doraemon của Victor, giới hạn số lượng.',
    'images/products/victor/victor-doraemon-p-drm_white_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (5, 'images/products/victor/victor-doraemon-p-drm_white_1.webp', 1),
    (5, 'images/products/victor/victor-doraemon-p-drm_white_2.webp', 2),
    (5, 'images/products/victor/victor-doraemon-p-drm_white_3.webp', 3),
    (5, 'images/products/victor/victor-doraemon-p-drm_white_4.webp', 4);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (5,38,5),(5,39,8),(5,40,10),(5,41,8),(5,42,5),(5,43,3);

-- Lining Aytu001 Blue (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 3, N'Lining AYTU001-4 Blue', 'lining-aytu001-4-blue', 1650000, 'men',
    N'Giày cầu lông Lining AYTU001, đế GMAX chống trơn trượt hiệu quả.',
    'images/products/lining/lining-aytu001-4_blue_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (6, 'images/products/lining/lining-aytu001-4_blue_1.webp', 1),
    (6, 'images/products/lining/lining-aytu001-4_blue_2.webp', 2),
    (6, 'images/products/lining/lining-aytu001-4_blue_3.webp', 3),
    (6, 'images/products/lining/lining-aytu001-4_blue_4.webp', 4);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (6,38,12),(6,39,18),(6,40,20),(6,41,15),(6,42,10),(6,43,6);

-- Kawasaki 357 Blue (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 4, N'Kawasaki 357 Blue', 'kawasaki-357-blue', 890000, 'men',
    N'Giày cầu lông Kawasaki giá tầm trung, phù hợp người mới chơi.',
    'images/products/kawasaki/kawasaki-357-blue_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (7, 'images/products/kawasaki/kawasaki-357-blue_1.webp', 1),
    (7, 'images/products/kawasaki/kawasaki-357-blue_2.webp', 2),
    (7, 'images/products/kawasaki/kawasaki-357-blue_3.webp', 3);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (7,38,15),(7,39,20),(7,40,25),(7,41,20),(7,42,15),(7,43,10);

-- Taro TR025 (Nam)
INSERT INTO products (category_id, brand_id, name, slug, price, target, description, thumbnail)
VALUES (1, 5, N'Taro TR025-1 Cam', 'taro-tr025-1-cam', 750000, 'men',
    N'Giày cầu lông Taro giá rẻ, bền, phù hợp tập luyện hàng ngày.',
    'images/products/taro/taro-tr025-1-cam_1.webp');

INSERT INTO product_images (product_id, image_url, sort_order) VALUES
    (8, 'images/products/taro/taro-tr025-1-cam_1.webp', 1),
    (8, 'images/products/taro/taro-tr025-1-cam_2.webp', 2),
    (8, 'images/products/taro/taro-tr025-1-cam_3.webp', 3),
    (8, 'images/products/taro/taro-tr025-1-cam_4.webp', 4);

INSERT INTO product_sizes (product_id, size, quantity) VALUES
    (8,38,20),(8,39,25),(8,40,30),(8,41,25),(8,42,20),(8,43,15);

-- =============================================
-- XONG! Kiểm tra
-- =============================================
SELECT 'users'    AS [Table], COUNT(*) AS [Rows] FROM users    UNION ALL
SELECT 'brands',            COUNT(*) FROM brands               UNION ALL
SELECT 'products',          COUNT(*) FROM products             UNION ALL
SELECT 'product_images',    COUNT(*) FROM product_images       UNION ALL
SELECT 'product_sizes',     COUNT(*) FROM product_sizes        UNION ALL
SELECT 'news_posts',        COUNT(*) FROM news_posts;
GO

PRINT '✅ HAShopDB tạo thành công!';
PRINT '   Admin: admin@hashop.vn / admin123';
PRINT '   User:  user@test.vn   / 123456';
GO

-- =============================================
-- THÊM SẢN PHẨM (tổng 20 sản phẩm)
-- =============================================

-- SP 9: Yonex 88 Dial 3 Wide (Nam)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(1,1,N'Yonex 88 Dial 3 Wide 2024','yonex-88-dial-3-wide-2024',3200000,'men',
N'Giày cầu lông Yonex 88 Dial 3 Wide 2024, công nghệ Round Sole tối ưu vận động.',
'images/products/yonex/yonex-88-dial-3-wide-2024-den2_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(9,'images/products/yonex/yonex-88-dial-3-wide-2024-den2_1.webp',1),(9,'images/products/yonex/yonex-88-dial-3-wide-2024-den2_2.webp',2),(9,'images/products/yonex/yonex-88-dial-3-wide-2024-den2_3.webp',3);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(9,38,8),(9,39,12),(9,40,18),(9,41,15),(9,42,10),(9,43,6);

-- SP 10: Yonex 88 Dial 3 Wide White (Nam)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(1,1,N'Yonex 88 Dial 3 Wide White 2024','yonex-88-dial-3-wide-white',3200000,'men',
N'Phiên bản màu trắng của Yonex 88 Dial 3 Wide, thiết kế sang trọng.',
'images/products/yonex/yonex-88-dial-3-wide-2024_white_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(10,'images/products/yonex/yonex-88-dial-3-wide-2024_white_1.webp',1),(10,'images/products/yonex/yonex-88-dial-3-wide-2024_white_2.webp',2),(10,'images/products/yonex/yonex-88-dial-3-wide-2024_white_3.webp',3);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(10,38,6),(10,39,10),(10,40,15),(10,41,12),(10,42,8),(10,43,4);

-- SP 11: Victor P9200 III Red (Nam)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(1,2,N'Victor P9200 III Red','victor-p9200iii-red',2100000,'men',
N'Giày cầu lông Victor P9200 III, đế Energy MAX, bảo vệ mắt cá chân tốt.',
'images/products/victor/victor-p9200iii_red_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(11,'images/products/victor/victor-p9200iii_red_1.webp',1),(11,'images/products/victor/victor-p9200iii_red_2.webp',2),(11,'images/products/victor/victor-p9200iii_red_3.webp',3);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(11,38,10),(11,39,14),(11,40,20),(11,41,16),(11,42,10),(11,43,6);

-- SP 12: Lining AYZT005 White (Nữ)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(2,3,N'Lining AYZT005-1 White','lining-ayzt005-1-white',1850000,'women',
N'Giày cầu lông Lining AYZT005 dành cho nữ, nhẹ nhàng và linh hoạt.',
'images/products/lining/lining-ayzt005-1_white_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(12,'images/products/lining/lining-ayzt005-1_white_1.webp',1),(12,'images/products/lining/lining-ayzt005-1_white_2.webp',2),(12,'images/products/lining/lining-ayzt005-1_white_3.webp',3),(12,'images/products/lining/lining-ayzt005-1_white_4.webp',4);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(12,36,8),(12,37,12),(12,38,15),(12,39,10),(12,40,6);

-- SP 13: Lining Mau 1 (Nam)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(1,3,N'Lining Training Pro Đỏ','lining-training-pro-do',1350000,'men',
N'Giày cầu lông Lining dòng tập luyện, đế chống trơn, bền bỉ.',
'images/products/lining/lining_mau1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(13,'images/products/lining/lining_mau1.webp',1),(13,'images/products/lining/lining_mau2.webp',2),(13,'images/products/lining/lining_mau3.webp',3);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(13,38,15),(13,39,20),(13,40,25),(13,41,18),(13,42,12),(13,43,8);

-- SP 14: Kawasaki A3311 White (Nữ)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(2,4,N'Kawasaki A3311-2 White','kawasaki-a3311-2-white',950000,'women',
N'Giày cầu lông Kawasaki A3311 màu trắng, phù hợp nữ tập luyện.',
'images/products/kawasaki/kawasaki-a3311-2-white_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(14,'images/products/kawasaki/kawasaki-a3311-2-white_1.webp',1),(14,'images/products/kawasaki/kawasaki-a3311-2-white_2.webp',2);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(14,36,10),(14,37,15),(14,38,20),(14,39,15),(14,40,10);

-- SP 15: Taro TR025 Đen (Nam)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(1,5,N'Taro TR025-1 Đen','taro-tr025-1-den',750000,'men',
N'Giày cầu lông Taro màu đen, thiết kế năng động, phù hợp mọi sân.',
'images/products/taro/taro-tr025-1-den_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(15,'images/products/taro/taro-tr025-1-den_1.webp',1),(15,'images/products/taro/taro-tr025-1-den_2.webp',2),(15,'images/products/taro/taro-tr025-1-den_3.webp',3),(15,'images/products/taro/taro-tr025-1-den_4.webp',4);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(15,38,20),(15,39,25),(15,40,30),(15,41,22),(15,42,15),(15,43,10);

-- SP 16: Yonex Aerus Z2 Lady (Nữ - thêm màu khác)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(2,1,N'Yonex SHB 65Z3 Lady Pink','yonex-shb-65z3-lady',2200000,'women',
N'Giày cầu lông Yonex dành riêng cho nữ, màu hồng pastel thời trang.',
'images/products/lining/yonex-aerus-z2-lady-2024-light-pink_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(16,'images/products/lining/yonex-aerus-z2-lady-2024-light-pink_1.webp',1),(16,'images/products/lining/yonex-aerus-z2-lady-2024-light-pink_2.webp',2);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(16,36,8),(16,37,10),(16,38,15),(16,39,12),(16,40,8);

-- SP 17: Victor A970 Red (Nam)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(1,2,N'Victor A970 CADV Red','victor-a970-red',1980000,'men',
N'Giày cầu lông Victor A970 màu đỏ, bộ sưu tập Đại hội thể thao.',
'images/products/victor/victor-p9200iii_red_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(17,'images/products/victor/victor-p9200iii_red_1.webp',1),(17,'images/products/victor/victor-p9200iii_red_2.webp',2);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(17,38,8),(17,39,12),(17,40,18),(17,41,14),(17,42,9),(17,43,5);

-- SP 18: Kawasaki 357 (Nữ)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(2,4,N'Kawasaki 357 Lady Blue','kawasaki-357-lady',890000,'women',
N'Giày cầu lông Kawasaki 357 phiên bản nữ, nhẹ và êm ái.',
'images/products/kawasaki/kawasaki-357-blue_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(18,'images/products/kawasaki/kawasaki-357-blue_1.webp',1),(18,'images/products/kawasaki/kawasaki-357-blue_2.webp',2);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(18,36,10),(18,37,15),(18,38,20),(18,39,15),(18,40,10);

-- SP 19: Lining Aytu001 (Nữ)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(2,3,N'Lining AYTU001 Lady White','lining-aytu001-lady',1650000,'women',
N'Giày cầu lông Lining AYTU001 phiên bản nữ, thoáng khí, linh hoạt.',
'images/products/lining/lining-aytu001-4_blue_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(19,'images/products/lining/lining-aytu001-4_blue_1.webp',1),(19,'images/products/lining/lining-aytu001-4_blue_2.webp',2);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(19,36,8),(19,37,12),(19,38,16),(19,39,12),(19,40,8);

-- SP 20: Victor Doraemon Lady (Nữ)
INSERT INTO products (category_id,brand_id,name,slug,price,target,description,thumbnail)
VALUES(2,2,N'Victor Doraemon Lady Edition','victor-doraemon-lady',1750000,'women',
N'Phiên bản đặc biệt Doraemon dành cho nữ, giới hạn số lượng.',
'images/products/victor/victor-doraemon-p-drm_white_1.webp');
INSERT INTO product_images(product_id,image_url,sort_order) VALUES(20,'images/products/victor/victor-doraemon-p-drm_white_1.webp',1),(20,'images/products/victor/victor-doraemon-p-drm_white_2.webp',2),(20,'images/products/victor/victor-doraemon-p-drm_white_3.webp',3);
INSERT INTO product_sizes(product_id,size,quantity) VALUES(20,36,5),(20,37,8),(20,38,10),(20,39,8),(20,40,5);

-- Kiểm tra tổng
SELECT 'Tổng sản phẩm' AS [Check], COUNT(*) AS [Count] FROM products;
GO
PRINT '✅ Đã thêm đủ 20 sản phẩm!';
GO
