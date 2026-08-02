select * from ecommerce_orders_dataset;
-- rename table yang salah penamaan
-- memperbaiki type column
alter table ecommerce_orders_dataset
rename column ï»¿OrderID to OrderID;
alter table ecommerce_orders_dataset
rename column dates to Dates;

ALTER TABLE ecommerce_orders_dataset
MODIFY COLUMN Dates DATE;
ALTER TABLE ecommerce_orders_dataset
MODIFY COLUMN OrderID VARCHAR(50),
MODIFY COLUMN CustomerID VARCHAR(50),
MODIFY COLUMN OrderStatus VARCHAR(50),
MODIFY COLUMN PaymentMethod VARCHAR(50);

describe ecommerce_orders_dataset;


-- mencari data duplikat
SELECT 
    OrderID, 
    COUNT(*) AS jumlah_kemunculan
FROM ecommerce_orders_dataset
GROUP BY OrderID
HAVING COUNT(*) > 1;

-- Exploratory Data Analysis (EDA)

select
	count(OrderId) as jumlah_order,
    round(sum(Quantity * UnitPrice),2) as total_revenu,
    round(avg(TotalPrice), 2) as avg_revenue
from ecommerce_orders_dataset
where OrderStatus = 'Shipped';

SELECT 
    MIN(dates) AS tanggal_pertama,
    MAX(dates) AS tanggal_terakhir
FROM ecommerce_orders_dataset;

SELECT 
    MIN(TotalPrice) AS nilai_terendah,
    MAX(TotalPrice) AS nilai_tertinggi,
    round(AVG(TotalPrice), 2)  AS rata_rata,
    round(STDDEV(TotalPrice), 2) AS standar_deviasi
FROM ecommerce_orders_dataset;

SELECT OrderID, CustomerID, Product, Quantity, UnitPrice, TotalPrice
FROM ecommerce_orders_dataset
ORDER BY TotalPrice DESC
LIMIT 10;

SELECT OrderID, CustomerID, Product, Quantity, UnitPrice, TotalPrice
FROM ecommerce_orders_dataset
ORDER BY TotalPrice asc
LIMIT 10;

SELECT OrderID, CustomerID, Product, Quantity, UnitPrice, TotalPrice
FROM ecommerce_orders_dataset
WHERE TotalPrice <= 0 OR TotalPrice IS NULL
ORDER BY TotalPrice ASC
LIMIT 10;

SELECT *
FROM ecommerce_orders_dataset
WHERE TotalPrice > (
    SELECT AVG(TotalPrice) + (3 * STDDEV(TotalPrice)) 
    FROM ecommerce_orders_dataset
);

-- Business Questioning & Analysis
-- Trend Penjualan Harian
SELECT 
    DATE(Dates) AS tanggal,
    COUNT(OrderID) AS total_transaksi,
    ROUND(SUM(TotalPrice),2) AS total_omzet
FROM ecommerce_orders_dataset
WHERE OrderStatus = 'Shipped'
GROUP BY DATE(Dates)
ORDER BY total_omzet DESC;

-- Trend Penjualan Bulanan

SELECT 
    DATE_FORMAT(Dates, '%Y-%m') AS bulan_tahun, -- Format YYYY-MM (MySQL)
    COUNT(OrderID) AS total_transaksi,
    ROUND(SUM(TotalPrice), 2) AS total_omzet
FROM ecommerce_orders_dataset
WHERE  OrderStatus = 'Shipped'
GROUP BY bulan_tahun
ORDER BY bulan_tahun ASC; 

-- Analisa Hari Tertentu Dalam Seminggu

SELECT 
    DAYNAME(Dates) AS nama_hari,
    COUNT(OrderId) AS total_transaksi,
    ROUND(SUM(TotalPrice),2) AS total_omzet,
    ROUND(AVG(TotalPrice),2) AS rata_rata_omzet_per_hari
FROM ecommerce_orders_dataset
WHERE OrderStatus = 'Shipped'
GROUP BY nama_hari, DAYOFWEEK(Dates)
ORDER BY DAYOFWEEK(Dates) ASC; 

-- Identifikasi produk apa yang paling laris berdasarkan kuantitas (top seller).
SELECT
	Product,
    SUM(Quantity) AS total_produk_terjual
