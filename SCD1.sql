/*
SCD1 : This slowly changing dimension model is used to maintain only the current version of data.
No history is maintained in SCD1.
*/


if exists (select 1 from sys.tables where name = 'Source_SCD' )
begin
	drop table Source_SCD;
end
go

if exists (select 1 from sys.tables where name = 'Target_SCD1')
begin
	drop table Target_SCD1;
end
go

/* Create Source Table */

Create Table Source_SCD
(
	Id int primary key,
	[Value] varchar(50)
);


Create Table Target_SCD1
(
	Id int primary key,
	[Value] varchar(50), 
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

/* Target_SCD1 load */
/*
if Id is new, then the record will be inserted, 

For the same Id, if there is a change in [Value], then the value will be updated as in source. If there is 
no change then it will be ignored and no action will be performed.
*/

Merge Target_SCD1 tgt
using source_SCD src
	on tgt.Id = src.Id
when matched 
and (tgt.[Value] <> src.[Value])
then update 
set
	tgt.[Value] = src.[Value],
	tgt.UpdatedDate = getdate()
when not matched 
then
insert
(
Id,
[Value],
CreatedDate,
UpdatedDate
)
Values
(
	src.Id,
	src.[Value],
	getdate(),
	getdate()
);

select * from source_scd;
select * from target_SCD1
go

waitfor delay '00:00:05'
go
/* Execution 2 */

insert into Source_SCD Values (4,'Germany'); /* New Insert */

Update Source_SCD set [Value] = 'USA' where Id = 2; /* Updating the value for SCD1 */
Update Source_SCD set [Value] = 'UK' where Id = 3; /* Updating the value for SCD1 */

Merge Target_SCD1 tgt
using source_SCD src
	on tgt.Id = src.Id
when matched 
and (tgt.[Value] <> src.[Value])
then update 
set
	tgt.[Value] = src.[Value],
	tgt.UpdatedDate = getdate()
when not matched 
then
insert
(
Id,
[Value],
CreatedDate,
UpdatedDate
)
Values
(
	src.Id,
	src.[Value],
	getdate(),
	getdate()
);

select * 
from source_SCD;
select * from target_SCD1;