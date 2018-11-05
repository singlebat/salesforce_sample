public class ContractHosyoukinPDfController {
//一ページ目の行数
    private  Integer firstPage;
	//その他ページの行数
    private  Integer otherPage;

    public List<List<BilledDetail__c>> PageList {get;set;}
	public Billed__c billeds {get;set;}
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
               
    public  ContractHosyoukinPDfController(){
        String id =ApexPages.currentPage().getParameters().get('id');

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
     	 String querySubCondition =' Where agrement__c = \'' + id + '\' AND  Type__c=\'保証金返金\' ORDER BY createdDate desc';
     	 String queryCondition ='';
	    
 		 Integer zeroRow=0;
 	     if(agree.HoshokinSousai__c=='希望しない'){
 	    	zeroRow=13;
 	     }else{
 	    	zeroRow=11;
 	     }
		 for(Integer i=1;i<zeroRow;i++){
			Feelist.add('￥0');
		 }
		 otherPage = 42;
		 firstPage=0;
		 system.debug('agree:'+agree);
	      
	      //検索文の作成
	      String sql = getContractSalesPdfDataSql(queryCondition, querySubCondition);
	      system.debug(sql);
	      setPafData(sql);   
     }
     private String getContractSalesPdfDataSql(String queryCondition, String querySubCondition){
        String sql='SELECT'+
                     ' (SELECT ProductsDaikin__c, '+ //商品代金(販)
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
                     ' Agreement__r.Estimate__r.PaymentAmountSumTax__c  '+  //お支払総額消費税
                     ' FROM ClaimBilled__r WHERE InventoryOpportunityProduct__r.Status__c =  \'買取\''+
                     ' ORDER BY InventoryOpportunityProduct__r.OpportunityProduct__r.LocationNo__c NULLS LAST, '+
                     ' InventoryOpportunityProduct__r.OpportunityProduct__r.InstallationLocation__c NULLS LAST,'+
                     ' InventoryOpportunityProduct__r.OpportunityProduct__r.SortNo__c NULLS LAST ,InventoryOpportunityProduct__r.CreatedDate),'+

                     ' agrement__r.ProductKaitoriAmnout__c, '+  //買取商品金額(集計)
                     ' agrement__r.HoshokinSousai__c, ' + //保証金との相殺
                     ' agrement__r.OverPaymentAmount__c, ' + //(保証金返金)過入金
                     ' agrement__r.Hoshokin__c, ' + //保証金
                     ' agrement__r.damageMoney__c, ' + //(保証金返金)ダメージ料金
					 ' agrement__r.DeliveryFee__c, '+//(保証金返金)個別送料
					 ' agrement__r.OthersFee__c, '+//(保証金返金)その他料金
					 ' agrement__r.FusokuAmount__c, '+//(保証金返金)差引
					 ' agrement__r.InvoiceTaxFee__c, '+//買取商品金額(集計)
                     
                     ' Name, '+                           //請求番号
                     ' SeikyusakiPostalCode__c,'+		    //郵便番号
                     ' SeikyusakiAddress__c,'+			//請求先　住所
                     ' Account__r.Name,'+					//請求先
                     ' Contact_Position_Billed__c,'+		//請求先部門
                     ' KijituDate__c'+					//支払期日
                     
                     ' FROM Billed__c'+
                     querySubCondition + queryCondition ;   
		   system.debug(sql);
           return sql;
    }
    
    public void setPafData(String sql){
        List<Billed__c> billedsList = Database.query(sql);
        if (billedsList.size() > 0) {
            billeds = billedsList[0];
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
            
            if (!billeds.ClaimBilled__r.isEmpty()) {
                for(BilledDetail__c b:billeds.ClaimBilled__r){
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