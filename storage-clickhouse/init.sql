CREATE DATABASE IF NOT EXISTS dwh;
USE dwh;

-- platform db source
DROP TABLE IF EXISTS raw_platform_db_companies;
CREATE TABLE raw_platform_db_companies
(
    `cuit`      text,
    `name`      text,
    `load_date` Date
)
    ENGINE = MergeTree()
        PARTITION BY load_date
        order by cuit;

DROP TABLE IF EXISTS raw_platform_db_endcustomers;
CREATE TABLE raw_platform_db_endcustomers
(
    `document_number` text,
    `full_name`       text,
    `date_of_birth`   date,
    `load_date`       Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by document_number;

DROP TABLE IF EXISTS raw_platform_db_suppliers;
CREATE TABLE raw_platform_db_suppliers
(
    `cuit`      text,
    `name`      text,
    `load_date` Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by cuit;

DROP TABLE IF EXISTS raw_platform_db_products;
CREATE TABLE raw_platform_db_products
(
    `product_id`    int,
    `name`          text,
    `default_price` decimal(10, 2),
    `supplier_cuit` text,
    `load_date`     Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by product_id;

DROP TABLE IF EXISTS raw_platform_db_catalogs;
CREATE TABLE raw_platform_db_catalogs
(
    `catalog_id`   text,
    `company_cuit` text,
    `load_date`    Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by catalog_id;


DROP TABLE IF EXISTS raw_platform_db_catalogitems;
CREATE TABLE raw_platform_db_catalogitems
(
    `catalog_item_id` text,
    `catalog_id`      int,
    `product_id`      int,
    `price`           decimal(10, 2),
    `load_date`       Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by catalog_item_id;

DROP TABLE IF EXISTS raw_platform_db_orders;
CREATE TABLE raw_platform_db_orders
(
    order_id                 int,
    company_cuit             text,
    customer_document_number text,
    order_date               Date,
    load_date                Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by order_id;

DROP TABLE IF EXISTS raw_platform_db_orderitems;
CREATE TABLE raw_platform_db_orderitems
(
    order_item_id int,
    order_id      int,
    product_id    int,
    quantity      int,
    price         decimal(10, 2),
    load_date     Date
) ENGINE = MergeTree()
      PARTITION BY load_date
      order by order_item_id;

-- Kafka source
DROP TABLE IF EXISTS weblog_events;
CREATE TABLE weblog_events
(
    ip         text,
    identity   text,
    username   text,
    timestamp  text,
    request    text,
    status     text,
    size       text,
    referrer   text,
    user_agent text
)
    ENGINE = MergeTree()
        ORDER BY timestamp;

-- ip geocoding dictionary
create table geoip_url
(
    ip_range_start IPv4,
    ip_range_end   IPv4,
    country_code   Nullable(String),
    state1         Nullable(String),
    state2         Nullable(String),
    city           Nullable(String),
    postcode       Nullable(String),
    latitude       Float64,
    longitude      Float64,
    timezone       Nullable(String)
) engine = URL('https://raw.githubusercontent.com/sapics/ip-location-db/master/dbip-city/dbip-city-ipv4.csv.gz', 'CSV');

create table geoip
(
    geo_cidr_key String,
    geo_cidr     String ALIAS geo_cidr_key,
    latitude     Float64,
    longitude    Float64,
    city         String,
    state        String,
    country_code String
)
    engine = MergeTree()
        order by geo_cidr_key;

insert into geoip
with
    bitXor(ip_range_start, ip_range_end) as xor, if(xor != 0, ceil(log2(xor)), 0) as unmatched, 32 - unmatched as cidr_suffix, toIPv4(
        bitAnd(bitNot(pow(2, unmatched) - 1), ip_range_start) ::UInt64) as cidr_address
select concat(toString(cidr_address), '/', toString(cidr_suffix)) as geo_cidr_key,
       latitude,
       longitude,
       city,
       state1                                                     as state,
       country_code
from geoip_url;

CREATE DICTIONARY geo_ip_trie
(
    geo_cidr_key String,
    geo_cidr     String,
    latitude     Float64,
    longitude    Float64,
    city         String,
    state        String,
    country_code String
)
    primary key geo_cidr_key
    source (
        CLICKHOUSE(
                HOST 'localhost' PORT 9000 USER 'click' TABLE 'geoip' PASSWORD 'click' DB 'dwh'
        )
        )
    layout (ip_trie)
    lifetime (3600);

-- reports

Drop view if exists report_most_popular_device;
CREATE VIEW report_most_popular_device AS
SELECT user_agent, count(user_agent)
from weblog_events e
         inner join raw_platform_db_endcustomers c
                    on e.username = c.document_number
where c.load_date = yesterday()
group by user_agent
order by count(user_agent) desc
limit 5;


Drop view if exists report_top_product_by_country;
CREATE VIEW report_top_product_by_country AS
with user_login_country as (select dictGet('dwh.geo_ip_trie', 'country_code', tuple(w.ip::IPv4)) as country_code,
                                   w.username
                            from weblog_events w
                                     inner join raw_platform_db_endcustomers c
                                                on w.username = c.document_number
                            where c.load_date = yesterday()),
     most_popular_country as (select ulc.country_code
                              from user_login_country ulc
                              group by ulc.country_code
                              order by count(*) desc
                              limit 1),
     users_of_most_popular_country as (select distinct(ulc.username) as username
                                       from user_login_country ulc
                                                inner join most_popular_country mpc on ulc.country_code = mpc.country_code)
select r.product_id,
       r.name
from raw_platform_db_orders o
         inner join raw_platform_db_orderitems i
                    on o.order_id = i.order_id
         inner join raw_platform_db_products r
                    on i.product_id = r.product_id
         inner join users_of_most_popular_country uompc
                    on o.customer_document_number = uompc.username
where 1 = 1
  and o.load_date = yesterday()
  and i.load_date = yesterday()
  and r.load_date = yesterday()
group by r.product_id, r.name
order by sum(i.quantity) desc
limit 5;


Drop view if exists report_monthly_sales;
CREATE VIEW report_monthly_sales AS
with order_montly as (select o.order_id,
                             extract(MONTH FROM o.order_date) as month
                      from dwh.raw_platform_db_orders o
                      where 1 = 1
                        and o.load_date = yesterday()
                        and o.order_date >= subtractYears(yesterday(), 1))
SELECT m.month, sum(i.price) as result
from order_montly m
         inner join raw_platform_db_orderitems i
                    on m.order_id = i.order_id
where 1 = 1
  and i.load_date = yesterday()
group by m.month
order by month asc;
