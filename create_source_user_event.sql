
create table if not exists source_user_event (
    event_time varchar(50),
    user_id varchar(50),
    event_type varchar(50),
    platform varchar(50),
    country varchar(50),
    region varchar(50),
    device_id varchar(50),
    initial_referring_domain varchar(50)
);

