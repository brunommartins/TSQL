Create table A(
    [id] int, 
    value nvarchar(50), 
    CHECK (value = 'A'),
    PRIMARY KEY (ID, value))

Create table B(
    [id] int, 
    value nvarchar(50), 
    CHECK (value = 'B'),
    PRIMARY KEY (ID, value))



    create View V as (select id, value from A) UNION ALL (select id, value from B)


    select * from V

    select * from A
    select * from B


    insert into v (id, value) select 2,'B' 



   
