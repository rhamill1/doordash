
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




create table fact_user_day_search as

    select distinct
        event_date,
        user_id

    from dim_user_event
    where event_type = 'search_event';




create table rpt_funnel_summary_day_search_comp as

    select
        f.event_date,
        case when s.user_id is null then 'no_search' else 'search' end as search_flag,
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

    from fact_user_day f
    left join fact_user_day_search s on s.event_date = f.event_date and s.user_id = f.user_id

    group by 1, 2
    order by 1, 2;




create table rpt_search_comp as

    select
        s.event_date,
        s.hp_to_sp_conversion as search_hp_to_sp,
        n.hp_to_sp_conversion as no_search_hp_to_sp,
        round((s.hp_to_sp_conversion - n.hp_to_sp_conversion) /
        n.hp_to_sp_conversion, 3) as improvement_from_search_hp_to_sp,

        s.sp_to_co_conversion as search_sp_to_co,
        n.sp_to_co_conversion as no_search_sp_to_co,
        round((s.sp_to_co_conversion - n.sp_to_co_conversion) /
        n.sp_to_co_conversion, 3) as improvement_from_search_sp_to_co,

        s.co_to_cos_conversion as search_co_to_cos,
        n.co_to_cos_conversion as no_search_co_to_cos,
        round((s.co_to_cos_conversion - n.co_to_cos_conversion) /
        n.co_to_cos_conversion, 3) as improvement_from_search_co_to_cos

    from rpt_funnel_summary_day_search_comp s
    join rpt_funnel_summary_day_search_comp n on n.event_date = s.event_date
    where s.search_flag = 'search' and n.search_flag = 'no_search';
