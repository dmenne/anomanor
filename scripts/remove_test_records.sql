PRAGMA foreign_keys = 1;
DELETE FROM classification WHERE record in
     ('500613_ib', '000278_ib', '402865_ib', '404485_ib', '412011_ib');
DELETE FROM user where [group] = 'admins';
