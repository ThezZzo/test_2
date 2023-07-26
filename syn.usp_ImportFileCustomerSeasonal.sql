create procedure syn.usp_ImportFileCustomerSeasonal
	@ID_Record int
as
set nocount on
begin
	declare @RowCount int = (select count(*) from syn.SA_CustomerSeasonal)
	declare @ErrorMessage varchar(max)

-- �������� �� ������������ ��������
	if not exists (
	select 1
	from syn.ImportFile as f
	where f.ID = @ID_Record
		and f.FlagLoaded = cast(1 as bit)
	)
		begin
			set @ErrorMessage = '������ ��� �������� �����, ��������� ������������ ������'

			raiserror(@ErrorMessage, 3, 1)
			return
		end

	CREATE TABLE #ProcessedRows (
		ActionType varchar(255),
		ID int
	)
	
	--������ �� ���� ��������� ������
	select
		cc.ID as ID_dbo_Customer
		,cst.ID as ID_CustomerSystemType
		,s.ID as ID_Season
		,cast(cs.DateBegin as date) as DateBegin
		,cast(cs.DateEnd as date) as DateEnd
		,cd.ID as ID_dbo_CustomerDistributor
		,cast(isnull(cs.FlagActive, 0) as bit) as FlagActive
	into #CustomerSeasonal
	from syn.SA_CustomerSeasonal cs
		join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
			and cc.ID_mapping_DataSource = 1
		join dbo.Season as s on s.Name = cs.Season
		join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor
			and cd.ID_mapping_DataSource = 1
		join syn.CustomerSystemType as cst on cs.CustomerSystemType = cst.Name
	where try_cast(cs.DateBegin as date) is not null
		and try_cast(cs.DateEnd as date) is not null
		and try_cast(isnull(cs.FlagActive, 0) as bit) is not null

	-- ���������� ������������ ������
	-- ��������� �������, �� ������� ������ ��������� ������������
	select
		cs.*
		,case
			when cc.ID is null then 'UID ������� ����������� � ����������� "������"'
			when cd.ID is null then 'UID ������������� ����������� � ����������� "������"'
			when s.ID is null then '����� ����������� � ����������� "�����"'
			when cst.ID is null then '��� ������� � ����������� "��� �������"'
			when try_cast(cs.DateBegin as date) is null then '���������� ���������� ���� ������'
			when try_cast(cs.DateEnd as date) is null then '���������� ���������� ���� ������'
			when try_cast(isnull(cs.FlagActive, 0) as bit) is null then '���������� ���������� ����������'
		end as Reason
	into #BadInsertedRows
	from syn.SA_CustomerSeasonal as cs
	left join dbo.Customer as cc on cc.UID_DS = cs.UID_DS_Customer
		and cc.ID_mapping_DataSource = 1
	left join dbo.Customer as cd on cd.UID_DS = cs.UID_DS_CustomerDistributor and cd.ID_mapping_DataSource = 1
	left join dbo.Season as s on s.Name = cs.Season
	left join syn.CustomerSystemType as cst on cst.Name = cs.CustomerSystemType
	where cc.ID is null
		or cd.ID is null
		or s.ID is null
		or cst.ID is null
		or try_cast(cs.DateBegin as date) is null
		or try_cast(cs.DateEnd as date) is null
		or try_cast(isnull(cs.FlagActive, 0) as bit) is null
		
end
