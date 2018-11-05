public class ContractSalesPdfController {
//一ページ目の行数
    private  Integer firstPage;
	//その他ページの行数
    private  Integer otherPage;

    public List<List<BilledDetail__c>> PageList {get;set;}

	public List<InventoryOpportunityProduct__c> inven {get;set;}
	public Agreement__c agree {get;set;}
	public List<String> Feelist {get;set;}
	
    public Decimal allpageCountLease {get;set;}
    public Decimal allpageCountMove {get;set;}
    public Decimal allpageCountLeaseTax {get;set;}
    public Decimal allpageCountMoveTax {get;set;}
    public Decimal allpageCountHosyoukin {get;set;}
    public Decimal allpageCountGoukei {get;set;}
    public Decimal ProductKaitoriTax {get;set;}     
    
    public String financialName {get;set;}
    public String financialbranch {get;set;}
    public String financialENGName {get;set;}
    public String financialENGbranch {get;set;}
    public String bankaccounttype {get;set;}
    public String bankaccountNumber {get;set;}
    public String bankaccountNominee {get;set;}
    public String bankaccountENGNominee {get;set;}
                     
               
    public  ContractSalesPdfController(){
        String id =ApexPages.currentPage().getParameters().get('id');
        //system.debug('Ptype:'+Ptype);
        //test
        //Ptype ='ダメージ料金請求';
        //id='a0A0k000007zhPrEAI';

        //初期値の設定
        ProductKaitoriTax = 0;
        otherPage=18;
        firstPage = 10;

	   	//販売
        createInvoiceSales(id);
     }
     
     /**
     * 販売の帳票を出力
     * Param billedDate 請求日
     */
     public void createInvoiceSales(String id){
     	Feelist = new List<String>();
     	agree=[SELECT id,Estimate__r.Name,HoshokinSousai__c FROM Agreement__c WHERE id=:id];
     	String querySubCondition =' Where Agreement__c = \'' + id + '\'';
     	String queryCondition ='';

        inven =[SELECT id
						,OpportunityProduct__r.Name   //在庫案件商品名
						,UnitPriceLease__c//計算価値価格
					 FROM InventoryOpportunityProduct__c 
					 WHERE Agreement__c=:id 
					 AND ProductFlag__c=false
					 ];
		for(Integer i=1;i<16-inven.size();i++){
			Feelist.add('￥0');
		}
		otherPage = 42;
		firstPage=0;        
		queryCondition = ' And InventoryOpportunityProduct__r.ProductFlag__c = true ';
	     
	     //検索文の作成
	     String sql = getContractSalesPdfDataSql(queryCondition, querySubCondition);
	     system.debug(sql);
	     setPafData(sql);   
     }
     private String getContractSalesPdfDataSql(String queryCondition, String querySubCondition){
        String sql='SELECT'+
                     ' ProductsDaikin__c, '+ //商品代金(販)
                     ' ProductsTax__c, '+ //消費税(販)
                     ' BilledSales__c, '+ //請求金額（販）
                     ' ProductName__c , '+ //商品名（販）
                     ' MakerName__c, '+ //メーカー名（販）
                     ' Kataban__c, '+ //型番（販）
                     ' ManageNo__c, '+ //管理番号（販）
                     ' AmountPercent__c, '+ //定価(販)
                     ' SellingPrice__c, '+  //販売価格(販)

                     ' Agreement__r.Estimate__r.TAX__c, '+  //消費税率
                     ' Agreement__r.Estimate__r.AmountLeaseSum__c, '+  //計算価値価格(集計)
                     ' Agreement__r.Estimate__r.PaymentAmountSumTax__c , '+  //お支払総額消費税
                     
                     ' Billed__r.agrement__r.ProductKaitoriAmnout__c, '+  //買取商品金額(集計)
                     
                     ' Billed__r.agrement__r.HoshokinSousai__c, ' + //保証金との相殺
                     ' Billed__r.agrement__r.OverPaymentAmount__c, ' + //(保証金返金)過入金
                     ' Billed__r.agrement__r.Hoshokin__c, ' + //保証金
                     ' Billed__r.agrement__r.damageMoney__c, ' + //(保証金返金)ダメージ料金
					 ' Billed__r.agrement__r.DeliveryFee__c, '+//(保証金返金)個別送料
					 ' Billed__r.agrement__r.OthersFee__c, '+//(保証金返金)その他料金
					 ' Billed__r.agrement__r.FusokuAmount__c, '+//(保証金返金)差引
					 ' Billed__r.agrement__r.InvoiceTaxFee__c, '+//買取商品金額(集計)
                     
                     ' Billed__r.Name, '+                           //請求番号
                     ' Billed__r.SeikyusakiPostalCode__c,'+		    //郵便番号
                     ' Billed__r.SeikyusakiAddress__c,'+			//請求先　住所
                     ' Billed__r.Account__r.Name,'+					//請求先
                     ' Billed__r.Contact_Position_Billed__c,'+		//請求先部門
                     ' Billed__r.KijituDate__c'+					//支払期日
                     ' FROM BilledDetail__c'+
                     querySubCondition + queryCondition 
                     + 'ORDER BY InventoryOpportunityProduct__r.OpportunityProduct__r.LocationNo__c NULLS LAST, '
                     + 'InventoryOpportunityProduct__r.OpportunityProduct__r.InstallationLocation__c NULLS LAST,'
                     + 'InventoryOpportunityProduct__r.OpportunityProduct__r.SortNo__c NULLS LAST ,InventoryOpportunityProduct__r.CreatedDate';
		   system.debug(sql);
           return sql;
    }
    
    public void setPafData(String sql){
        List<BilledDetail__c> billedDetail =Database.query(sql);
        system.debug(billedDetail);
        //一ページ表示される行数
        Integer rows =1;
        PageList=new List<List<BilledDetail__c>>();
        List<BilledDetail__c> newBill= new  List<BilledDetail__c>();
        PageList.add(newBill);
		allpageCountLease=0;
      	allpageCountMove=0;
      	allpageCountLeaseTax=0;
      	allpageCountMoveTax =0;
      	allpageCountHosyoukin =0;
      	allpageCountGoukei=0;

        for(BilledDetail__c b:billedDetail){
            if((rows-firstPage)==1){
            	//①一ページ目が満たす場合、改ページ
                List<BilledDetail__c> Page= new  List<BilledDetail__c>();
                PageList.add(Page);
            }else if(rows>firstPage && Math.mod(rows-firstPage,otherPage)==1){
            	//①一ページ以外が満たす場合、改ページ
            	List<BilledDetail__c> Page= new  List<BilledDetail__c>();
                PageList.add(Page);
            }
            ((List<BilledDetail__c>)PageList[PageList.size()-1]).add(b);
            rows+=1;
        }
		//販売の場合
		if (billedDetail.size() > 0) {
		    PageList[0].add(billedDetail[0]);
		}

        //sizeの10のlist、不足のは空いた対象を充填
        Integer cont=1;
        Integer pageCont=firstPage;
        for (List<BilledDetail__c> Page:PageList) {
				if(cont!=1){
					pageCont=otherPage;
				}
				for(Integer i=Page.size();i<pageCont;i++){
						Page.add(new BilledDetail__c());
				}
				cont+=1;
        }

        //自社口座などをセット
        Account ac=CommonUntil.getOwnerAccount();
		//金融機関名(仕向銀行名)
        financialName=ac.Financial_Name__c;
        //金融機関支店名(仕向店名)
        financialbranch=ac.Financial_branch__c;
        //金融機関名英語
        financialENGName=ac.Financial_Name_English__c;
        //金融機関支店名英語
        financialENGbranch=ac.Financial_branch_English__c;
        //口座種類区分
        bankaccounttype=ac.Bank_account_type__c;
        //口座番号
        bankaccountNumber=ac.Bank_account_Number__c;
        //口座名義人(振込依頼人名)
		bankaccountNominee=ac.Bank_account_Nominee__c;       
		// 口座名義人英語(振込依頼人名)
        bankaccountENGNominee=ac.Bank_account_Nominee_English__c;
        system.debug(sql);
        system.debug(PageList);
        
    }

}