/** 
 * 取引先詳細レコード画面において、「新規見積」クイックアクションより、見積作成コンポーネント向けのコントローラ
 */
public with sharing class CreateNewMitumoriController {
    	
	/** 
     * リース契約情報を取得
     */ 
	@AuraEnabled
	public static LeaseRateMaster__c getLeaseRateMasterInfo(String leaseRateMasterId){
		System.debug('leaseRateMasterId = ' + leaseRateMasterId);
        LeaseRateMaster__c leaseRateMaster  = [SELECT InitialRate__c,SyokaiLeaseMonthCnt__c,
                                                      KeiyakuKikan__c,Hosyokin__c
		                                       FROM LeaseRateMaster__c
		                                       WHERE ID = :leaseRateMasterId
		                                      ];
	    return leaseRateMaster;
	}
	
    /** 
     * 案件情報を取得
     */ 
	@AuraEnabled
	public static Account getAccountInfo(String Id , String sObjType){
		String accountId;
        if (sObjType == 'Opportunity') {
            Opportunity opportunity  = [SELECT Id,AccountId FROM Opportunity WHERE ID = :Id];
            accountId = opportunity.AccountId;
        } else {
            accountId = Id;
        }
        Account account  = [SELECT Id,ContractSigningForm__c,Bilting_Language__c FROM Account WHERE ID = :accountId];
        
	    return account;
	}

    /** 
     * 取引先から、見積作成の前に、案件を作成する。
     */ 
	@AuraEnabled
	public static Id createOpportunity(String accountId , String oppName ,String closeDate, String userNew ,String propertyName,String homeNumber){
        Opportunity opportunity  = new Opportunity(AccountId=accountId,Name=oppName ,CloseDate=date.valueOf(closeDate), UserNew__c=(String.isBlank(userNew)?null:userNew),
                                   StageName='見積・提案', Customer_Dates__c=Date.today(), Observation_date__c=Date.today(),PropertyName__c=(String.isBlank(propertyName)?null:propertyName),
                                   HomeNumber__c = homeNumber);
        insert opportunity;

	    return opportunity.Id;
	}
	
	/** 
     * 取引先から、見積作成失敗の場合、作成した案件を削除する。
     */ 
	@AuraEnabled
	public static void deleteOpportunity(String oppId){
        Database.delete(oppId);
	}
	
    /** 
     * 見積作成した後、配送作成且契約の作成、見積の初回契約の更新
     */ 
	@InvocableMethod(label='createDeliveryAndAgreement')
	public static void createDeliveryAndAgreement(List<Request> requests){
		system.debug('createDeliveryAndAgreement Start');
		for (Request request : requests) {
			//見積名の更新
			updateEstimateName(request.estimateId);
			Estimate__c estimate = [SELECT Id,Name,
			                               Opportunity__r.Account.Financial_Name__c,
			                               Opportunity__r.Account.Financial_Name_English__c,
			                               Opportunity__r.Account.Financial_branch__c,
			                               Opportunity__r.Account.Financial_branch_English__c,
			                               Opportunity__r.Account.Bank_account_type__c,
			                               Opportunity__r.Account.Bank_account_Number__c,
			                               Opportunity__r.Account.Bank_account_Nominee__c
			                        FROM Estimate__c 
			                        WHERE Id = :request.estimateId];
			String agreementName = estimate.Name.left(6) + '000';
			
			Agreement__c agreement = new Agreement__c();
			agreement.Estimate__c = request.estimateId;
			agreement.Name = agreementName;
            agreement.Financial_Name__c = estimate.Opportunity__r.Account.Financial_Name__c;
            agreement.Financial_Name_English__c = estimate.Opportunity__r.Account.Financial_Name_English__c;
            agreement.Financial_branch__c = estimate.Opportunity__r.Account.Financial_branch__c;
            agreement.Financial_branch_English__c = estimate.Opportunity__r.Account.Financial_branch_English__c;
            agreement.Bank_account_type3__c = estimate.Opportunity__r.Account.Bank_account_type__c;
            agreement.Bank_account_Number__c = estimate.Opportunity__r.Account.Bank_account_Number__c;
            agreement.Bank_account_Nominee__c = estimate.Opportunity__r.Account.Bank_account_Nominee__c;
			if(request.leaseStart!=null){
 				agreement.LeaseStart__c = request.leaseStart;
 				agreement.LeaseEnd__c = request.leaseStartEnd;
			    agreement.MonthlyLeaseRate__c = request.monthlyLeaseRate;
			}
			insert agreement;
            //配送を作成
            Delivery__c delivery = new Delivery__c(Estimate__c = request.estimateId, Agreement__c = agreement.Id);
            insert delivery;
            //案件ステータスを更新
            Opportunity opp = new Opportunity(Id = request.oppId);
            opp.StageName = '見積・提案';
            update opp;
		}
		system.debug('createDeliveryAndAgreement End');
	}
	
	public class Request {
		/*案件ID*/
        @InvocableVariable(required=true)
        public ID oppId;
        /*見積ID*/
        @InvocableVariable(required=true)
        public ID estimateId;
        /*リース開始日*/
        @InvocableVariable(required=false)
        public Date leaseStart;
        /*リース終了日*/
        @InvocableVariable(required=false)
        public Date leaseStartEnd;
        /*月額リース料*/
        @InvocableVariable(required=false)
        public Decimal monthlyLeaseRate;
    }
	
	/** 
     * 見積名の更新
     */ 
	@AuraEnabled
	public static void updateEstimateName(String estimateId){
        system.debug(estimateId);
        
        //カスタマイズ設定から、見積採番番号を取得
        List<EstimateNumber__c> estimateNums = [SELECT Id,EstimateSerialNum__c FROM EstimateNumber__c FOR UPDATE];
        //EstimateNumber__c estimateNum = EstimateNumber__c.getOrgDefaults();
	    system.debug(estimateNums);
	    EstimateNumber__c estimateNum;
	    //見積名前採番更新
	    if (estimateNums.size() == 0) {//まだ採番しないの場合
	    	estimateNum = new EstimateNumber__c();
	        estimateNum.EstimateSerialNum__c = 1;
	        insert estimateNum;
	    } else {
	    	estimateNum = estimateNums[0];
	        estimateNum.EstimateSerialNum__c += 1;
	        update estimateNum;
	    }
	    system.debug(estimateNum.EstimateSerialNum__c);
	    Estimate__c estimate = new Estimate__c();
	    estimate.Id = estimateId;
	    estimate.Name = 'L' + String.valueOf((Integer)estimateNum.EstimateSerialNum__c).leftPad(4, '0') + '_00';
	    update estimate;
	}
}