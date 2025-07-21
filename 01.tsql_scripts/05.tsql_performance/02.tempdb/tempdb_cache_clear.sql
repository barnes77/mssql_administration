--Clearing SystemCache with checkpoint - USE WITH CAUTION
CHECKPOINT;
GO
--free procedure cache (can affect next few times running ad-hoc queries and stored procedures)
DBCC FREEPROCCACHE;
GO
--flush cash indexes and data pages
DBCC DROPCLEANBUFFERS;
GO
-- free other caches
DBCC FREESYSTEMCACHE ('ALL');
GO
--flush distributed query connection cache
DBCC FREESESSIONCACHE;
GO
