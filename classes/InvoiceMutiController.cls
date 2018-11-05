public class InvoiceMutiController {

    //一ページ目の行数
    private  Integer firstPage;
	//その他ページの行数
    private  Integer otherPage;

    public List<List<List<BilledDetail__c>>> BigPageList {get;set;}
    public List<Billed__c> Bigbilleds{get;set;}

	public List<InventoryOpportunityProduct__c> inven {get;set;}
	public Agreement__c agree {get;set;}
	public List<String> Feelist {get;set;}
	
    public list<Decimal> allpageCountLeaselist {get;set;}
    public list<Decimal> allpageCountMovelist {get;set;}
    public list<Decimal> allpageCountLeaseTaxlist {get;set;}
    public list<Decimal> allpageCountMoveTaxlist {get;set;}
    public list<Decimal> allpageCountHosyoukinlist {get;set;}
    public list<Decimal> allpageCountGoukeilist {get;set;}
    public list<Decimal> ProductKaitoriTaxlist {get;set;}     
    
    public String financialName {get;set;}
    public String financialbranch {get;set;}
    public String financialENGName {get;set;}
    public String financialENGbranch {get;set;}
    public String bankaccounttype {get;set;}
    public String bankaccountNumber {get;set;}
    public String bankaccountNominee {get;set;}
    public String bankaccountENGNominee {get;set;}
                     
    public String monthly;
    public String year;
    public String month;
    public String PaywayValue;
    public String localValue;
    public String day;
    public String request;
    public String questionNO;
                        
     public  InvoiceMutiController(){
        //初期値の設定
        otherPage=18;
        firstPage = 10;

        String year = ApexPages.currentPage().getParameters().get('year');
        String month = ApexPages.currentPage().getParameters().get('month');
        String PaywayValue = ApexPages.currentPage().getParameters().get('PaywayValue');
        String localValue = ApexPages.currentPage().getParameters().get('localValue');
        String day = ApexPages.currentPage().getParameters().get('day');
        String request = ApexPages.currentPage().getParameters().get('request');
        String questionNO = ApexPages.currentPage().getParameters().get('questionNO');
        List<Id> BilledDetailIdList = CreateAllMultipleBilled.getAllBilledDetailIds(year,month,PaywayValue,localValue,day,request,questionNO);
        if (BilledDetailIdList.size() > 0) {
    	    getAllBilled(BilledDetailIdList);
    	}
    	return;
    	//請求明細IDS
    	//String BilledDetailIds = ApexPages.currentPage().getParameters().get('id');
    	//メイン処理
    	//getAllBilled(BilledDetailIds);
     }
     
    private void getAllBilled(List<Id> BilledDetailIdList){
        List<BilledDetail__c> billedDetailLists = [SELECT ID,NAME,Billed__c FROM BilledDetail__c WHERE Id in :BilledDetailIdList];
        Set<Id> BilledIds = new Set<Id>();
        for (BilledDetail__c BilledDetail : billedDetailLists) {
            if (!BilledIds.contains(BilledDetail.Billed__c)) {
                BilledIds.add(BilledDetail.Billed__c);
            }
        }
        //画面データを設定
        setPafMutilData(getDetailData(BilledDetailIdList,BilledIds));
    }
    
    //請求、請求明細データを取得
	private List<Billed__c> getDetailData(List<String> BilledDetailList, Set<Id> BilledIds){
        return [SELECT Name,BilledDate__c,SeikyusakiPostalCode__c,SeikyusakiAddress__c,
                       Account__r.Name,Contact_Position_Billed__c,Contact_name_Billed__c,BilledLeaseAmountSum__c,
                       Account__r.AzukariAmount__c,KijituDate__c,
                       (SELECT ContractName__c,MonthlyLeaseFee__c,HansyutuAmount__c,LeaseFeeTax__c,HansyutuTax__c,
                               Hoshokin__c,TotalLeaseAmount2__c,Count__c,LeaseEndDate__c,BilledKikanStart__c,
                               ReturnBilledKikanEnd__c,Wording__c
                        FROM ClaimBilled__r
                        WHERE Id in :BilledDetailList)
                FROM Billed__c
                WHERE Id in :BilledIds
               ];
    }
	
	public void setPafMutilData(List<Billed__c> detailData){
		system.debug(detailData);
	 	Bigbilleds= new List<Billed__c>();
		Bigbilleds = detailData;
		allpageCountLeaselist =new  list<Decimal>();
		allpageCountMovelist =new  list<Decimal>();
		allpageCountLeaseTaxlist =new  list<Decimal>();
		allpageCountMoveTaxlist =new  list<Decimal>();
		allpageCountHosyoukinlist =new  list<Decimal>();
		allpageCountGoukeilist =new  list<Decimal>();
		BigPageList =new List<List<List<BilledDetail__c>>>();
      	//請求毎にループする
		for(Billed__c bill:Bigbilleds){
			//一ページ表示される行数
        	Integer rows =1;
        	//一PageListは一請求
        	List<List<BilledDetail__c>> PageList=new List<List<BilledDetail__c>>();
			List<BilledDetail__c> newBill= new  List<BilledDetail__c>();
        	PageList.add(newBill);
			Decimal allpageCountLease=0;
      		Decimal allpageCountMove=0;
      		Decimal allpageCountLeaseTax=0;
      		Decimal allpageCountMoveTax =0;
      		Decimal allpageCountHosyoukin =0;
      		Decimal allpageCountGoukei=0;
			for(BilledDetail__c b:bill.ClaimBilled__r){
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
			system.debug(allpageCountLease);
			allpageCountLeaselist.add(allpageCountLease);
			allpageCountMovelist.add(allpageCountMove);
			allpageCountLeaseTaxlist.add(allpageCountLeaseTax);
			allpageCountMoveTaxlist.add(allpageCountMoveTax);
			allpageCountHosyoukinlist.add(allpageCountHosyoukin);
			allpageCountGoukeilist.add(allpageCountGoukei);
			BigPageList.add(PageList);
		}
		//sizeの10のlist、不足のは空いた対象を充填
		for(List<List<BilledDetail__c>> PageList:BigPageList){
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
	
	
		system.debug(BigPageList);
	 }
		

}