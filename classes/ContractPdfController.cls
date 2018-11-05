public class ContractPdfController {

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
    
    public String Ptype {get;set;}
    public String kind;                    
                 
     public  ContractPdfController(){
        String id =ApexPages.currentPage().getParameters().get('id');
        //test
        //id='a0A0k000007suQ4EAI';//リースID

        //初期値の設定
        ProductKaitoriTax = 0;
        otherPage=18;
        firstPage = 10;

   		//個別請求リース
    	getBilledByAgreementId(id);
     }
  
    /**
     * 個別請求取得
     * Param agreementId 契約番号
     */
    public  void getBilledByAgreementId(String agreementId){
        String querySubCondition =' Where Agreement__c = \'' + agreementId + '\'' ;
        String queryCondition = ' And Count__c = 1' ;
        //契約から検索(初回契約)
        String sql = getContractPdfDataSql(queryCondition, querySubCondition);
        system.debug(sql);
        setPafData(sql);
    }

    private String getContractPdfDataSql(String queryCondition, String querySubCondition){
        String sql='SELECT'+
                     ' Billed__r.Name, '+ 								//請求番号
                     ' Billed__r.BilledDate__c, '+      				//請求日
                     ' Billed__r.SeikyusakiPostalCode__c,'+		//郵便番号
                     ' Billed__r.SeikyusakiAddress__c,'+				//請求先　住所
                     ' Billed__r.Account__r.Name,'+					//請求先
                     ' Billed__r.Contact_Position_Billed__c,'+		//請求先部門
                     ' Billed__r.Contact_name_Billed__c,'+			//請求先　担当
                     ' Billed__r.BilledLeaseAmountSum__c,'+		//当限請求額
                     ' Billed__r.Account__r.AzukariAmount__c,'+					//お預り金額
                     ' Billed__r.KijituDate__c,'+						//支払期日
                     ' ContractName__c,'+								//契約番号
                     ' MonthlyLeaseFee__c,'+							//リース料
                     ' HansyutuAmount__c,'+							//搬出入費等
                     ' LeaseFeeTax__c,'+								//リース料　消費税
                     ' HansyutuTax__c,'+								//搬出入費等　消費税
            		 ' Hoshokin__c,'+									//保証金
            		 ' TotalLeaseAmount2__c,'+						//合計
                     ' Count__c,'+										 //回数
                     ' LeaseEndDate__c,'+								//満了日
                     ' BilledKikanStart__c,'+							//請求対象期間(開始)(リ)
                     ' ReturnBilledKikanEnd__c,'+					//請求対象期間(終了)(リ)
                     ' Wording__c'+ 										//摘要(リ)
                     ' FROM BilledDetail__c'+
                     querySubCondition+queryCondition;
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
        	//各合計を求め
            allpageCountLease=allpageCountLease+(b.MonthlyLeaseFee__c==NULL?0:b.MonthlyLeaseFee__c);
            allpageCountMove=allpageCountMove+(b.HansyutuAmount__c==NULL?0:b.HansyutuAmount__c);
            allpageCountLeaseTax=allpageCountLeaseTax+(b.LeaseFeeTax__c==NULL?0:b.LeaseFeeTax__c);
            allpageCountMoveTax=allpageCountMoveTax+(b.HansyutuTax__c==NULL?0:b.HansyutuTax__c);
            allpageCountHosyoukin=allpageCountHosyoukin+(b.Hoshokin__c==NULL?0:b.Hoshokin__c);
            allpageCountGoukei=allpageCountGoukei+(b.TotalLeaseAmount2__c==NULL?0:b.TotalLeaseAmount2__c);
            
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