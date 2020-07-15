
drop table if exists dim_user_event;


create table if not exists dim_user_event as

    select
        to_timestamp(event_time, 'YYYY-MM-DD HH24:MI:SS') as event_timestamp,
        to_date(left(event_time, 10), 'YYYY-MM-DD') as event_date,
        user_id,
        event_type,
        platform,
        country,
        region,
        device_id,
        initial_referring_domain

    from source_user_event;


alter table dim_user_event add column user_event_id serial primary key;