FROM ecommerce_orders_dataset
where OrderStatus = 'Shipped'
group by Product
order by total_produk_terjual desc;

-- Identifikasi produk yang menyumbang pendapatan terbesar (top revenue).
select
	Product,
    round(sum(Quantity * UnitPrice), 2) as pendapatan_terbesar
from ecommerce_orders_dataset
where OrderStatus = 'Shipped'
group by product
order by pendapatan_terbesar desc
limit 10;

-- cari pelanggan behavior
-- repet order or retention

WITH CustomerOrderCount AS (
    -- Langkah 1: Hitung total transaksi per pelanggan
    SELECT 
        CustomerID,
        COUNT(DISTINCT OrderID) AS total_order
    FROM ecommerce_orders_dataset
    WHERE OrderStatus = 'Shipped'
    GROUP BY CustomerID
)
-- Langkah 2: Hitung proporsi dan persentasenya
SELECT 
    CASE 
        WHEN total_order = 1 THEN 'Single Purchase (1x Beli)'
        ELSE 'Repeat Customer (>1x Beli)'
    END AS tipe_pelanggan,
    
    COUNT(CustomerID) AS jumlah_pelanggan,
    
    ROUND(
        (COUNT(CustomerID) * 100.0) / SUM(COUNT(CustomerID)) OVER(), 
        2
    ) AS persentase
FROM CustomerOrderCount
GROUP BY tipe_pelanggan;

-- analysis payment method

SELECT 
    PaymentMethod, -- Nama kolom metode pembayaran di tabel Anda
    COUNT(DISTINCT OrderID) AS total_transaksi,
    SUM(Quantity * UnitPrice) AS total_omzet,
    
    -- Menghitung Persentase Transaksi
    ROUND(
        (COUNT(DISTINCT OrderID) * 100.0) / SUM(COUNT(DISTINCT OrderID)) OVER(), 
        2
    ) AS persentase_penggunaan
FROM ecommerce_orders_dataset
WHERE OrderStatus = 'Shipped'
GROUP BY PaymentMethod
ORDER BY total_transaksi DESC;

-- Analisis Rasio Status Pesanan (Order Status Ratio)
SELECT 
    OrderStatus,
    COUNT(DISTINCT OrderID) AS total_pesanan,
    
    -- Menghitung persentase terhadap total seluruh pesanan
    ROUND(
        (COUNT(DISTINCT OrderID) * 100.0) / SUM(COUNT(DISTINCT OrderID)) OVER(), 
        2
    ) AS persentase
FROM ecommerce_orders_dataset
GROUP BY OrderStatus
ORDER BY total_pesanan DESC;

-- Persentase Transaksi Menggunakan Coupon Code

SELECT 
    CASE 
        WHEN CouponCode IS NOT NULL AND CouponCode != '' THEN 'Pakai Kupon'
        ELSE 'Tanpa Kupon'
    END AS kategori_kupon,
    
    COUNT(DISTINCT OrderID) AS total_transaksi,
    ROUND(SUM(Quantity * UnitPrice),2) AS total_omzet,
    
    ROUND(
        (COUNT(DISTINCT OrderID) * 100.0) / SUM(COUNT(DISTINCT OrderID)) OVER(), 
        2
    ) AS persentase_transaksi
FROM ecommerce_orders_dataset
WHERE OrderStatus = 'Shipped' 
GROUP BY kategori_kupon;


-- analysa customer referalsource

SELECT 
    ReferralSource, -- Nama kolom sumber traffic (misal: TikTok, Instagram, Google, Direct)
    COUNT(DISTINCT OrderID) AS total_transaksi,
    ROUND(SUM(Quantity * UnitPrice),2) AS total_omzet,
    
    -- Persentase transaksi berdasarkan rujukan
    ROUND(
        (COUNT(DISTINCT OrderID) * 100.0) / SUM(COUNT(DISTINCT OrderID)) OVER(), 
        2
    ) AS persentase_transaksi,
    
    -- Rata-rata nilai belanja per transaksi (Average Order Value / AOV)
    ROUND(
        SUM(Quantity * UnitPrice) / COUNT(DISTINCT OrderID), 
        2
    ) AS rata_rata_belanja
FROM ecommerce_orders_dataset
WHERE OrderStatus = 'Shipped'
GROUP BY ReferralSource
ORDER BY total_transaksi DESC;
