public class hosyoukinController {
  
    public Agreement__c agreement {get;set;}
    public String financialName {get;set;}
    public String financialbranch {get;set;}


    public hosyoukinController() {
    	String agreementId=ApexPages.currentPage().getParameters().get('id');
        system.debug('messageid: '+agreementId);
        getAgreement(agreementId);
        //test
        //getagreement('a0A0k00000701KREAY');
    }

      public void getagreement(String agreementId){
        agreement=[SELECT 
		              		Estimate__r.Account__c,//契約先(担当者名)
		              		Estimate__r.Opportunity__r.Account.Contact_Position__c,//取引先名
		                  	Estimate__r.Opportunity__r.Account.Contact_name__c,//所有者
		                  	Owner.Name,//担当者
		                  	UserNew__c,//使用者
		                  	Hoshokin__c,//保証金
		                  	Name,//お問合せNo.
		                  	TotalFee__c,//差引
		                  	HenkinAmount__c,//返金
		                  	OverPaymentAmount__c,//過入金返金 
		                  	HoshokinSousai__c, //保証金との相殺
		                  	LeaseStart__c,//リース開始日
		                  	LeaseEnd__c,//リース終了日
		                  	ReturnHoshokinDate__c,//返金日
		                  	Financial_Name__c,//(保証金返金)金融機関名(仕向銀行名)
		                  	Financial_branch__c,//(保証金返金)金融機関支店名(仕向店名)
		                  	Bank_account_type3__c,//(保証金返金)口座種類区分
		                  	Bank_account_Nominee__c,//(保証金返金)口座名義人(振込依頼人名)
		                  	Bank_account_Number__c//(保証金返金)口座番号                                     
                  FROM Agreement__c
                  WHERE id=:agreementId
        ];
        
        //自社口座などをセット
        Account ac=CommonUntil.getOwnerAccount();
		//金融機関名(仕向銀行名)
        financialName=ac.Financial_Name__c;
          //金融機関支店名(仕向店名)
        financialbranch=ac.Financial_branch__c;  
    }
    
}