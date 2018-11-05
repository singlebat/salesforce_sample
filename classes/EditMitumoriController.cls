/** 取引先詳細レコード画面において、「編集見積」クイックアクションより、見積作成コンポーネント向けのコントローラ
 */
public with sharing class EditMitumoriController {
    @AuraEnabled
	public static Estimate__c init(String estimateId){
		system.debug(estimateId);
        Estimate__c ec  = [SELECT ID,EstimatedDate__c,QuotationType__c,QuotationSalesType__c,ExpirationDate__c,LeaseTerm__c,LeaseTerm__r.Name,LeaseStart__c,MonthlyLeaseRate__c,QuotationStatus__c,
        							SyokaiLeaseMonthCnt__c,LeaseEnd__c,LeaseTerm__r.Hosyokin__c,DepositMonth__c,SubTitle__c,Opportunity__c,Remarks__c,
        							Opportunity__r.Name,Opportunity__r.CloseDate,Opportunity__r.UserNew__c,Opportunity__r.UserNew__r.Name,RecordType.Name,
        							Opportunity__r.PropertyName__c,Opportunity__r.PropertyName__r.Name,Opportunity__r.HomeNumber__c,
        							ApprovalStatus__c //承認状況
		                                       FROM Estimate__c
		                                       WHERE ID = :estimateId
		                                      ];
	    return ec;
	}	
	/** 更新
     * //更新：　　　　　　　　　　リース料率、開始日、終了日
	   //商品、在庫案件商品：リース料率
     */ 
	@AuraEnabled
	public static void updateOther(String estimateId,object MonthlyLeaseRate,String LeaseStart,String LeaseEnd){
		
        Agreement__c agreement  = [SELECT id,MonthlyLeaseRate__c
		                                       FROM Agreement__c
		                                       WHERE Estimate__c = :estimateId
		                                      ];
		
		string rate=String.valueOf(MonthlyLeaseRate); 
		system.debug(rate+'.0');
		//開始日
		agreement.LeaseStart__c=Date.valueOf(LeaseStart);
		//終了日
		agreement.LeaseEnd__c=Date.valueOf(LeaseEnd);
		//リース料率
		agreement.MonthlyLeaseRate__c=Decimal.valueOf(rate);
		update agreement;         
		string agid=agreement.id;
		system.debug(estimateId+'estimateId');
		List<OpportunityProduct__c> op  = [SELECT MonthlyLeaseRate__c,ProductFlag__c
		                                       FROM OpportunityProduct__c
		                                       WHERE Estimates__c = :estimateId
		                                      ];
	    List<OpportunityProduct__c> newop  =new List<OpportunityProduct__c>();
		//リース料率                           
		for(OpportunityProduct__c p:op){
			if(p.ProductFlag__c==true){
			p.MonthlyLeaseRate__c=Decimal.valueOf(rate);		
			}else{
			p.MonthlyLeaseRate__c=Decimal.valueOf(0);
			}
			newop.add(p);	
		}           
		update newop;
		
		List<InventoryOpportunityProduct__c> inOp  = [SELECT MonthlyLeaseRate__c,ProductFlag__c
		                                       FROM InventoryOpportunityProduct__c
		                                       WHERE Agreement__c = :agid
		                                      ];
		List<InventoryOpportunityProduct__c> newinOp  =new List<InventoryOpportunityProduct__c>();                                      
	    for(InventoryOpportunityProduct__c inp:inOp){
	    	if(inp.ProductFlag__c==true){
			inp.MonthlyLeaseRate__c=Decimal.valueOf(rate);
	    	}else{
	    	inp.MonthlyLeaseRate__c=Decimal.valueOf(0);
	    	}
			newinOp.add(inp);			
		}                                          
		update newinOp;
		
	}
	
	/** 
     * 取引先から、見積作成の前に、案件を更新する。
     */ 
	@AuraEnabled
	public static void updateOpportunity(String OpportunityId , String oppName ,String closeDate, String userNew ,String PropertyId,String homeNumber){
		
        Opportunity opportunity  = [SELECT Name,CloseDate,UserNew__c,PropertyName__c,HomeNumber__c FROM Opportunity WHERE Id = :OpportunityId];
        opportunity.Name=oppName;                           
        opportunity.CloseDate=date.valueOf(closeDate);                    
        opportunity.UserNew__c=(String.isBlank(userNew)?null:userNew);        
        opportunity.PropertyName__c=(String.isBlank(PropertyId)?null:PropertyId);
        opportunity.HomeNumber__c = homeNumber;      
        system.debug(opportunity);       
        update opportunity;
	}
	
	
	/** 
     * リース契約情報を取得
     */ 
	@AuraEnabled
	public static LeaseRateMaster__c getLeaseRateMasterInfo(String leaseRateMasterId){
        LeaseRateMaster__c leaseRateMaster  = [SELECT InitialRate__c,SyokaiLeaseMonthCnt__c,
                                                      KeiyakuKikan__c,Hosyokin__c
		                                       FROM LeaseRateMaster__c
		                                       WHERE ID = :leaseRateMasterId
		                                      ];
	    return leaseRateMaster;
	}
}