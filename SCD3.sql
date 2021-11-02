/*
SCD3 : This slowly changing dimension model is used to maintain the history to the last version of data only
*/


if exists (select 1 from sys.tables where name = 'Source_SCD' )
begin
	drop table Source_SCD;
end
go

if exists (select 1 from sys.tables where name = 'Target_SCD3')
begin
	drop table Target_SCD3;
end
go

/* Create Source Table */

Create Table Source_SCD
(
	Id int primary key,
	[Value] varchar(50)
);


Create Table Target_SCD3
(
	Id int primary key,
	[CurrentValue] varchar(50), /* Stores the current version of data */
	[PreviousValue] varchar(50), /* Stores the previous version of data */
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

/* Target_SCD3 load */
/*
if Id is new, then the record will be inserted, [PreviousValue] column will have null [Value] 
indicating that its a new record, and there is no prior version of the data.

For the same Id, if there is a change in [Value], then 
[PreviousValue] will have the [CurrentValue] [Value] and
[CurrentValue] will have the [Value] [Value] from source.

For the same Id,  if there is no change between [Value] [Value] from Source
to [CurrentValue] in Target, then the record will be ignored.

*/

Merge Target_SCD3 tgt
using source_SCD src
	on tgt.Id = src.Id
when matched 
and (tgt.[CurrentValue] <> src.[Value])
then update 
set
	tgt.[PreviousValue] = tgt.[CurrentValue],
	tgt.[CurrentValue] = src.[Value],
	tgt.UpdatedDate = getdate()
when not matched 
then
insert
(
Id,
[CurrentValue],
[PreviousValue],
CreatedDate,
UpdatedDate
)
Values
(
	src.Id,
	src.[Value],
	NULL,
	getdate(),
	getdate()
);

select * from source_scd;
select * from target_scd3
go

waitfor delay '00:00:05'
go
/* Execution 2 */

insert into Source_SCD Values (4,'Germany');

Update Source_SCD set [Value] = 'USA' where Id = 2; /* Updating the value for SCD */
Update Source_SCD set [Value] = 'UK' where Id = 3; /* Updating the value for SCD */

Merge Target_SCD3 tgt
using source_SCD src
	on tgt.Id = src.Id
when matched 
and (tgt.[CurrentValue] <> src.[Value])
then update 
set
	tgt.[PreviousValue] = tgt.[CurrentValue],
	tgt.[CurrentValue] = src.[Value],
	tgt.UpdatedDate = getdate()
when not matched 
then
insert
(
Id,
[CurrentValue],
[PreviousValue],
CreatedDate,
UpdatedDate
)
Values
(
	src.Id,
	src.[Value],
	NULL,
	getdate(),
	getdate()
);

select * 
from source_SCD;
select * from target_scd3;