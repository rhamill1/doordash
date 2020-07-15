
import psycopg2
from pathlib import Path


dbSession = psycopg2.connect("dbname='' user='' password=''")
dbCursor = dbSession.cursor()

base_path = Path(__file__).parent
file_path = (base_path / './data/Business Intelligence Exercise.csv').resolve()


row_count = 0
with open(file_path, 'r') as user_events:

    for line in user_events:
        if row_count != 0:

            sline = line.strip().split(',')
            dbCursor.execute('''
                insert into source_user_event (event_time, user_id, event_type, platform, country, region, device_id, initial_referring_domain)
                values (%s, %s, %s, %s, %s, %s, %s, %s);
                ''',
                (sline[0], sline[1], sline[2], sline[3], sline[4], sline[5], sline[6], sline[7]))

        row_count += 1

dbSession.commit()
dbCursor.close()
dbSession.close()

print('insert_source_user_event.py successfully inserted {} rows.'.format(row_count))
