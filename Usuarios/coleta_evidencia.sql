 
select @@servername as ServerName, t1.UserLogin,t2.createdate,t1.lastpassword_resetTime from
(select 'username' as UserLogin, LOGINPROPERTY('username','PasswordLastSetTime') as lastPassword_ResetTime) t1
inner join sys.syslogins t2 on t1.UserLogin = t2.Loginname
