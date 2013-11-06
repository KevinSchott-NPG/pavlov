declare
@serverName nvarchar(50)
,@server int
,@status int  -- for order_status use WIP
set @server = 0
set @serverName =
case
when @server = 1
then
'eclipsestaging.eclipse_staging.dbo.sp_executesql'
when @server = 2
then
'eclipsetest.eclipse_qa.dbo.sp_executesql'
else
'eclipselive.eclipse_live.dbo.sp_executesql'
end

---- for testing outside VS ------------------------------------------------------
---- Current / Cancelled / All Orders --
--set @status = 1
--exec @serverName
--N' 
--set @orderStatus = 
--case
--@status
--when  0
--then
--',0,5,6,7,8,9,10,11,12,13,14,15,16,' -- Current Orders (Active)
--when  1
--then
--',1,2,3,4,'  -- Cancelled Orders
--else
--',0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,'  -- All Orders
--end

--select distinct
--order_status
--into #tmpOrdStatus
--from order_item
--where 
--charindex(','+cast(order_status as varchar(50))+',', @orderStatus) > 0
--'
----------------------------------------------------------------------------------

exec @serverName
N'
declare
@branding varchar(25)
,@oc nvarchar(10)
,@revenue_method nvarchar(10)
,@subscription_type varchar(25) 

--  For Testing Outside VS -----------------------
set @branding = ''Nature Publishing Group''
set @oc = 1038
set @revenue_method = 0
set @subscription_type = ''Null''
--------------------------------------------------

select 
oc.oc
,oc.description as oc_description
,vmb.branding_description as branding
,oi.customer_id, oi.orderhdr_id
,oi.order_item_seq
,oi.start_date
,oi.expire_date
,oi.order_date
,oi.bundle_qty
,oi.subscrip_id
,oi.cancel_date
,oi.cancel_reason
,a.company as agency
,oi.agent_ref_nbr
,sco.source_code
,sco.description as source_code_description
,dv_payment.short_description as payment_status
,dv_status.short_description as order_status
,sd.subscription_def
,sd.description as subscription_def_description
,sc.description as subscription_category
,p.product
,p.description as product_description
,ca_ship.title
,ca_ship.fname
,ca_ship.lname
,ca_ship.department
,ca_ship.company
,ca_ship.address1
,ca_ship.address2
,ca_ship.address3
,ca_ship.city
,ca_ship.zip
,ca_ship.state
,s_ship.country
,ca_ship.email
,ca_ship.phone
,ca_bill.title as bill_to_title
,ca_bill.fname as bill_to_fname
,ca_bill.lname as bill_to_lname
,ca_bill.department as bill_to_department
,ca_bill.company as bill_to_company
,ca_bill.address1 as bill_to_address1
,ca_bill.address2 as bill_to_address2
,ca_bill.address3 as bill_to_address3
,ca_bill.city as bill_to_city
,ca_bill.zip as bill_to_zip
,ca_bill.state as bill_to_state
,s_bill.country as bill_to_country
,ca_bill.email as bill_to_email
,ca_bill.phone as bill_to_phone
,ca_bill.tax_id_number
,pm.payment_type
,pb.pay_currency_amount
,pm.currency
,pb.base_amount

from 
order_item oi
inner join oc 
	on oi.oc_id = oc.oc_id
left outer join oc oc_parent 
	on oc.parent_oc_id = oc_parent.oc_id
left outer join oc oc_parent_jnl_grp 
	on oc_parent.parent_oc_id = oc_parent_jnl_grp.oc_id
inner join view_mcmn_branding vmb 
	on oi.oc_id = vmb.oc_id
left outer join agency a 
	on oi.agency_customer_id = a.customer_id
inner join source_code sco 
	on oi.source_code_id = sco.source_code_id
left outer join domain_value dv_payment 
	on oi.payment_status = dv_payment.domain_value
left outer join domain_value dv_status 
	on oi.order_status = dv_status.domain_value
left outer join subscription_def sd 
	on oi.subscription_def_id = sd.subscription_def_id
left outer join subscription_category sc 
	on sd.subscription_category_id = sc.subscription_category_id
left outer join product p 
	on oi.product_id = p.product_id
inner join customer_address ca_ship 
	on oi.customer_id = ca_ship.customer_id
	and oi.customer_address_seq = ca_ship.customer_address_seq
inner join state s_ship 
	on ca_ship.state = s_ship.state
inner join customer_address ca_bill 
	on oi.bill_to_customer_id = ca_bill.customer_id
	and oi.bill_to_customer_address_seq = ca_bill.customer_address_seq
inner join state s_bill 
	on ca_bill.state = s_bill.state
left outer join order_item_amt_break oiab 
	on oi.orderhdr_id = oiab.orderhdr_id
	and oi.order_item_seq = oiab.order_item_seq
left outer join paybreak pb 
	on oiab.orderhdr_id = pb.orderhdr_id
	and oiab.order_item_seq = pb.order_item_seq
	and oiab.order_item_amt_break_seq = pb.order_item_amt_break_seq
left outer join payment pm 
	on pb.customer_id = pm.customer_id
	and pb.payment_seq = pm.payment_seq
left outer join order_item_sgl_issues ois 
	on oi.orderhdr_id = ois.orderhdr_id
	and oi.order_item_seq = ois.order_item_seq
--inner join #tmpOrdStatus
--	on #tmpOrdStatus.order_status = oi.order_status

where 
dv_payment.domain_name = ''payment_status Domain''
and dv_status.domain_name = ''order_status''
and oi.order_item_type <> 4
and (
		(oi.start_date is null)
		or
		(oi.start_date <= getdate())
		)
		and (
		(oi.expire_date is null)
		or
		(oi.expire_date >= getdate())
	)
and ois.issue_id is null
and vmb.branding_description in (@branding)
and oc.oc_id in (@oc)
and oi.revenue_method in (@revenue_method)
and (sc.description is null or sc.description in (@subscription_type))
'

