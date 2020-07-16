### Python Env Setup

```
$ python3 -m venv venv
$ source venv/bin/activate
$ pip install psycopg2
$ pip freeze > requirements.txt
```

### Runtime Instructions
```
$ psql -h host -U username -d myDataBase -a -f create_source_user_event.sql
$ python3 insert_source_user_event.py
$ psql -h host -U username -d myDataBase -a -f create_load_dim_user_event.sql
$ psql -h host -U username -d myDataBase -a -f create_load_fact_user_day.sql
```

### Considersations
1. Envisioning the import file could at some point become very large, I chose to use Python for this step and to write only one row at a time. This job should never fail due to the file being too large.
2. I chose to include timestamps instead of True/False in fact\_user_day so velocity could be calculated from the same source table.
3. Some prior milestones/page navigations are null. These are excluded from the denominator when calculating conversion because the conversion/success is not a function of the prior page. For example if a customer navigated directly to a store page without first navigating to the home page, they were excluded from home_page to store_page conversion.

### Data Model
1. dim\_user_event - stores all user events and all source fields. Updates varchar timestamp field to date and datetime fields for querying convenience.
2. fact\_user\_day - one record per user per day the user had an event. Event types are pivoted into columns populated with timestamps of the first occurance of the given event on that date.
3. rpt\_funnel\_summary\_day and rpt\_funnel\_summary\_day\_search_comp both leverage fact\_user\_day to aggregate and summarize funnel KPIs.
4. rpt\_search\_comp builds upon rpt\_funnel\_summary\_day\_search_comp to assess whether conversion is better with or without search.


### Q1
* The metrics included are:
   1. the count of users at the originating milestone
   2. the count of those users to convert to the next milestone
   3. the conversion rate
   4. the average time in minutes it took for the converted users get from the first milestone to the next
* The summary table is `rpt_funnel_summary_day`

### Q2
* I added the additional column `search_flag` to segment the users into users who used `search` vs. ones who did not (I.e. `no_search`). Using this field you could see that users who did use search convert at a higher rate at all funnel stages.
* I addressed search by identifying customers who had an event_type of 'search\_event' on a given day.
* The summary table is `rpt_funnel_summary_day_search_comp`
* The table comparing the search vs no search is `rpt_search_comp`

### Conversion improvements from search
1. home\_page --> store_page: 12-30%
2. store_page --> checkout: 36-102%
3. checkout --> checkout_success: 6-13%

### QA Methodology
Distinct user counts and event records were counted along the way to ensure joins were correct. Example `select count(distinct user_id) from source_user_event;`

### Recommendation
It makes sense to segment search from non-search when assessing funnel performance. Customers who search have a stronger intent to buy in the moment. If they're searching, it's an indicator that they want something (probably something specific).

Customers who don't search can be further segmented. They might be navigating to a specific store, indicating that they're returning customers and they know exactly what they want. In that case the home\_page to store\_page conversion didn't influence their purchase but not converting from checkout\_page to check\_out\_success could be an indicator of a bug or unoptimized UX.

Customers who don't search might just be window shoping. As a result they need more to be pushed over the threshold to buy. In this later group it would be interesting to see if they're returning or new customers and to make the ability to search more prevelant in the display to assess if conversion can be increased. It would be worth digging deeper into this group to assess if search isn't as prominent on certain devices and the UX and CSS could be inhibiting conversion.

### Technical Next Steps
1. For future considerations I'd look at making this an incremental job and leverage unions to append existing data sets.
2. I would also have the Python script parse the header and read lines into a dictionary to ensure fields in the import file do not change.
3. Also it would make sense to have the file read in from S3 rather than my local directory. Boto3 would be a good Python library to leverage for this.
4. It would make sense for a future version of this data to assess if there's higher conversion for certain devices.
