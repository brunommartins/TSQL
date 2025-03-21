--sp_WhoIsActive

exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @get_plans =1, @get_locks = 1

exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @show_sleeping_spids = 2, @get_plans =1, @get_locks = 1

exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @show_sleeping_spids = 2, @filter ='dbname', @filter_type = 'database'

exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @show_sleeping_spids = 2, @filter ='host', @filter_type = 'xxx'

exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @show_sleeping_spids = 2, @filter ='user', @filter_type = 'login'

exec master.dbo.sp_WhoIsActive  @sort_order= '[session_id] ASC', @show_sleeping_spids = 2, @filter ='127', @filter_type = 'session'
