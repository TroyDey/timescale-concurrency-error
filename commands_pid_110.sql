SELECT * FROM create_metric_table('blastoise1_blastoise13', 'pcm', 'FLOAT8', '1', '3600', '604800', '2592000');
CALL finalize_metric_creation('blastoise1_blastoise13', 'pcm');
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{3677~test~4FAB,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{9C68~test~B2DD,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{BFAB~test~3345,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{DD38~test~119B,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{151D~test~6FB5,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{FF70~test~61D4,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{28DC~test~5BE9,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{F7A7~test~3349,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{6054~test~ADBB,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{295D~test~B3E8,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{1601~test~295B,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{4CF9~test~F1F3,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{EA6C~test~BA7C,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{1352~test~0D94,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{4064~test~5322,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{68EA~test~9C3C,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{6F0B~test~3E53,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{DE30~test~F20B,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{E54A~test~BF45,1.0,3}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise13', ('{hostname,kernel_version,blastoise1}')::text[], ('{E74D~test~A29D,1.0,3}')::text[]);
SELECT insert_metric_row('pcm_blastoise1_blastoise13', ('{1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860}')::bigint[], ('{0.5603380836095828,0.3924656005550997,0.504855249629286,0.8876171732904936,0.6261904843590528,0.5543616995780529,0.26121297405891253,0.7491575615464232,0.26610290384473395,0.5721157177760392,0.5629885137290263,0.41092653595334905,0.8386576971790317,0.9305330126925171,0.7983700210993251,0.298738674250183,0.8683404171776783,0.9362294256226845,0.5085763440728391,0.4389705701942819}')::float8[], ('{4,9,12,17,21,25,32,38,42,52,57,61,66,70,76,81,85,90,95,98}')::int[]);
SELECT * FROM create_metric_table('blastoise1_blastoise14', 'pcm', 'FLOAT8', '1', '3600', '604800', '2592000');
CALL finalize_metric_creation('blastoise1_blastoise14', 'pcm');
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{3677~test~4FAB,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{9C68~test~B2DD,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{BFAB~test~3345,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{DD38~test~119B,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{151D~test~6FB5,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{FF70~test~61D4,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{28DC~test~5BE9,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{F7A7~test~3349,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{6054~test~ADBB,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{295D~test~B3E8,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{1601~test~295B,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{4CF9~test~F1F3,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{EA6C~test~BA7C,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{1352~test~0D94,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{4064~test~5322,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{68EA~test~9C3C,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{6F0B~test~3E53,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{DE30~test~F20B,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{E54A~test~BF45,1.0,4}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise14', ('{hostname,kernel_version,blastoise1}')::text[], ('{E74D~test~A29D,1.0,4}')::text[]);
SELECT insert_metric_row('pcm_blastoise1_blastoise14', ('{1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860}')::bigint[], ('{0.5603380836095828,0.3924656005550997,0.504855249629286,0.8876171732904936,0.6261904843590528,0.5543616995780529,0.26121297405891253,0.7491575615464232,0.26610290384473395,0.5721157177760392,0.5629885137290263,0.41092653595334905,0.8386576971790317,0.9305330126925171,0.7983700210993251,0.298738674250183,0.8683404171776783,0.9362294256226845,0.5085763440728391,0.4389705701942819}')::float8[], ('{153,159,164,171,180,183,187,192,196,198,200,202,205,207,210,212,215,218,224,230}')::int[]);
SELECT * FROM create_metric_table('blastoise1_blastoise15', 'pcm', 'FLOAT8', '1', '3600', '604800', '2592000');
CALL finalize_metric_creation('blastoise1_blastoise15', 'pcm');
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{3677~test~4FAB,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{9C68~test~B2DD,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{BFAB~test~3345,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{DD38~test~119B,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{151D~test~6FB5,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{FF70~test~61D4,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{28DC~test~5BE9,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{F7A7~test~3349,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{6054~test~ADBB,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{295D~test~B3E8,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{1601~test~295B,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{4CF9~test~F1F3,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{EA6C~test~BA7C,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{1352~test~0D94,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{4064~test~5322,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{68EA~test~9C3C,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{6F0B~test~3E53,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{DE30~test~F20B,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{E54A~test~BF45,1.0,5}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise15', ('{hostname,kernel_version,blastoise1}')::text[], ('{E74D~test~A29D,1.0,5}')::text[]);
SELECT insert_metric_row('pcm_blastoise1_blastoise15', ('{1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860}')::bigint[], ('{0.5603380836095828,0.3924656005550997,0.504855249629286,0.8876171732904936,0.6261904843590528,0.5543616995780529,0.26121297405891253,0.7491575615464232,0.26610290384473395,0.5721157177760392,0.5629885137290263,0.41092653595334905,0.8386576971790317,0.9305330126925171,0.7983700210993251,0.298738674250183,0.8683404171776783,0.9362294256226845,0.5085763440728391,0.4389705701942819}')::float8[], ('{282,288,291,296,303,305,306,308,311,314,319,325,330,335,341,345,350,352,357,361}')::int[]);
SELECT * FROM create_metric_table('blastoise1_blastoise16', 'pcm', 'FLOAT8', '1', '3600', '604800', '2592000');
CALL finalize_metric_creation('blastoise1_blastoise16', 'pcm');
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{3677~test~4FAB,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{9C68~test~B2DD,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{BFAB~test~3345,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{DD38~test~119B,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{151D~test~6FB5,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{FF70~test~61D4,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{28DC~test~5BE9,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{F7A7~test~3349,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{6054~test~ADBB,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{295D~test~B3E8,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{1601~test~295B,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{4CF9~test~F1F3,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{EA6C~test~BA7C,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{1352~test~0D94,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{4064~test~5322,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{68EA~test~9C3C,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{6F0B~test~3E53,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{DE30~test~F20B,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{E54A~test~BF45,1.0,6}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise16', ('{hostname,kernel_version,blastoise1}')::text[], ('{E74D~test~A29D,1.0,6}')::text[]);
SELECT insert_metric_row('pcm_blastoise1_blastoise16', ('{1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860}')::bigint[], ('{0.5603380836095828,0.3924656005550997,0.504855249629286,0.8876171732904936,0.6261904843590528,0.5543616995780529,0.26121297405891253,0.7491575615464232,0.26610290384473395,0.5721157177760392,0.5629885137290263,0.41092653595334905,0.8386576971790317,0.9305330126925171,0.7983700210993251,0.298738674250183,0.8683404171776783,0.9362294256226845,0.5085763440728391,0.4389705701942819}')::float8[], ('{391,395,403,407,412,417,422,427,429,433,436,441,445,449,452,456,459,462,465,468}')::int[]);
SELECT * FROM create_metric_table('blastoise1_blastoise10', 'pcm', 'FLOAT8', '1', '3600', '604800', '2592000');
CALL finalize_metric_creation('blastoise1_blastoise10', 'pcm');
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{3677~test~4FAB,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{9C68~test~B2DD,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{BFAB~test~3345,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{DD38~test~119B,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{151D~test~6FB5,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{FF70~test~61D4,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{28DC~test~5BE9,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{F7A7~test~3349,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{6054~test~ADBB,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{295D~test~B3E8,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{1601~test~295B,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{4CF9~test~F1F3,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{EA6C~test~BA7C,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{1352~test~0D94,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{4064~test~5322,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{68EA~test~9C3C,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{6F0B~test~3E53,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{DE30~test~F20B,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{E54A~test~BF45,1.0,0}')::text[]);
SELECT * FROM get_or_create_series_id_for_kv_array('pcm', 'blastoise1_blastoise10', ('{hostname,kernel_version,blastoise1}')::text[], ('{E74D~test~A29D,1.0,0}')::text[]);
SELECT insert_metric_row('pcm_blastoise1_blastoise10', ('{1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860,1662472860}')::bigint[], ('{0.5603380836095828,0.3924656005550997,0.504855249629286,0.8876171732904936,0.6261904843590528,0.5543616995780529,0.26121297405891253,0.7491575615464232,0.26610290384473395,0.5721157177760392,0.5629885137290263,0.41092653595334905,0.8386576971790317,0.9305330126925171,0.7983700210993251,0.298738674250183,0.8683404171776783,0.9362294256226845,0.5085763440728391,0.4389705701942819}')::float8[], ('{481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500}')::int[]);
