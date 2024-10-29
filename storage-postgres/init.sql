-- Create databases
CREATE DATABASE mlflow;
CREATE DATABASE store_db;
CREATE DATABASE airflow;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mlflow TO postgres_user;
GRANT ALL PRIVILEGES ON DATABASE store_db TO postgres_user;
GRANT ALL PRIVILEGES ON DATABASE airflow TO postgres_user;

-- Setup store_db
\c store_db
CREATE TABLE Companies
(
    cuit CHAR(11) PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE EndCustomers
(
    document_number CHAR(8) PRIMARY KEY,
    full_name       VARCHAR(255) NOT NULL,
    date_of_birth   DATE         NOT NULL
);

CREATE TABLE Suppliers
(
    cuit CHAR(11) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    FOREIGN KEY (cuit) REFERENCES Companies (cuit)
);

CREATE TABLE Products
(
    product_id    SERIAL PRIMARY KEY,
    name          VARCHAR(255)   NOT NULL,
    default_price DECIMAL(10, 2) NOT NULL,
    supplier_cuit CHAR(11)       NOT NULL,
    FOREIGN KEY (supplier_cuit) REFERENCES Suppliers (cuit)
);

CREATE TABLE Catalogs
(
    catalog_id   SERIAL PRIMARY KEY,
    company_cuit CHAR(11) NOT NULL,
    FOREIGN KEY (company_cuit) REFERENCES Companies (cuit)
);

CREATE TABLE CatalogItems
(
    catalog_item_id SERIAL PRIMARY KEY,
    catalog_id      INT            NOT NULL,
    product_id      INT            NOT NULL,
    price           DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (catalog_id) REFERENCES Catalogs (catalog_id),
    FOREIGN KEY (product_id) REFERENCES Products (product_id),
    UNIQUE (catalog_id, product_id)
);

CREATE TABLE Orders
(
    order_id                 SERIAL PRIMARY KEY,
    company_cuit             CHAR(11) NOT NULL,
    customer_document_number CHAR(8) NOT NULL,
    order_date               DATE     NOT NULL,
    FOREIGN KEY (company_cuit) REFERENCES Companies (cuit),
    FOREIGN KEY (customer_document_number) REFERENCES EndCustomers (document_number)
);

CREATE TABLE OrderItems
(
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT            NOT NULL,
    product_id    INT            NOT NULL,
    quantity      INT            NOT NULL,
    price         DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders (order_id),
    FOREIGN KEY (product_id) REFERENCES Products (product_id)
);

-- Insert sample data into Companies
INSERT INTO Companies (cuit, name)
VALUES ('20123456780', 'Company A'),
       ('20345678901', 'Company B'),
       ('20456789012', 'Supplier X'),
       ('20567890123', 'Supplier Y');

-- Insert sample data into EndCustomers
INSERT INTO EndCustomers (document_number, full_name, date_of_birth)
VALUES ('DN123456', 'John Doe', '1985-05-15'),
       ('DN654321', 'Jane Smith', '1990-10-20'),
       ('DN789012', 'Alice Brown', '1975-08-25'),
       ('DN345678', 'Charlie Johnson', '1980-02-10'),
       ('DN987654', 'Emily Davis', '1995-11-05'),
       ('DN543210', 'Michael Miller', '1983-04-17');

-- Insert sample data into Suppliers (note that Suppliers are also Companies)
INSERT INTO Suppliers (cuit, name)
VALUES ('20456789012', 'Supplier X'),
       ('20567890123', 'Supplier Y');

-- Insert sample data into Products
INSERT INTO Products (name, default_price, supplier_cuit)
VALUES ('Product 1', 100.00, '20456789012'),
       ('Product 2', 150.00, '20456789012'),
       ('Product 3', 200.00, '20456789012'),
       ('Product 4', 250.00, '20456789012'),
       ('Product 5', 300.00, '20567890123'),
       ('Product 6', 350.00, '20567890123'),
       ('Product 7', 400.00, '20567890123'),
       ('Product 8', 450.00, '20567890123');

-- Insert sample data into Catalogs
INSERT INTO Catalogs (company_cuit)
VALUES ('20123456780'),
       ('20345678901');

-- Insert sample data into CatalogItems
INSERT INTO CatalogItems (catalog_id, product_id, price)
VALUES (1, 1, 90.00),
       (1, 2, 140.00),
       (2, 3, 190.00),
       (2, 4, 240.00),
       (1, 5, 10.00),
       (1, 6, 155.00),
       (2, 7, 40.00),
       (2, 8, 34.00);

-- Insert sample data into Orders
INSERT INTO Orders (company_cuit, customer_document_number, order_date)
VALUES ('20123456780', 'DN123456', '2024-07-01'),
       ('20123456780', 'DN123456', '2024-07-02'),
       ('20345678901', 'DN654321', '2024-07-03'),
       ('20345678901', 'DN654321', '2024-06-04'),
       ('20456789012', 'DN789012', '2024-07-05'),
       ('20456789012', 'DN789012', '2024-07-06'),
       ('20567890123', 'DN345678', '2024-06-07'),
       ('20567890123', 'DN345678', '2024-06-08'),
       ('20345678901', 'DN987654', '2024-07-09'),
       ('20345678901', 'DN987654', '2024-06-10'),
       ('20123456780', 'DN123456', '2024-01-11'),
       ('20123456780', 'DN123456', '2024-04-12'),
       ('20123456780', 'DN654321', '2024-04-13'),
       ('20123456780', 'DN654321', '2024-03-14'),
       ('20123456780', 'DN789012', '2024-07-15'),
       ('20123456780', 'DN789012', '2024-02-16'),
       ('20345678901', 'DN345678', '2024-07-17'),
       ('20345678901', 'DN345678', '2024-02-18'),
       ('20456789012', 'DN987654', '2024-07-19'),
       ('20456789012', 'DN987654', '2023-01-20');

-- Insert sample data into OrderItems
INSERT INTO OrderItems (order_id, product_id, quantity, price)
VALUES (1, 1, 2, 100.00),
       (1, 2, 1, 150.00),
       (2, 3, 3, 200.00),
       (2, 4, 1, 250.00),
       (3, 5, 1, 300.00),
       (3, 6, 2, 350.00),
       (4, 7, 1, 400.00),
       (4, 8, 1, 450.00),
       (5, 1, 2, 100.00),
       (5, 3, 1, 200.00),
       (6, 2, 2, 150.00),
       (6, 4, 1, 250.00),
       (7, 5, 1, 300.00),
       (7, 6, 2, 350.00),
       (8, 7, 1, 400.00),
       (8, 8, 1, 450.00),
       (9, 1, 2, 100.00),
       (9, 2, 1, 150.00),
       (10, 3, 3, 200.00),
       (10, 4, 1, 250.00),
       (11, 5, 1, 300.00),
       (11, 6, 2, 350.00),
       (12, 7, 1, 400.00),
       (12, 8, 1, 450.00),
       (13, 1, 2, 100.00),
       (13, 2, 1, 150.00),
       (14, 3, 3, 200.00),
       (14, 4, 1, 250.00),
       (15, 5, 1, 300.00),
       (15, 6, 2, 350.00),
       (16, 7, 1, 400.00),
       (16, 8, 1, 450.00),
       (17, 1, 2, 100.00),
       (17, 2, 1, 150.00),
       (18, 3, 3, 200.00),
       (18, 4, 1, 250.00),
       (19, 5, 1, 300.00),
       (19, 6, 2, 350.00),
       (20, 7, 1, 400.00),
       (20, 8, 1, 450.00);