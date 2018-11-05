public with sharing class CreateMultipleSalesBilled extends CreateInvoiceFatherBilled{
    /**
     * 販売請求作成（販売見積、保証金返金）
     * @agreementId 契約番号
     * @KBN 販売見積、保証金返金
     */
    @AuraEnabled
    public static void createBilledByAgreementId(String agreementId , String KBN){
    	//既に請求を作成したの場合、明細を作成しない、そのまま印刷。
    	List<BilledDetail__c> billedDetails;
    	if (KBN == '保証金') {
    	    billedDetails = [SELECT Id,Name,Billed__c FROM BilledDetail__c WHERE Agreement__c = :agreementId AND InventoryOpportunityProduct__c	!=null ORDER BY Billed__c];
    	} else {
    	    billedDetails = [SELECT Id,Name,Billed__c FROM BilledDetail__c WHERE Agreement__c = :agreementId ORDER BY Billed__c];
    	}
    	system.debug(billedDetails);
    	if (billedDetails.size() == 0) {
    	    String queryCondition = ' ID = \'' + agreementId + '\'' ;
            //更新、支払予定明細データを取得、CreateInvoiceFatherBilledのメソッドをコール
            List<Agreement__c> AgreementList = getAgreementList(queryCondition, '' , KBN);
            //契約から検索(初回契約)
            createSalesBilled(AgreementList,KBN);
    	}
    }

    /**
     * 請求、請求明細作成 個別作成の場合             （販売, 保証金返金）
     * @AgreementList  契約
     * @KBN            販売 ：''  保証金返金: 保証金 
     */
    private static void createSalesBilled(List<Agreement__c> AgreementList ,String KBN){
        system.debug('KBN::' + KBN);

        //請求明細
        List<BilledDetail__c> billedDetailList=new List<BilledDetail__c>();
        
        //TODO エラー処理
        if(AgreementList.size() == 0){
        	throw new AuraHandledException('エラーが発生しました');
        }
        
        Agreement__c agreement = AgreementList[0];
        
        Billed__c billed = new Billed__c();
        //請求先
        billed.Account__c = agreement.Estimate__r.Seikyusaki__r.Id;
       

    	if(KBN == '保証金'){//保証金返金の場合
    		billed.agrement__c=agreement.id;
    	    billed.KijituDate__c=agreement.ReturnHoshokinDate__c;
    	    //区分
    	    billed.Type__c = '保証金返金';
        }else{//販売の場合
        	billed.KijituDate__c=agreement.FirstPaymentDate__c;
        	//区分
        	billed.Type__c = agreement.Estimate__r.RecordType.Name;
        }
        //請求日
        billed.BilledDate__c = System.today();
        
        //請求作成
        insert billed;
        
        //請求明細の作成
        for(InventoryOpportunityProduct__c inven: agreement.InventoryOpportunityProduct__r){
    		BilledDetail__c billedDetail = new BilledDetail__c();
    		billedDetail = createBilledDetailSales(agreement,inven, agreement.Estimate__r.RecordType.Name);
    		billedDetail.Billed__c = billed.Id;
        	billedDetailList.add(billedDetail);
        }
        
        insert billedDetailList;
    }

   /**
     * 請求明細(販売)の作成
     * Param agreement 契約
     * Param billed 請求
     */
    private static BilledDetail__c createBilledDetailSales(Agreement__c agreement, InventoryOpportunityProduct__c inven, String Difference){
        system.debug(agreement.ID);

        //請求明細の作成
        BilledDetail__c billedDetail = new BilledDetail__c();

        //契約
        billedDetail.Agreement__c=agreement.ID;

		if(Difference == 'リース'){
			//計算価値価格 
	    	billedDetail.SellingPrice__c=inven.UnitPriceSellForLease__c;
	    	//商品フラグ
        	billedDetail.ProductsFlag__c=true;
		}else{	    
			//販売
		    //計算価値価格
			billedDetail.SellingPrice__c=inven.UnitPriceLease__c;
		}

		//在庫案件商品
		billedDetail.InventoryOpportunityProduct__c=inven.id;
		
        return billedDetail;
    } 
}