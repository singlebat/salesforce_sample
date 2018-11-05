public with sharing class KikankanryouController {
    
    public Opportunity opp {get;set;}
    public Estimate__c mitumori {get;set;}
    public String pdftype {get;set;}
    public Agreement__c   agreement {get;set;}
    public List<InventoryOpportunityProduct__c> inventory{get;set;}
    public  KikankanryouController(){
          String agreementId=ApexPages.currentPage().getParameters().get('id');
          pdftype=ApexPages.currentPage().getParameters().get('pdfType');
          system.debug('messageid: '+agreementId);
          getSyodan(agreementId);
          //test
          //pdftype='Kaiyaku';
          //getSyodan('a0A0k00000701v1EAA');
    }
   
    public void getSyodan(String id){
       
       agreement=[SELECT Name,                              // お問合せNo.
                         Contractors__c,                    //契約先
                         UserNew__c,                        //使用者
                         PropertyAddress__c,                //場所（物件名）住所
                         PropertyHomeNo__c,                 // 物件名・部屋番号
                         LeaseStart__c,                     //リース開始日
                         LeaseEnd__c,                       //リース終了日
                         MonthlyLeaseFeeTotal2__c,          //月額リース料（集計）
                         MonthlyLeaseFeeTax__c,             //月額リース料消費税
                         Hoshokin__c,                       //保証金
                         NextLeaseStart__c,                 //次回リース開始日
                         NextLeaseEnd__c,                   //次回リース終了日
                         MonthlyLeaseFeeForUpdTotal__c,     //更新後月額リース料(集計)
                         MonthlyLeaseFeeTaxForUpdTotal__c,  //更新後月額リース料消費税
                         
                         ZanzonStartDate__c,				//残存ﾘｰｽ期間開始日
						 ZanzonEndDate__c,					//残存ﾘｰｽ期間終了日
						 ZanzonLeaseAmount__c,				//残存ﾘｰｽ
						 NyukinOverAmount__c,               //入金済金額
						 NyukinKiaknStartDate__c,           //入金期間開始日
						 NyukinKiaknEndDate__c,             //入金期間終了日
						 KaiyakuDate__c,                    //解約日
						 
                         AmountPercentLeaseTotal__c,        //計算価値価格(集計)
                         UnitPriceSellForLeaseTotal__c,     //販売価格(リース)(集計)
                         (SELECT id,
                                 OpportunityProduct__r.UnitPriceLease__c,
                                 UnitPriceSellForLease__c,
                                 MonthlyLeaseFeeForUpd__c,
                                 InventoryProduct__r.Name,
                                 InventoryProduct__r.ProductName__c
                                 FROM  InventoryOpportunityProduct__r
                                 WHERE ProductFlag__c = true
                                 ORDER BY OpportunityProduct__r.LocationNo__c NULLS LAST, OpportunityProduct__r.InstallationLocation__c NULLS LAST ,
                                        SetupFeeFlag__c,OpportunityProduct__r.SortNo__c NULLS LAST ,CreatedDate)                      
                  FROM Agreement__c
                  WHERE Id=:id  
                  //WHERE id='a0A0k00000701NT'
                 ];
       
        inventory = agreement.InventoryOpportunityProduct__r;
    }
}