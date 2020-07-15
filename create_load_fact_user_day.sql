
create table stage_user_day as

    select
        event_date,
        user_id,
        event_type,
        min(event_timestamp) as min_timestamp

    from dim_user_event
    group by 1,2,3;




create table fact_user_day as

    select
        d.event_date,
        d.user_id,
        min(case when d.event_type = 'home_page' then s.min_timestamp else null end) as home_page,
        min(case when d.event_type = 'store_ordering_page' then s.min_timestamp else null end) as store_page,
        min(case when d.event_type = 'checkout_page' then s.min_timestamp else null end) as checkout_page,
        min(case when d.event_type = 'checkout_success' then s.min_timestamp else null end) as successful_checkout_page

    from dim_user_event d
    left join stage_user_day s on s.user_id = d.user_id and s.event_date = d.event_date and s.event_type = d.event_type

    where s.min_timestamp is not null
    group by 1,2;


alter table fact_user_day add column user_day_id serial primary key;




create table rpt_funnel_summary_day as

    select
        event_date,
        sum(case when home_page is not null then 1 else 0 end) as home_page_visitors,
        sum(case when home_page is not null and store_page is not null then 1 else 0 end) as store_page_visitors_from_home_page,
        round(cast(sum(case when home_page is not null and store_page is not null then 1 else 0 end) as decimal)
        / cast(sum(case when home_page is not null then 1 else 0 end) as decimal), 3) as hp_to_sp_conversion,
        round(cast(avg(date_part('minute', store_page - home_page)) as decimal), 2) as avg_velo_hp_to_sp,

        sum(case when store_page is not null then 1 else 0 end) as store_page_visitors,
        sum(case when store_page is not null and checkout_page is not null then 1 else 0 end) as checkout_page_visitors_from_store_page,
        round(cast(sum(case when store_page is not null and checkout_page is not null then 1 else 0 end) as decimal)
        / cast(sum(case when store_page is not null then 1 else 0 end) as decimal), 3) as sp_to_co_conversion,
        round(cast(avg(date_part('minute', checkout_page - store_page)) as decimal), 2) as avg_velo_sp_to_co,

        sum(case when checkout_page is not null then 1 else 0 end) as checkout_page_visitors,
        sum(case when checkout_page is not null and successful_checkout_page is not null then 1 else 0 end) as checkout_success_visitors_from_checkout_page,
        round(cast(sum(case when checkout_page is not null and successful_checkout_page is not null then 1 else 0 end) as decimal)
        / cast(sum(case when checkout_page is not null then 1 else 0 end) as decimal), 3) as co_to_cos_conversion,
        round(cast(avg(date_part('minute', successful_checkout_page - checkout_page)) as decimal), 2) as avg_velo_co_to_cos

    from fact_user_day

    group by 1
    order by 1;
