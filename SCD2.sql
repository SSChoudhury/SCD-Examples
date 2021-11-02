/*
SCD2 : This slowly changing dimension model is used to maintain history of data.
There will be 2 date/timestamp columns which denote the timeframe between which the data was active.
StartDateTime : Denotes from when the record is active
EndDateTime : If the record is active then the value will a high date like 2099-12-31 23:59:59
				For an inactive record the endtime will be the timestamp when the ETL job was executed

Note : If the source has columns which denotes the start and endtime of the record, the that also can be used.
*/


if exists (select 1 from sys.tables where name = 'Source_SCD' )
begin
	drop table Source_SCD;
end
go

if exists (select 1 from sys.tables where name = 'Target_SCD2')
begin
	drop table Target_SCD2;
end
go

/* Create Source Table */

Create Table Source_SCD
(
	Id int primary key,
	[Value] varchar(50)
);


Create Table Target_SCD2
(
	SCD2Id int primary key identity(1,1),
	Id int,
	[Value] varchar(50), 
	StartDateTime Datetime,
	EndDateTime DateTime,
	CreatedDate datetime,
	UpdatedDate Datetime
);

/* Execution 1 */

/* Source Data */
Insert into Source_SCD(Id , [Value])
Values
(1, 'India'),
(2,'United States Of America'),
(3, 'United Kingdom');

/* Target_SCD2 load */
/*
if Id is new, then the record will be inserted, 

For an existing record, if the value is different between source and the target active record, 
then 2 steps will be executed
1. Update the endtime for the active record hence marking it as inactive
2. Insert the record from source as active record
*/

/* Execution 1 */
insert into Target_SCD2(
Id,
[Value],
StartDateTime,
	EndDateTime,
	CreatedDate,
	UpdatedDate
)
select 
Id,
[Value],
StartDateTime,
	EndDateTime,
	CreatedDate,
	UpdatedDate
from (
Merge Target_SCD2 tgt
using 
(select Id, [value],
getdate() as DateTimeValue,
	cast('2099-12-31 23:59:59' as datetime) as EndDateTime
	from source_SCD 
) as src
	on tgt.Id = src.Id
when matched 
and (
tgt.EndDateTime = src.EndDateTime and
tgt.[Value] <> src.[Value])
then update 
set
	tgt.UpdatedDate = src.DateTimeValue,
	tgt.EndDateTime = src.DateTimeValue
when not matched 
then
insert
(
Id,
[Value],
StartDateTime ,
EndDateTime ,
CreatedDate ,
UpdatedDate 
)
Values
(
	src.Id,
	src.[Value],
	src.DateTimeValue,
	src.Enddatetime,
	src.DateTimeValue,
	src.DateTimeValue
)
output $action,
src.Id,
src.[value],
src.DateTimeValue as StartDateTime,
src.EndDatetime,
src.DateTimeValue as CreatedDate,
src.DateTimeValue as UpdatedDate
) 
as changes
(
	action,
	Id,
	[Value],
	StartDateTime,
	EndDateTime,
	CreatedDate,
	UpdatedDate
)
where action = 'UPDATE'
;
select * from source_scd;
select * from Target_SCD2
go

waitfor delay '00:00:05'

/* Execution 2*/

insert into Source_SCD Values (4,'Germany');

Update Source_SCD set [Value] = 'USA' where Id = 2; /* Updating the value for SCD2 */
Update Source_SCD set [Value] = 'UK' where Id = 3; /* Updating the value for SCD2 */

insert into Target_SCD2(
Id,
[Value],
StartDateTime,
	EndDateTime,
	CreatedDate,
	UpdatedDate
)
select 
Id,
[Value],
StartDateTime,
	EndDateTime,
	CreatedDate,
	UpdatedDate
from (
Merge Target_SCD2 tgt
using 
(select Id, [value],
getdate() as DateTimeValue,
	cast('2099-12-31 23:59:59' as datetime) as EndDateTime
	from source_SCD 
) as src
	on tgt.Id = src.Id
when matched 
and (
tgt.EndDateTime = src.EndDateTime and
tgt.[Value] <> src.[Value])
then update 
set
	tgt.UpdatedDate = src.DateTimeValue,
	tgt.EndDateTime = src.DateTimeValue
when not matched 
then
insert
(
Id,
[Value],
StartDateTime ,
EndDateTime ,
CreatedDate ,
UpdatedDate 
)
Values
(
	src.Id,
	src.[Value],
	src.DateTimeValue,
	src.Enddatetime,
	src.DateTimeValue,
	src.DateTimeValue
)
output $action,
src.Id,
src.[value],
dateadd(second, 1 , src.DateTimeValue) as StartDateTime,
src.EndDatetime,
src.DateTimeValue as CreatedDate,
src.DateTimeValue as UpdatedDate
) 
as changes
(
	action,
	Id,
	[Value],
	StartDateTime,
	EndDateTime,
	CreatedDate,
	UpdatedDate
)
where action = 'UPDATE'
;
select * from source_scd;
select * from Target_SCD2
order by id, enddatetime desc
go




