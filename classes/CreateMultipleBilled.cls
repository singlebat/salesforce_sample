public with sharing class CreateMultipleBilled extends CreateInvoiceFatherBilled{

    /**
     * 初回請求作成
     * Param agreementId 契約番号
     */
    @AuraEnabled
    public static void createBilledByAgreementId(String agreementId){
    	//既に請求を作成したの場合、明細を作成しない、そのまま印刷。
    	List<BilledDetail__c> billedDetails;
    	billedDetails = [SELECT Id,Name,Billed__c FROM BilledDetail__c WHERE Agreement__c = :agreementId ORDER BY Billed__c];
    	system.debug(billedDetails.size());
    	if (billedDetails.size() == 0) {
    	    String querySubCondition = ' AND Count__c = 1' ;
            String queryCondition = '  ID = \'' + agreementId + '\'' ;
            //更新、支払予定明細データを取得、CreateInvoiceFatherBilledに遷移
            List<Agreement__c> AgreementList = getAgreementList(queryCondition, querySubCondition , '');
            //契約から検索(初回契約)
            createBilled(AgreementList);
    	}
    }

    /**
     * 請求、請求明細作成 初回作成の場合             （リース初回請求）
     * @AgreementList  契約                                共通
     * @KBN                             リース初回請求
     */
    private static void createBilled(List<Agreement__c> AgreementList){
        //TODO エラー処理
        if(AgreementList.size() == 0){
        	throw new AuraHandledException('エラーが発生しました');
        }
        
        Agreement__c agreement = AgreementList[0];
        
        //請求作成
        Billed__c billed = new Billed__c();
        //請求先
        billed.Account__c = agreement.Estimate__r.Seikyusaki__r.Id;
        //区分
        billed.Type__c = agreement.Estimate__r.RecordType.Name;

        //場合
        billed.KijituDate__c = agreement.FirstPaymentDate__c;

        //請求日
        billed.BilledDate__c = System.today();
        
        insert billed;
        
		//リース初回請求
		//請求明細データを作成する
		createDetailData(agreement, billed);
    }
    
	/**
	 * 請求明細データを作成する
     * @agreement  契約
     * @billed  請求
     */    
    private static void createDetailData(Agreement__c agreement, Billed__c billed){
    	//請求明細
        List<BilledDetail__c> billedDetailList=new List<BilledDetail__c>();
    									
        for(PaymentDetails__c paymentDetail: agreement.rel_PaymentDetails__r){
            //請求明細の作成
            BilledDetail__c billedDetail = new BilledDetail__c();
            //CreateInvoiceFatherBilledのメソッドをコール
            billedDetail = createBilledDetail(agreement,paymentDetail);
            billedDetail.Billed__c = billed.Id;
            billedDetailList.add(billedDetail);
            system.debug(billedDetailList);
        }
        
        insert billedDetailList;
        
        //支払予定明細は請求明細と紐づける
        Integer i = 0;
        for(PaymentDetails__c paymentDetail: agreement.rel_PaymentDetails__r){
        	paymentDetail.BilledDetail__c = billedDetailList[i].id;
        	i++;
    	}
    	
    	update agreement.rel_PaymentDetails__r;
    }
}